/* FROSTY FRIDAY WEEK 7

If you want, these are the drop statements
to get back to the previous state:

```sql
DROP DATABASE ffw7_db;
DROP WAREHOUSE ffw7_wh;
DROP ROLE ffw7_role;
DROP ROLE ffw7_user__1;
DROP ROLE ffw7_user__2;
DROP ROLE ffw7_user__3;
```

In the first part,
we will set up the necessary context
for the problem and solution,
by creating a warehouse, database, schema, tables
and a tag:

*/

USE ROLE accountadmin;

CREATE WAREHOUSE IF NOT EXISTS ffw7_wh
	WITH
		WAREHOUSE_SIZE = XSMALL
		INITIALLY_SUSPENDED = TRUE
	;
CREATE DATABASE IF NOT EXISTS ffw7_db;
CREATE SCHEMA IF NOT EXISTS ffw7_db.evil;

USE WAREHOUSE ffw7_wh;
USE SCHEMA ffw7_db.evil;

/*  The way the tables are set up
    is an alternative to the challenge
    that should leave us with the same results:
    */

CREATE TABLE IF NOT EXISTS
    week7_villain_information
    AS SELECT
        1                       AS id
        , 'Chrissy'             AS first_name
        , 'Riches'              AS last_name
        , 'criches0@ning.com'   AS email
        , 'Waterbuck, defassa'  AS Alter_Ego
    UNION
    SELECT
        2
        , 'Libbie'
        , 'Fargher'
        , 'lfargher1@vistaprint.com'
        , 'Ibis, puna'
    UNION
    SELECT
        3
		, 'Becka'
		, 'Attack'
		, 'battack2@altervista.org'
		, 'Falcon, prairie'
    UNION
    SELECT
        4
		, 'Euphemia'
		, 'Whale'
		, 'ewhale3@mozilla.org'
		, 'Egyptian goose'
    UNION
    SELECT 5
		, 'Dixie'
		, 'Bemlott'
		, 'dbemlott4@moonfruit.com'
		, 'Eagle, long-crested hawk'
    UNION
    SELECT
        6
		, 'Giffard'
		, 'Prendergast'
		, 'gprendergast5@odnoklassniki.ru'
		, 'Armadillo, seven-banded'
    UNION
    SELECT
        8
		, 'Celine'
		, 'Fotitt'
		, 'cfotitt7@baidu.com'
		, 'Clark''s nutcracker'
    UNION
    SELECT
        9
        , 'Leopold'
        , 'Axton'
        , 'laxton8@mac.com'
        , 'Defassa waterbuck'
    UNION
    SELECT
        10
		, 'Tadeas'
		, 'Thorouggood'
		, 'tthorouggood9@va.gov'
		, 'Armadillo, nine-banded'
    ;

CREATE TABLE IF NOT EXISTS
    week7_monster_information
    AS SELECT
        1                           AS id
		, 'Northern elephant seal'  AS monster
		, 'Huangban'                AS hideout_location
    UNION
    SELECT
        2
		, 'Paddy heron (unidentified)'
		, 'Várzea Paulista'
	UNION
	SELECT
        3
		, 'Australian brush turkey'
		, 'Adelaide Mail Centre'
	UNION
	SELECT
        4
		, 'Gecko
		, tokay'
		, 'Tafí Viejo'
	UNION
	SELECT
        5
        , 'Robin, white-throated'
        , 'Turośń Kościelna'
	UNION
	SELECT
        6
		, 'Goose, andean'
		, 'Berezovo'
	UNION
	SELECT
        7
		, 'Puku'
		, 'Mayskiy'
	UNION
	SELECT
        8
		, 'Frilled lizard'
		, 'Fort Lauderdale'
	UNION
	SELECT
        9
		, 'Yellow-necked spurfowl'
		, 'Sezemice'
	UNION
	SELECT
        10
		, 'Agouti'
		, 'Najd al Jumā‘ī'
    ;


CREATE TABLE IF NOT EXISTS
    week7_weapon_storage_location
	AS SELECT
        1                                           AS id
		, 'Ullrich-Gerhold'                         AS created_by
		, 'Mazatenango'                             AS location
		, 'Assimilated object-oriented extranet'    AS catch_phrase
		, 'Fintone'                                 AS weapon
	UNION
	SELECT
        2
		, 'Olson-Lindgren'
		, 'Dvorichna'
		, 'Switchable demand-driven knowledge user'
		, 'Andalax'
	UNION
	SELECT
        3
		, 'Rodriguez, Flatley and Fritsch'
		, 'Palmira'
		, 'Persevering directional encoding'
		, 'Toughjoyfax'
	UNION
	SELECT
        4
		, 'Conn-Douglas'
		, 'Rukem'
		, 'Robust tangible Graphical User Interface'
		, 'Flowdesk'
	UNION
	SELECT
        5
		, 'Huel, Hettinger and Terry'
		, 'Bulawin'
		, 'Multi-channelled radical knowledge user'
		, 'Y-Solowarm'
	UNION
	SELECT
        6
		, 'Torphy, Ritchie and Lakin'
		, 'Wang Sai Phun'
		, 'Self-enabling client-driven project'
		, 'Alphazap'
	UNION
	SELECT
        7
		, 'Carroll and Sons'
		, 'Digne-les-Bains'
		, 'Profound radical benchmark'
		, 'Stronghold'
	UNION
	SELECT
        8
		, 'Hane, Breitenberg and Schoen'
		, 'Huangbu'
		, 'Function-based client-server encoding'
		, 'Asoka'
	UNION
	SELECT
        9
		, 'Ledner and Sons'
		, 'Bukal Sur'
		, 'Visionary eco-centric budgetary management'
		, 'Ronstring'
	UNION
	SELECT
        10
		, 'Will-Thiel'
		, 'Zafar'
		, 'Robust even-keeled algorithm'
		, 'Tin'
    ;


/* 	Creates the TAG.
	A TAG is a schema object,
	so this TAG will be created
	in FFW7_DB.EVIL,
	since we are working in that schema.
	*/

CREATE TAG IF NOT EXISTS
	security_class
	COMMENT = 'sensitive data'
	;


/*  This challenge is about finding which
    roles accessed our "sensitive" data.
    We will create a role that will get
    all the necessary privileges and then
    assign that role to the 3 roles we made
    and are actually interested in:
    */

CREATE ROLE IF NOT EXISTS ffw7_role;
GRANT USAGE ON WAREHOUSE ffw7_wh TO ROLE ffw7_role;
GRANT USAGE ON DATABASE ffw7_db TO ROLE ffw7_role;
GRANT USAGE ON ALL SCHEMAS IN DATABASE ffw7_db TO ROLE ffw7_role;
GRANT SELECT ON ALL TABLES IN DATABASE ffw7_db TO ROLE ffw7_role;


/*  These are the roles that will
    be used to build the query history:
    */

CREATE ROLE IF NOT EXISTS ffw7_user__1;
CREATE ROLE IF NOT EXISTS ffw7_user__2;
CREATE ROLE IF NOT EXISTS ffw7_user__3;


/*  These are the role grants that we need:
    */

GRANT ROLE ffw7_user__1 TO ROLE accountadmin;
GRANT ROLE ffw7_user__2 TO ROLE accountadmin;
GRANT ROLE ffw7_user__3 TO ROLE accountadmin;
GRANT ROLE ffw7_role TO ROLE ffw7_user__1;
GRANT ROLE ffw7_role TO ROLE ffw7_user__2;
GRANT ROLE ffw7_role TO ROLE ffw7_user__3;


/*  Now, we can apply the tag to the tables
    assigning 2 different *tag value strings*:
    */

ALTER TABLE
	week7_villain_information
	SET TAG security_class = 'Level Super Secret A+++++++'
	;
ALTER TABLE
	week7_monster_information
	SET TAG security_class = 'Level B'
	;
ALTER TABLE
	week7_weapon_storage_location
	SET TAG security_class = 'Level Super Secret A+++++++'
	;


/*  These statements/queries will build our query history.
    Given these statements,
    we should expect the solution query
    to return `FFW7_USER__1` and `FFW7_USER__3`
    to us!
    */

USE ROLE ffw7_user__1;
SELECT * FROM week7_villain_information;

USE ROLE ffw7_user__2;
SELECT * FROM week7_monster_information;

USE ROLE ffw7_user__3;
SELECT * FROM week7_weapon_storage_location;


/*  This is the solution!
    We need the ACCOUNTADMIN role.
    Then a single query with multiple CTEs
    will give us the result we are looking for.
    First, we find all the Snowflake objects (tables)
    that have the tag value string (`tag value`)
    `Level Super Secret A+++++++`.
    We use the *Tag References* view in the account usage schema
    for that.
    Now we know the id's of these tables,
    we will see what queries accessed them
    by querying the *Access History* view.
    This view gives us a column that contains an array
    with semi-structured objects, that can contain the key
    `objectId`.
    The value that is associated with that key
    enables us to filter the results,
    leaving only the rows with our previously found
    object id's.
    We can now look up the query in the *Query History* view
    and find the role that was used to run that query.
    */

USE ROLE accountadmin;

WITH object_ids AS (

	SELECT *
	FROM snowflake.account_usage.tag_references
	WHERE tag_value = 'Level Super Secret A+++++++'

	)

, accessed_tables AS (

	SELECT *
	FROM snowflake.account_usage.access_history
		, LATERAL FLATTEN(base_objects_accessed)
	WHERE
		value['objectId']::number IN (

			SELECT object_id
			FROM object_ids

			)

		)

, potential_leaks AS (

	SELECT *
	FROM accessed_tables
	INNER JOIN snowflake.account_usage.query_history AS hist
		ON
			hist.query_id = accessed_tables.query_id

	)

, potential_perpetrators AS (

	SELECT DISTINCT role_name
	FROM potential_leaks

	)

SELECT * FROM potential_perpetrators
;

/*  There is also a short version if you like.
    We will not use CTE's for that one,
    but a subquery and a join.
    The order needs to be a little different,
    we put the lateral join after the inner join for example.
    I think the following query is a little harder
    to understand and
    also harder to debug,
    but can be useful in some situations.
    */

SELECT role_name
FROM snowflake.account_usage.access_history AS acs
INNER JOIN snowflake.account_usage.query_history AS hist
	ON acs.query_id = hist.query_id
, LATERAL FLATTEN(base_objects_accessed)
WHERE value['objectId']::number IN (

	SELECT object_id
	FROM snowflake.account_usage.tag_references
	WHERE tag_value = 'Level Super Secret A+++++++'

	)
;
