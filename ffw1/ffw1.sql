/* FROSTY FRIDAY WEEK 1

s3://frostyfridaychallenges/challenge_1/
http://frostyfridaychallenges.s3.amazonaws.com

s3://frostyfridaychallenges/challenge_1/1.csv
http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/1.csv
s3://frostyfridaychallenges/challenge_1/2.csv
http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/2.csv
s3://frostyfridaychallenges/challenge_1/3.csv
http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/3.csv

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
