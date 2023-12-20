__1. How many pizzas were ordered?__
```sql
SELECT COUNT(pizza_id) AS total_orders 
FROM customer_orders;
```
![a1](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/0a877cbf-78d8-43cc-828b-df79bf9d5c4f)

---

__2. How many unique customer orders were made?__
```sql
SELECT COUNT(DISTINCT order_id) order_count
FROM customer_orders;
```
![a2](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/bcd72ea0-4887-46fb-9667-79cd5e9e6700)

---

__3. How many successful orders were delivered by each runner?__
```sql
SELECT COUNT(order_id) AS successful_delivery
FROM runner_orders
WHERE pickup_time <> NULL;
```
![a3](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c71f7b13-5a5e-4c89-b33c-af63449ecf81)

---

__4. How many of each type of pizza was delivered?__
```sql
SELECT pizza_id, COUNT(order_id) AS number_of_pizzas
FROM customer_orders
GROUP BY pizza_id; 
```
![a4](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/57c4df5f-5348-4ceb-b142-b519c4eda951)

---

__5. How many Vegetarian and Meatlovers were ordered by each customer?__
```sql
SELECT customer_id, pizza_id, COUNT(order_id) AS no_of_pizza
FROM customer_orders
GROUP BY customer_id, pizza_id;
```
![a5](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/70584406-56c7-4118-92e9-102622ada45e)

---

__6. What was the maximum number of pizzas delivered in a single order?__
```sql
SELECT *
FROM (
	SELECT order_id, COUNT(order_id) AS pizzas
    FROM customer_orders
    GROUP BY order_id
) AS ncs
ORDER BY pizzas DESC
LIMIT 1;
```
![a6](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/4e9741d7-cc17-41e5-9846-777c10a733e8)

---

__7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?__
```sql
SELECT COUNT(order_id) AS new_count
FROM customer_orders
WHERE (exclusions IS NULL) && (extras IS NULL);
```
![a7](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/7e4edea1-ed42-466e-a2b7-5609cbfbcad1)

---

__8. How many pizzas were delivered that had both exclusions and extras?__
```sql
SELECT (SELECT COUNT(*) FROM customer_orders) - COUNT(order_id) AS new_count
FROM customer_orders
WHERE (exclusions IS NULL) || (extras IS NULL);
```
![a8](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/95059e52-0055-4aaa-aef1-1d94f485a6b6)

---

__9. What was the total volume of pizzas ordered for each hour of the day?__
```sql
WITH pizza_volume AS (
	SELECT HOUR(order_time) AS hours, order_id
    FROM customer_orders
)

SELECT hours, COUNT(order_id) AS volume
FROM pizza_volume
GROUP BY hours;
```
![a9](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/9764f778-889b-4361-a3bd-e931f806b700)

---

__10. What was the volume of orders for each day of the week?__
```sql
WITH daily_pizza_volume AS (
	SELECT DATE_FORMAT(order_time, "%W") AS week_day, order_id
    FROM customer_orders
)

SELECT week_day, COUNT(order_id) AS volume
FROM daily_pizza_volume
GROUP BY week_day;
```
![a10](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/92445cac-c6ad-4e56-9d85-a9d3cf1796cb)
