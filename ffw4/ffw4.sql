/* FROSTY FRIDAY WEEK 4 */

/* Be sure to set a role, database, schema and warehouse
beforehand, with `USE ROLE` etc. statements.
*/

CREATE OR REPLACE TEMPORARY STAGE
    ffw4_stage
    URL = 's3://frostyfridaychallenges/challenge_4/Spanish_Monarchs.json'
    FILE_FORMAT = (
        TYPE = JSON
        STRIP_OUTER_ARRAY = TRUE
        )
    ;

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
    , houses.*
FROM @ffw4_stage
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
;

/* FIELDS
 "Age at Time of Death"
  "Birth"
  "Burial Place"
  "Consort\\/Queen Consort" []
  "Death"
  "Duration"
  "End of Reign"
  "Name"
  "Nickname"
  "Place of Birth"
  "Place of Death"
  "Start of Reign"
 */