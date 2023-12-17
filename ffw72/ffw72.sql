/*  FROSTY FRIDAY WEEK 72

    In the challenge we are directed to
    `s3://frostyfridaychallenges`.
    However, we need to search a little bit before we
    can find the SQL instructions that we
    want to execute for the solution.

    After we created the stage,
    we take a look with `LS @ffw72_stage;`.
    We find `challenge_72/insert.sql`,
    which looks like something we can execute with
    an `EXECUTE IMMEDIATE FROM`.
*/

ls @ffw72_stage;

CREATE OR REPLACE TEMPORARY TABLE
    week72_employees (
        employeeid INT,
        firstname STRING,
        lastname STRING,
        dateofbirth DATE,
        position STRING
        )
    ;

CREATE OR REPLACE TEMPORARY STAGE 
    ffw72_stage
    URL = 's3://frostyfridaychallenges'
    ;

EXECUTE IMMEDIATE
    FROM @ffw72_stage/challenge_72/insert.sql
    ;


/*  The following query
    gives us the result we are looking for!
    */
SELECT * FROM week72_employees;


/*  If we want to be prudent,
    we could take a look at the code
    before we execute it.
    We could either run a *curl* command from the command line,
    or create a temporary file format,
    that allows us to see what is happening
    directly from Snowflake.
    For the curl command we need to convert 
    `s3://frostyfridaychallenges/challenge_72/insert.sql` to 
    `https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_72/insert.sql`.
    Then, we can execute it:

    ```sh
    curl https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_72/insert.sql
    ```

    For the Snowflake method, see below.
    */

/*  We use `\r` as the field delimiter
    so there are no conflicts with the
    row delimiter,
    while still allowing us to get the whole line
    until the line break.
    */

CREATE OR REPLACE TEMPORARY FILE FORMAT
    ffw72_format
    TYPE = CSV
    FIELD_DELIMITER = '\r'
    ;


/*  Now we can query
    the data in the staged file.
    We use `LISTAGG()` to show a single string,
    making sure we get the right order
    by specifying `metadata$file_row_number`
    in the after `WITHIN GROUP`:
    */

SELECT 
    LISTAGG($1, '\n') 
        WITHIN GROUP (ORDER BY metadata$file_row_number)
        AS
    code
FROM @ffw72_stage/challenge_72/insert.sql
(FILE_FORMAT => 'ffw72_format')
;
