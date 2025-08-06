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