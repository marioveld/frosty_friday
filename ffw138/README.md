# A solution to Frosty Friday Week 138

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 138][ffw138].

This week's challenge is about the behavior
of `NULL` values when ordering results in a query.
If we order rows based on the value in a certain field
and that column contains `NULL` values,
Snowflake needs to decide what to do.
By default, Snowflake will order ascending (`ASC`)
and will put the records that have a `NULL` order field value
at the bottom.
We can do 2 things to change this behavior,
while still sorting ascending:

1.  We can set the `DEFAULT_NULL_ORDERING` session parameter to `FIRST`.
1.  We can add `NULLS FIRST` to the `ORDER BY` clause.

This will cause the records with `NULL` values to show at the top.
Now, if we sort descending (`ORDER BY ... DESC`)
the behavior is sort of inverted.
That means that in the default situation `NULL`'s will show up
at the top.
Changing the session parameter and/or adding `NULLS FIRST` to the clause
will make sure the `NULL` records go to the bottom again!
For more information see the Snowflake documentation
on the [DEFAULT NULL ORDERING parameter][parameter].

[fros]: https://frostyfriday.org/
[ffw138]: https://frostyfriday.org/blog/2025/04/25/week-138-intermediate/
[parameter]: https://docs.snowflake.com/en/sql-reference/parameters#default-null-ordering
