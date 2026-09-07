-- ============================================================
-- Retail Sales Performance Analysis
-- SQL Business Analysis
-- ============================================================

-- Database:
-- retail_sales_analysis


-- ============================================================
-- 1. Core Business KPIs
-- ============================================================

SELECT
    ROUND(SUM(gross_sales), 2) AS gross_merchandise_sales,
    ROUND(SUM(return_value), 2) AS return_value,
    ROUND(SUM(net_merchandise_revenue), 2) AS net_merchandise_revenue,
    SUM(units_sold) AS units_sold,
    SUM(returned_units) AS returned_units,
    SUM(net_units) AS net_units
FROM retail_sales;

-- ============================================================
-- 2. Return Rate KPIs
-- ============================================================

SELECT
    ROUND(
        SUM(return_value) / NULLIF(SUM(gross_sales), 0) * 100,
        2
    ) AS revenue_return_rate_pct,

    ROUND(
        SUM(returned_units)::NUMERIC
        / NULLIF(SUM(units_sold), 0)
        * 100,
        2
    ) AS unit_return_rate_pct
FROM retail_sales;

-- ============================================================
-- 3. Monthly Revenue Trend
-- ============================================================

SELECT
    year_month,
    ROUND(SUM(gross_sales), 2) AS gross_sales,
    ROUND(SUM(return_value), 2) AS return_value,
    ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(units_sold) AS units_sold
FROM retail_sales
GROUP BY year_month
ORDER BY year_month;

-- ============================================================
-- 4. Yearly Performance Comparison
-- ============================================================

SELECT
    year,
    ROUND(SUM(gross_sales), 2) AS gross_sales,
    ROUND(SUM(return_value), 2) AS return_value,
    ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,
    COUNT(DISTINCT invoice) AS orders,
    SUM(units_sold) AS units_sold
FROM retail_sales
WHERE year IN (2010, 2011)
GROUP BY year
ORDER BY year;

-- ============================================================
-- 5. YoY Growth, AOV, and Revenue per Unit
-- ============================================================

WITH yearly_metrics AS (
    SELECT
        year,
        SUM(gross_sales) AS gross_sales,
        COUNT(DISTINCT invoice) AS orders,
        SUM(units_sold) AS units_sold
    FROM retail_sales
    WHERE year IN (2010, 2011)
    GROUP BY year
),

calculated_metrics AS (
    SELECT
        year,
        gross_sales,
        orders,
        units_sold,
        gross_sales / NULLIF(orders, 0) AS average_order_value,
        gross_sales / NULLIF(units_sold, 0) AS revenue_per_unit
    FROM yearly_metrics
)

SELECT
    year,
    ROUND(gross_sales, 2) AS gross_sales,
    orders,
    units_sold,
    ROUND(average_order_value, 2) AS average_order_value,
    ROUND(revenue_per_unit, 4) AS revenue_per_unit,

    ROUND(
        (
            gross_sales
            / NULLIF(LAG(gross_sales) OVER (ORDER BY year), 0)
            - 1
        ) * 100,
        2
    ) AS gross_sales_yoy_pct,

    ROUND(
        (
            average_order_value
            / NULLIF(LAG(average_order_value) OVER (ORDER BY year), 0)
            - 1
        ) * 100,
        2
    ) AS aov_yoy_pct,

    ROUND(
        (
            revenue_per_unit
            / NULLIF(LAG(revenue_per_unit) OVER (ORDER BY year), 0)
            - 1
        ) * 100,
        2
    ) AS revenue_per_unit_yoy_pct

FROM calculated_metrics
ORDER BY year;

-- ============================================================
-- 6. Monthly YoY Seasonality
-- ============================================================

WITH monthly_sales AS (
    SELECT
        year,
        month_number,
        month,
        SUM(gross_sales) AS gross_sales
    FROM retail_sales
    WHERE year IN (2010, 2011)
    GROUP BY
        year,
        month_number,
        month
),

monthly_comparison AS (
    SELECT
        month_number,
        month,
        MAX(CASE WHEN year = 2010 THEN gross_sales END) AS sales_2010,
        MAX(CASE WHEN year = 2011 THEN gross_sales END) AS sales_2011
    FROM monthly_sales
    GROUP BY
        month_number,
        month
)

SELECT
    month_number,
    month,
    ROUND(sales_2010, 2) AS sales_2010,
    ROUND(sales_2011, 2) AS sales_2011,

    ROUND(
        (
            sales_2011
            / NULLIF(sales_2010, 0)
            - 1
        ) * 100,
        2
    ) AS yoy_growth_pct

FROM monthly_comparison
WHERE sales_2010 IS NOT NULL
  AND sales_2011 IS NOT NULL
  AND month_number <> 12
ORDER BY month_number;

-- ============================================================
-- 7. Monthly YoY Performance Ranking
-- ============================================================

WITH monthly_sales AS (
    SELECT
        year,
        month_number,
        month,
        SUM(gross_sales) AS gross_sales
    FROM retail_sales
    WHERE year IN (2010, 2011)
    GROUP BY
        year,
        month_number,
        month
),

monthly_comparison AS (
    SELECT
        month_number,
        month,
        MAX(CASE WHEN year = 2010 THEN gross_sales END) AS sales_2010,
        MAX(CASE WHEN year = 2011 THEN gross_sales END) AS sales_2011
    FROM monthly_sales
    GROUP BY
        month_number,
        month
)

SELECT
    month_number,
    month,
    ROUND(sales_2010, 2) AS sales_2010,
    ROUND(sales_2011, 2) AS sales_2011,
    ROUND(
        (sales_2011 / NULLIF(sales_2010, 0) - 1) * 100,
        2
    ) AS yoy_growth_pct
FROM monthly_comparison
WHERE sales_2010 IS NOT NULL
  AND sales_2011 IS NOT NULL
  AND month_number <> 12
ORDER BY yoy_growth_pct DESC;

-- ============================================================
-- 8. Product Performance Analysis
-- ============================================================

WITH product_performance AS (
    SELECT
        stock_code,
        description,

        ROUND(SUM(gross_sales), 2) AS gross_sales,
        ROUND(SUM(return_value), 2) AS return_value,
        ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,

        SUM(units_sold) AS units_sold,
        SUM(returned_units) AS returned_units,

        COUNT(DISTINCT invoice) AS orders

    FROM retail_sales
    WHERE line_category = 'Merchandise'
    GROUP BY
        stock_code,
        description
)

SELECT *
FROM product_performance
ORDER BY gross_sales DESC
LIMIT 10;

-- ============================================================
-- 9. Top Products by Units Sold
-- ============================================================

WITH product_performance AS (
    SELECT
        stock_code,
        description,
        ROUND(SUM(gross_sales), 2) AS gross_sales,
        SUM(units_sold) AS units_sold,
        COUNT(DISTINCT invoice) AS orders
    FROM retail_sales
    WHERE line_category = 'Merchandise'
    GROUP BY
        stock_code,
        description
)

SELECT *
FROM product_performance
ORDER BY units_sold DESC
LIMIT 10;

-- ============================================================
-- 10. Top Products by Order Frequency
-- ============================================================

WITH product_performance AS (
    SELECT
        stock_code,
        description,
        ROUND(SUM(gross_sales), 2) AS gross_sales,
        SUM(units_sold) AS units_sold,
        COUNT(DISTINCT invoice) AS orders
    FROM retail_sales
    WHERE line_category = 'Merchandise'
    GROUP BY
        stock_code,
        description
)

SELECT *
FROM product_performance
ORDER BY orders DESC
LIMIT 10;

-- ============================================================
-- 11. Product Return Risk
-- ============================================================

WITH product_returns AS (
    SELECT
        stock_code,
        description,
        SUM(gross_sales) AS gross_sales,
        SUM(return_value) AS return_value,
        SUM(units_sold) AS units_sold,
        SUM(returned_units) AS returned_units
    FROM retail_sales
    WHERE line_category = 'Merchandise'
    GROUP BY
        stock_code,
        description
)

SELECT
    stock_code,
    description,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(return_value, 2) AS return_value,

    ROUND(
        return_value / NULLIF(gross_sales, 0) * 100,
        2
    ) AS revenue_return_rate_pct,

    units_sold,
    returned_units,

    ROUND(
        returned_units::NUMERIC
        / NULLIF(units_sold, 0)
        * 100,
        2
    ) AS unit_return_rate_pct

FROM product_returns
WHERE gross_sales > 0
ORDER BY revenue_return_rate_pct DESC
LIMIT 20;

-- ============================================================
-- 12. High-Volume Products with Return Risk
-- ============================================================

WITH product_returns AS (
    SELECT
        stock_code,
        description,
        SUM(gross_sales) AS gross_sales,
        SUM(return_value) AS return_value,
        SUM(units_sold) AS units_sold,
        SUM(returned_units) AS returned_units
    FROM retail_sales
    WHERE line_category = 'Merchandise'
    GROUP BY
        stock_code,
        description
)

SELECT
    stock_code,
    description,
    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(return_value, 2) AS return_value,
    units_sold,
    returned_units,

    ROUND(
        returned_units::NUMERIC
        / NULLIF(units_sold, 0)
        * 100,
        2
    ) AS unit_return_rate_pct

FROM product_returns
WHERE units_sold >= 1000
  AND returned_units > 0
ORDER BY unit_return_rate_pct DESC
LIMIT 20;

-- ============================================================
-- 13. Customer Performance Analysis
-- ============================================================

WITH customer_performance AS (
    SELECT
        customer_id,

        ROUND(SUM(gross_sales), 2) AS gross_sales,
        ROUND(SUM(return_value), 2) AS return_value,
        ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,

        COUNT(DISTINCT invoice) AS orders,

        SUM(units_sold) AS units_purchased,
        SUM(returned_units) AS returned_units

    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
)

SELECT
    customer_id,
    gross_sales,
    return_value,
    net_revenue,
    orders,
    units_purchased,
    returned_units,

    ROUND(
        net_revenue / NULLIF(orders, 0),
        2
    ) AS average_order_value

FROM customer_performance
ORDER BY net_revenue DESC
LIMIT 20;

-- ============================================================
-- 14. Customer Revenue Concentration
-- ============================================================

WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(net_merchandise_revenue) AS net_revenue
    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

ranked_customers AS (
    SELECT
        customer_id,
        net_revenue,

        net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0)
        * 100 AS revenue_share_pct,

        SUM(net_revenue) OVER (
            ORDER BY net_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        )
        / NULLIF(SUM(net_revenue) OVER (), 0)
        * 100 AS cumulative_revenue_share_pct

    FROM customer_revenue
)

SELECT
    customer_id,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(revenue_share_pct, 2) AS revenue_share_pct,
    ROUND(cumulative_revenue_share_pct, 2)
        AS cumulative_revenue_share_pct
FROM ranked_customers
ORDER BY net_revenue DESC
LIMIT 20;

-- ============================================================
-- 15. One-Time vs Repeat Customer Analysis
-- ============================================================

WITH customer_summary AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS orders,
        SUM(net_merchandise_revenue) AS net_revenue,
        SUM(net_units) AS net_units
    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

customer_types AS (
    SELECT
        customer_id,
        orders,
        net_revenue,
        net_units,

        CASE
            WHEN orders = 1 THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type

    FROM customer_summary
)

SELECT
    customer_type,

    COUNT(*) AS customers,
    SUM(orders) AS orders,

    ROUND(SUM(net_revenue), 2) AS net_revenue,
    SUM(net_units) AS net_units,

    ROUND(
        COUNT(*)::NUMERIC
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS customer_share_pct,

    ROUND(
        SUM(net_revenue)
        / NULLIF(SUM(SUM(net_revenue)) OVER (), 0)
        * 100,
        2
    ) AS revenue_share_pct

FROM customer_types
GROUP BY customer_type
ORDER BY net_revenue DESC;

-- ============================================================
-- 16. Repeat Customer Rate
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS orders
    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE orders > 1
    ) AS repeat_customers,

    ROUND(
        COUNT(*) FILTER (WHERE orders > 1)::NUMERIC
        / NULLIF(COUNT(*), 0)
        * 100,
        2
    ) AS repeat_customer_rate_pct

FROM customer_orders;

-- ============================================================
-- 17. Customer Value by Customer Type
-- ============================================================

WITH customer_summary AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS orders,
        SUM(net_merchandise_revenue) AS net_revenue,
        SUM(net_units) AS net_units
    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

customer_types AS (
    SELECT
        *,
        CASE
            WHEN orders = 1 THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM customer_summary
)

SELECT
    customer_type,

    ROUND(AVG(net_revenue), 2)
        AS avg_net_revenue_per_customer,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY net_revenue)::NUMERIC,
        2
    ) AS median_net_revenue_per_customer,

    ROUND(AVG(orders), 2)
        AS avg_orders_per_customer,

    ROUND(AVG(net_units), 2)
        AS avg_net_units_per_customer

FROM customer_types
GROUP BY customer_type
ORDER BY avg_net_revenue_per_customer DESC;

-- ============================================================
-- 18. Customer Order Frequency Distribution
-- ============================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice) AS orders
    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

frequency_groups AS (
    SELECT
        customer_id,
        orders,

        CASE
            WHEN orders = 1 THEN '1 Order'
            WHEN orders BETWEEN 2 AND 5 THEN '2-5 Orders'
            WHEN orders BETWEEN 6 AND 10 THEN '6-10 Orders'
            WHEN orders BETWEEN 11 AND 20 THEN '11-20 Orders'
            ELSE '20+ Orders'
        END AS order_frequency_group,

        CASE
            WHEN orders = 1 THEN 1
            WHEN orders BETWEEN 2 AND 5 THEN 2
            WHEN orders BETWEEN 6 AND 10 THEN 3
            WHEN orders BETWEEN 11 AND 20 THEN 4
            ELSE 5
        END AS sort_order

    FROM customer_orders
)

SELECT
    order_frequency_group,
    COUNT(*) AS customers
FROM frequency_groups
GROUP BY
    order_frequency_group,
    sort_order
ORDER BY sort_order;


-- ============================================================
-- 19. Geographic Performance Analysis
-- ============================================================

WITH country_performance AS (
    SELECT
        country_standardized,

        ROUND(SUM(gross_sales), 2) AS gross_sales,
        ROUND(SUM(return_value), 2) AS return_value,
        ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,

        COUNT(DISTINCT invoice) AS orders,

        COUNT(DISTINCT customer_id)
            FILTER (WHERE customer_known = TRUE) AS customers

    FROM retail_sales
    WHERE map_eligible = TRUE
    GROUP BY country_standardized
)

SELECT
    country_standardized,
    gross_sales,
    return_value,
    net_revenue,
    orders,
    customers,

    ROUND(
        net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0)
        * 100,
        2
    ) AS revenue_share_pct

FROM country_performance
ORDER BY net_revenue DESC;

-- ============================================================
-- 20. UK vs International Revenue Concentration
-- ============================================================

WITH geographic_split AS (
    SELECT
        CASE
            WHEN country_standardized = 'United Kingdom'
                THEN 'United Kingdom'
            ELSE 'International'
        END AS market,

        SUM(net_merchandise_revenue) AS net_revenue

    FROM retail_sales
    WHERE map_eligible = TRUE
    GROUP BY
        CASE
            WHEN country_standardized = 'United Kingdom'
                THEN 'United Kingdom'
            ELSE 'International'
        END
)

SELECT
    market,
    ROUND(net_revenue, 2) AS net_revenue,

    ROUND(
        net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0)
        * 100,
        2
    ) AS revenue_share_pct

FROM geographic_split
ORDER BY net_revenue DESC;

-- ============================================================
-- 21. International Market Return Risk
-- ============================================================

WITH international_performance AS (
    SELECT
        country_standardized,

        SUM(gross_sales) AS gross_sales,
        SUM(return_value) AS return_value,
        SUM(net_merchandise_revenue) AS net_revenue,

        COUNT(DISTINCT invoice) AS orders,

        COUNT(DISTINCT customer_id)
            FILTER (WHERE customer_known = TRUE) AS customers

    FROM retail_sales
    WHERE map_eligible = TRUE
      AND country_standardized <> 'United Kingdom'
    GROUP BY country_standardized
)

SELECT
    country_standardized,

    ROUND(gross_sales, 2) AS gross_sales,
    ROUND(return_value, 2) AS return_value,
    ROUND(net_revenue, 2) AS net_revenue,

    orders,
    customers,

    ROUND(
        return_value
        / NULLIF(gross_sales, 0)
        * 100,
        2
    ) AS revenue_return_rate_pct

FROM international_performance
WHERE gross_sales >= 10000
ORDER BY revenue_return_rate_pct DESC;

-- ============================================================
-- 22. Established International Markets
-- ============================================================

WITH international_performance AS (
    SELECT
        country_standardized,

        SUM(net_merchandise_revenue) AS net_revenue,

        COUNT(DISTINCT invoice) AS orders,

        COUNT(DISTINCT customer_id)
            FILTER (WHERE customer_known = TRUE) AS customers,

        SUM(return_value)
        / NULLIF(SUM(gross_sales), 0)
        * 100 AS revenue_return_rate_pct

    FROM retail_sales
    WHERE map_eligible = TRUE
      AND country_standardized <> 'United Kingdom'
    GROUP BY country_standardized
)

SELECT
    country_standardized,
    ROUND(net_revenue, 2) AS net_revenue,
    orders,
    customers,

    ROUND(
        net_revenue / NULLIF(orders, 0),
        2
    ) AS average_order_value,

    ROUND(
        revenue_return_rate_pct,
        2
    ) AS revenue_return_rate_pct

FROM international_performance
WHERE orders >= 10
ORDER BY net_revenue DESC;

-- ============================================================
-- 23. RFM Customer Base
-- ============================================================

WITH customer_rfm AS (
    SELECT
        customer_id,

        MAX(invoice_date_only) AS last_purchase_date,

        (
            SELECT MAX(invoice_date_only)
            FROM retail_sales
        ) - MAX(invoice_date_only) AS recency_days,

        COUNT(DISTINCT invoice) AS frequency,

        SUM(net_merchandise_revenue) AS monetary

    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
)

SELECT
    customer_id,
    last_purchase_date,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary
FROM customer_rfm
ORDER BY monetary DESC
LIMIT 20;

-- ============================================================
-- 24. RFM Scoring
-- ============================================================

WITH customer_rfm AS (
    SELECT
        customer_id,
        (
            SELECT MAX(invoice_date_only)
            FROM retail_sales
        ) - MAX(invoice_date_only) AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(net_merchandise_revenue) AS monetary
    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        *,
        5 - NTILE(4) OVER (
            ORDER BY recency_days
        ) AS r_score,

        NTILE(4) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(4) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM customer_rfm
)

SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score
FROM rfm_scores
ORDER BY
    r_score DESC,
    f_score DESC,
    m_score DESC
LIMIT 20;

-- ============================================================
-- 25. RFM Customer Segmentation
-- ============================================================

WITH customer_rfm AS (
    SELECT
        customer_id,

        (
            SELECT MAX(invoice_date_only)
            FROM retail_sales
        ) - MAX(invoice_date_only) AS recency_days,

        COUNT(DISTINCT invoice) AS frequency,

        SUM(net_merchandise_revenue) AS monetary

    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        *,

        5 - NTILE(4) OVER (
            ORDER BY recency_days
        ) AS r_score,

        NTILE(4) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(4) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM customer_rfm
),

customer_segments AS (
    SELECT
        *,

        CASE
            WHEN r_score = 4
                 AND f_score >= 3
                 AND m_score >= 3
                THEN 'Champions'

            WHEN r_score >= 3
                 AND f_score >= 3
                 AND m_score >= 2
                THEN 'Loyal Customers'

            WHEN r_score = 4
                 AND f_score <= 2
                THEN 'Recent Customers'

            WHEN r_score = 3
                 AND f_score <= 2
                THEN 'Promising'

            WHEN r_score <= 2
                 AND f_score >= 3
                 AND m_score >= 3
                THEN 'High-Value At Risk'

            WHEN r_score <= 2
                 AND f_score >= 2
                THEN 'At Risk'

            ELSE 'Low Engagement'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    customer_segment
FROM customer_segments
ORDER BY
    monetary DESC
LIMIT 50;

-- ============================================================
-- 26. RFM Segment Summary
-- ============================================================

WITH customer_rfm AS (
    SELECT
        customer_id,

        (
            SELECT MAX(invoice_date_only)
            FROM retail_sales
        ) - MAX(invoice_date_only) AS recency_days,

        COUNT(DISTINCT invoice) AS frequency,

        SUM(net_merchandise_revenue) AS monetary

    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        *,

        5 - NTILE(4) OVER (
            ORDER BY recency_days
        ) AS r_score,

        NTILE(4) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(4) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM customer_rfm
),

customer_segments AS (
    SELECT
        *,

        CASE
            WHEN r_score = 4
                 AND f_score >= 3
                 AND m_score >= 3
                THEN 'Champions'

            WHEN r_score >= 3
                 AND f_score >= 3
                 AND m_score >= 2
                THEN 'Loyal Customers'

            WHEN r_score = 4
                 AND f_score <= 2
                THEN 'Recent Customers'

            WHEN r_score = 3
                 AND f_score <= 2
                THEN 'Promising'

            WHEN r_score <= 2
                 AND f_score >= 3
                 AND m_score >= 3
                THEN 'High-Value At Risk'

            WHEN r_score <= 2
                 AND f_score >= 2
                THEN 'At Risk'

            ELSE 'Low Engagement'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(AVG(recency_days), 2)
        AS avg_recency_days,

    ROUND(AVG(frequency), 2)
        AS avg_frequency,

    ROUND(SUM(monetary), 2)
        AS net_revenue,

    ROUND(AVG(monetary), 2)
        AS avg_customer_value,

    ROUND(
        COUNT(*)::NUMERIC
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS customer_share_pct,

    ROUND(
        SUM(monetary)
        / NULLIF(SUM(SUM(monetary)) OVER (), 0)
        * 100,
        2
    ) AS revenue_share_pct

FROM customer_segments
GROUP BY customer_segment
ORDER BY net_revenue DESC;

-- ============================================================
-- 27. RFM Segment Business Contribution
-- ============================================================

WITH customer_rfm AS (
    SELECT
        customer_id,
        (
            SELECT MAX(invoice_date_only)
            FROM retail_sales
        ) - MAX(invoice_date_only) AS recency_days,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(net_merchandise_revenue) AS monetary
    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        *,
        5 - NTILE(4) OVER (ORDER BY recency_days) AS r_score,
        NTILE(4) OVER (ORDER BY frequency) AS f_score,
        NTILE(4) OVER (ORDER BY monetary) AS m_score
    FROM customer_rfm
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN r_score = 4
                 AND f_score >= 3
                 AND m_score >= 3
                THEN 'Champions'

            WHEN r_score >= 3
                 AND f_score >= 3
                 AND m_score >= 2
                THEN 'Loyal Customers'

            WHEN r_score = 4
                 AND f_score <= 2
                THEN 'Recent Customers'

            WHEN r_score = 3
                 AND f_score <= 2
                THEN 'Promising'

            WHEN r_score <= 2
                 AND f_score >= 3
                 AND m_score >= 3
                THEN 'High-Value At Risk'

            WHEN r_score <= 2
                 AND f_score >= 2
                THEN 'At Risk'

            ELSE 'Low Engagement'
        END AS customer_segment

    FROM rfm_scores
),

segment_summary AS (
    SELECT
        customer_segment,
        COUNT(*) AS customers,
        SUM(monetary) AS net_revenue,
        AVG(monetary) AS avg_customer_value
    FROM customer_segments
    GROUP BY customer_segment
)

SELECT
    customer_segment,
    customers,

    ROUND(
        customers::NUMERIC
        / SUM(customers) OVER ()
        * 100,
        2
    ) AS customer_share_pct,

    ROUND(net_revenue, 2) AS net_revenue,

    ROUND(
        net_revenue
        / NULLIF(SUM(net_revenue) OVER (), 0)
        * 100,
        2
    ) AS revenue_share_pct,

    ROUND(avg_customer_value, 2)
        AS avg_customer_value

FROM segment_summary
ORDER BY net_revenue DESC;

-- ============================================================
-- 28. Sales by Weekday
-- ============================================================

SELECT
    weekday_number,
    weekday,

    ROUND(SUM(gross_sales), 2) AS gross_sales,
    ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,

    COUNT(DISTINCT invoice) AS orders,
    SUM(units_sold) AS units_sold

FROM retail_sales
GROUP BY
    weekday_number,
    weekday
ORDER BY weekday_number;

-- ============================================================
-- 29. Sales by Hour of Day
-- ============================================================

SELECT
    hour,

    ROUND(SUM(gross_sales), 2) AS gross_sales,
    ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,

    COUNT(DISTINCT invoice) AS orders,
    SUM(units_sold) AS units_sold

FROM retail_sales
GROUP BY hour
ORDER BY hour;

-- ============================================================
-- 30. Peak Sales Hours
-- ============================================================

SELECT
    hour,

    ROUND(SUM(net_merchandise_revenue), 2) AS net_revenue,
    COUNT(DISTINCT invoice) AS orders,

    ROUND(
        SUM(net_merchandise_revenue)
        / NULLIF(COUNT(DISTINCT invoice), 0),
        2
    ) AS average_order_value

FROM retail_sales
GROUP BY hour
ORDER BY net_revenue DESC
LIMIT 10;

-- ============================================================
-- 31. Final SQL Analysis Validation
-- ============================================================

SELECT
    COUNT(*) AS total_rows,

    ROUND(SUM(gross_sales), 2) AS gross_sales,

    ROUND(SUM(return_value), 2) AS return_value,

    ROUND(SUM(net_merchandise_revenue), 2)
        AS net_merchandise_revenue,

    SUM(units_sold) AS units_sold,

    SUM(returned_units) AS returned_units,

    COUNT(DISTINCT invoice) AS total_invoices,

    COUNT(DISTINCT customer_id)
        FILTER (WHERE customer_known = TRUE)
        AS known_customers,

    MIN(invoice_date) AS earliest_transaction,

    MAX(invoice_date) AS latest_transaction

FROM retail_sales;

-- ============================================================
-- 32. Final Data Integrity Check
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE description IS NULL
    ) AS missing_descriptions,

    COUNT(*) FILTER (
        WHERE invoice_date IS NULL
    ) AS missing_dates,

    COUNT(*) FILTER (
        WHERE country IS NULL
    ) AS missing_countries,

    COUNT(*) FILTER (
        WHERE transaction_type IS NULL
    ) AS missing_transaction_types,

    COUNT(*) FILTER (
        WHERE line_category IS NULL
    ) AS missing_line_categories

FROM retail_sales;


DROP TABLE IF EXISTS customer_rfm_segments;

CREATE TABLE customer_rfm_segments AS

WITH customer_rfm AS (
    SELECT
        customer_id,
        (
            SELECT MAX(invoice_date_only)
            FROM retail_sales
        ) - MAX(invoice_date_only) AS recency_days,

        COUNT(DISTINCT invoice) AS frequency,

        SUM(net_merchandise_revenue) AS monetary

    FROM retail_sales
    WHERE customer_known = TRUE
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        *,
        5 - NTILE(4) OVER (
            ORDER BY recency_days
        ) AS r_score,

        NTILE(4) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(4) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM customer_rfm
),

customer_segments AS (
    SELECT
        *,
        CONCAT(r_score, f_score, m_score) AS rfm_score,

        CASE
            WHEN r_score = 4
                AND f_score >= 3
                AND m_score >= 3
                THEN 'Champions'

            WHEN r_score >= 3
                AND f_score >= 3
                AND m_score >= 2
                THEN 'Loyal Customers'

            WHEN r_score = 4
                AND f_score <= 2
                THEN 'Recent Customers'

            WHEN r_score = 3
                AND f_score <= 2
                THEN 'Promising'

            WHEN r_score <= 2
                AND f_score >= 3
                AND m_score >= 3
                THEN 'High-Value At Risk'

            WHEN r_score <= 2
                AND f_score >= 2
                THEN 'At Risk'

            ELSE 'Low Engagement'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    customer_segment
FROM customer_segments;

SELECT COUNT(*) AS customers
FROM customer_rfm_segments;

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS net_revenue
FROM customer_rfm_segments
GROUP BY customer_segment
ORDER BY net_revenue DESC;