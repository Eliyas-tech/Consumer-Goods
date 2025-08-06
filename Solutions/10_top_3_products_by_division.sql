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