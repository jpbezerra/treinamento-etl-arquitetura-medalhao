/*
  silver_flights
  -----------
  Grain: 1 linha = 1 voo (pela versão mais recente de cada id)

  O que esta camada faz:
    - Deduplica por `id`, mantendo a ingestão mais recente
    - Converte tipos (timestamps, inteiros, booleanos)
    - Extrai o primeiro destino do array JSON `route`
    - Aplica flag `_is_invalid` em registros sem id ou sem scheduleDateTime
    - NÃO aplica regras de negócio — apenas conforma o dado
*/

WITH

-- ── 1. Deduplicação ───────────────────────────────────────────────────────────
-- Cada voo pode aparecer múltiplas vezes na Bronze (janela deslizante ou
-- reprocessamentos). Mantemos apenas a versão com maior ingestion_ts.
deduped AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY id
                ORDER BY ingestion_ts DESC
            ) AS rn
        FROM {{ source('bronze', 'bronze_flights') }}
        WHERE id IS NOT NULL AND id != 'None'
    )
    WHERE rn = 1
),

-- ── 2. Tipagem e extração de campos ──────────────────────────────────────────
typed AS (
    SELECT
        -- Identificadores
        id                                                  AS flight_id,
        flightName                                          AS flight_name,
        flightNumber                                        AS flight_number,
        prefixIATA                                          AS airline_iata,
        prefixICAO                                          AS airline_icao,

        -- Direção: A = Arrival, D = Departure
        flightDirection                                     AS flight_direction,

        -- Tipo de serviço (J = passageiros regular, C = charter, etc.)
        serviceType                                         AS service_type,

        -- Datas e horários
        TRY_CAST(scheduleDateTime  AS TIMESTAMPTZ)          AS schedule_datetime,
        TRY_CAST(scheduleDate      AS DATE)                 AS schedule_date,
        TRY_CAST(actualLandingTime AS TIMESTAMPTZ)          AS actual_landing_time,
        TRY_CAST(estimatedLandingTime AS TIMESTAMPTZ)       AS estimated_landing_time,
        TRY_CAST(actualOffBlockTime   AS TIMESTAMPTZ)       AS actual_off_block_time,

        -- Infra aeroportuária
        TRY_CAST(terminal AS INTEGER)                       AS terminal,
        gate,
        pier,

        -- Rota: o campo `route` é um JSON serializado na Bronze
        -- Extraímos o primeiro destino do array destinations
        json_extract_string(route, '$.destinations[0]')    AS destination_iata_1,
        json_extract_string(route, '$.eu')                 AS route_eu_zone,
        json_extract_string(route, '$.visa')               AS route_visa_required,

        -- Estado público do voo (array serializado)
        json_extract_string(publicFlightState, '$.flightStates[0]') AS flight_state,

        -- Metadados da Bronze (preservados)
        dt_ingest,
        run_id,
        TRY_CAST(ingestion_ts AS TIMESTAMPTZ)               AS ingestion_ts,
        source_system

    FROM deduped
),

-- ── 3. Flags de qualidade ────────────────────────────────────────────────────
final AS (
    SELECT
        *,
        CASE
            WHEN flight_id IS NULL         THEN TRUE
            WHEN schedule_datetime IS NULL THEN TRUE
            WHEN flight_direction NOT IN ('A', 'D') THEN TRUE
            ELSE FALSE
        END AS _is_invalid,

        CASE
            WHEN flight_id IS NULL         THEN 'missing_flight_id'
            WHEN schedule_datetime IS NULL THEN 'missing_schedule_datetime'
            WHEN flight_direction NOT IN ('A', 'D') THEN 'invalid_flight_direction'
            ELSE NULL
        END AS _invalid_reason

    FROM typed
)

SELECT * FROM final