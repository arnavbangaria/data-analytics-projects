__1. Total amount each customer spend at the restautant?__
```sql 
SELECT s.customer_id, SUM(m.price) AS total_amount_per_customer
FROM sales AS s LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_amount_per_customer;
```
![A1](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/cb82f9ca-5cb6-4965-8c2f-094ad513cd00)

---

__2. How many days has each customer visited the restaurant?__
```sql
SELECT customer_id, COUNT(DISTINCT order_date) AS no_of_visits
FROM sales
GROUP BY customer_id;
```
![A2](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/0b7d0d06-04af-44d7-8b59-831b7d5dca2f)

---

__3. First item from the menu purchased by each customer?__
```sql
WITH cte1 AS 
(
	SELECT 
		s.customer_id, 
		m.product_name, 
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranking
	FROM sales s INNER JOIN menu m 
		ON s.product_id = m.product_id
)

SELECT customer_id, product_name
FROM cte1 
WHERE ranking = 1;
```
![A3](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/601b14c9-d8c0-4368-b346-7aa67b15826e)

---

__4. Most purchased item and number of purchases by all customers?__
```sql
SELECT 
	s.product_id,
  m.product_name,
  COUNT(*) item_purchase_count
FROM sales s JOIN menu m 
	ON s.product_id = m.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1;
```
![A4](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/14aa790c-88c5-4909-b8ab-3a58a55a85d7)

---

__5. Most popular item for each customer?__
```sql
WITH info AS(
SELECT 
  s.customer_id,
  m.product_name,
  ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranking
FROM sales AS s JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT customer_id, product_name
FROM info
WHERE ranking = 1;
```
![A5](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/e9d7ab38-ac65-4de6-b87b-93d8cb52ae09)

---

__6. Item which was purchased first after they became member?__
```sql
WITH pam AS(
SELECT 
	  s.customer_id,
    s.order_date, 
    s.product_id, 
    men.product_name,
    m.join_date,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
FROM sales AS s
INNER JOIN members AS m ON s.customer_id = m.customer_id
INNER JOIN menu AS men ON men.product_id = s.product_id
WHERE s.order_date >= m.join_date 
)

SELECT customer_id, product_name
FROM pam
WHERE ranking = 1;
```
![A6](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/fab867b5-1cdf-4a06-a5bf-2cb0348f764c)

---

__7. Item purchased before person became member?__
```sql
WITH pam AS(
SELECT 
	  s.customer_id,
    s.order_date, 
    s.product_id, 
    men.product_name,
    m.join_date,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS ranking
FROM sales AS s
INNER JOIN members AS m ON s.customer_id = m.customer_id
INNER JOIN menu AS men ON men.product_id = s.product_id
WHERE s.order_date < m.join_date 
)

SELECT 
	  customer_id,
    order_date,
    join_date,
    product_id,
    product_name
FROM pam
WHERE ranking = 1;
```
![A7](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/b5566d6a-fc67-4598-a5d3-d52d7c902d5a)

---

__8. Total items and amount spend for each member before they became member?__
```sql
SELECT 
	  s.customer_id,
    COUNT(s.product_id) AS total_items,
	  SUM(price) AS amount_spend
FROM sales AS s
INNER JOIN members AS mem ON s.customer_id = mem.customer_id
INNER JOIN menu AS m ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;
```
![A8](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/b42bfcd3-3b22-4848-829c-cf713d5c40e3)

---

__9. Points of each customer if $1 is 10 points and sushi has 2x multiplier?__
```sql
SELECT 
	  s.customer_id,
	  SUM(
    CASE 
		WHEN s.product_id = 1 THEN price*20
    ELSE price*10
    END) AS total_points
FROM sales AS s
INNER JOIN members AS mem ON s.customer_id = mem.customer_id
INNER JOIN menu AS m ON m.product_id = s.product_id
WHERE s.order_date >= mem.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id; 
```
![A9](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/aa3c3e30-0c42-4358-9e91-321bde88395c)

---

_10. First week bonus for members?__
```sql
WITH cte AS 
(
SELECT 
	    s.customer_id,
    	m.join_date,
    	s.order_date,
    	DATE_ADD(m.join_date, INTERVAL(6) DAY) firstweek,
    	me.product_name,
    	me.price
FROM sales s LEFT JOIN members m
	ON s.customer_id = m.customer_id
    	LEFT JOIN menu me
		ON s.product_id = me.product_id
)

SELECT 
	customer_id,
    	SUM(
    	CASE
    	WHEN order_date BETWEEN join_date AND firstweek THEN price*20
    	WHEN (order_date NOT BETWEEN join_date AND firstweek) AND product_name = 'sushi' THEN price*20
    	ELSE price*10
    	END
    	) AS points
FROM cte
WHERE order_date < '2021-02-01'
GROUP BY 1;
```
![A10](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/1be2920b-cf8c-4eac-b84f-582ae7db82c9)

---

__Bonus Question__
```sql
SELECT 
	s.customer_id, 
    s.order_date,
    s.product_id,
    m.product_name,
    m.price,
    mem.join_date
FROM sales AS s
LEFT JOIN members AS mem ON s.customer_id = mem.customer_id
INNER JOIN menu AS m ON m.product_id = s.product_id;

SELECT 
	s.customer_id, 
    s.order_date,
    s.product_id,
    m.product_name,
    m.price,
    mem.join_date,
    DENSE_RANK() OVER(ORDER BY order_date) AS ranking 
FROM sales AS s
LEFT JOIN members AS mem ON s.customer_id = mem.customer_id
INNER JOIN menu AS m ON m.product_id = s.product_id;
```
![Bonus](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/5e249c88-f582-45be-bcba-d029a5dbe5be)
