
    
    

select
    flight_sk as unique_field,
    count(*) as n_records

from "warehouse"."main_gold"."fct_flights"
where flight_sk is not null
group by flight_sk
having count(*) > 1


