__1. How many unique nodes are there on the Data Bank system?__
```sql
SELECT COUNT(DISTINCT customer_id) AS unique_nodes
FROM customer_nodes;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/5260219e-aab7-4d9f-97a8-f2dea266b8e8)

---

__2. What is the number of nodes per region?__
```sql
SELECT r.region_id, r.region_name, COUNT(node_id) AS nodes_by_region
FROM customer_nodes cn JOIN regions r 
	ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c46837b1-3bb8-42b5-81a3-52801cca3854)

---

__3. How many customers are allocated to each region?__
```sql
SELECT r.region_id, r.region_name, COUNT(DISTINCT customer_id) AS nodes_by_region
FROM customer_nodes cn JOIN regions r 
	ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/bb104975-7a01-42f5-a117-c2d11ea73890)

---

__4. How many days on average are customers reallocated to a different node?__
```sql
SELECT ABS(AVG(DATEDIFF(start_date, end_date))) AS avg_day
FROM customer_nodes
WHERE end_date <> '9999-12-31';
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/28fdbbd2-0e29-42f0-8c9a-a65b556a5be1)

---

__5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?__
```sql
WITH date_diff AS
(
    SELECT cn.customer_id,
           cn.region_id,
           r.region_name,
           TIMESTAMPDIFF(DAY, start_date, end_date) AS reallocation_days
    FROM customer_nodes cn
    INNER JOIN regions r ON cn.region_id = r.region_id
    WHERE end_date != '9999-12-31'
),

per_rank_cte AS 
(
SELECT 
	region_id,
    region_name,
    ROUND(PERCENT_RANK() OVER(PARTITION BY region_id, region_name ORDER BY reallocation_days), 2) AS ranking
FROM date_diff
ORDER BY ranking DESC
)

SELECT 
	DISTINCT region_id, 
    region_name,
    ranking
FROM per_rank_cte
WHERE ranking IN (0.50, 0.95, 0.80)
ORDER BY 3;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/eb1039fe-9d66-479f-bba5-3f60168897e4)
