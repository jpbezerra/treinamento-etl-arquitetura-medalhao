# Pipeline Schiphol — ETL Local com Python + dbt + DuckDB

Pipeline completo que extrai dados da API pública da Schiphol e implementa a
Arquitetura Medalhão (Bronze → Silver → Gold) 100% local, sem cloud.

## Arquitetura

```
API Schiphol
    │
    │  Extract (requests)
    ▼
data/bronze/schiphol/
    ├── flights/dt_ingest=YYYY-MM-DD/run_id=.../parte_0.parquet
    └── destinations/dt_ingest=YYYY-MM-DD/run_id=.../parte_0.parquet
    │
    │  Load (duckdb)
    ▼
data/warehouse.duckdb
    ├── main.bronze_flights
    └── main.bronze_destinations
    │
    │  Transform (dbt)
    ▼
    ├── silver.slv_flights        ← tipado, deduplicado, com flags
    ├── silver.slv_destinations   ← tipado, deduplicado, com flags
    ├── gold.dim_destinations     ← dimensão com surrogate key
    └── gold.fct_flights          ← fato transacional com métricas de delay
```

## Setup

### 1. Criar chaves na API da Schiphol

Acesse https://developer.schiphol.nl/, crie uma conta e gere um app.
Você receberá um `app_id` e um `app_key`.

### 2. Configurar variáveis de ambiente

```bash
cp .env.example .env
# edite o .env e cole seu app_id e app_key
```

### 3. Instalar dependências

```bash
pip install -r requirements.txt
```

### 4. Rodar o pipeline

```bash
python pipeline.py
```

Isso irá:
- Buscar voos e destinos da API (3 páginas de voos, 5 de destinos)
- Salvar os Parquet na estrutura Bronze em `data/bronze/`
- Carregar os dados no DuckDB em `data/warehouse.duckdb`
- Executar `dbt run` (Silver + Gold)
- Executar `dbt test` (asserções de qualidade)

## Estrutura do Projeto

```
schiphol-pipeline/
├── .env.example
├── requirements.txt
├── pipeline.py                         ← orquestrador principal
├── scripts/
│   ├── extract.py                      ← chamadas à API Schiphol
│   └── bronze_loader.py                ← flatten + parquet + duckdb
├── data/
│   ├── bronze/                         ← parquet files (gerado em runtime)
│   └── warehouse.duckdb                ← banco local (gerado em runtime)
└── dbt_project/
    ├── dbt_project.yml
    ├── profiles.yml                    ← conexão DuckDB
    └── models/
        ├── sources.yml                 ← aponta para tabelas bronze no DuckDB
        ├── silver/
        │   ├── schema.yml              ← testes das tabelas silver
        │   ├── slv_flights.sql
        │   └── slv_destinations.sql
        └── gold/
            ├── schema.yml              ← testes das tabelas gold
            ├── dim_destinations.sql
            └── fct_flights.sql
```

## Consultando os Resultados

Depois de rodar o pipeline, consulte qualquer tabela diretamente:

```python
import duckdb
con = duckdb.connect("data/warehouse.duckdb")

# Voos atrasados por destino
con.sql("""
    SELECT
        d.destination_name,
        d.country,
        COUNT(*) AS total_chegadas,
        SUM(CASE WHEN f.is_delayed THEN 1 ELSE 0 END) AS atrasados,
        ROUND(AVG(f.delay_minutes), 1) AS atraso_medio_min
    FROM gold.fct_flights f
    JOIN gold.dim_destinations d USING (destination_sk)
    WHERE f.flight_direction = 'A'
    GROUP BY 1, 2
    ORDER BY atrasados DESC
""").show()
```

## Endpoints utilizados

| Endpoint | Descrição |
|---|---|
| `GET /flights` | Voos (chegadas e partidas) em tempo real e programados |
| `GET /destinations` | Aeroportos de destino com código IATA, cidade e país |