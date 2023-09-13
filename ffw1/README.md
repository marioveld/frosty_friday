# A solution to Frosty Friday Week 1

[Frosty Friday][fros] is a weekly Snowflake challange series
created by Christopher Marland and Mike Droog.
These challanges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 1][ffw1].

## Challange

In the challange we are asked to take data
in an Amazon S3 bucket
and load it to a `TABLE` in Snowflake,
using a Snowflake `STAGE`.

The Amazon S3 bucket can be referecend from
`s3://frostyfridaychallenges/challenge_1/`.

## Solution

After making a stage with the Amazon S3 bucket URL,
it is possible to see which files are contained in the bucket:

```sql
CREATE OR REPLACE TEMPORARY STAGE
    challenge_1
    URL = 's3://frostyfridaychallenges/challenge_1/'
    ;

LS @challenge_1;
```

This shows us that there are 3 files:

|                                                 |
| :---------------------------------------------- |
| `s3://frostyfridaychallenges/challenge_1/1.csv` |
| `s3://frostyfridaychallenges/challenge_1/2.csv` |
| `s3://frostyfridaychallenges/challenge_1/3.csv` |

If we want to see what is inside these files we can 
change these references a little bit and come to
the following URLs:

1.  `http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/1.csv`
1.  `http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/2.csv`
1.  `http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/3.csv`

This is generally something that can be done
with these kinds of Amazon S3 buckets.

Now we can simply enter these URLs in a browser and see what is
in them.
Or, we can use curl from the command-line:

```sh
curl 'http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/1.csv'
# result
# you
# have
# gotten
curl 'http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/2.csv'
# result
# it
curl 'http://frostyfridaychallenges.s3.amazonaws.com/challenge_1/3.csv'
# result
# right
# NULL
# totally_empty
# congratulations!
```

There seems to be a header `result`
and the values `NULL` and `totally_empty` seem
like something we should substitue with SQL NULL.

[fros]: https://frostyfriday.org/
[ffw1]: https://frostyfriday.org/blog/2022/07/14/week-1/
