select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    destination_iata as unique_field,
    count(*) as n_records

from "warehouse"."main_gold"."dim_destinations"
where destination_iata is not null
group by destination_iata
having count(*) > 1



      
    ) dbt_internal_test