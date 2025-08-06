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