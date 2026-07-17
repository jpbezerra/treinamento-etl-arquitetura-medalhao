/*
  fct_flights
  -----------
  Fato transacional de voos — cada linha é um evento de voo em Schiphol.
  Grain: 1 linha = 1 voo (por flight_id).
  Tipo de fato: Transacional.

  Métricas disponíveis:
    - delay_minutes: diferença entre pouso real e agendado (chegadas)
    - is_delayed: flag booleano de atraso > 15 min
*/

WITH

flights AS (
    SELECT *
    FROM {{ ref('silver_flights') }}
    WHERE _is_invalid = FALSE
),

destinations AS (
    SELECT *
    FROM {{ ref('dim_destinations') }}
),

final AS (
    SELECT
        -- Surrogate key do fato (determinístico)
        md5(f.flight_id)                            AS flight_sk,

        -- FKs para dimensões
        d.destination_sk,
        CAST(strftime(f.schedule_datetime, '%Y%m%d') AS INTEGER) AS schedule_date_sk,

        -- Atributos degenerados (identificadores que ficam na fato)
        f.flight_id,
        f.flight_name,
        f.flight_number,
        f.airline_iata,
        f.flight_direction,
        f.service_type,
        f.terminal,
        f.gate,
        f.pier,
        f.flight_state,
        f.destination_iata_1,
        f.route_eu_zone,

        -- Datas e horários
        f.schedule_datetime,
        f.schedule_date,
        f.actual_landing_time,
        f.estimated_landing_time,
        f.actual_off_block_time,

        -- ── Métricas ──────────────────────────────────────────────────────────
        -- Delay em minutos (só para chegadas com pouso real registrado)
        CASE
            WHEN f.flight_direction = 'A'
             AND f.actual_landing_time IS NOT NULL
             AND f.schedule_datetime IS NOT NULL
            THEN DATEDIFF(
                'minute',
                f.schedule_datetime,
                f.actual_landing_time
            )
            ELSE NULL
        END AS delay_minutes,

        -- Flag de atraso: > 15 minutos é considerado atrasado
        CASE
            WHEN f.flight_direction = 'A'
             AND f.actual_landing_time IS NOT NULL
             AND f.schedule_datetime IS NOT NULL
             AND DATEDIFF('minute', f.schedule_datetime, f.actual_landing_time) > 15
            THEN TRUE
            ELSE FALSE
        END AS is_delayed,

        -- Metadados de controle
        f.dt_ingest,
        f.run_id,
        f.ingestion_ts

    FROM flights f
    LEFT JOIN destinations d
        ON f.destination_iata_1 = d.destination_iata
)

SELECT * FROM final