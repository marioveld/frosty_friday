# A solution to Frosty Friday Week 6

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 6][ffw6].

## Challenge

In this week's challenge,
we are given 2 CSV's.
These contain geographical information about
nations or regions on the one side
and parliamentary constituencies on the other.
These entities can consist of one or more
territories or area's (in a non-mathematical sense) 
that need not be contiguous.
A good example is the *Argyll and Bute* constituency
that has multiple islands in it, 
separated by sea.
A good way to represent these areas (different islands for example)
is to use polygons.
These polygons are made up of a collection
of connected combinations of longitude and latitude values (points).

In the challenge, we are confronted with 
rows of longitude and latitude values
associated with the polygon or one of the polygons
that can be used to represent
a constituency or a region or nation.
First, we need to create polygons of these
longitude and latitude values.
Then, we can use these polygons to compute
the intersections between nations/regions
on the one side and constituencies on the other.
Finally, we can show how many constituencies
are (partially) within a nation or region.

## Geospatial

Many geospatial functions in Snowflake start with `ST`.
Perhaps, this stands for **S**pa**T**ial.
We will use two of them in this challenge:

1.  `ST_GEOGRAPHYFROMWKT()`
1.  `ST_INTERSECTS()`

First, however, we need to ingest
the data into Snowflake.

## Ingest using a template

Both datasets are structured quite
similarly,
so we will only look at one here.
First, we create a stage for the CSV:

```sql
CREATE OR REPLACE TEMPORARY STAGE
    constituencies_stage
    URL = 's3://frostyfridaychallenges/challenge_6/westminster_constituency_points.csv'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        )
    ;
```

Note that we skip the header.
Some of the fields contain comma's
and are enclosed by double quotes `"`.
So, we need to pass `FIELD_OPTIONALLY_ENCLOSED_BY = '"'`
and let Snowflake keep these fields together.

Now, we are going to use `INFER_SCHAMA()`
to create the columns we need automatically
from the CSV.
In order to do that,
we have to create a `FILE FORMAT` with
`PARSE_HEADER = TRUE`,
becasue `INFER_SCHEMA()` needs the header!

```sql
CREATE OR REPLACE TEMPORARY FILE FORMAT
    ffw6_format
    TYPE = CSV
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ;
```

Then, we can use `INFER_SCHEMA()` table function
to first create a row for every 
column in the CSV:

```sql
SELECT *
FROM TABLE(INFER_SCHEMA(
    LOCATION => '@constituencies_stage'
    , FILE_FORMAT => 'ffw6_format'
    , IGNORE_CASE => TRUE
    ))
;
```

The output of the above query would be the
following table:


| COLUMN_NAME | TYPE | NULLABLE | EXPRESSION | FILENAMES | ORDER_ID |
| :---------- | :--- | :------- | :--------- | :-------- | :------- |
| CONSTITUENCY | TEXT | true | $1::TEXT | challenge_6/westminster_constituency_points.csv | 0 |
| SEQUENCE_NUM | NUMBER(4, 0) | true | $2::NUMBER(4, 0) | challenge_6/westminster_constituency_points.csv | 1 |
| LONGITUDE | NUMBER(7, 6) | true | $3::NUMBER(7, 6) | challenge_6/westminster_constituency_points.csv | 2 |
| LATITUDE | NUMBER(8, 6) | true | $4::NUMBER(8, 6) | challenge_6/westminster_constituency_points.csv | 3 |
| PART | NUMBER(3, 0) | true | $5::NUMBER(3, 0) | challenge_6/westminster_constituency_points.csv | 4 |

We can see that all the information we need to
create a table is present.
This is not enough to let Snowflake create a table
from a template, however.
We still need to do two more things:

1.  Reduce the number of columns to one
    by putting all columns in a semi-structured
    `OBJECT`.
1.  Reduce the number of rows to one
    by putting all rows in a semi-structured
    `ARRAY`.

This creates an `OBJECT` for every row:

```sql
SELECT OBJECT_CONSTRUCT(*)
FROM TABLE(INFER_SCHEMA(
    LOCATION => '@constituencies_stage'
    , FILE_FORMAT => 'ffw6_format'
    , IGNORE_CASE => TRUE
    ))
;
```

And this, then, creates an `ARRAY` of
every row:

```sql
SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
FROM TABLE(INFER_SCHEMA(
    LOCATION => '@constituencies_stage'
    , FILE_FORMAT => 'ffw6_format'
    , IGNORE_CASE => TRUE
    ))
;
```

Now, we are left with a single row
containing a single column
that can be used by `USING TEMPLATE()` below:

```sql
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
```

Obviously, we also need to actually populate the table:

```sql
COPY INTO constituencies
    FROM @constituencies_stage
    ;
```

## Solution

Now that we ingested all the data,
we just need 1 query
to get the answer we are looking for.
It is a pretty complex query, however:

```sql
WITH nat_reg_parts AS (

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
```

Let's break down what happens here.
We have a number of common table expressions (CTEs).
Two create the polygons for the *nations or regions*
and two other create the polygons for the *constituencies*.
After that, we have the main query that combines
all the polygons.

We have a similar process for *nation or regions*
and *constituencies*.
So, let's only look at constituencies for now.
The first CTE for constituencies,
creates a string that can be used inside
a [well-known text representation of geometry][wwkt] (WKT).
A WKT is a human-readable string that can be
used in Snowflake (and other places)
to represent geometry objects,
e.g. MultiPolygons.

Since we have longitude and latitude values in separate
rows we use the `LISTAGG()` aggregate function
that combines strings in multiple rows into one.
We know that the points needed in MultiPolygons
are separated from each other by a comma
and that longitude and latitude values
that make up that point are separated by a space.
So we `CONCAT_WS` the longitude to the latitude of a row
and then `LISTAGG` them with a `,`.
The points inside our MultiPolygon should be in
a specific order
and the first point should be the same as the last point.
Therefore, we need to order the result
of the `LISTAGG()` aggregate function
and we do that with `WITHIN GROUP (ORDER BY sequence_num)`.
`sequence_num` is a field present in the CSV
that indicates the order of points.

Another thing to note is that
a constituency can consist of multiple
non-contiguous parts and therefore polygons.
At this stage we have a row for every part
of every constituency:

```sql
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
```

We are ready to combine the separate parts
of the constituencies into strings
that adhere to the format of a WKT:

```sql
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
```

Again, we first use a `LISTAGG()`:
we combine the rows for each part
of a constituency into one.
Then, we add `MULTIPOLYGON` to the
string and place a few parentheses.
When the string has all the elements it needs
it is ready to be passed to the
`ST_GEOGRAPHYFROMWKT()` function
that turns a string that is a WKT
into a value of the `GEOGRAPHY` data type.
We need that for the next part of the query:

```sql
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
```

Here, we first join *nations or regions*
to *constituencies*
on the condition that the respective multipolygons
intersect with one another.
This is done with the `ST_INTERSECTS()` function.
Finally, we simply group by the nation or region name
and then count how many constituency intersect
for that nation or region.

And this completes the Frosty Friday Week 6 challenge!

[fros]: https://frostyfriday.org/
[ffw6]: https://frostyfriday.org/blog/2022/07/22/week-6-hard/
[wwkt]: https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry
