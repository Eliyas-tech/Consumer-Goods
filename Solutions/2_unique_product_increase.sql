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