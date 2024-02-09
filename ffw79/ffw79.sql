/*  FROSTY FRIDAY WEEK 79 */

/*  Authentication policies
    are schema objects
    That is why we need to go through
    the folllowing steps first:
    */

USE ROLE sysadmin;
SET pswd = (SELECT randstr(24, random()));

/* If you want to copy the password for USER_1: */
-- SELECT $pswd;

CREATE DATABASE IF NOT EXISTS security_db;
GRANT OWNERSHIP
    ON DATABASE security_db
    TO ROLE securityadmin
    ;

USE ROLE securityadmin;
CREATE SCHEMA security_db.policies;
CREATE AUTHENTICATION POLICY IF NOT EXISTS
    security_db.policies.only_snowflake_ui -- schema object
    CLIENT_TYPES = ('SNOWFLAKE_UI')
    AUTHENTICATION_METHODS = ('PASSWORD')
    ;
-- SHOW AUTHENTICATION POLICIES IN ACCOUNT;
-- DESC AUTHENTICATION POLICY only_snowflake_ui;

/*  If we want to apply the authentication policy
    we cannot use CREATE USER,
    we have to use ALTER USER.
    So first we create the user
    and then we alter it:
    */

USE ROLE useradmin;
CREATE USER user_1;
USE ROLE securityadmin;
ALTER USER user_1
    SET AUTHENTICATION POLICY only_snowflake_ui
    ;

/*  If we want to test if everyting works.
    We can set a password for USER_1
    and try the various ways of logging in:
    */
ALTER USER user_1
    SET PASSWORD = $pswd
    ;

/*  We can also ALTER ACCOUNT SET AUTHENTICATION POLICY 
    to apply the authentication policy to the entire account,
    but I do not want to do that.
    */

/*  To undo the changes to our account
    we can execute the following statement:
    */

USE ROLE securityadmin;
DROP DATABASE IF EXISTS security_db;
DROP USER user_1;
