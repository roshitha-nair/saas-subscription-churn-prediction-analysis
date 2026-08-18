/*
SaaS / Subscription Churn Prediction & Analysis

File: 01_extraction.sql

SQL Dialect: DuckDB SQL
Execution Environment: DBeaver + DuckDB

Objective:
Create a customer-level feature-ready analytical base table for churn
analysis and prediction.

Final analytical grain:
    One row = one customer

Logical warehouse entities:
    1. customer
       - customer demographics and household attributes

    2. subscription
       - tenure, contract, billing, payment, and charge information

    3. service
       - phone, internet, security, support, backup, protection, and
         streaming services

    4. churn outcome
       - observed churn status

The source Telco dataset is physically stored as a single CSV. The entities
above represent a logical warehouse-style separation for analytical SQL
design rather than separate physical source tables.

Business objective:
    Produce a customer-level feature-ready dataset that can be passed to
    Pandas for cleaning/feature engineering and later used for churn
    modeling and revenue-at-risk analysis.
*/


-- ============================================================
-- 1. Customer Base CTE
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id,
        gender,
        SeniorCitizen AS senior_citizen,
        Partner AS has_partner,
        Dependents AS has_dependents
    FROM raw_telco_churn
)

SELECT *
FROM customer_base;


-- ============================================================
-- 2. Customer Base Grain Validation
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id,
        gender,
        SeniorCitizen AS senior_citizen,
        Partner AS has_partner,
        Dependents AS has_dependents
    FROM raw_telco_churn
)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_base;


-- ============================================================
-- 3. Duplicate Customer Validation
-- Expected result: 0 rows
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id,
        gender,
        SeniorCitizen AS senior_citizen,
        Partner AS has_partner,
        Dependents AS has_dependents
    FROM raw_telco_churn
)

SELECT
    customer_id,
    COUNT(*) AS row_count
FROM customer_base
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 4. Subscription Base CTE
-- ============================================================

WITH subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
)

SELECT *
FROM subscription_base;


-- ============================================================
-- 5. Subscription Base Grain Validation
-- ============================================================

WITH subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM subscription_base;


-- ============================================================
-- 6. Subscription Duplicate Validation
-- Expected result: 0 rows
-- ============================================================

WITH subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
)

SELECT
    customer_id,
    COUNT(*) AS row_count
FROM subscription_base
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 7. Subscription Field Range & Raw Data Validation
--
-- Purpose:
-- Validate the expected ranges of tenure and monthly charges
-- and confirm the number of blank TotalCharges values carried
-- forward from the raw source.
--
-- Cleaning of TotalCharges is intentionally deferred to Pandas.
-- Expected:
--   min_tenure = 0
--   max_tenure = 72
--   min_monthly_charges = 18.25
--   max_monthly_charges = 118.75
--   blank_total_charges = 11
-- ============================================================

WITH subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
)

SELECT
    MIN(tenure) AS min_tenure,
    MAX(tenure) AS max_tenure,
    MIN(monthly_charges) AS min_monthly_charges,
    MAX(monthly_charges) AS max_monthly_charges,
    COUNT(*) FILTER (WHERE TRIM(total_charges) = '') AS blank_total_charges
FROM subscription_base;


-- ============================================================
-- 8. Service Base CTE
-- ============================================================

WITH service_base AS (
    SELECT
        customerID AS customer_id,
        PhoneService AS phone_service,
        MultipleLines AS multiple_lines,
        InternetService AS internet_service,
        OnlineSecurity AS online_security,
        OnlineBackup AS online_backup,
        DeviceProtection AS device_protection,
        TechSupport AS tech_support,
        StreamingTV AS streaming_tv,
        StreamingMovies AS streaming_movies
    FROM raw_telco_churn
)

SELECT *
FROM service_base;


-- ============================================================
-- 9. Service Base Grain Validation
-- ============================================================

WITH service_base AS (
    SELECT
        customerID AS customer_id,
        PhoneService AS phone_service,
        MultipleLines AS multiple_lines,
        InternetService AS internet_service,
        OnlineSecurity AS online_security,
        OnlineBackup AS online_backup,
        DeviceProtection AS device_protection,
        TechSupport AS tech_support,
        StreamingTV AS streaming_tv,
        StreamingMovies AS streaming_movies
    FROM raw_telco_churn
)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM service_base;


-- ============================================================
-- 10. Service Duplicate Validation
-- Expected result: 0 rows
-- ============================================================

WITH service_base AS (
    SELECT
        customerID AS customer_id,
        PhoneService AS phone_service,
        MultipleLines AS multiple_lines,
        InternetService AS internet_service,
        OnlineSecurity AS online_security,
        OnlineBackup AS online_backup,
        DeviceProtection AS device_protection,
        TechSupport AS tech_support,
        StreamingTV AS streaming_tv,
        StreamingMovies AS streaming_movies
    FROM raw_telco_churn
)

SELECT
    customer_id,
    COUNT(*) AS row_count
FROM service_base
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 11. Service Category Validation
--
-- Purpose:
-- Confirm the extracted InternetService categories match the
-- raw source structure.
-- ============================================================

WITH service_base AS (
    SELECT
        customerID AS customer_id,
        InternetService AS internet_service
    FROM raw_telco_churn
)

SELECT
    internet_service,
    COUNT(*) AS customers
FROM service_base
GROUP BY internet_service
ORDER BY customers DESC;


-- ============================================================
-- 12. Customer-Level Analytical Join
--
-- Purpose:
-- Combine customer, subscription, and service attributes into
-- a single customer-level analytical dataset.
--
-- Expected grain:
--   One row = one customer
--
-- Expected row count:
--   7,043
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id,
        gender,
        SeniorCitizen AS senior_citizen,
        Partner AS has_partner,
        Dependents AS has_dependents
    FROM raw_telco_churn
),

subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
),

service_base AS (
    SELECT
        customerID AS customer_id,
        PhoneService AS phone_service,
        MultipleLines AS multiple_lines,
        InternetService AS internet_service,
        OnlineSecurity AS online_security,
        OnlineBackup AS online_backup,
        DeviceProtection AS device_protection,
        TechSupport AS tech_support,
        StreamingTV AS streaming_tv,
        StreamingMovies AS streaming_movies
    FROM raw_telco_churn
),

customer_analytical_base AS (
    SELECT
        c.customer_id,
        c.gender,
        c.senior_citizen,
        c.has_partner,
        c.has_dependents,

        s.tenure,
        s.contract_type,
        s.paperless_billing,
        s.payment_method,
        s.monthly_charges,
        s.total_charges,

        v.phone_service,
        v.multiple_lines,
        v.internet_service,
        v.online_security,
        v.online_backup,
        v.device_protection,
        v.tech_support,
        v.streaming_tv,
        v.streaming_movies

    FROM customer_base c

    INNER JOIN subscription_base s
        ON c.customer_id = s.customer_id

    INNER JOIN service_base v
        ON c.customer_id = v.customer_id
)

SELECT *
FROM customer_analytical_base;


-- ============================================================
-- 13. Analytical Base Grain Validation
--
-- Expected:
--   total_rows = 7043
--   unique_customers = 7043
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id,
        gender,
        SeniorCitizen AS senior_citizen,
        Partner AS has_partner,
        Dependents AS has_dependents
    FROM raw_telco_churn
),

subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
),

service_base AS (
    SELECT
        customerID AS customer_id,
        PhoneService AS phone_service,
        MultipleLines AS multiple_lines,
        InternetService AS internet_service,
        OnlineSecurity AS online_security,
        OnlineBackup AS online_backup,
        DeviceProtection AS device_protection,
        TechSupport AS tech_support,
        StreamingTV AS streaming_tv,
        StreamingMovies AS streaming_movies
    FROM raw_telco_churn
),

customer_analytical_base AS (
    SELECT
        c.customer_id,
        c.gender,
        c.senior_citizen,
        c.has_partner,
        c.has_dependents,
        s.tenure,
        s.contract_type,
        s.paperless_billing,
        s.payment_method,
        s.monthly_charges,
        s.total_charges,
        v.phone_service,
        v.multiple_lines,
        v.internet_service,
        v.online_security,
        v.online_backup,
        v.device_protection,
        v.tech_support,
        v.streaming_tv,
        v.streaming_movies
    FROM customer_base c
    INNER JOIN subscription_base s
        ON c.customer_id = s.customer_id
    INNER JOIN service_base v
        ON c.customer_id = v.customer_id
)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_analytical_base;


-- ============================================================
-- 14. Join Coverage Validation
--
-- Purpose:
-- Confirm that the analytical join retains every source customer.
--
-- Expected:
--   source_customers = 7043
--   analytical_customers = 7043
--   customers_lost = 0
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id
    FROM raw_telco_churn
),

subscription_base AS (
    SELECT
        customerID AS customer_id
    FROM raw_telco_churn
),

service_base AS (
    SELECT
        customerID AS customer_id
    FROM raw_telco_churn
),

customer_analytical_base AS (
    SELECT
        c.customer_id
    FROM customer_base c
    INNER JOIN subscription_base s
        ON c.customer_id = s.customer_id
    INNER JOIN service_base v
        ON c.customer_id = v.customer_id
)

SELECT
    (SELECT COUNT(DISTINCT customer_id)
     FROM customer_base) AS source_customers,

    (SELECT COUNT(DISTINCT customer_id)
     FROM customer_analytical_base) AS analytical_customers,

    (SELECT COUNT(DISTINCT customer_id)
     FROM customer_base)
    -
    (SELECT COUNT(DISTINCT customer_id)
     FROM customer_analytical_base) AS customers_lost;


-- ============================================================
-- 15. Contract-Level Tenure Ranking
--
-- Purpose:
-- Rank customers by tenure within their contract type.
--
-- Business question:
-- Within each contract segment, which customers have the
-- longest tenure?
--
-- Window function:
-- ROW_NUMBER() partitions customers by contract type and
-- orders them by tenure from highest to lowest.
--
-- Note:
-- This is an analytical SQL demonstration rather than a final
-- modeling feature. The dataset does not contain historical
-- month-by-month usage data, so no artificial usage trend is
-- created.
-- ============================================================

WITH customer_analytical_base AS (
    SELECT
        customerID AS customer_id,
        Contract AS contract_type,
        tenure
    FROM raw_telco_churn
),

ranked_customers AS (
    SELECT
        customer_id,
        contract_type,
        tenure,

        ROW_NUMBER() OVER (
            PARTITION BY contract_type
            ORDER BY tenure DESC, customer_id
        ) AS tenure_rank_within_contract

    FROM customer_analytical_base
)

SELECT *
FROM ranked_customers
ORDER BY contract_type, tenure_rank_within_contract
LIMIT 20;


-- ============================================================
-- 16. Contract-Level Tenure Validation
-- ============================================================

WITH customer_analytical_base AS (
    SELECT
        customerID AS customer_id,
        Contract AS contract_type,
        tenure
    FROM raw_telco_churn
),

ranked_customers AS (
    SELECT
        customer_id,
        contract_type,
        tenure,

        ROW_NUMBER() OVER (
            PARTITION BY contract_type
            ORDER BY tenure DESC, customer_id
        ) AS tenure_rank_within_contract

    FROM customer_analytical_base
)

SELECT
    contract_type,
    COUNT(*) AS customers,
    MAX(tenure_rank_within_contract) AS max_rank
FROM ranked_customers
GROUP BY contract_type
ORDER BY contract_type;


-- ============================================================
-- 17. Contract-Level Tenure Ranking Validation
-- ============================================================

WITH customer_analytical_base AS (
    SELECT
        customerID AS customer_id,
        Contract AS contract_type,
        tenure
    FROM raw_telco_churn
),

ranked_customers AS (
    SELECT
        customer_id,
        contract_type,
        tenure,

        ROW_NUMBER() OVER (
            PARTITION BY contract_type
            ORDER BY tenure DESC, customer_id
        ) AS tenure_rank_within_contract

    FROM customer_analytical_base
)

SELECT *
FROM ranked_customers
WHERE tenure_rank_within_contract <= 3
ORDER BY contract_type, tenure_rank_within_contract;


-- ============================================================
-- 18. Final Feature-Ready Customer Base
--
-- Purpose:
-- Create the final customer-level analytical dataset that will
-- be passed to the Pandas cleaning and feature-engineering stage.
--
-- Final grain:
--   One row = one customer
--
-- Target:
--   churn
--
-- Important:
--   The window-function demonstration is intentionally excluded
--   from this final modeling base because tenure rank is not
--   required as a business feature.
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id,
        gender,
        SeniorCitizen AS senior_citizen,
        Partner AS has_partner,
        Dependents AS has_dependents
    FROM raw_telco_churn
),

subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
),

service_base AS (
    SELECT
        customerID AS customer_id,
        PhoneService AS phone_service,
        MultipleLines AS multiple_lines,
        InternetService AS internet_service,
        OnlineSecurity AS online_security,
        OnlineBackup AS online_backup,
        DeviceProtection AS device_protection,
        TechSupport AS tech_support,
        StreamingTV AS streaming_tv,
        StreamingMovies AS streaming_movies
    FROM raw_telco_churn
),

customer_analytical_base AS (
    SELECT
        c.customer_id,
        c.gender,
        c.senior_citizen,
        c.has_partner,
        c.has_dependents,

        s.tenure,
        s.contract_type,
        s.paperless_billing,
        s.payment_method,
        s.monthly_charges,
        s.total_charges,

        v.phone_service,
        v.multiple_lines,
        v.internet_service,
        v.online_security,
        v.online_backup,
        v.device_protection,
        v.tech_support,
        v.streaming_tv,
        v.streaming_movies,

        r.Churn AS churn

    FROM customer_base c

    INNER JOIN subscription_base s
        ON c.customer_id = s.customer_id

    INNER JOIN service_base v
        ON c.customer_id = v.customer_id

    INNER JOIN raw_telco_churn r
        ON c.customer_id = r.customerID
)

SELECT *
FROM customer_analytical_base;


-- ============================================================
-- 19. Final Feature-Ready Customer Base Validation
-- ============================================================

WITH customer_base AS (
    SELECT
        customerID AS customer_id,
        gender,
        SeniorCitizen AS senior_citizen,
        Partner AS has_partner,
        Dependents AS has_dependents
    FROM raw_telco_churn
),

subscription_base AS (
    SELECT
        customerID AS customer_id,
        tenure,
        Contract AS contract_type,
        PaperlessBilling AS paperless_billing,
        PaymentMethod AS payment_method,
        MonthlyCharges AS monthly_charges,
        TotalCharges AS total_charges
    FROM raw_telco_churn
),

service_base AS (
    SELECT
        customerID AS customer_id,
        PhoneService AS phone_service,
        MultipleLines AS multiple_lines,
        InternetService AS internet_service,
        OnlineSecurity AS online_security,
        OnlineBackup AS online_backup,
        DeviceProtection AS device_protection,
        TechSupport AS tech_support,
        StreamingTV AS streaming_tv,
        StreamingMovies AS streaming_movies
    FROM raw_telco_churn
),

customer_analytical_base AS (
    SELECT
        c.customer_id,
        c.gender,
        c.senior_citizen,
        c.has_partner,
        c.has_dependents,
        s.tenure,
        s.contract_type,
        s.paperless_billing,
        s.payment_method,
        s.monthly_charges,
        s.total_charges,
        v.phone_service,
        v.multiple_lines,
        v.internet_service,
        v.online_security,
        v.online_backup,
        v.device_protection,
        v.tech_support,
        v.streaming_tv,
        v.streaming_movies,
        r.Churn AS churn
    FROM customer_base c
    INNER JOIN subscription_base s
        ON c.customer_id = s.customer_id
    INNER JOIN service_base v
        ON c.customer_id = v.customer_id
    INNER JOIN raw_telco_churn r
        ON c.customer_id = r.customerID
)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    COUNT(*) FILTER (WHERE churn = 'No') AS retained_customers
FROM customer_analytical_base;


-- ============================================================
-- 20. Export Feature-Ready Base Table
--
-- Purpose:
-- Export the validated customer-level analytical dataset for
-- downstream Pandas cleaning and feature engineering.
--
-- Output:
--   data/processed/feature_ready_base.csv
--
-- Final grain:
--   One row = one customer
-- ============================================================

COPY (
	WITH customer_base AS (
    	SELECT
        	customerID AS customer_id,
        	gender,
        	SeniorCitizen AS senior_citizen,
        	Partner AS has_partner,
        	Dependents AS has_dependents
    	FROM raw_telco_churn
	),

	subscription_base AS (
    	SELECT
        	customerID AS customer_id,
        	tenure,
        	Contract AS contract_type,
        	PaperlessBilling AS paperless_billing,
        	PaymentMethod AS payment_method,
        	MonthlyCharges AS monthly_charges,
        	TotalCharges AS total_charges
    	FROM raw_telco_churn
	),

	service_base AS (
    	SELECT
        	customerID AS customer_id,
        	PhoneService AS phone_service,
        	MultipleLines AS multiple_lines,
        	InternetService AS internet_service,
        	OnlineSecurity AS online_security,
        	OnlineBackup AS online_backup,
        	DeviceProtection AS device_protection,
        	TechSupport AS tech_support,
        	StreamingTV AS streaming_tv,
        	StreamingMovies AS streaming_movies
    	FROM raw_telco_churn
	),

	customer_analytical_base AS (
    	SELECT
        	c.customer_id,
        	c.gender,
        	c.senior_citizen,
        	c.has_partner,
        	c.has_dependents,

        	s.tenure,
        	s.contract_type,
        	s.paperless_billing,
        	s.payment_method,
        	s.monthly_charges,
        	s.total_charges,

        	v.phone_service,
        	v.multiple_lines,
        	v.internet_service,
        	v.online_security,
        	v.online_backup,
        	v.device_protection,
        	v.tech_support,
        	v.streaming_tv,
        	v.streaming_movies,

        	r.Churn AS churn

    	FROM customer_base c

    	INNER JOIN subscription_base s
        	ON c.customer_id = s.customer_id

    	INNER JOIN service_base v
        	ON c.customer_id = v.customer_id

    	INNER JOIN raw_telco_churn r
        	ON c.customer_id = r.customerID
	)

	SELECT *
	FROM customer_analytical_base
)
TO 'C:/Users/roshi/DA_Sprint/projects/saas-subscription-churn-prediction-analysis/data/processed/feature_ready_base.csv'
WITH (HEADER, DELIMITER ',');