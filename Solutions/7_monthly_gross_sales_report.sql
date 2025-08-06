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