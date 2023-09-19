/* FROSTY FRIDAY WEEK 3 */

/* Be sure to set a role, database, schema and warehouse
beforehand, with `USE DATABASE` etc. statements.
*/

/* The FILE FORMAT is necesary for the later
INFER_SCHEMA functions:
 */

CREATE OR REPLACE FILE FORMAT
    ffw3_format
    TYPE = CSV
    PARSE_HEADER = TRUE
    ;

CREATE OR REPLACE TEMPORARY STAGE
    ffw3_stage
    URL = 's3://frostyfridaychallenges/challenge_3/'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
    )
    ;

/* We will infer the columns for both tables
from the files in the stage:
*/

CREATE OR REPLACE TEMPORARY TABLE
    ffw3_dumps
    USING TEMPLATE (

        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(INFER_SCHEMA(
            LOCATION => '@ffw3_stage'
            , FILES => 'week3_data1.csv'
            , FILE_FORMAT =>'ffw3_format'
            , IGNORE_CASE => TRUE
            ))

        )
    ;
CREATE OR REPLACE TEMPORARY TABLE
    ffw3_keywords
    USING TEMPLATE (

        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(INFER_SCHEMA(
            LOCATION => '@ffw3_stage'
            , FILES => 'keywords.csv'
            , FILE_FORMAT =>'ffw3_format'
            , IGNORE_CASE => TRUE
            ))

        )
    ;

/* we do not need the FILE FORMAT anymore: */

DROP FILE FORMAT ffw3_format;

COPY INTO ffw3_dumps
    FROM @ffw3_stage
    PATTERN = 'challenge_3/week3_.*'
    ;

COPY INTO ffw3_keywords
    FROM @ffw3_stage
    FILES = ('keywords.csv')
    ;


CREATE OR REPLACE TEMPORARY TABLE
    ffw3
    AS (

        SELECT
            metadata$filename AS filename
            , COUNT(*) AS number_of_rows
        FROM @ffw3_stage AS w3
        INNER JOIN ffw3_keywords AS key
            ON
                CONTAINS(filename, key.keyword)
        GROUP BY
            filename

        )
    ;

SELECT * FROM ffw3
ORDER BY
    number_of_rows
;
