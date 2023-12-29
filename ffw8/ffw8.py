import streamlit
from snowflake.snowpark.context import get_active_session

def getPaymentsDataframe(stage_name, table_name):
    """This function executes
    statements on Snowflake
    to create a stage that refers to the S3 CSV
    of this challenge
    and a table with the data inside that CSV.
    Then it executes a query to get that data
    and returns it inside a dataframe.
    """

    stage_statement = f"""

        CREATE OR REPLACE STAGE {stage_name}
            URL = 's3://frostyfridaychallenges/challenge_8/payments.csv'
            FILE_FORMAT = (
                TYPE = CSV
                SKIP_HEADER = 1
                )
            ;

        """

    table_statement = f"""

        CREATE OR REPLACE TABLE {table_name}
            AS
            SELECT
                $1::int         AS row_number
                , $2::date      AS payment_date
                , $3::varchar   AS card_type
                , $4::number    AS amount_spent
            FROM @{stage_name}
            ;

        """

    query = f"""

        SELECT
            date_trunc('week', payment_date) as payment_date
            , SUM(amount_spent) AS amount_spent
        FROM {table_name}
        GROUP BY date_trunc('week', payment_date)

        """

    session = get_active_session()

    stage_response = session.sql(stage_statement).collect()
    table_response = session.sql(table_statement).collect()
    payments_dataframe = session.sql(query).to_pandas()

    return payments_dataframe

def createApp(payments_dataframe):
    """This function takes a dataframe
    and creates the streamlit app based
    on that dataframe.
    No connection is made to Snowflake.
    """

    streamlit.title('Payments in 2021')

    payment_dates = payments_dataframe['PAYMENT_DATE']
    min_payment_date = min(payment_dates)
    max_payment_date = max(payment_dates)


    min_date = streamlit.slider(
        'Select min date',
        min_value=min_payment_date,
        max_value=max_payment_date,
        value=min_payment_date
        )

    max_date = streamlit.slider(
        'Select max date',
        min_value=min_payment_date,
        max_value=max_payment_date,
        value=max_payment_date
        )

    filtered_dataframe = payments_dataframe[
        (payments_dataframe['PAYMENT_DATE'] >= min_date)
        & (payments_dataframe['PAYMENT_DATE'] <= max_date)
        ]

    streamlit.line_chart(
        data=filtered_dataframe,
        x='PAYMENT_DATE',
        y='AMOUNT_SPENT'
        )

    return None

createApp(getPaymentsDataframe('ffw8_stage', 'ffw8'))
