# A solution to Frosty Friday Week 78

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 78][ffw78].

## AVG()

A nice feature of Snowflake session variables,
is that you can actually assign the result
of a subquery.
One important requirement for that is that the
subquery returns just one value,
not a number of rows.
Snowflake also needs to know that a single value
(or a scalar) will be returned.
That is why the following line works in our solution for this week:

```sql
SET sales_avg = (SELECT AVG(sales_amount) FROM w78);
```

`AVG()` is an aggregate function,
so we know it's going to return just one value
(unless it is used as a window function of course).

[fros]: https://frostyfriday.org/
[ffw78]: https://frostyfriday.org/blog/2024/01/26/week-78-basic/
