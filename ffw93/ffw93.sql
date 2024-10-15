/* FROSTY FRIDAY WEEK 93 */

/*
Make sure you use a role that has
the CREATE INTEGRATION permission.
This is an account-level permission that needs
to be granted by the ACCOUNTADMIN role.
If your role is named FROSTY,
you could use the following statements:

```sql
use role accountadmin;
grant create integration on account to role FROSTY;
```

You also need to be in the right schema,
on which the current role has ownership.
Only the EXTERNAL ACCESS INTEGRATION is an
account-level resource.
All the other resources we will be creating are
schema-level.
*/

CREATE OR REPLACE NETWORK RULE
    treasury_nr
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = ('api.fiscaldata.treasury.gov')
;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION
    treasury_eai
    ALLOWED_NETWORK_RULES = (treasury_nr)
    ENABLED = TRUE
;

CREATE OR REPLACE TABLE
    week_93
    ( avg_interest_rate_amt FLOAT
    , record_date DATE
    , security_desc STRING
    , security_type_desc STRING
    , src_line_nbr STRING
    , api_call_start_date DATE
    , api_call_end_date DATE
    )
;

CREATE OR REPLACE PROCEDURE
    get_treasury_data(start_date DATE, end_date DATE)
    RETURNS TEXT
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.8'
    EXTERNAL_ACCESS_INTEGRATIONS = (treasury_eai)
    PACKAGES = ('snowflake-snowpark-python', 'requests')
    HANDLER = 'insertData'
    as
$$
import snowflake.snowpark.session
import requests
import datetime

def getData(start_date, end_date):
    host = 'api.fiscaldata.treasury.gov'
    path = '/services/api/fiscal_service//v2/accounting/od/avg_interest_rates'
    fields = ','.join([
        'avg_interest_rate_amt'
        , 'record_date'
        , 'security_desc'
        , 'security_type_desc'
        , 'src_line_nbr'
    ])
    filters = f'record_date:gte:{start_date},record_date:lte:{end_date}'
    url = f'https://{host}{path}?fields={fields}&filter={filters}'
    data = []
    next_url = url
    while True:
        resp = requests.get(next_url).json()
        new_data = resp['data']
        data.extend(new_data)
        next_page = resp["links"]["next"]
        next_url = f'{url}{next_page}'
        if new_data == [] or next_page is None:
            break
    return data

def insertData(session, start_date, end_date):
    api_call_start_date = datetime.date.today()
    data = getData(start_date, end_date)
    if len(data) == 0:
        return f'No data to be inserted'
    api_call_end_date = datetime.date.today()
    df_data = session.create_dataframe(data)
    df = df_data.withColumn(
        'api_call_start_date'
        , snowflake.snowpark.functions.lit(api_call_start_date)
    ).withColumn(
        'api_call_end_date'
        , snowflake.snowpark.functions.lit(api_call_end_date)
    )
    df.write.mode('truncate').saveAsTable('zeven_db.aap.week_93')
    return f'Inserted {len(data)} rows into table.'
$$
;

CALL get_treasury_data('2020-01-01'::date, '2024-04-30'::date);
SELECT * FROM week_93;
