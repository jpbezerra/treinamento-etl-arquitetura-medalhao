
    
    



select flight_id
from (select * from "warehouse"."main_silver"."silver_flights" where _is_invalid = false) dbt_subquery
where flight_id is null


