/*  FROSTY FRIDAY WEEK 78

    Be sure to set a role, database, schema and warehouse
    beforehand, with `USE ROLE` etc. statements.
    */

CREATE OR REPLACE TEMPORARY TABLE w78 AS
    SELECT
    SEQ4() AS sales_id
    ,   CASE
            WHEN MOD(SEQ4(), 4) = 0 THEN 'Product A'
            WHEN MOD(SEQ4(), 4) = 1 THEN 'Product B'
            WHEN MOD(SEQ4(), 4) = 2 THEN 'Product C'
            ELSE 'Product D' 
        END 
        AS
      product_name
    , UNIFORM(1, 10, RANDOM())::INTEGER AS quantity_sold
    , DATEADD(DAY
        , - UNIFORM(1, 365, RANDOM())::INTEGER
        , CURRENT_DATE()
        ) AS
      sales_date
    , UNIFORM(20, 100, RANDOM())::FLOAT 
        * UNIFORM(1, 10, RANDOM())::INTEGER
        AS
      sales_amount
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    ;

SET sales_avg = (SELECT AVG(sales_amount) FROM w78);

SELECT * FROM w78
WHERE sales_amount
    BETWEEN $sales_avg - 50
        AND $sales_avg + 50
;
