select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    flight_id as unique_field,
    count(*) as n_records

from (select * from "warehouse"."main_silver"."silver_flights" where _is_invalid = false) dbt_subquery
where flight_id is not null
group by flight_id
having count(*) > 1



      
    ) dbt_internal_test