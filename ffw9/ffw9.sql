/*  FROSTY FRIDAY WEEK 9

    Be sure to set a role, database, schema and warehouse
    beforehand, with `USE ROLE` etc. statements.
    The role should not be ACCOUNTADMIN,
    but it should have `APPLY MASKING POLICY ON ACCOUNT`.
    */


CREATE OR REPLACE TEMPORARY TABLE data_to_be_masked 
    AS
    SELECT
        'Eveleen'               AS first_name
        , 'Danzelman'           AS last_name
        , 'The Quiet Antman'    AS hero_name
    UNION
    SELECT 'Harlie', 'Filipowicz','The Yellow Vulture'
    UNION
    SELECT 'Mozes', 'McWhin','The Broken Shaman'
    UNION
    SELECT 'Horatio', 'Hamshere','The Quiet Charmer'
    UNION
    SELECT 'Julianna', 'Pellington','Professor Ancient Spectacle'
    UNION
    SELECT 'Grenville', 'Southouse','Fire Wonder'
    UNION
    SELECT 'Analise', 'Beards','Purple Fighter'
    UNION
    SELECT 'Darnell', 'Bims','Mister Majestic Mothman'
    UNION
    SELECT 'Micky', 'Shillan','Switcher'
    UNION
    SELECT 'Ware', 'Ledstone','Optimo'
    ;


/*  We will create 2 TAGs,
    one for the first names
    and the second one for the last names:
    */

CREATE TAG IF NOT EXISTS lower_ups;
CREATE TAG IF NOT EXISTS higher_ups;


/*  Now, we will create 2 MASKING POLICIES
    that will later be applied to one of the 2 tags.
    Note that we already use the names of
    the roles that have not yet been created.
    This is not a problem, since these are just strings:
    */

CREATE MASKING POLICY IF NOT EXISTS
    lower_mask
    AS (val VARCHAR)
    RETURNS VARCHAR
    ->
    CASE
        WHEN IS_ROLE_IN_SESSION('FOO1')
        THEN val
        ELSE '******'
    END
    ;

CREATE MASKING POLICY IF NOT EXISTS
    higher_mask
    AS (val VARCHAR)
    RETURNS VARCHAR
    ->
    CASE
        WHEN IS_ROLE_IN_SESSION('FOO2')
        THEN val
        ELSE '******'
    END
    ;


/*  We apply the masking policies to the right tags:
    */

ALTER TAG lower_ups SET MASKING POLICY lower_mask;
ALTER TAG higher_ups SET MASKING POLICY higher_mask;


/*  We only have to apply the tags to the
    right columns in the table:
    */

ALTER TABLE data_to_be_masked
    MODIFY COLUMN first_name SET TAG lower_ups = ''
    , COLUMN last_name SET TAG higher_ups = ''
    ;


/*  We want to create the 2 roles
    so we can test the tags.
    FOO2 is higher up than FOO1,
    so we grant F001 to FOO2.
    We also need to save some context
    for later:
    */

SET usr = CURRENT_USER();
SET rle = CURRENT_ROLE();

USE ROLE USERADMIN;
CREATE ROLE IF NOT EXISTS foo1;
CREATE ROLE IF NOT EXISTS foo2;
GRANT ROLE foo1 TO ROLE foo2;


/*  Grant the higher role to the current user: */

GRANT ROLE foo2 TO USER IDENTIFIER($usr);


/*  Grant access to the table and a warehouse
    by granting the role that created the table
    to the lower role:
    */

USE ROLE securityadmin;
GRANT ROLE IDENTIFIER($rle) TO ROLE foo1;


/*  Check if everything works: */

USE ROLE accountadmin;
SELECT * FROM data_to_be_masked;
USE ROLE foo1;
SELECT * FROM data_to_be_masked;
USE ROLE foo2;
SELECT * FROM data_to_be_masked;
