# A solution to Frosty Friday Week 4

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 4][ffw4].

## Challenge

For this week's challenge we are asked to
turn a JSON file into a table
with multiple rows.
We have to put the data
in specific columns and
we need to assign numbers to the rows
in complex ways. 

## Solution

We will start by turning the following
URL into something we can use in
an external stage:

- `https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_4/Spanish_Monarchs.json`

As usual, we substitute `https://` with `s3://`
and remove `.s3.eu-west-1.amazonaws.com`.
With the new URL we are able to create
an external stage in the following way:

```sql
CREATE OR REPLACE TEMPORARY STAGE
    ffw4_stage
    URL = 's3://frostyfridaychallenges/challenge_4/Spanish_Monarchs.json'
    FILE_FORMAT = (
        TYPE = JSON
        STRIP_OUTER_ARRAY = TRUE
        )
    ;
```

Note that we specify the `TYPE` (`JSON`)
and we instruct Snowflake to strip the outer array.
This means we will already get two rows
instead of just one row with an array containing
two elements,
which will make our life just a little bit easier
in the following part.

The rest of the solution consists of creating a temporary
table as a select statement (CTAS)
and then querying that table. 

## Getting to the data

After creating the stage,
we are essentially left with
a table with 2 rows that both contain
a semi-structured OBJECT.
We basically need to get inside these
objects and turn these 2 rows
into 26 rows with the information we need.
For this, we can use the `FLATTEN()` table function
twice and laterally join these to
the table we started with.
Take a look at the following part
of our select statement:

```sql
FROM @ffw4_stage AS top
JOIN LATERAL FLATTEN(
    input   => $1
    , path  => 'Houses'
    ) AS houses
JOIN LATERAL FLATTEN(
    input   => houses.value
    , path  => 'Monarchs'
    ) AS monarchs
```

At the `@ffw4_stage` or `top` level
we find information about the *Era*
a monarch lived in.
One level below that, 
we find information about the houses monarchs
belong to and in the final level
we get information about the individual monarchs.
Note that we are interested in the array `Houses`
and then in the array `Monarchs` below that.
By passing `Houses` and `Monarchs` as `path`,
we first get a row for each house in `Houses`
and then get a row for each monarch in `Monarchs`.
First, we take the first column (`$1`) of the stage
as input.
Then, we take the values of the first lateral join
(`houses.value`).
`FLATTEN()` returns several columns;
we are mostly interested in the `value` column,
since it contains the values for the paths
we passed to it.
We need those.

Now that we have all the rows we need,
we can start to reveal the information:

```sql
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
```

As we can see,
this mostly consists of getting certain keys
from the values.
However, we also need to do something with
occasional arrays on a lower level.
This is the case for nicknames and queen (consorts).
Sometimes these fields contain an array,
sometimes just a string.
We check if we are dealing with an array
by selecting the first element of the value that
corresponds to the key.
If there is no first element,
we will get a `NULL`
in which case we just take the whole thing as a string.
Otherwise, we just take the first element.
The second and third nicknames and queen (consorts)
are easier, since we are necessarily dealing with arrays
if there are any values.
No array would just mean `NULL` if we
try to get the second or third element out of it.

## Window functions

Finally, we need to number the rows in two ways.
This was actually one of the trickiest parts.
For the `id` column we need to assign an
ascending number
based on the date of birth.
We can use the `ROW_NUMBER()` window function for that
with an order by clause:

```sql
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
```

For the `inter_house_id` column we need to
start numbering again for every new house.
The number, however, does not correspond 
to the order the rows are in.
We need to take the order in which
the elements appear inside the arrays
as the basis for our numbering.
For this we can use the `.seq` and `.index`
fields we get with the `FLATTEN()` window function.
`.seq` shows us in which of the two initial rows
the house is (`1` of `2`).
The `.index` of the houses and monarchs show us
the order of the houses and monarchs respectively
as they appear in the arrays.

Then, we just order by `id` (`ORDER BY id`)
and query our table for our final result!

[fros]: https://frostyfriday.org/
[ffw4]: https://frostyfriday.org/blog/2022/07/15/week-4-hard/
