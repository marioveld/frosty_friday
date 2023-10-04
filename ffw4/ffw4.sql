/* FROSTY FRIDAY WEEK 4 */

/* Be sure to set a role, database, schema and warehouse
beforehand, with `USE ROLE` etc. statements.
*/

/* We can strip the outer array
so we have an operation less we need to do
later on:
*/

CREATE OR REPLACE TEMPORARY STAGE
    ffw4_stage
    URL = 's3://frostyfridaychallenges/challenge_4/Spanish_Monarchs.json'
    FILE_FORMAT = (
        TYPE = JSON
        STRIP_OUTER_ARRAY = TRUE
        )
    ;

CREATE OR REPLACE TEMPORARY TABLE
    ffw4
    AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY monarchs.value['Birth'])  
            AS 
          id
        , ROW_NUMBER() OVER (
            PARTITION BY
                houses.seq
                , houses.index
            ORDER BY 
                houses.seq ASC
                , houses.index ASC
                , monarchs.index ASC
            ) AS
          inter_house_id
        , top.$1['Era']::varchar AS era
        , houses.value['House']::varchar
            AS 
          house
        , monarchs.value['Name']::varchar
            AS 
          name
        , IFNULL(
            monarchs.value['Nickname'][0]
            , monarchs.value['Nickname']
            )::varchar AS 
          nickname_1
        , monarchs.value['Nickname'][1]::varchar
            AS 
          nickname_2
        , monarchs.value['Nickname'][2]::varchar
            AS 
          nickname_3
        , monarchs.value['Birth']::date
            AS 
          birth
        , monarchs.value['Place of Birth']::varchar
            AS 
          place_of_birth
        , monarchs.value['Start of Reign']::date
            AS 
          start_of_reign
        , IFNULL(
            monarchs.value['Consort\\/Queen Consort'][0]
            , monarchs.value['Consort\\/Queen Consort']::varchar
            ) AS
          queen_or_queen_consort_1
        , monarchs.value['Consort\\/Queen Consort'][1]::varchar
            AS
          queen_or_queen_consort_2
        , monarchs.value['Consort\\/Queen Consort'][2]::varchar
            AS
          queen_or_queen_consort_3
        , monarchs.value['End of Reign']::date
            AS
          end_of_reign
        , monarchs.value['Duration']::varchar
            AS
          duration
        , monarchs.value['Death']::date
            AS
          death
        , monarchs.value['Age at Time of Death']::varchar
            AS
          age_at_time_of_death_years
        , monarchs.value['Place of Death']::varchar
            AS
          place_of_death
        , monarchs.value['Burial Place']::varchar
            AS
          burial_place
    FROM @ffw4_stage AS top
    JOIN LATERAL FLATTEN(
        input   => $1
        , path  => 'Houses'
        ) AS houses
    JOIN LATERAL FLATTEN(
        input   => houses.value
        , path  => 'Monarchs'
        ) AS monarchs
    ORDER BY 
        id
    )
    ;

SELECT * FROM ffw4;
