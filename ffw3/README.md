# A solution to Frosty Friday Week 3

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 3][ffw3].

## Challenge

For the week 3 challenge we are supposed to create
3 tables.
The first table contains data from a number
of files in an S3 bucket.
These files all start with `week3_`.
The second table contains data from
just a single file `keywords.csv`.
The third table, however,
should contain the filenames
used for the first table
that contain keywords listed in the second table.
For this we need to select from a stage
and query the underlying metadata (`metadata$filename`).

## Solution

We start by creating a stage,
so we can take a look at the files
in the S3 bucket (with `list @ffw3_stage;`).
Since the CSV files in our bucket
have a header,
we use `SKIP_HEADER = 1` to skip those headers.

```sql
CREATE OR REPLACE TEMPORARY STAGE
    ffw3_stage
    URL = 's3://frostyfridaychallenges/challenge_3/'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
    )
    ;
```

## What columns do we need?  

Even though the CSV headers were skipped in
in the previous step, 
we will now use them to let Snowflake decide
what columns our table should have.
Before we can do that,
we have to create a file format:
the `INFER_SCHEMA()` function
needs a named file format;
directly specifying what we need inside
the function is not possible.

```sql
CREATE OR REPLACE FILE FORMAT
    ffw3_format
    TYPE = CSV
    PARSE_HEADER = TRUE
    ;
```

Note that we set `PARSE_HEADER` to `TRUE`,
because we are specifically interested in the headers.

Now, we are ready to create both our first
and second table using basically the same 
statements:

```sql
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
```

Note that only the table name and
`FILES => ''` change.
This is what happens in a nutshell:

1.  We use `INFER_SCHEMA()` to get 
    the information we need for the creation 
    of our table and columns from
    a file in our S3 bucket.
    We get this information in separate rows.
1.  We turn the columns in these separate rows
    into Snowflake semi-structured OBJECTs
    with `OBJECT_CONSTRUCT(*)`.
1.  We turn the separate rows with OBJECTs
    into a single semi-structured ARRAY with `ARRAY_AGG()`.
1.  We use this ARRAY as a template (`USING TEMPLATE ()`)
    while creating the tables.

## The metadata table

By now, we do not need the file format anymore
and could delete it with `drop file format ffw3_format;`.
We will do that, since we are already using `TEMPORARY` 
tables and stages that will not persist
after the Snowflake session ends.

After that, it is time to copy data from
the S3 bucket to our newly created tables:

```sql
COPY INTO ffw3_dumps
    FROM @ffw3_stage
    PATTERN = 'challenge_3/week3_.*'
    ;

COPY INTO ffw3_keywords
    FROM @ffw3_stage
    FILES = ('keywords.csv')
    ;
```

Finally, we are ready to query our stage
and see which files in our S3 bucket
have a file name that contains any of 
the keywords in our second table:

```sql
SELECT
    metadata$filename AS filename
    , COUNT(*) AS number_of_rows
FROM @ffw3_stage AS w3
INNER JOIN ffw3_keywords AS key
    ON
        CONTAINS(filename, key.keyword)
GROUP BY
    filename
```

Note that we are only able to use
`metadata$filename`
when we select directly from a stage (`@ffw3_stage`).
This query returns all the rows in our stage
where the file name of that row can be joined
to the keywords table (the second table)
and it then groups the rows together per file name
to get a count of the rows.
Alternatively, we could have queried `MAX(metadata$file_row_number)`
in stead of `COUNT(*)`.

As a last step, to see whether our solution is correct
we execute the following query:

```sql
SELECT * FROM ffw3
ORDER BY
    number_of_rows
;
```

[fros]: https://frostyfriday.org/
[ffw3]: https://frostyfriday.org/blog/2022/07/15/week-3-basic/
