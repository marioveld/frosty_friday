/* FROSTY FRIDAY WEEK 6 */

/* Be sure to set a role, database, schema and warehouse
beforehand, with `USE ROLE` etc. statements.
*/

/* The CSV contains fields that are mostly enclosed
by double quotes and sometimes contain comma's.
That is why we need `FIELD_OPTIONALLY_ENCLOSED_BY ='"'`:
*/

CREATE OR REPLACE TEMPORARY STAGE
    nations_regions_stage
    URL = 's3://frostyfridaychallenges/challenge_6/nations_and_regions.csv'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        )
    ;

CREATE OR REPLACE TEMPORARY STAGE
    constituencies_stage
    URL = 's3://frostyfridaychallenges/challenge_6/westminster_constituency_points.csv'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        )
    ;

/* We need a FILE FORMAT that parses headers
for use with the INFER_SCHEMA() table function:
*/

CREATE OR REPLACE TEMPORARY FILE FORMAT
    ffw6_format
    TYPE = CSV
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ;

CREATE OR REPLACE TEMPORARY TABLE
    nations_regions
    USING TEMPLATE (

        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(INFER_SCHEMA(
            LOCATION => '@nations_regions_stage'
            , FILE_FORMAT => 'ffw6_format'
            , IGNORE_CASE => TRUE
            ))

        )
    ;

CREATE OR REPLACE TEMPORARY TABLE
    constituencies
    USING TEMPLATE (

        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        FROM TABLE(INFER_SCHEMA(
            LOCATION => '@constituencies_stage'
            , FILE_FORMAT => 'ffw6_format'
            , IGNORE_CASE => TRUE
            ))

        )
    ;


COPY INTO nations_regions
    FROM @nations_regions_stage
    ;

COPY INTO constituencies
    FROM @constituencies_stage
    ;

select * from nations_regions;

WITH nat_reg_parts AS (

    /* First we combine all the points,
    in the separate parts of nations or regions,
    together as a string:
    */

    SELECT 
        nation_or_region_name
        , '((' 
            ||  LISTAGG(concat_ws(' ', longitude, latitude), ', ') 
                WITHIN GROUP (ORDER BY sequence_num)
            || '))'
            AS part
    FROM nations_regions
    GROUP BY 
        nation_or_region_name
        , part

    )

, nat_reg_multipolygons AS (

    /* Now, we can combine all the parts
    to form a MultiPolygon string
    that conforms to the
    *Well-known text representation of geometry*:
    */

    SELECT 
        nation_or_region_name
        , ST_GEOGRAPHYFROMWKT(
            'MULTIPOLYGON (' 
                ||  LISTAGG(part, ', ') 
                    WITHIN GROUP (ORDER BY part)
                || ')'
            )
            AS mutli_polygon
    FROM nat_reg_parts
    GROUP BY 
        nation_or_region_name

    )

, constituency_parts AS (

    SELECT 
        constituency
        , '((' 
            ||  LISTAGG(concat_ws(' ', longitude, latitude), ', ') 
                WITHIN GROUP (ORDER BY sequence_num)
            || '))'
            AS part
    FROM constituencies
    GROUP BY 
        constituency
        , part

    )

, constituency_multipolygons AS (

    SELECT 
        constituency
        , ST_GEOGRAPHYFROMWKT(
            'MULTIPOLYGON (' 
                ||  LISTAGG(part, ', ') 
                    WITHIN GROUP (ORDER BY part)
                || ')'
            )
            AS mutli_polygon
    FROM constituency_parts
    GROUP BY 
        constituency

    )


/* We use ST_INTERSECTS as
a filter here,
retaining only rows where
the regions or nation intersects
with a constituency:
*/

SELECT
    nation_or_region_name
    , COUNT(*) AS intersecting_constituencies 
FROM nat_reg_multipolygons AS natreg
JOIN constituency_multipolygons AS cons
WHERE
    ST_INTERSECTS(
        natreg.mutli_polygon
        , cons.mutli_polygon
        )
GROUP BY 1
ORDER BY 2 DESC
;
