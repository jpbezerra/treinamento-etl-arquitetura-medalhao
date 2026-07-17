
    
    



select iata
from (select * from "warehouse"."main_silver"."silver_destinations" where _is_invalid = false) dbt_subquery
where iata is null


