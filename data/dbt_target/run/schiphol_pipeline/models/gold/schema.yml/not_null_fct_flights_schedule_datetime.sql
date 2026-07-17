select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select schedule_datetime
from "warehouse"."main_gold"."fct_flights"
where schedule_datetime is null



      
    ) dbt_internal_test