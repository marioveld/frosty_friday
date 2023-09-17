# A solution to Frosty Friday Week 1

[Frosty Friday][fros] is a weekly Snowflake challange series
created by Christopher Marland and Mike Droog.
These challanges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 2][ffw2].

## How to infer the schema of a parquet file

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

## Result

| `EMPLOYEE_ID` | `DEPT` | `JOB_TITLE` | `METADATA$ROW_ID` | `METADATA$ACTION` | `METADATA$ISUPDATE` |
| :---------- | :--- | :-------- | :-------------- | :-------------- | :---------------- |
| 25 | Marketing | Assistant Professor | 2b2b50b06e3d465bd10a62edad7f90afaacb9191 | INSERT | true |
| 68 | Product Management | Senior Financial Analyst | f1fb1b7b53417b2901ba38bd1b12970abcc2cff1 | INSERT | true |
| 25 | Accounting | Assistant Professor | 2b2b50b06e3d465bd10a62edad7f90afaacb9191 | DELETE | true |
| 68 | Product Management | Assistant Manager | f1fb1b7b53417b2901ba38bd1b12970abcc2cff1 | DELETE | true |

## More information

1.  `https://docs.snowflake.com/en/sql-reference/sql/create-table#create-table-using-template`
2.  `https://docs.snowflake.com/en/sql-reference/functions/infer_schema`

[fros]: https://frostyfriday.org/
[ffw2]: https://frostyfriday.org/blog/2022/07/15/week-2-intermediate/
