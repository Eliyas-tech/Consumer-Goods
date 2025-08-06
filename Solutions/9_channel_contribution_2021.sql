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