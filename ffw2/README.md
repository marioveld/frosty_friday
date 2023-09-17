# A solution to Frosty Friday Week 1

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 2][ffw2].

## Challenge

In the challenge we are asked to create a stream
that records only changes to certain columns
in a table.
We are given a Parquet file with data
that we need to load into this table.
This initial data is not to be recorded in the stream
(so we create the stream afterwards).
Then, we need to apply a distinct set of changes
and see if the stream recorded them properly.
The end result should look like:

| `EMPLOYEE_ID` | `DEPT` | `JOB_TITLE` | `METADATA$ROW_ID` | `METADATA$ACTION` | `METADATA$ISUPDATE` |
| :---------- | :--- | :-------- | :-------------- | :-------------- | :---------------- |
| 25 | Marketing | Assistant Professor | 2b2b50b06e3d465bd10a62edad7f90afaacb9191 | INSERT | true |
| 68 | Product Management | Senior Financial Analyst | f1fb1b7b53417b2901ba38bd1b12970abcc2cff1 | INSERT | true |
| 25 | Accounting | Assistant Professor | 2b2b50b06e3d465bd10a62edad7f90afaacb9191 | DELETE | true |
| 68 | Product Management | Assistant Manager | f1fb1b7b53417b2901ba38bd1b12970abcc2cff1 | DELETE | true |

(Note that `METADATA$ROW_ID` will vary every time.)

## Solution

We start by the converting the URL of the download like we got
to something we can use in a Snowflake STAGE.

We need to go from `https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_2/employees.parquet` 
to `s3://frostyfridaychallenges/challenge_2/employees.parquet`.
That means we need to replace `https://` with `s3://` 
and then basically remove `.s3.eu-west-1.amazonaws.com`.

This allows us to use the URL in a stage:

```sql
CREATE OR REPLACE TEMPORARY STAGE
    ffw2_stage
    URL = 's3://frostyfridaychallenges/challenge_2/employees.parquet'
    FILE_FORMAT = (TYPE = PARQUET)
    ;
```

If we like,
we can take a look with `LS @ffw2_stage;`.

Now, we can create a table with
the contents of the Parquet file.
If we want, we can use a Snowflake function
`INFER_SCHEMA()` to automatically
create the columns based on information
that is already present in the parquet file.

Before that though, we would need a named `FILE_FORMAT`.
Otherwise we won't be able to specify a file format
to be used by `INFER_SCHEMA()`.

```sql
CREATE OR REPLACE TEMPORARY FILE FORMAT
    ffw2_format 
    TYPE = 'PARQUET'
    ;
```

## How to infer the schema of a parquet file

We can create a table based on a template
in Snowflake:

```sql
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
```

We see that this template uses 3 functions in a row:

1.  `INFER_SCHEMA()`
1.  `OBJECT_CONSTRUCT()` 
1.  `ARRAY_AGG()`

`INFER_SCHEMA()` gives us information about
the structure of the Parquet file
that we can use for the column names and data types.
`INFER_SCHEMA()` returns rows with the information we need
in separate columns.
We combine those columns with `OBJECT_CONSTRUCT()` 
by creating a single semi-structured OBJECTs per row
(Snowflake data type)
that combine all columns in those rows.
Finally, we combine all those rows into 1 array
with `ARRAY_AGG()`.

If you are curious how the result looks after each of those steps,
take a look at the following query:

```sql
WITH infer AS (
    
    SELECT * FROM TABLE(INFER_SCHEMA(
        LOCATION => '@ffw2_stage'
        , FILE_FORMAT => 'ffw2_format'
        , IGNORE_CASE => TRUE
        ))

    )

, obj AS (

    SELECT OBJECT_CONSTRUCT(*)
    FROM infer

    )

, arr AS (

    SELECT ARRAY_AGG(*)
    FROM obj

    )

select * from arr;
```

Replace `select * from arr` with
any other CTE name to see its result:

1.  `select * from infer`
1.  `select * from obj`

## Stream a view

Now that we have our table in place,
we can load the data from our previously created stage:

```sql
COPY INTO ffw2
    FROM @ffw2_stage
    MATCH_BY_COLUMN_NAME = 'CASE_INSENSITIVE'
    ;
```

Since we are only interested in certain columns
and want to ignore the rest in our stream,
we need to create a view with only those columns
before we create the stream:

```sql
CREATE OR REPLACE TEMPORARY VIEW
    ffw2_view 
    AS SELECT
        employee_id
        , dept
        , job_title
    FROM ffw2
    ;
```

Now, we simply create the stream:

```sql
CREATE OR REPLACE STREAM ffw2_stream
    ON VIEW ffw2_view
    ;
```

And that's it!
If we apply the changes to the underlying table
the stream reflects only the changes that affect
the columns specified in the view.

To make sure we got it right,
we can take a look at our stream with
the following query:

```sql
SELECT *
FROM ffw2_stream
```

## More information

1.  `https://docs.snowflake.com/en/sql-reference/sql/create-table#create-table-using-template`
1.  `https://docs.snowflake.com/en/sql-reference/functions/infer_schema`
1.  `https://en.wikipedia.org/wiki/Apache_Parquet`

[fros]: https://frostyfriday.org/
[ffw2]: https://frostyfriday.org/blog/2022/07/15/week-2-intermediate/
