select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select destination_iata
from "warehouse"."main_gold"."dim_destinations"
where destination_iata is null



      
    ) dbt_internal_test