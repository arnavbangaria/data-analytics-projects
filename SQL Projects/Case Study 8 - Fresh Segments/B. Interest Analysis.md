__1. Which interests have been present in all month_year dates in our dataset?__
```sql
WITH cte1 AS 
(
SELECT 
	interest_id,
    COUNT(MONTH(month_year)) AS month_count
FROM interest_metrics
GROUP BY 1
),

total_months AS
(
SELECT 
	month_count,
    COUNT(interest_id) AS cnts
FROM cte1
GROUP BY 1
)

SELECT *
FROM total_months;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/e88f95d8-537b-4db5-8c41-d9e7533dc9ed)

---

__2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?__
```sql
WITH cte1 AS 
(
SELECT 
	interest_id,
    COUNT(DISTINCT month_year) AS month_count
FROM interest_metrics
GROUP BY 1
),

total_months AS
(
SELECT 
	month_count,
    COUNT(interest_id) AS cnts
FROM cte1
GROUP BY 1
)

SELECT 
	month_count,
    cnts,
    CONCAT((SUM(cnts) OVER(ORDER BY month_count DESC))*100 / (SELECT SUM(cnts) FROM total_months), " %") AS cumm_percent
FROM total_months;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/1bcdbf8b-231d-45c1-88ed-c2f6091250b3)

---

__3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?__
```sql
WITH cte1 AS
(
SELECT 
	interest_id,
    COUNT(DISTINCT month_year) AS months
FROM interest_metrics
GROUP BY 1
)

SELECT COUNT(interest_id) AS count_of_removed_datapoint
FROM cte1 
WHERE months < 6;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/fbb8b22a-f607-4d86-97e0-48956e7756d5)

---

__Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.__
```
These data points need not to be deleted from business perspective since they will be useful for some other analysis and business has only only functioned for 14 months according to data thus initial data are important and precious
```

---

__4. After removing these interests - how many unique interests are there for each month?__
```sql
WITH cte1 AS
(
SELECT 
	interest_id,
    COUNT(DISTINCT month_year) AS months
FROM interest_metrics
GROUP BY 1
)

SELECT (COUNT(DISTINCT interest_id) - (SELECT COUNT(DISTINCT interest_id) FROM cte1 WHERE months < 6)) AS  remaining_unique_interest_id
FROM cte1 ;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/85090194-83fa-4e97-a6ce-da6d8bbfab19)
