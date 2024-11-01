/* FROSTY FRIDAY WEEK 95 */

/*
The procedure we are going to make is a schema-level object.
So we need to specify which schema we are going to use beforehand,
with a `USE SCHEMA` statement.
Also, make sure the current role has enough privileges
to create a procedure in that schema.
Ownership on the schema should be sufficient,
in combination with usage on the database and a warehouse.
*/

/*
The following `PUT` statement works when using VSCODE
with the official Snowflake extension.
It does not work with Snowsight, however,
where you would need to use a named stage and the GUI.

I you are on a Mac like I am,
had a user named `Zeven`,
and had the python script `congrats.py` on the Desktop,
you could use the path `/Users/Zeven/Desktop/congrats.py`:
*/

PUT file:///Users/Zeven/Desktop/congrats.py @~;

CREATE OR REPLACE PROCEDURE
    frosty_challenge()
    RETURNS string
    LANGUAGE python
    PACKAGES=('snowflake-snowpark-python')
    imports=('@~/congrats.py')
    HANDLER = 'func'
    RUNTIME_VERSION=3.8
    AS
$$
import congrats

def func(session):
    return congrats.success()
$$
;

CALL frosty_challenge();
