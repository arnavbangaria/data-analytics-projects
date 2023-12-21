```sql
WITH plans_cte AS (
    SELECT 
        customer_id,
        s.plan_id,
        start_date,
        ROUND(price, 2) AS current_price,
        ROUND(LEAD(p.price, 1) OVER(PARTITION BY customer_id ORDER BY start_date), 2) AS next_price,
        ROUND(LAG(p.price, 1) OVER(PARTITION BY customer_id ORDER BY start_date), 2) AS prev_price,
        LEAD(s.plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM subscriptions s 
    JOIN plans p ON s.plan_id = p.plan_id
)

SELECT 
    customer_id,
    start_date,
    plan_id,
    CASE 
        WHEN plan_id IN (0, 1, 2) THEN start_date
        WHEN plan_id = 3 THEN LAST_DAY(start_date)
    END AS payment_start_date,
    CASE
        WHEN plan_id IN (0, 1, 2) THEN DATE_ADD(start_date, INTERVAL 1 MONTH)
        WHEN plan_id = 3 THEN LAST_DAY(start_date)
    END AS next_payment_date,
    CASE
        WHEN plan_id IN (0, 4) THEN NULL
        WHEN plan_id IN (1, 2, 3) THEN ABS(IFNULL(current_price, 0) - IFNULL(prev_price, 0))
    END AS due_amount
FROM plans_cte;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c7d8aa0d-4f37-427f-9add-127cdf3d7113)
