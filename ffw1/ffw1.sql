/* FROSTY FRIDAY WEEK 1 */

/* This solution focusses on getting the phrase
"you have gotten it right congratulations!"
as a result.

We use TEMPORARY for both STAGE and TABLE
in order not to create anything permanent in our account.

The bucket contains CSV files
so we use `TYPE = CSV`. 
The CSV-specific options `SKIP_HEADER` makes sure 
we don't get header rows.
We want 'totally_emtpy' and 'NULL' to be
considered SQL NULL,
because they don't look like real words
and we cannot use them in our phrase ;)
*/

CREATE OR REPLACE TEMPORARY STAGE 
    challenge_1
    URL = 's3://frostyfridaychallenges/challenge_1/'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
        NULL_IF = ('NULL', 'totally_empty')
        )
    ;

/* Since we want to get our phrase out,
we use the `LISTAGG()` to combine all the rows
into one.
But we need the words to be in a certain order:
the order of the files and then the order of the
rows in those files.

We cannot use `ORDER BY` here because that
will just order our single row.
Instead, we need to use `WITHIN GROUP` after
the LISTAGG to be able to specify
the order we want the result of LISTAGG to be in.

`METADATA$FILENAME` gives us the filenames
of files in the Amazon S3 bucket,
while `METADATA$FILE_ROW_NUMBER` gives
us the row numbers of the columns in those files.
We can use those to get a correct `ORDER BY`.
*/

CREATE OR REPLACE TEMPORARY TABLE
    ffw1
    AS SELECT 
        LISTAGG($1, ' ') WITHIN GROUP (ORDER BY 
            METADATA$FILENAME
            , METADATA$FILE_ROW_NUMBER
            ) AS words
    FROM @challenge_1
    ;

SELECT * FROM ffw1;
