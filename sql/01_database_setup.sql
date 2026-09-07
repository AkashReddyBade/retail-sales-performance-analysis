-- ============================================================
-- Retail Sales Performance Analysis
-- Database Setup
-- ============================================================

-- Database:
-- retail_sales_analysis


-- ============================================================
-- 1. Create analysis-ready retail sales table
-- ============================================================

CREATE TABLE retail_sales (

    invoice TEXT,
    stock_code TEXT,
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    price NUMERIC(12,4),
    customer_id TEXT,
    country TEXT,
    source_period TEXT,

    customer_known BOOLEAN,
    is_cancellation_invoice BOOLEAN,
    transaction_type TEXT,
    line_category TEXT,

    line_value NUMERIC(14,4),
    gross_sales NUMERIC(14,4),
    return_value NUMERIC(14,4),
    net_merchandise_revenue NUMERIC(14,4),

    units_sold INTEGER,
    returned_units INTEGER,
    zero_price_units INTEGER,
    net_units INTEGER,

    year INTEGER,
    quarter TEXT,
    month_number INTEGER,
    month TEXT,
    year_month TEXT,
    weekday TEXT,
    weekday_number INTEGER,
    hour INTEGER,
    invoice_date_only DATE,

    country_standardized TEXT,
    map_eligible BOOLEAN,

    is_paid_merchandise_sale BOOLEAN,
    is_merchandise_return BOOLEAN,
    is_revenue_generating BOOLEAN
);
-- ============================================================
-- 2. Validate table structure
-- ============================================================

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'retail_sales'
ORDER BY ordinal_position;

SELECT COUNT(*) AS row_count
FROM retail_sales;

-- Data imported via psql \copy from:
-- data/processed/retail_sales_analysis_ready.csv
-- Imported rows: 1,028,761

-- ============================================================
-- 3. Post-Import Validation
-- ============================================================

SELECT COUNT(*) AS row_count
FROM retail_sales;

SELECT
    MIN(invoice_date) AS earliest_transaction,
    MAX(invoice_date) AS latest_transaction
FROM retail_sales;

SELECT
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_description,
    COUNT(*) FILTER (WHERE invoice_date IS NULL) AS missing_invoice_date,
    COUNT(*) FILTER (WHERE country IS NULL) AS missing_country
FROM retail_sales;

SELECT
    transaction_type,
    COUNT(*) AS row_count
FROM retail_sales
GROUP BY transaction_type
ORDER BY row_count DESC;

SELECT
    transaction_type,
    COUNT(*) AS row_count
FROM retail_sales
GROUP BY transaction_type
ORDER BY row_count DESC;

-- ============================================================
-- 4. Create Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_retail_sales_invoice_date
ON retail_sales (invoice_date);

CREATE INDEX IF NOT EXISTS idx_retail_sales_customer_id
ON retail_sales (customer_id);

CREATE INDEX IF NOT EXISTS idx_retail_sales_stock_code
ON retail_sales (stock_code);

CREATE INDEX IF NOT EXISTS idx_retail_sales_country
ON retail_sales (country_standardized);

CREATE INDEX IF NOT EXISTS idx_retail_sales_transaction_type
ON retail_sales (transaction_type);

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'retail_sales'
ORDER BY indexname;