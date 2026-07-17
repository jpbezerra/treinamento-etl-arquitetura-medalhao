
    
    

select
    iata as unique_field,
    count(*) as n_records

from (select * from "warehouse"."main_silver"."silver_destinations" where _is_invalid = false) dbt_subquery
where iata is not null
group by iata
having count(*) > 1


