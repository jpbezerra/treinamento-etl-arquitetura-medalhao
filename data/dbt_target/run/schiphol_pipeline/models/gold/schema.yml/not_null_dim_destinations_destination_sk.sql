select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select destination_sk
from "warehouse"."main_gold"."dim_destinations"
where destination_sk is null



      
    ) dbt_internal_test