__The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients. Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.__

__1. What is the top 10 interests by the average composition for each month?__
```sql
SELECT 
	t1.interest_id,
    t2.interest_name,
    ROUND(AVG(composition), 2) AS avg_comp
FROM interest_metrics t1 LEFT JOIN interest_map t2
	ON t1.interest_id = t2.id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/a718d6fa-c674-45f9-ad70-ffd1f15d8ff5)

---

__2. For all of these top 10 interests - which interest appears the most often?__
```sql
SELECT 
	t1.interest_id,
    t2.interest_name,
    ROUND(AVG(composition), 2) AS avg_comp,
    COUNT(interest_id) AS appearance
FROM interest_metrics t1 LEFT JOIN interest_map t2
	ON t1.interest_id = t2.id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/1627a8d7-a8de-4654-ad27-312bcfef5eee)

---

__3. What is the average of the average composition for the top 10 interests for each month?__
```sql
WITH average_comp AS
(
SELECT
	month_year,
    interest_id,
    composition,
    index_value,
    ROUND((composition / index_value), 2) AS avg_comp,
    DENSE_RANK() OVER(PARTITION BY month_year ORDER BY (composition / index_value) DESC) AS ranking
FROM interest_metrics
)

SELECT 
	month_year,
    ROUND(AVG(avg_comp), 2) AS avg_avg_comp
FROM average_comp
WHERE ranking<=10
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/8ea025bd-691e-4cb7-af73-33b089b9a941)

---

__4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.__
```sql
WITH avg_compositions AS (
  SELECT 
    month_year,
    interest_id,
    ROUND(composition / index_value, 2) AS avg_comp,
    ROUND(MAX(composition / index_value) OVER(PARTITION BY month_year), 2) AS max_avg_comp
  FROM interest_metrics
  WHERE month_year IS NOT NULL
),

max_avg_comp AS (
  SELECT *
  FROM avg_compositions
  WHERE avg_comp = max_avg_comp
),

moving_avg_comp AS (
  SELECT 
    t1.month_year,
    t2.interest_name,
    t1.max_avg_comp AS max_index_composition,
    ROUND(AVG(t1.max_avg_comp) OVER(ORDER BY t1.month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS '3_month_moving_avg',
    CONCAT(
		LAG(t2.interest_name) OVER (ORDER BY t1.month_year), 
        ': ',
		CAST(LAG(t1.max_avg_comp) OVER (ORDER BY t1.month_year) AS CHAR(4))
        ) AS '1_month_ago',
    CONCAT(
		LAG(t2.interest_name, 2) OVER (ORDER BY t1.month_year), 
        ': ',
		CAST(LAG(t1.max_avg_comp, 2) OVER (ORDER BY t1.month_year) AS CHAR(4))
        ) AS '2_month_ago'
  FROM max_avg_comp t1 JOIN interest_map t2 
    ON t1.interest_id = t2.id
)

SELECT *
FROM moving_avg_comp
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/8a45a3b1-9a27-47fa-82ca-dbd6605a8eab)

__5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?__
```
Most of the fresh segment business relied on travel and trips as seen in the above composition result.
```
