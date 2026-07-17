select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select _is_invalid
from "warehouse"."main_silver"."silver_destinations"
where _is_invalid is null



      
    ) dbt_internal_test