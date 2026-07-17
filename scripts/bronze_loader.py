"""
Bronze Loader
-------------
Responsabilidades:
  1. Achatar (flatten) os registros da API — objetos aninhados viram JSON string.
  2. Adicionar metadados obrigatórios: dt_ingest, run_id, ingestion_ts, source_system.
  3. Todos os campos como STRING (princípio da Bronze).
  4. Salvar como Parquet na estrutura de pastas padrão:
       data/bronze/<fonte>/<entidade>/dt_ingest=YYYY-MM-DD/run_id=<id>/parte_0.parquet
  5. Carregar os Parquet no DuckDB para que o dbt possa lê-los como sources.
"""

import json
import logging
import os
from datetime import datetime, timezone
from pathlib import Path

import duckdb
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

logger = logging.getLogger(__name__)

BRONZE_BASE = Path("data/bronze")
DW_PATH = Path("data/warehouse.duckdb")


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

def _flatten(record: dict) -> dict:
    """
    Achata um dicionário um nível. Objetos aninhados (dict/list)
    são serializados como JSON string — a Bronze não interpreta, só guarda.
    """
    flat: dict[str, str | None] = {}
    for key, value in record.items():
        if isinstance(value, (dict, list)):
            flat[key] = json.dumps(value, ensure_ascii=False)
        elif value is None:
            flat[key] = None
        else:
            flat[key] = str(value)
    return flat


def _add_metadata(records: list[dict], run_id: str, source_system: str) -> list[dict]:
    """Injeta metadados obrigatórios da Bronze em cada registro."""
    now = datetime.now(timezone.utc)
    dt_ingest = now.strftime("%Y-%m-%d")
    ingestion_ts = now.isoformat()

    result = []
    for rec in records:
        flat = _flatten(rec)
        flat["dt_ingest"] = dt_ingest
        flat["run_id"] = run_id
        flat["ingestion_ts"] = ingestion_ts
        flat["source_system"] = source_system
        result.append(flat)
    return result


# ─────────────────────────────────────────────
# Salvar Parquet
# ─────────────────────────────────────────────

def save_to_bronze(records: list[dict], fonte: str, entidade: str, run_id: str) -> Path:
    """
    Salva os registros como Parquet na estrutura:
      data/bronze/<fonte>/<entidade>/dt_ingest=YYYY-MM-DD/run_id=<run_id>/parte_0.parquet
    """
    dt_ingest = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    path = BRONZE_BASE / fonte / entidade / f"dt_ingest={dt_ingest}" / f"run_id={run_id}"
    path.mkdir(parents=True, exist_ok=True)

    df = pd.DataFrame(records)
    # Garante que tudo é string (principio da Bronze)
    df = df.astype(str).where(df.notna(), other=None)

    table = pa.Table.from_pandas(df, preserve_index=False)
    output_file = path / "parte_0.parquet"
    pq.write_table(table, output_file)

    logger.info(f"[bronze] salvo: {output_file} ({len(records)} registros)")
    return output_file


# ─────────────────────────────────────────────
# Carregar no DuckDB
# ─────────────────────────────────────────────

def load_into_duckdb(fonte: str, entidade: str, table_name: str) -> None:
    """
    Lê todos os Parquet da entidade e cria/substitui a tabela no DuckDB.
    O dbt irá referenciar essas tabelas como sources.
    """
    pattern = str(BRONZE_BASE / fonte / entidade / "**" / "*.parquet")
    con = duckdb.connect(str(DW_PATH))

    con.execute(f"""
        CREATE OR REPLACE TABLE {table_name} AS
        SELECT * FROM read_parquet('{pattern}', hive_partitioning=true)
    """)

    count = con.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
    logger.info(f"[duckdb] tabela '{table_name}' carregada com {count} registros")
    con.close()


# ─────────────────────────────────────────────
# Interface pública
# ─────────────────────────────────────────────

def process_and_load(
    raw_records: list[dict],
    fonte: str,
    entidade: str,
    table_name: str,
    run_id: str,
) -> None:
    """
    Fluxo completo para uma entidade:
      raw records → flatten + metadata → Parquet → DuckDB
    """
    enriched = _add_metadata(raw_records, run_id=run_id, source_system=fonte)
    save_to_bronze(enriched, fonte=fonte, entidade=entidade, run_id=run_id)
    load_into_duckdb(fonte=fonte, entidade=entidade, table_name=table_name)