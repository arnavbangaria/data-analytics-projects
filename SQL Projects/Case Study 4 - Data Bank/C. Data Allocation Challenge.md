To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time

<br> 

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer

## Running Customer Balance
```sql
WITH balance_cte1 AS 
(
	SELECT 
		*,
		(
		CASE
		WHEN txn_type = 'deposit' THEN txn_amount
		ELSE (-1*txn_amount)
		END
		) AS updated_amount
	FROM customer_transactions
)

SELECT 
	customer_id, 
	txn_date,
	txn_type,
	SUM(updated_amount) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_total
FROM balance_cte1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/af96f5b2-2059-499c-9069-4e092faa4d1d)

---

## Customer Balance at end of month
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
		END
		) AS updated_amount
	FROM customer_transactions
	GROUP BY 1, 2
)

SELECT 
	customer_id, 
	months,
	SUM(updated_amount) OVER(PARTITION BY customer_id ORDER BY months) AS closing_balance
FROM balance_cte
ORDER BY customer_id, months;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/3126b547-5008-475a-ba68-872f79ffca9b)

---

## Min, Avg and Max Value
```sql
WITH balance_cte1 AS 
(
	SELECT 
		*,
		(
		CASE
		WHEN txn_type = 'deposit' THEN txn_amount
		ELSE (-1*txn_amount)
		END
		) AS updated_amount
	FROM customer_transactions
),

balance_cte2 AS
(
SELECT 
	customer_id, 
	txn_date,
	txn_type,
	SUM(updated_amount) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_total
FROM balance_cte1
)

SELECT 
	customer_id, 
	MIN(running_total) AS min_value,
	AVG(running_total) AS avg_value,
	MAX(running_total) AS max_value
FROM balance_cte2
GROUP BY customer_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/9d7ca96f-7353-453e-94a2-3cb55e03241f)
