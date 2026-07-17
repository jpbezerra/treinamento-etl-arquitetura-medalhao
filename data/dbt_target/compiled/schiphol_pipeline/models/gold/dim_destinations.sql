/*
  dim_destinations
  ----------------
  Dimensão de aeroportos de destino.
  Grain: 1 linha = 1 aeroporto.

  Surrogate key: md5 do código IATA (determinístico — suporta reprocessamento).
*/

WITH

valid AS (
    SELECT *
    FROM "warehouse"."main_silver"."silver_destinations"
    WHERE _is_invalid = FALSE
)

SELECT
    md5(iata)                       AS destination_sk,   -- surrogate key
    iata                            AS destination_iata,  -- natural key
    COALESCE(name_english, city)    AS destination_name,
    name_dutch                      AS destination_name_dutch,
    city,
    country,

    -- Metadados de controle
    dt_ingest,
    ingestion_ts

FROM valid