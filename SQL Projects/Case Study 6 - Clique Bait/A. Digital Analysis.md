__1. How many users are there?__
```sql
SELECT COUNT(DISTINCT user_id) AS total_users 
FROM users;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/ef78739f-d3fd-46c9-b7c5-291ef5abf39b)

---

__2. How many cookies does each user have on average?__
```sql
SELECT ROUND(AVG(counts), 0) AS average_cookies
FROM (
	SELECT user_id, COUNT(DISTINCT cookie_id) AS counts
    FROM users
    GROUP BY user_id
) x;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/87455b86-fcb5-4aba-95e0-aa41536e8416)

---

__3. What is the unique number of visits by all users per month?__
```sql
SELECT 
	MONTH(event_time) AS months,
    MONTHNAME(event_time) AS mon_name,
    COUNT(DISTINCT visit_id) AS visit_count
FROM events
GROUP BY MONTH(event_time), mon_name;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/e0f28141-1c4b-4f75-ac4b-e507ea120130)

---

__4. What is the number of events for each event type?__
```sql
SELECT 
	event_type,
    COUNT(visit_id) AS counts
FROM events
GROUP BY event_type;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/932db317-7039-4566-b5d4-861d75829c49)

---

__5. What is the percentage of visits which have a purchase event?__
```sql
SELECT
	CONCAT(100*(COUNT(DISTINCT visit_id) / (SELECT COUNT(DISTINCT visit_id) FROM events)), " %") AS percent
FROM events
WHERE event_type=3;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/d0b21164-fd1e-4b2d-94e6-48fe89670051)

---

__6. What is the percentage of visits which view the checkout page but do not have a purchase event?__
```sql
WITH event_cte AS 
(
SELECT *, LAST_VALUE(page_id) OVER(PARTITION BY visit_id ORDER BY page_id RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lastval
FROM events
ORDER BY visit_id DESC, page_id
)

SELECT CONCAT(COUNT(DISTINCT visit_id)*100 / (SELECT COUNT(DISTINCT visit_id) FROM event_cte), "%") AS percent_val
FROM event_cte
WHERE lastval = 12;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/2ff7b438-e22c-4066-981c-328982339b2e)

---

__7. What are the top 3 pages by number of views?__
```sql
SELECT 
	e.page_id,
    ph.page_name,
    COUNT(visit_id) AS page_view
FROM events e
JOIN page_hierarchy ph 
	ON e.page_id = ph.page_id 
GROUP BY e.page_id, ph.page_name
ORDER BY page_view DESC
LIMIT 3;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/301ca0e6-a87b-40d7-ba16-b10fe7c2654a)

---

__8. What is the number of views and cart adds for each product category?__
```sql
WITH event_cte AS 
(
	SELECT 
		ph.product_id, 
		e.event_type
	FROM events e JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	WHERE product_id IS NOT NULL
)

SELECT 
	product_id,
    SUM(
		CASE WHEN event_type = 1 THEN 1
		ELSE 0
		END
    ) AS views, 
    SUM(
		CASE WHEN event_type = 2 THEN 1
		ELSE 0
		END
    ) AS added_to_cart
FROM event_cte
GROUP BY product_id
ORDER BY product_id;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/d129953c-7947-4f4c-8843-3f051661ea36)

---

__9. What are the top 3 products by purchases?__
```sql
SELECT 
	product_id,
    page_name,
    SUM(
		CASE 
        WHEN event_type = 2 THEN 1
        ELSE 0
        END
    ) AS purchase_count
FROM events e JOIN page_hierarchy ph
	ON 	ph.page_id = e.page_id
WHERE visit_id IN (SELECT visit_id FROM events WHERE event_type = 3)
GROUP BY product_id, page_name
HAVING product_id IS NOT NULL
ORDER BY purchase_count DESC
LIMIT 3;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6e6ccb8e-8b88-4580-9d0b-62a05cb18749)
