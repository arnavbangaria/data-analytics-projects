__1. How many unique transactions were there?__
```sql
SELECT COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/50f543fe-2892-4bbe-8203-d5a9be12dbea)

---

__2. What is the average unique products purchased in each transaction?__
```sql
SELECT
	txn_id,
    COUNT(DISTINCT prod_id) AS unique_product
FROM sales
GROUP BY txn_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6ac38a8a-c87c-4503-9987-2cc50132e013)

---

__3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?__
```sql
WITH cte1 AS
(
SELECT
	txn_id,
    SUM(qty*price) AS revenue_per_transaction
FROM sales
GROUP BY txn_id
),

cte2 AS 
(
SELECT 
	txn_id,
    revenue_per_transaction,
    ROUND(PERCENT_RANK() OVER(ORDER BY revenue_per_transaction), 2) AS ranking
FROM cte1
)

SELECT 
	DISTINCT revenue_per_transaction,
    ranking
FROM cte2
WHERE ranking IN (0.25, 0.50, 0.75);
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/d5485017-6dba-4539-8b1a-ee6afb420db2)

---

__4. What is the average discount value per transaction?__
```sql
SELECT 
	txn_id,
    ROUND(AVG(discount), 2) AS avg_discount
FROM sales
GROUP BY txn_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/425d1d53-4f17-4965-8d0d-77176bd30d86)

---

__5. What is the percentage split of all transactions for members vs non-members?__
```sql
SELECT 
	(
    CASE WHEN member = 1 THEN 'Member'
    ELSE 'Non-Member'
    END
    ) AS customer_type,
    CONCAT(
		ROUND(
			(COUNT(DISTINCT txn_id) / (SELECT COUNT(DISTINCT txn_id) FROM sales))*100
            , 2)
		, " %") AS percentage
FROM sales
GROUP BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c9f5d877-9b13-45a9-9241-b93224f28c1f)

---

__6. What is the average revenue for member transactions and non-member transactions?__
```sql
SELECT
	(
    CASE WHEN member = 1 THEN 'Member'
    ELSE 'Non-Member'
    END
    ) AS customer_type,
    AVG(qty*price) AS avg_revenue
FROM sales
GROUP BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/cd75e1d1-adad-42e1-ad4b-3f8f0a86050d)
