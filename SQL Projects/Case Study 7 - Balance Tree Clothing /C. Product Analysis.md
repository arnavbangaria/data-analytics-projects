__1. What are the top 3 products by total revenue before discount?__
```sql
SELECT
	s.prod_id,
    pd.product_name,
    SUM(s.qty*s.price) AS tot_revenue
FROM sales s JOIN product_details pd
	ON s.prod_id = pd.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 3;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/ec183e7d-75ec-4157-9e32-87227d077eb9)

---

__2. What is the total quantity, revenue and discount for each segment?__
```sql
SELECT 
	segment_id,
    segment_name,
    ROUND(AVG(discount), 2) AS avg_discount,
    SUM(s.qty) AS tot_quantity,
    SUM(s.qty*s.price) AS tot_revenue
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/cc64369e-7fcc-41e4-95a9-445d05d33e73)

---

__3. What is the top selling product for each segment?__
```sql
WITH cte1 AS
(
SELECT 
	segment_id, 
    segment_name,
    prod_id,
    product_name,
    SUM(qty) AS tot_quantity
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2, 3, 4
ORDER BY segment_name, tot_quantity DESC
)

SELECT *
FROM cte1
WHERE tot_quantity IN (
	SELECT MAX(tot_quantity)
    FROM cte1 
    GROUP BY segment_id, segment_name
);
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/5e21b94f-9fa4-46f4-b80c-f3be9638cdfc)

---

__4. What is the total quantity, revenue and discount for each category?__
```sql
SELECT 
	category_id,
    category_name,
    ROUND(AVG(discount), 2) AS avg_discount,
    SUM(s.qty) AS tot_quantity,
    SUM(s.qty*s.price) AS tot_revenue
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/acb87ca9-b686-436d-87b0-df3e5a7a0e04)

---

__5. What is the top selling product for each category?__
```sql
WITH cte1 AS
(
SELECT 
	category_id, 
    category_name,
    prod_id,
    product_name,
    SUM(qty) AS tot_quantity
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2, 3, 4
)

SELECT *
FROM cte1
WHERE tot_quantity IN (
	SELECT MAX(tot_quantity)
    FROM cte1 
    GROUP BY category_id, category_name
);
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/9744c90e-14e2-4f27-9a57-b45892616ffc)

---

__6. What is the percentage split of revenue by product for each segment?__
```sql
SELECT 
	segment_id,
    segment_name,
    CONCAT(ROUND((SUM(s.qty*s.price)*100 / (SELECT SUM(qty*price) FROM sales)), 2), " %") AS revenue_split
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2
ORDER BY revenue_split DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/779e230d-5f9a-4bb6-b99c-3fc08c3bed13)

---

__7. What is the percentage split of revenue by segment for each category?__
```sql
SELECT 
	category_id,
    category_name,
	segment_id,
    segment_name,
    CONCAT(ROUND((SUM(s.qty*s.price)*100 / (SELECT SUM(qty*price) FROM sales)), 2), " %") AS revenue_split
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2, 3, 4
ORDER BY revenue_split DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/f858a9e9-69c8-4d62-9f2e-6beb9e2740e1)

---

__8. What is the percentage split of total revenue by category?__
```sql
SELECT 
	category_id,
    category_name,
    CONCAT(ROUND((SUM(s.qty*s.price)*100 / (SELECT SUM(qty*price) FROM sales)), 2), " %") AS revenue_split
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2
ORDER BY revenue_split DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/dfeb6cd6-e9cf-43f5-8281-7953c50adc23)

---

__9. What is the total transaction “penetration” for each product?__
__(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)__
```sql
SELECT
	pd.product_id,
    pd.product_name,
    CONCAT(ROUND(COUNT(txn_id)*100 / (SELECT COUNT(txn_id) FROM sales), 2), " %") AS penetration
FROM sales s JOIN product_details pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2
ORDER BY penetration DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/d6c553b8-da39-46e1-9f54-3cb31c221ab5)

---

__10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?__
```sql
SELECT
	prod1,
    prod2,
    prod3,
    bought_together
FROM 
	(
	WITH products AS 
	(
	SELECT 
		txn_id,
		product_name
	FROM sales s JOIN product_details pd
		ON s.prod_id = pd.product_id
	)

	SELECT 
		p1.product_name AS prod1,
        p2.product_name AS prod2,
        p3.product_name AS prod3,
        COUNT(*) AS bought_together,
        ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS ranking
	FROM products p1 
    JOIN products p2 
		ON p1.txn_id = p2.txn_id 
			AND p1.product_name <> p2.product_name 
            AND p1.product_name < p2.product_name
	JOIN products p3
		ON p1.txn_id = p3.txn_id
			AND p1.product_name <> p2.product_name
            AND p2.product_name <> p3.product_name
            AND p1.product_name < p2.product_name
            AND p2.product_name < p3.product_name
	GROUP BY p1.product_name, p2.product_name, p3.product_name
) AS tab
WHERE ranking = 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c00c75d2-27c9-415d-8ecd-cf54abcf5a7e)
