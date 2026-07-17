select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        flight_direction as value_field,
        count(*) as n_records

    from "warehouse"."main_gold"."fct_flights"
    group by flight_direction

)

select *
from all_values
where value_field not in (
    'A','D'
)



      
    ) dbt_internal_test