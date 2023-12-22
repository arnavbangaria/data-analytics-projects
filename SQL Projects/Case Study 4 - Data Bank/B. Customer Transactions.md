__1. What is the unique count and total amount for each transaction type?__
```sql
SELECT 
	txn_type,
	COUNT(DISTINCT customer_id) AS unique_count,
	COUNT(customer_id) AS total_count
FROM customer_transactions 
GROUP BY txn_type
ORDER BY txn_type;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/f7a1727b-2c9c-4cdb-8bd5-c58db57540ed)

---

__2. What is the average total historical deposit counts and amounts for all customers?__
```sql
WITH deposit_summary AS
(
	SELECT customer_id,
	       txn_type,
	       COUNT(*) AS deposit_count,
	       SUM(txn_amount) AS deposit_amount
	FROM customer_transactions
	GROUP BY customer_id, txn_type
)

SELECT txn_type,
       AVG(deposit_count) AS avg_deposit_count,
       AVG(deposit_amount) AS avg_deposit_amount
FROM deposit_summary
WHERE txn_type = 'deposit'
GROUP BY txn_type;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/74a40351-71b9-4abf-914a-58654782d497)

---

__3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?__
```sql
WITH customer_activity AS
(
	SELECT customer_id,
	       MONTH(txn_date) AS month_id,
	       MONTHNAME(txn_date) AS month_name,
	       SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
	       SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
	       SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
FROM customer_transactions
GROUP BY 1, 2, 3
)

SELECT month_id,	
       month_name,
       COUNT(DISTINCT customer_id) AS active_customer_count
FROM customer_activity
WHERE deposit_count > 1
      AND (purchase_count > 0 OR withdrawal_count > 0)
GROUP BY month_id, month_name;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/d085619f-35fd-465a-9d55-73be632c7f7e)

---

__4. What is the closing balance for each customer at the end of the month?__
```sql
WITH balance_cte AS 
(
	SELECT 
		customer_id,
		MONTH(txn_date) AS months,
		SUM(
		CASE 
		WHEN txn_type = 'deposit' THEN txn_amount 
		ELSE (-1*txn_amount) 
		END) AS total
	FROM customer_transactions
	GROUP BY 1, 2
)

SELECT 
	customer_id,
	months,
	SUM(total) OVER(PARTITION BY customer_id ORDER BY months) AS closing_balance
FROM balance_cte
ORDER BY customer_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/50684cdc-24ef-41a3-94e9-56c519f837bf)

---

__5. What is the percentage of customers who increase their closing balance by more than 5%?__
```sql
WITH balance_cte1 AS
(
SELECT 
	customer_id,
	MONTH(txn_date) AS months,
	SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE (-1*txn_amount) END) AS updated_balance
FROM customer_transactions
GROUP BY 1, 2
),

balance_cte2 AS 
(
SELECT 
	customer_id,
	months,
	SUM(updated_balance) OVER(PARTITION BY customer_id ORDER BY months) AS closing_balance
FROM balance_cte1
),

balance_cte3 AS 
(
SELECT
	customer_id,
	months,
	closing_balance,
	LAG(closing_balance, 1) OVER(PARTITION BY customer_id ORDER BY months) AS prev_balance
FROM balance_cte2
),

balance_cte4 AS 
(
SELECT 
	customer_id,
	months,
	closing_balance,
	prev_balance,
	(100*(closing_balance - NULLIF(prev_balance, 0)) / NULLIF(prev_balance, 0)) AS per_change
FROM balance_cte3
)

SELECT 
	CONCAT((100*COUNT(DISTINCT customer_id)) / (SELECT COUNT(DISTINCT customer_id) FROM balance_cte4), " %") AS increase_by_5_percent
FROM balance_cte4
WHERE per_change > 5;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/d41e1a42-0087-4501-bcef-cfeed783dd72)
