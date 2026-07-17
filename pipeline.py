"""
Pipeline Schiphol — Orquestrador
---------------------------------
Executa as três etapas em sequência:
  1. Extract   — busca dados na API da Schiphol
  2. Bronze    — achata, adiciona metadados, salva Parquet, carrega no DuckDB
  3. Transform — executa os modelos dbt (Silver + Gold)

Uso:
  python pipeline.py
"""

import logging
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

from scripts.extract import fetch_flights, fetch_destinations
from scripts.bronze_loader import process_and_load

# ── Setup ──────────────────────────────────────────────────────────────────────
load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("pipeline")

DBT_PROJECT_DIR = Path(__file__).parent / "dbt_project"


# ── Helpers ────────────────────────────────────────────────────────────────────

def make_run_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def run_dbt() -> None:
    logger.info("── Iniciando dbt run (Silver + Gold) ──")
    result = subprocess.run(
        ["dbt", "run", "--profiles-dir", ".", "--project-dir", str(DBT_PROJECT_DIR)],
        cwd=DBT_PROJECT_DIR,
        capture_output=False,
    )
    if result.returncode != 0:
        logger.error("dbt run falhou.")
        sys.exit(1)

    logger.info("── Iniciando dbt test ──")
    subprocess.run(
        ["dbt", "test", "--profiles-dir", ".", "--project-dir", str(DBT_PROJECT_DIR)],
        cwd=DBT_PROJECT_DIR,
        capture_output=False,
    )


# ── Main ───────────────────────────────────────────────────────────────────────

def main() -> None:
    run_id = make_run_id()
    logger.info(f"Pipeline iniciado — run_id: {run_id}")

    # ── 1. Extract ─────────────────────────────────────────────────────────────
    logger.info("── EXTRACT ──")
    flights_raw = fetch_flights(max_pages=3)
    destinations_raw = fetch_destinations(max_pages=5)

    # ── 2. Bronze ──────────────────────────────────────────────────────────────
    logger.info("── BRONZE ──")

    process_and_load(
        raw_records=flights_raw,
        fonte="schiphol",
        entidade="flights",
        table_name="bronze_flights",
        run_id=run_id,
    )

    process_and_load(
        raw_records=destinations_raw,
        fonte="schiphol",
        entidade="destinations",
        table_name="bronze_destinations",
        run_id=run_id,
    )

    # ── 3. Transform (dbt) ─────────────────────────────────────────────────────
    logger.info("── TRANSFORM (dbt) ──")
    run_dbt()

    logger.info(f"Pipeline concluído — run_id: {run_id}")


if __name__ == "__main__":
    main()