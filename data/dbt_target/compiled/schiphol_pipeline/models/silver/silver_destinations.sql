/*
  silver_destinations
  ----------------
  Grain: 1 linha = 1 aeroporto de destino (pelo código IATA)

  O que esta camada faz:
    - Deduplica por `iata`, mantendo a ingestão mais recente
    - Extrai campos do objeto publicName (JSON serializado na Bronze)
    - Aplica flag `_is_invalid` em registros sem IATA
*/

WITH

deduped AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY iata
                ORDER BY ingestion_ts DESC
            ) AS rn
        FROM "warehouse"."main"."bronze_destinations"
        WHERE iata IS NOT NULL AND iata != 'None'
    )
    WHERE rn = 1
),

typed AS (
    SELECT
        iata,
        city,
        country,

        -- publicName é um objeto JSON: {"dutch": "...", "english": "..."}
        json_extract_string(publicName, '$.dutch')      AS name_dutch,
        json_extract_string(publicName, '$.english')    AS name_english,

        -- Metadados da Bronze
        dt_ingest,
        run_id,
        TRY_CAST(ingestion_ts AS TIMESTAMPTZ) AS ingestion_ts,
        source_system

    FROM deduped
),

final AS (
    SELECT
        *,
        CASE
            WHEN iata IS NULL    THEN TRUE
            WHEN country IS NULL THEN TRUE
            ELSE FALSE
        END AS _is_invalid,

        CASE
            WHEN iata IS NULL    THEN 'missing_iata'
            WHEN country IS NULL THEN 'missing_country'
            ELSE NULL
        END AS _invalid_reason

    FROM typed
)

SELECT * FROM final