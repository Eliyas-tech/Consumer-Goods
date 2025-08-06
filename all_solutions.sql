/************************************************************************************************
REQUEST 1: Provide the list of markets in which customer "Atliq Exclusive" operates its 
business in the APAC region.
************************************************************************************************/

SELECT DISTINCT market
FROM dim_customer
WHERE 
    customer = "Atliq Exclusive" 
    AND region = "APAC";

/************************************************************************************************
REQUEST 2: What is the percentage of unique product increase in 2021 vs. 2020?
************************************************************************************************/

WITH product_counts AS (
    SELECT
        -- Count distinct products for the year 2020
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
        
        -- Count distinct products for the year 2021
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021
    FROM 
        fact_sales_monthly
)
SELECT
    unique_products_2020,
    unique_products_2021,
    -- Calculate the percentage change
    ROUND((unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020, 2) AS percentage_chg
FROM 
    product_counts;

/************************************************************************************************
REQUEST 3: Provide a report with all the unique product counts for each segment and 
sort them in descending order of product counts.
************************************************************************************************/

SELECT
    segment,
    COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY
    segment
ORDER BY
    product_count DESC;

/************************************************************************************************
REQUEST 4: Which segment had the most increase in unique products in 2021 vs 2020?
************************************************************************************************/

WITH product_counts_by_segment AS (
    SELECT
        p.segment,
        -- Count distinct products for 2020 in each segment
        COUNT(DISTINCT CASE WHEN s.fiscal_year = 2020 THEN s.product_code END) AS product_count_2020,
        
        -- Count distinct products for 2021 in each segment
        COUNT(DISTINCT CASE WHEN s.fiscal_year = 2021 THEN s.product_code END) AS product_count_2021
    FROM
        fact_sales_monthly s
    JOIN
        dim_product p ON s.product_code = p.product_code
    GROUP BY
        p.segment
)
SELECT
    segment,
    product_count_2020,
    product_count_2021,
    -- Calculate the difference
    (product_count_2021 - product_count_2020) AS difference
FROM
    product_counts_by_segment
ORDER BY
    difference DESC;

/************************************************************************************************
REQUEST 5: Get the products that have the highest and lowest manufacturing costs.
************************************************************************************************/

WITH ranked_costs AS (
    SELECT
        p.product_code,
        p.product,
        m.manufacturing_cost,
        -- Rank products by cost from lowest to highest
        RANK() OVER (ORDER BY m.manufacturing_cost ASC) as rank_asc,
        -- Rank products by cost from highest to lowest
        RANK() OVER (ORDER BY m.manufacturing_cost DESC) as rank_desc
    FROM
        fact_manufacturing_cost m
    JOIN
        dim_product p ON m.product_code = p.product_code
)
SELECT
    product_code,
    product,
    manufacturing_cost
FROM
    ranked_costs
WHERE
    -- Select the #1 ranked in both categories
    rank_asc = 1 OR rank_desc = 1;

/************************************************************************************************
REQUEST 6: Generate a report which contains the top 5 customers who received an 
average high pre_invoice_discount_pct for the fiscal year 2021 and in the 
Indian market.
************************************************************************************************/

WITH CustomerDiscounts AS (
    -- First, calculate the average discount for each customer in the specified market and year
    SELECT
        c.customer_code,
        c.customer,
        AVG(pid.pre_invoice_discount_pct) AS average_discount_percentage
    FROM
        fact_pre_invoice_deductions pid
    JOIN
        dim_customer c ON pid.customer_code = c.customer_code
    WHERE
        pid.fiscal_year = 2021
        AND c.market = 'India'
    GROUP BY
        c.customer_code,
        c.customer
),
RankedCustomers AS (
    -- Next, rank the customers based on their average discount
    SELECT
        customer_code,
        customer,
        average_discount_percentage,
        DENSE_RANK() OVER (ORDER BY average_discount_percentage DESC) as discount_rank
    FROM
        CustomerDiscounts
)
-- Finally, select the top 5 ranked customers
SELECT
    customer_code,
    customer,
    ROUND(average_discount_percentage, 4) AS average_discount_percentage
FROM
    RankedCustomers
WHERE
    discount_rank <= 5;

/************************************************************************************************
REQUEST 7: Get the complete report of the Gross sales amount for the customer "Atliq 
Exclusive" for each month.
************************************************************************************************/

WITH MonthlySales AS (
    -- First, join the tables to get the gross price for each sale and filter for the specific customer
    SELECT
        s.date,
        (s.sold_quantity * g.gross_price) AS gross_sales_amount
    FROM
        fact_sales_monthly s
    JOIN
        dim_customer c ON s.customer_code = c.customer_code
    JOIN
        fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
    WHERE
        c.customer = 'Atliq Exclusive'
)
-- Now, aggregate the results by month and year
SELECT
    DATE_FORMAT(date, '%M') AS Month, -- Format date to get the full month name
    YEAR(date) AS Year,
    ROUND(SUM(gross_sales_amount), 2) AS `Gross sales Amount`
FROM
    MonthlySales
GROUP BY
    Year, Month, MONTH(date) -- Group by month number as well for correct sorting
ORDER BY
    Year, MONTH(date); -- Order by month number to ensure chronological order

/************************************************************************************************
REQUEST 8: In which quarter of 2020, got the maximum total_sold_quantity?
************************************************************************************************/

SELECT
    -- Format the quarter number as 'Q1', 'Q2', etc. for better readability
    CONCAT('Q', QUARTER(date)) AS Quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY
    Quarter
ORDER BY
    total_sold_quantity DESC;

/************************************************************************************************
REQUEST 9: Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?
************************************************************************************************/

WITH ChannelGrossSales AS (
    -- First, calculate the gross sales for each channel in the fiscal year 2021
    SELECT
        c.channel,
        SUM(s.sold_quantity * g.gross_price) AS total_gross_sales
    FROM
        fact_sales_monthly s
    JOIN
        dim_customer c ON s.customer_code = c.customer_code
    JOIN
        fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
    WHERE
        s.fiscal_year = 2021
    GROUP BY
        c.channel
)
-- Now, calculate the contribution percentage for each channel
SELECT
    channel,
    -- Format gross sales in millions with rounding
    ROUND(total_gross_sales / 1000000, 2) AS gross_sales_mln,
    -- Calculate percentage contribution using a window function to get the grand total
    ROUND(
        total_gross_sales * 100.0 / SUM(total_gross_sales) OVER (),
        2
    ) AS percentage
FROM
    ChannelGrossSales
ORDER BY
    percentage DESC;

/************************************************************************************************
REQUEST 10: Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021.
************************************************************************************************/

WITH ProductSales AS (
    -- First, calculate the total sold quantity for each product in the fiscal year 2021
    SELECT
        p.division,
        p.product_code,
        p.product,
        SUM(s.sold_quantity) AS total_sold_quantity
    FROM
        fact_sales_monthly s
    JOIN
        dim_product p ON s.product_code = p.product_code
    WHERE
        s.fiscal_year = 2021
    GROUP BY
        p.division,
        p.product_code,
        p.product
),
RankedProducts AS (
    -- Next, rank the products within each division based on their total sold quantity
    SELECT
        division,
        product_code,
        product,
        total_sold_quantity,
        DENSE_RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) as rank_order
    FROM
        ProductSales
)
-- Finally, select the top 3 ranked products from each division
SELECT
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM
    RankedProducts
WHERE
    rank_order <= 3;
```