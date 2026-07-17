select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select iata
from (select * from "warehouse"."main_silver"."silver_destinations" where _is_invalid = false) dbt_subquery
where iata is null



      
    ) dbt_internal_test