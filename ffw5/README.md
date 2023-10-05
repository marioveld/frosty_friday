# A solution to Frosty Friday Week 5

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 5][ffw5].

## Challenge

This challenge is about creating function
that uses Python (`LANGUAGE`).
The function should return the input
integer times three (`* 3`)
and we should be able to use this function
inside a query!

## Solution

As instructed, we start by creating a table
that contains integers:

```sql
CREATE OR REPLACE TEMPORARY TABLE
    ff_week_5
    AS SELECT 
        ROW_NUMBER() OVER (ORDER BY TRUE) AS start_int
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
    ;
```

Since we don't want to manually insert 500 lines
we use the table function `GENERATOR()`.
This creates 500 rows, without a column however!
Because we want the column `start_int` to contain
ascending integers starting from 1,
we use the window function `ROW_NUMBER()`.
`ROW_NUMBER()` needs an order by clause.
However, it does not matter what expression we use there.
It can basically be anything.
So, we could use `ORDER BY 1`,
`ORDER BY SEQ1()` (which is often used in similar cases),
or `ORDER BY TRUE`.
The last one is the smallest/quickest expression
we can use here, I think.

## The Python User-Defined Function

Now, we will create a Python user-defined function (or UDF):

```sql
CREATE OR REPLACE TEMPORARY FUNCTION
    timesthree (num NUMBER)
    RETURNS NUMBER
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.10'
    HANDLER = 'fun'

AS $$

def fun(num):
    return num * 3

$$;
```

The Python function is pretty simple, as expected:

```python
def fun(num):
    return num * 3
```

However, it is important to note
that Python uses significant whitespace
and we are not allowed to put any tabs or other
whitespace in front of the lines,
other than the obligatory 4 spaces in front
of `return num * 3`.

If we look at the first part of the `CREATE FUNCTION` statement,
we see that we need a name and argument for the function.
Furthermore, we need to specify what the function will return:
`RETURNS NUMBER`.
Naturally, we need to say what programming language is used
(`LANGUAGE PYTHON`)
and we specify the Python version `RUNTIME VERSION = '3.10'`.
Probably the least straightforward part is `HANDLER`.
We can do a lot of things inside the function definition (`AS $$ $$`).
We can define multiple functions,
define variables and so on and so forth.
With `HANDLER` we simply tell Snowflake
which function inside the function definition
we want to use for what we will return with the UDF.
In this case we define a Python function `fun()`
inside the function definition
and we want to use that function in a query
outside the `CREATE FUNCTION` statement.
So, we say `HANDLER = 'fun'`.

Now, we only have to test whether our UDF
works as intended:

```sql
SELECT start_int, timesthree(start_int)
FROM FF_week_5
ORDER BY
    start_int
;
```

And we are done!

[fros]: https://frostyfriday.org/
[ffw5]: https://frostyfriday.org/blog/2022/07/15/week-5-basic/
