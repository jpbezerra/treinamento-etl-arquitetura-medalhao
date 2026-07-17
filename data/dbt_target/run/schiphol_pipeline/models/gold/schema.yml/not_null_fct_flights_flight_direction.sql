select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select flight_direction
from "warehouse"."main_gold"."fct_flights"
where flight_direction is null



      
    ) dbt_internal_test