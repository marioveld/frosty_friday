import streamlit
from snowflake.snowpark.context import get_active_session

# Toevoeging

stage_statement = """
CREATE OR REPLACE STAGE ffw8_stage
    URL = 's3://frostyfridaychallenges/challenge_8/payments.csv'
    FILE_FORMAT = (
        TYPE = CSV
        SKIP_HEADER = 1
        )
    ;
"""

table_statement = """
CREATE OR REPLACE TABLE ffw8 
    AS
    SELECT 
        $1::int         AS row_number
        , $2::date      AS payment_date
        , $3::varchar   AS card_type
        , $4::number    AS amount_spent
    FROM @ffw8_stage
    ;
"""

query = """
SELECT
    date_trunc('week', payment_date) as payment_date
    , SUM(amount_spent) AS amount_spent
FROM ffw8
GROUP BY date_trunc('week', payment_date)
"""

# Get the current credentials
session = get_active_session()

session.sql(stage_statement).collect()
session.sql(table_statement).collect()
hallo = session.sql(query).to_pandas()

streamlit.title('Payments in 2021')

slide_test = streamlit.slider(
    'Select min date',
    min_value=min(hallo['PAYMENT_DATE']),
    max_value=max(hallo['PAYMENT_DATE']),
    value=min(hallo['PAYMENT_DATE'])
)

slide_test = streamlit.slider(
    'Select max date',
    min_value=min(hallo['PAYMENT_DATE']),
    max_value=max(hallo['PAYMENT_DATE']),
    value=max(hallo['PAYMENT_DATE'])
)

streamlit.line_chart(
    data=hallo,
    x='PAYMENT_DATE',
    y='AMOUNT_SPENT'
)
