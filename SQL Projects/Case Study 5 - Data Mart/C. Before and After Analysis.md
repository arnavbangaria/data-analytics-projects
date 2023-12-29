This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

```sql
WITH cte1 AS 
(
SELECT 
	*,
    (
    CASE 
    WHEN txn_date = '2020-06-15' THEN 'Baseline'
    WHEN txn_date > '2020-06-15' THEN 'After'
    WHEN txn_date < '2020-06-15' THEN 'Before'
    END
    ) AS tag
FROM clean_weekly_sales
)

SELECT *
FROM cte1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/479bca8c-44cb-4358-bd78-3d8f7c58c901)

---

__1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?__
```sql
WITH cte1 AS 
(
    SELECT 
		SUM(
		CASE
		WHEN txn_date BETWEEN '2020-06-15' AND DATE_ADD('2020-06-15', INTERVAL 3 WEEK) THEN txn_sales
		END
		) AS after_baseline,
		SUM(
		CASE
		WHEN txn_date BETWEEN DATE_SUB('2020-06-15', INTERVAL 3 WEEK) AND '2020-06-15' THEN txn_sales
		END
		) AS before_baseline
	FROM clean_weekly_sales
)

SELECT 
	*,
    ((after_baseline - before_baseline) / before_baseline)*100 AS per_change
FROM cte1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/18b4c379-374d-4bcb-aa56-d71e01f43932)

---

__2. What about the entire 12 weeks before and after?__
```sql
WITH cte1 AS 
(
    SELECT 
		SUM(
		CASE
		WHEN txn_date BETWEEN '2020-06-15' AND DATE_ADD('2020-06-15', INTERVAL 11 WEEK) THEN txn_sales
		END
		) AS after_baseline,
		SUM(
		CASE
		WHEN txn_date BETWEEN DATE_SUB('2020-06-15', INTERVAL 11 WEEK) AND '2020-06-15' THEN txn_sales
		END
		) AS before_baseline
	FROM clean_weekly_sales
)

SELECT 
	*,
    ((after_baseline - before_baseline) / before_baseline)*100 AS per_change
FROM cte1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6a91ce25-ed72-462e-bd55-c36f4a46e709)

---

__3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?__
```sql
SELECT WEEKOFYEAR(txn_date) AS week_num
FROM clean_weekly_sales
WHERE txn_date IN ('2020-06-15', '2019-06-15', '2018-06-15')
GROUP BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/b1298498-90a5-499d-8835-af95b8bbd5d6)

```sql
WITH cte1 AS 
(
	SELECT 
		calendar_year,
		SUM(CASE WHEN week_number < 25 THEN txn_sales END) AS before_sales,
		SUM(CASE WHEN week_number > 25 THEN txn_sales END) AS after_sales
	FROM clean_weekly_sales
	GROUP BY 1
)

SELECT 
	*,
    (after_sales - before_sales) AS diff_sales,
    ((after_sales - before_sales) / before_sales)*100 AS per_change
FROM cte1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/14b0f2aa-2751-4124-8ce1-b6141c6e08b6)
