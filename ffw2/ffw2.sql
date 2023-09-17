/* FROSTY FRIDAY WEEK 2 */

/* Be sure to set a role, database, schema and warehouse
beforehand, with `USE DATABASE` etc. statements.
*/

/* We need a FILE FORMAT for the INFER_SCHEMA() function
later on:
Specifying TYPE is not possible in that function,
we need a named FILE FORMAT.
*/

CREATE OR REPLACE TEMPORARY FILE FORMAT
    ffw2_format 
    TYPE = 'PARQUET'
    ;

CREATE OR REPLACE TEMPORARY STAGE
    ffw2_stage
    URL = 's3://frostyfridaychallenges/challenge_2/employees.parquet'
    FILE_FORMAT = (TYPE = PARQUET)
    ;


CREATE OR REPLACE TEMPORARY TABLE
    ffw2
    USING TEMPLATE (

        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(INFER_SCHEMA(
            LOCATION => '@ffw2_stage'
            , FILE_FORMAT => 'ffw2_format'
            , IGNORE_CASE => TRUE
            ))

        )
    ;

/* The MATCH_BY_COLUMN_NAME copy option 
is necessary,
otherwise nothing will load.
*/

COPY INTO ffw2
    FROM @ffw2_stage
    MATCH_BY_COLUMN_NAME = 'CASE_INSENSITIVE'
    ;

/* We need to create a view with a subset of columns
if we want only those columns to be tracked: 
 */

CREATE OR REPLACE TEMPORARY VIEW
    ffw2_view 
    AS SELECT
        employee_id
        , dept
        , job_title
    FROM ffw2
    ;

CREATE OR REPLACE STREAM ffw2_stream
    ON VIEW ffw2_view
    ;
UPDATE ffw2 SET COUNTRY = 'Japan' WHERE EMPLOYEE_ID = 8;
UPDATE ffw2 SET LAST_NAME = 'Forester' WHERE EMPLOYEE_ID = 22;
UPDATE ffw2 SET DEPT = 'Marketing' WHERE EMPLOYEE_ID = 25;
UPDATE ffw2 SET TITLE = 'Ms' WHERE EMPLOYEE_ID = 32;
UPDATE ffw2 SET JOB_TITLE = 'Senior Financial Analyst' WHERE EMPLOYEE_ID = 68;

/* We use an anonymous block to get the result,
drop the stream and then show the result.
If you don't care for dropping the stream,
you could also just use `SELECT * FROM ffw2_stream`.
 */

BEGIN
    LET res RESULTSET := (

        SELECT *
        FROM ffw2_stream

    );
    DROP STREAM ffw2_stream;
    RETURN TABLE(res);
END;
