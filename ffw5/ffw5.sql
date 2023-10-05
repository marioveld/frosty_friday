/* FROSTY FRIDAY WEEK 5 */

/* Be sure to set a role, database, schema and warehouse
beforehand, with `USE ROLE` etc. statements.
*/

/* We use the GENERATOR table function in combination
with SEQ1 to create rows and then we
fill in the values 1 to 500 with the ROW_NUMBER() window function:
*/

CREATE OR REPLACE TEMPORARY TABLE
    ff_week_5
    AS SELECT
        ROW_NUMBER() OVER (ORDER BY TRUE) AS start_int
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
    ;

CREATE OR REPLACE TEMPORARY FUNCTION
    timesthree (num NUMBER)
    RETURNS NUMBER
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.10'
    HANDLER = 'fun'

/* Note that there should not be
any indentation for the following Python lines:
*/

AS $$

def fun(num):
    return num * 3

$$;

SELECT start_int, timesthree(start_int)
FROM FF_week_5
ORDER BY
    start_int
;