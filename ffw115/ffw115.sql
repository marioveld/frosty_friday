/* FROSTY FRIDAY WEEK 115 */

/*
This Challenge has 4 different parts.
For every part we will be making a table,
inserting some data,
and then querying that table
with a Snowflake regular expression function.

Make sure you are in the right schema:
all objects will be made in this schema.
*/

/* Challenge 1: Validate Complex Email Addresses */

create or replace table users (
    user_id INT AUTOINCREMENT
    , email VARCHAR
);

INSERT OVERWRITE INTO users (email) VALUES
    ('john.doe@example.com')
    , ('invalid-email@.com')
    , ('alice_smith@sub-domain.co.uk')
    , ('bob@domain.com')
    , ('user@invalid_domain@com')
;

SELECT
    *
    , REGEXP_LIKE(email, '[a-zA-Z0-9].*[a-z]+\.[a-z]{2,6}') AS valid_email
    , REGEXP_LIKE(email, $$\w.*\w+\.\w{2,6}$$) AS valid_email_underscores
FROM users
;

/* Challenge 2: Extract Valid Dates in Multiple Formats */

CREATE TABLE documents (
    doc_id INT AUTOINCREMENT PRIMARY KEY,
    text_column VARCHAR(500)
);
INSERT INTO documents (text_column) VALUES
    ('This document was created on 15/03/2023.')
    , ('The report is due by 04-15-2022.')
    , ('Version 1.0 released on 2021.08.30.')
    , ('No date provided in this text.')
    , ('Invalid date 32/13/2020.')
;

SELECT
    *
    , COALESCE(
        TRY_TO_DATE(
            REGEXP_SUBSTR(text_column, $$\d{2}/\d{2}/\d{4}$$)
            , 'DD/MM/YYYY'
          )
        , TRY_TO_DATE(
            REGEXP_SUBSTR(text_column, $$\d{2}-\d{2}-\d{4}$$)
            , 'MM-DD-YYYY'
          )
        , TRY_TO_DATE(
            REGEXP_SUBSTR(text_column, $$\d{4}.\d{2}.\d{2}$$)
            , 'YYYY.MM.DD'
          )
    ) AS extracted_date
FROM documents
;

/* Challenge 3: Mask Credit Card Numbers */

CREATE TABLE transactions (
    transaction_id INT AUTOINCREMENT PRIMARY KEY,
    card_number VARCHAR(50)
);
INSERT INTO transactions (card_number) VALUES
    ('1234-5678-9012-3456'),
    ('9876 5432 1098 7654'),
    ('1111222233334444'),
    ('4444-3333-2222-1111'),
    ('Invalid number 12345678901234567')
;

SELECT
    *
    , REGEXP_REPLACE(
        REGEXP_REPLACE(
            card_number
            , $$(\d{4}-\d{4}-\d{4})-(\d{4})$$, 'XXXX-XXXX-XXXX-\\2'
          )
        , '(^\\d{12})(\\d{4}$)'
        , 'XXXXXXXXXXXX\\2'
      ) AS masked_card_number_alt
FROM transactions
;

/* If we don't mind masking some not well-formed card numbers: */

SELECT
    *
    , REGEXP_REPLACE(
        REGEXP_REPLACE(card_number, $$\d{4}-$$, 'XXXX-')
        , $$\d{12}$$
        , REPEAT('X', 12)
        )
    AS masked_card_number
FROM transactions
;

/* Challenge 4: Extract Hashtags from a Text Block */

CREATE TABLE social_posts (
    post_id INT AUTOINCREMENT PRIMARY KEY,
    text_column VARCHAR(500)
);
INSERT INTO social_posts (text_column) VALUES
    ('Check out our new product! #launch #excited')
    , ('Loving the weather today! #sunnyDay #relax')
    , ('Follow us at #example_page for more updates!')
    , ('No hashtags in this sentence.')
;

SELECT
    *
    , array_to_string(regexp_substr_all(text_column, '#\\w*'), ' ')
      AS extracted_hashtags
FROM social_posts
;/
