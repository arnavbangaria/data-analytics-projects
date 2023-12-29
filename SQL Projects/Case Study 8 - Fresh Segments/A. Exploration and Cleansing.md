```sql
ALTER TABLE interest_metrics
RENAME COLUMN _month TO month,
RENAME COLUMN _year TO year;
```

---

__1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month?__
```sql
ALTER TABLE fresh_segments.interest_metrics
MODIFY COLUMN month_year VARCHAR(10);

UPDATE fresh_segments.interest_metrics
SET month_year = CONCAT('01-', month_year);

UPDATE fresh_segments.interest_metrics
SET month_year = STR_TO_DATE(month_year, "%d-%m-%Y");

ALTER TABLE fresh_segments.interest_metrics
MODIFY COLUMN month_year DATE,
MODIFY COLUMN month INTEGER,
MODIFY COLUMN year INTEGER,
MODIFY COLUMN interest_id INTEGER;

DESC interest_metrics;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/1570a769-475b-4af9-b4d2-f6ae9c840c3b)

---

__2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?__
```sql
SELECT 
	month,
    COUNT(*) AS counts
FROM interest_metrics
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/bd4342d6-cb85-4c14-8eac-6eaf059a4acc)

---

__What do you think we should do with these null values in the fresh_segments.interest_metrics__
```sql
-- Removing the entry 
DELETE FROM interest_metrics WHERE month = "";
```

---

__3. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?__
```sql
SELECT COUNT(DISTINCT interest_id) AS id_count
FROM interest_metrics;

SELECT COUNT(DISTINCT id) AS id_count
FROM interest_map;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/1aee3467-af74-46bc-bd41-f70ad99eb83d)
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/639c07d2-6fbf-4379-8257-ca55bf1d34ce)

---

__4. Summarise the id values in the fresh_segments.interest_map by its total record count in this table__
__What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.__
```sql
SELECT *
FROM interest_map t1 LEFT JOIN interest_metrics t2
	ON t1.id = t2.interest_id
WHERE month IS NULL;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/55409a0b-7f53-4934-b0cb-5921c044cfe5)

---

__5. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table?__
```sql
SELECT *
FROM interest_map t1 LEFT JOIN interest_metrics t2
	ON t1.id = t2.interest_id
WHERE month_year < created_at;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/9498f0bd-20f3-4525-a607-1a9919e5f101)
