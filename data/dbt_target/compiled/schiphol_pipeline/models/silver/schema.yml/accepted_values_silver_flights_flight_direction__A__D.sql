
    
    

with all_values as (

    select
        flight_direction as value_field,
        count(*) as n_records

    from (select * from "warehouse"."main_silver"."silver_flights" where _is_invalid = false) dbt_subquery
    group by flight_direction

)

select *
from all_values
where value_field not in (
    'A','D'
)


