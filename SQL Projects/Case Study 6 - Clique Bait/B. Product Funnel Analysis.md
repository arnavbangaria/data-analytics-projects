Using a single SQL query - create a new output table which has the following details:

- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?

Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

__Product Analysis View__
```sql
CREATE VIEW ProductAnalysis AS 
(
WITH cte1 AS
(
	SELECT 
		product_id,
		page_name,
		SUM(
			CASE
			WHEN event_type = 1 THEN 1
			ELSE 0
			END
		) AS page_view,
		SUM(
			CASE 
			WHEN event_type = 2 THEN 1
			ELSE 0
			END
		) AS added_to_cart
	FROM events e LEFT JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	WHERE product_id IS NOT NULL
	GROUP BY product_id, page_name
),

cte2 AS
(
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
)

SELECT 
	cte1.product_id, 
    cte1.page_name, 
    page_view, 
    added_to_cart, 
    purchase_count,
    (added_to_cart - purchase_count) AS abandoned_count
FROM cte1 JOIN cte2
	ON cte1.product_id = cte2.product_id AND cte1.page_name = cte2.page_name
ORDER BY cte1.product_id
);
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/432a2fe1-cde0-4c9a-8c0e-7144855366d0)


__Category Analysis View__
```sql
CREATE VIEW CategoryAnalysis AS 
(
WITH cte1 AS
(
	SELECT
		product_category,
		SUM(
			CASE
			WHEN event_type = 1 THEN 1
			ELSE 0
			END
		) AS page_view,
		SUM(
			CASE 
			WHEN event_type = 2 THEN 1
			ELSE 0
			END
		) AS added_to_cart
	FROM events e LEFT JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	WHERE product_category IS NOT NULL
	GROUP BY product_category
),

cte2 AS
(
SELECT 
	product_category,
    SUM(
		CASE 
        WHEN event_type = 2 THEN 1
        ELSE 0
        END
    ) AS purchase_count
FROM events e JOIN page_hierarchy ph
	ON 	ph.page_id = e.page_id
WHERE visit_id IN (SELECT visit_id FROM events WHERE event_type = 3)
GROUP BY product_category
HAVING product_category IS NOT NULL
)

SELECT 
	cte1.product_category,
    page_view, 
    added_to_cart, 
    purchase_count,
    (added_to_cart - purchase_count) AS abandoned_count
FROM cte1 JOIN cte2
	ON cte1.product_category = cte2.product_category
ORDER BY cte1.product_category
);
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/75657a77-23b7-4e54-aaf3-ce2e28a47a81)

---

__Use your 2 new output tables - answer the following questions:__

__1. Which product had the most views, cart adds and purchases?__
```sql
SELECT *
FROM productanalysis
ORDER BY page_view DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6dfa7481-d8de-4532-972b-107cd1e6064e)

```sql
SELECT *
FROM productanalysis
ORDER BY added_to_cart DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/b342d188-6bf7-41c3-9d53-2a16244e2c02)

```sql
SELECT *
FROM productanalysis
ORDER BY purchase_count DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/93a938ea-9392-4493-8353-cc939b48da79)

---

__2. Which product was most likely to be abandoned?__
```sql
SELECT *
FROM productanalysis
ORDER BY abandoned_count DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6a1ef5d7-c8db-49df-a339-bac01c6f77de)

---

__3. Which product had the highest view to purchase percentage?__
```sql
SELECT
	product_id,
    page_name,
	CONCAT(ROUND((purchase_count / page_view)*100, 2), " %") AS view_purchase_percent
FROM productanalysis
ORDER by view_purchase_percent DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/7cbe2a52-38f1-49d0-983b-d22f1cd48844)

---

__4. What is the average conversion rate from view to cart add?__
```sql
SELECT
	product_id,
    page_name,
	CONCAT(ROUND((added_to_cart / page_view)*100, 2), " %") AS cart_view_percent
FROM productanalysis
ORDER by cart_view_percent DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/68921d0e-f2ab-4c9c-aef4-ecfcaa7e3a37)

---

__5. What is the average conversion rate from cart add to purchase?__
```sql
SELECT
	product_id,
    page_name,
	CONCAT(ROUND((purchase_count / added_to_cart)*100, 2), " %") AS purchase_cart_percent
FROM productanalysis
ORDER by purchase_cart_percent DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/fc47c400-1815-404f-87fd-dd3297355098)
