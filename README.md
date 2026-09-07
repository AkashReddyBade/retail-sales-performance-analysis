# Retail Sales Performance Analysis

An end-to-end retail analytics project using **Python, PostgreSQL, and Tableau** to turn transaction data into insights about revenue, customer value, product performance, and returns.

**[Explore the interactive Tableau dashboard](https://public.tableau.com/app/profile/akash.bade/viz/RetailSalesPerformanceAnalysis_17887934712640/OperationsReturnRisk)** — use the dashboard navigation buttons to move between the executive, customer, and operations views.

## Business objective

Help a retail team understand where revenue comes from, which customers merit retention attention, and when product returns or operating patterns warrant investigation.

The analysis addresses four questions:

- How does net merchandise revenue vary over time and across markets?
- Which products contribute the most revenue and which have high return rates?
- How do customer recency, frequency, and monetary value distinguish customer groups?
- Which weekdays and hours generate the most revenue?

## Results at a glance

Figures below were checked against the processed transaction dataset. Monetary values are in **GBP (£)**.

| Metric | Result |
|---|---:|
| Analysis-ready transaction lines | 1,028,761 |
| Transaction coverage | 1 December 2009–9 December 2011 |
| Gross merchandise sales | £19,645,617.81 |
| Return value | £716,532.13 |
| Net merchandise revenue | £18,929,085.68 |
| Revenue return rate | 3.65% |
| Paid merchandise units sold | 11,188,141 |
| Customers in the exported RFM dataset | 5,942 |

Revenue return rate is return value divided by gross merchandise sales. It differs from unit return rate, which measures returned units divided by units sold.

## Findings and potential business actions

| Finding | Potential action |
|---|---|
| Monthly net revenue peaks around November in both 2010 and 2011. | Prepare inventory and fulfilment capacity ahead of the seasonal peak. |
| REGENCY CAKESTAND 3 TIER leads the displayed top-ten products by net revenue. | Review availability and replenishment for major revenue contributors. |
| Champions generate the largest total revenue and highest average customer value among the RFM segments. | Prioritize retention and service for this group, alongside targeted outreach to High-Value At Risk customers. |
| Thursday generates the most weekday net revenue, and 12:00 leads the hourly revenue ranking. | Compare staffing and fulfilment coverage with these observed demand patterns. |
| Several products show very high unit return rates. | Investigate transaction history, cancellations, and order context before attributing returns to product quality. |

These are descriptive findings and proposed actions, not measured business improvements or causal conclusions.

## Interactive controls

- **Executive Sales Overview:** filter by year and country. The monthly year-over-year chart retains 2010 and 2011 for comparison while responding to the country selection.
- **Customer Analysis:** filter by customer segment to explore customer counts, revenue, average value, and RFM patterns. Segments are calculated from the full analysis period.
- **Operations & Return Risk:** filter by year and country to explore product returns, weekday revenue, peak hours, and average order value.
- Select **(All)** in each filter to restore the full view.

Use the Tableau Public link for interactive exploration; the images below are static previews.

## Dashboard previews

All monetary values are shown in GBP (£), matching the source dataset.

### Executive Sales Overview

Revenue KPIs, monthly trends, monthly year-over-year comparisons, geographic performance, and leading products.

![Executive Sales Overview](images/Executive%20Sales%20Overview.png)

### Customer Analysis

RFM segment size, revenue contribution, average customer value, and customer-level relationships between recency, frequency, and monetary value.

![Customer Analysis](images/Customer%20Analysis.png)

### Operations & Return Risk

Product unit return rates, weekday revenue, peak revenue hours, and average order value by hour.

![Operations and Return Risk](images/Operations%20%26%20Return%20Risk.png)

## Data preparation and analytical approach

1. **Profile the source:** inspect worksheet structure, date coverage, missing values, duplicates, cancellations, zero prices, and special stock codes.
2. **Resolve source overlap:** retain the first annual worksheet through November 2010 and use the second from December 2010 onward to avoid counting the overlapping period twice.
3. **Remove exact duplicate lines:** retain the first occurrence based on the available transaction fields.
4. **Treat missing values by use:** exclude missing-description records identified as non-revenue operational activity; retain unidentified-customer transactions for aggregate sales analysis and exclude them from customer-specific analysis.
5. **Classify transactions:** separate paid merchandise sales, returns/cancellations, zero-price activity, operational adjustments, and non-merchandise lines.
6. **Engineer measures:** calculate gross sales, return value, net merchandise revenue, paid units, date attributes, standardized countries, and analytical flags.
7. **Analyze in PostgreSQL:** use aggregations, common table expressions, window functions, rankings, and quartile-based RFM segmentation.
8. **Present in Tableau:** connect the prepared transaction data and customer segmentation export to the three dashboard views.

RFM uses the latest transaction date as its recency reference, distinct invoices as frequency, and net merchandise revenue as monetary value for identified customers. The SQL assigns quartile scores and maps them to seven rule-based segments.

## Repository guide

| File or folder | Purpose |
|---|---|
| [01_data_profiling.ipynb](python/01_data_profiling.ipynb) | Source investigation and documented cleaning decisions |
| [02_data_preparation.ipynb](python/02_data_preparation.ipynb) | Repeatable cleaning, feature engineering, validation, and CSV export |
| [01_database_setup.sql](sql/01_database_setup.sql) | PostgreSQL table schema, validation queries, and indexes |
| [02_business_analysis.sql](sql/02_business_analysis.sql) | Revenue, products, customers, RFM, geography, and operations analysis |
| [customer_rfm_segments.csv](data/processed/customer_rfm_segments.csv) | Exported customer-level segmentation results |
| [images](images/) | Dashboard previews |

The raw workbook and the large `retail_sales_analysis_ready.csv` are excluded from Git. The transaction CSV can be regenerated using the preparation notebook. The interactive dashboard is hosted on Tableau Public.

## Reproduce the analysis

1. Download `online_retail_II.xlsx` from the [UCI Online Retail II dataset page](https://archive.ics.uci.edu/dataset/502/online+retail+ii) and place it in `data/raw/`.
2. Set up Python with Jupyter, pandas, NumPy, and openpyxl:

   ```bash
   python3 -m pip install jupyter pandas numpy openpyxl
   ```

3. Start Jupyter from the `python` directory so the notebooks' relative paths resolve correctly. Run `01_data_profiling.ipynb`, then `02_data_preparation.ipynb`. The second notebook creates `data/processed/retail_sales_analysis_ready.csv`.
4. Create a PostgreSQL database named `retail_sales_analysis`. Run `sql/01_database_setup.sql` to create the table and indexes. Its post-import checks should be rerun after loading the CSV.
5. In a `psql` session connected to that database, with the repository root as the working directory, import the generated CSV:

   ```sql
   \copy retail_sales FROM 'data/processed/retail_sales_analysis_ready.csv' WITH (FORMAT csv, HEADER true);
   ```

   The CSV column order matches the table schema. Confirm the imported row count is 1,028,761.
6. Run `sql/02_business_analysis.sql` to inspect the results and create the customer segmentation table. Its final section drops and recreates `customer_rfm_segments`.
7. Use the committed customer CSV for inspection, or export the regenerated segmentation table. View the published Tableau dashboard for the visual presentation.

## Interpretation notes

- December 2011 is incomplete. The monthly SQL year-over-year comparison excludes December; whole-year totals do not represent equal coverage.
- Merchandise revenue excludes non-product categories such as postage and manual adjustments. Revenue is not profit: the dataset does not provide product costs.
- Customer results cover identified customers only. RFM frequency counts distinct invoices in that population, including return/cancellation invoices, and should not be interpreted as a count of paid sales orders.
- Returns and cancellations are grouped analytically; high return rates do not by themselves establish product defects.
- Exact duplicate removal is an analytical assumption because the source lacks a unique line-item identifier.

## Data attribution

Chen, D. (2012). *Online Retail II* [Dataset]. UCI Machine Learning Repository. [https://doi.org/10.24432/C5CG6D](https://doi.org/10.24432/C5CG6D). Dataset license: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Portfolio analysis and visualization by **Akash Bade**.
