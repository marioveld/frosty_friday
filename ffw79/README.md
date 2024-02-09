# A solution to Frosty Friday Week 79

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 79][ffw79].

In this weeks challenge we are asked to restrict
how a user can access our Snowflake account.
We want them to be able to use only
the *Snowflake UI* and logging in should
only be possible with username and password.

## Solution

What we need in this situation is an *authentication policy*.
We can then apply this policy to either individual users
or the entire account.
This is done with `ALTER USER SET AUTHENTICATION POLICY`
statements for users and
`ALTER ACCOUNT SET AUTHENTICATION POLICY` for the entire account.

Say we create the following authentication policy
that restricts client types to `SNOWFLAKE_UI`
and authentication methods to `PASSWORD`:

```sql
CREATE AUTHENTICATION POLICY IF NOT EXISTS
    security_db.policies.only_snowflake_ui -- schema object
    CLIENT_TYPES = ('SNOWFLAKE_UI')
    AUTHENTICATION_METHODS = ('PASSWORD')
    ;
```

We can then apply this to a user `USER_1`
with the following statement:

```sql
ALTER USER user_1
    SET AUTHENTICATION POLICY only_snowflake_ui
    ;
```

## Setup for the solution

In the SQL file that accompanies this README
you will find the various statements
that you will need to test the solution.
It presupposes SYSADMIN and SECURITYADMIN privileges.

Authentication policies are schema objects.
That means they are defined and exist within a database
and within a schema in that database.
Most of the scaffolding in the code
is focussed on handling that.

We first create a database with SYSADMIN
and then grant it to SECURITYADMIN.  
Now we can create a schema and the 
authentication policy with the SECURITYADMIN role.

If we want to test the policy,
we need to create a user
(and specify a password).
Finally, we apply the authentication policy
to the user and try logging in!

[fros]: https://frostyfriday.org/
[ffw79]: https://frostyfriday.org/blog/2024/02/02/week-79-basic/
