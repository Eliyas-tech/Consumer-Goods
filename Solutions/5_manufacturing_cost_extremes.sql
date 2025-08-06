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