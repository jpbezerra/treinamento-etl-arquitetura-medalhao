select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select flight_id
from (select * from "warehouse"."main_silver"."silver_flights" where _is_invalid = false) dbt_subquery
where flight_id is null



      
    ) dbt_internal_test