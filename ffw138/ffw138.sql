/* FROSTY FRIDAY WEEK 138 */

/* Change the session parameter from the default `LAST`: */

ALTER SESSION SET DEFAULT_NULL_ORDERING = 'FIRST';

/* WARNING: some peppers are too hot too handle!!
If you don't know the Scoville heat, don't eat!
*/

WITH peppers AS (
    SELECT 'Habanero' AS pepper, 225000 AS scoville_heat_units
    UNION SELECT 'Carolina Reaper', NULL
    UNION SELECT 'Madame Jeanette', 225000
    UNION SELECT 'Cayenne', 40000
    UNION SELECT 'Dragon\'s Breath', NULL
    UNION SELECT 'Adjuma', 250000
    UNION SELECT 'Frigitello', 250
    UNION SELECT 'Tabasco', 40000
)
SELECT * FROM PEPPERS
ORDER BY scoville_heat_units NULLS LAST -- !!!
;
