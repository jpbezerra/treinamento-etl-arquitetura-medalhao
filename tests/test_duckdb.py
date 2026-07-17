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
    FROM main_gold.fct_flights f
    JOIN main_gold.dim_destinations d USING (destination_sk)
    WHERE f.flight_direction = 'A'
    GROUP BY 1, 2
    ORDER BY atrasados DESC
""").show()