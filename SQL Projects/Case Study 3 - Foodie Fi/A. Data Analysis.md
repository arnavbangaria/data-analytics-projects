__CUSTOMER JOURNEY__
Based on 8 sample customers we can deduce the following outcomes
- There is a trial periods of 1 week or 7 days
- 12.5% of customers adopted for pro monthly plan after trial period ended
- 87.5% of customers adopted for basic monthly plan after trial period ended
- 28.5% of customers who adopted for basic monthly plan churned after two months
- 28.5% of customers who adopted for basic monthly plan upgarded to pro monthly plan

---

__1. How many customers has Foodie-Fi ever had?__
```sql
SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/2cacdf03-2963-4f4d-a7e5-7e64b2bda52c)

---

__2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value?__
```sql
SELECT 
	MONTH(start_date) AS months,
	COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions
GROUP BY MONTH(start_date);
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/e6fe1abf-cbfc-4861-b33c-9d478ca0af7b)

---

__3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name__
```sql
SELECT
	p.plan_id,
	p.plan_name,
	COUNT(*) AS date_count
FROM subscriptions s JOIN plans p
	ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6ad6d855-570b-435e-b513-4f167d586e53)

---

__4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?__
```sql
SELECT 
	COUNT(*) AS cust_count,
    ROUND((COUNT(*)/(SELECT COUNT(customer_id) FROM subscriptions))*100, 1) AS churn_percentage
FROM subscriptions
WHERE plan_id = 4;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/59ee4b9e-f169-49c5-bb41-57b85afff423)

---

__5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?__
```sql
WITH churn_cte AS (
SELECT 
	*,
    LAG(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS prev_plan
FROM subscriptions
)

SELECT
	COUNT(prev_plan) AS cust_count,
    ROUND((COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions))*100, 0) AS churned_percentage
FROM churn_cte
WHERE plan_id = 4 AND prev_plan = 0;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/3dba1af8-b3c1-44b7-9637-5d082e75ff85)

---
    
__6. What is the number and percentage of customer plans after their initial free trial?__
```sql
WITH next_plan_cte AS (
    SELECT 
        *,
        LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS next_plan
    FROM subscriptions
)

SELECT 
    next_plan,
    COUNT(*) AS cust_plan,
    ROUND((COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions))*100, 1) AS cust_percent
FROM next_plan_cte
WHERE next_plan IS NOT NULL AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/5e3f9679-1ca1-4d60-8b68-fb51d11ef3c2)

---

__7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?__
```sql
SELECT 
	plan_id,
    COUNT(customer_id) AS customer_count,
    CONCAT(ROUND(100*(COUNT(customer_id) / (SELECT COUNT(*) FROM subscriptions)), 2), " %") AS percent_breakdown 
FROM subscriptions
GROUP BY plan_id
ORDER BY plan_id; 
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/ac7105c3-7f94-4d98-a896-9da515b613ac)

---

__8. How many customers have upgraded to an annual plan in 2020?__
```sql
SELECT 
	COUNT(customer_id) AS sub_count
FROM subscriptions
WHERE plan_id = 3 AND 2020 = YEAR(start_date);
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c7b25338-d876-4736-a2b2-d0169041b98b)

---

__9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?__
```sql
WITH subs_cte1 AS 
(
SELECT 
	customer_id,
    plan_id,
    start_date,
    CAST(MIN(start_date) OVER(PARTITION BY customer_id ORDER BY plan_id) AS DATE) AS join_date
FROM subscriptions
),

subs_cte2 AS 
(
SELECT 
	customer_id,
    ABS(DATEDIFF(start_date, join_date)) AS dates
FROM subs_cte1
WHERE plan_id = 3
)

SELECT ROUND(AVG(dates)) AS avg_days
FROM subs_cte2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/b259fa81-80ae-4a78-a591-42bd5cb68236)

---

__10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)__
```sql
WITH cte_subs_1 AS (
	SELECT 
		*,
		MIN(start_date) OVER(PARTITION BY customer_id ORDER BY plan_id) AS join_date
	FROM subscriptions
),

cte_subs_2 AS (
	SELECT 
		*,
		ABS(DATEDIFF(join_date, start_date)) AS date_diff,
		ROUND(ABS((DATEDIFF(join_date, start_date)))/30) AS buckets
	FROM cte_subs_1
	WHERE plan_id =3
),

cte_subs_3 AS 
(
SELECT 
	(
	CASE
	WHEN (buckets = 0) OR (buckets = 12) THEN '0  - 30'
	WHEN buckets = 1 THEN '31 - 60'
	WHEN buckets = 2 THEN '61 - 90'
	WHEN buckets = 3 THEN '91 - 120'
	WHEN buckets = 4 THEN '121 - 150'
	WHEN buckets = 5 THEN '151 - 180'
	WHEN buckets = 6 THEN '181 - 210'
	WHEN buckets = 7 THEN '211 - 240'
	WHEN buckets = 8 THEN '241 - 270'
	WHEN buckets = 9 THEN '271 - 300'
	WHEN buckets = 10 THEN '301 - 330'
	WHEN buckets = 11 THEN '331 - 365'
	END
	) AS day_range,
    IF(buckets=12, 0, buckets) AS rn_no,
	ROUND(AVG(date_diff)) AS avg_date
FROM cte_subs_2
GROUP BY 1, 2
)

SELECT 
	day_range,
    avg_date
FROM cte_subs_3
ORDER BY rn_no;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/a88cf5d7-d2da-4bda-8061-8f68b3a759a1)

---

__11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?__
```sql
WITH cte1 AS
(
	SELECT 
		customer_id,
		plan_id AS curr_plan,
		LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_plan
	FROM subscriptions
	WHERE 2020 = YEAR(start_date)
)

SELECT COUNT(DISTINCT customer_id) AS downgrade_count
FROM cte1
WHERE curr_plan = 2 AND next_plan = 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/54d4a4ce-9e68-4367-baec-951d7e4cef68)
