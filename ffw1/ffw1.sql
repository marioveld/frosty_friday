/* FROSTY FRIDAY WEEK 1 */

/* Be sure to set a role, database, schema and warehouse
beforehand, with `USE ROLE` etc. statements.
*/

CREATE OR REPLACE TEMPORARY STAGE 
    challenge_1
    URL = 's3://frostyfridaychallenges/challenge_1/'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
        NULL_IF = ('NULL', 'totally_empty')
        )
    ;

/* We need a WITHIN GROUP clause
after the LISTAGG function
to order the values within the concatenation
based on the CSV filenames (`METADATA$FILENAME`)
and the rows in those CSV's (`METADATA$FILE_ROW_NUMBER`).
*/

CREATE OR REPLACE TEMPORARY TABLE
    ffw1
    AS SELECT 
        LISTAGG($1, ' ') WITHIN GROUP (ORDER BY 
            METADATA$FILENAME
            , METADATA$FILE_ROW_NUMBER
            ) AS words
    FROM @challenge_1
    ;

SELECT * FROM ffw1;
