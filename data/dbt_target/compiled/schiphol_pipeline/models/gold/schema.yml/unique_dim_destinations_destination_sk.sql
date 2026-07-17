
    
    

select
    destination_sk as unique_field,
    count(*) as n_records

from "warehouse"."main_gold"."dim_destinations"
where destination_sk is not null
group by destination_sk
having count(*) > 1


