/*  FROSTY FRIDAY WEEK 71

    Be sure to set a role, database, schema and warehouse
    beforehand, with `USE ROLE` etc. statements.
    */

/* Challenge setup */

/* Create the Sales table */

CREATE OR REPLACE TEMPORARY TABLE 
    sales (  
        sale_id         INT PRIMARY KEY
        , product_ids   VARIANT --INT
        )
    ;

/* Inserting sample sales data */

/* Products A and C in the same sale */

INSERT INTO sales 
    (sale_id, product_ids) 
    SELECT 1, PARSE_JSON('[1, 3]')
    ;

/* Products B and D in the same sale */

INSERT INTO sales 
    (sale_id, product_ids) 
    SELECT 2, PARSE_JSON('[2, 4]')
    ; 


/* Create the Products table */

CREATE OR REPLACE TEMPORARY TABLE 
    products (
        product_id              INT PRIMARY KEY
        , product_name          VARCHAR
        , product_categories    VARIANT --VARCHAR
        )
    ;

/* Inserting sample data into Products */

INSERT INTO products 
    (product_id, product_name, product_categories) 
    SELECT 1, 'Product A', ARRAY_CONSTRUCT('Electronics', 'Gadgets')
    ;
INSERT INTO products 
    (product_id, product_name, product_categories) 
    SELECT 2, 'Product B', ARRAY_CONSTRUCT('Clothing', 'Accessories')
    ;
INSERT INTO products 
    (product_id, product_name, product_categories) 
    SELECT 3, 'Product C', ARRAY_CONSTRUCT('Electronics', 'Appliances')
    ;
INSERT INTO products 
    (product_id, product_name, product_categories) 
    SELECT 4, 'Product D', ARRAY_CONSTRUCT('Clothing')
    ;

/*  Solution 

    */

/*  We need the PRODUCT_IDs
    to be in a form that can be used in a join.
    That is why we first flatten the array in SALES,
    so we have the separate PRODUCT_IDs:
    */

WITH product_ids AS (

    SELECT
        sale_id
        , value::int as product_id
    FROM sales
        , LATERAL FLATTEN(product_ids)

    )

/*  Now, we perform a join
    that will give us the categories that belong to the 
    SALES_IDs.
    Since we flattened the categories,
    we need to recompose them into an array
    using `ARRAY_AGG()`:
    */

, categories AS (

    SELECT
        ids.sale_id
        , ARRAY_AGG(product_categories) AS
          commoncategories
    FROM product_ids as ids
    LEFT JOIN products
        ON ids.product_id = products.product_id
    GROUP BY
        sale_id
    ORDER BY 
        sale_id

    )

/*  Finally, we can query the CTE
    to get our answer.
    */

SELECT * FROM categories