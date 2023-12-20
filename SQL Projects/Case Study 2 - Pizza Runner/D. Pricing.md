__1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?__
```sql
SELECT 
	order_id,
    order_time,
    customer_id,
    pizza_id,
    (
    CASE
    WHEN pizza_id = 1 THEN CONCAT("$", 12)
    WHEN pizza_id = 2 THEN CONCAT('$', 10)
    END
    ) AS pizza_price
FROM updated_customer_orders;
```
![d1](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/cf8ccbff-2540-4eed-a419-3fada097626f)

---

__2. What if there was an additional $1 charge for any pizza extras?__
	- __Add cheese is $1 extra__
```sql
SELECT 
	order_id,
    order_time,
    customer_id,
    pizza_id,
    extra1,
    extra2,
    (
    CASE
    WHEN pizza_id = 1 THEN CONCAT("$", (12 + IF(extra1 IS NULL, 0, 1) + IF(extra2 IS NULL, 0, 1)))
    WHEN pizza_id = 2 THEN CONCAT('$', (10 + IF(extra1 IS NULL, 0, 1) + IF(extra2 IS NULL, 0, 1)))
    END
    ) AS pizza_price
FROM updated_customer_orders;    
```
![d2](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c0106252-b07d-4cf2-ad6f-629e9979f0be)

---

__3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.__

Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
-	order_id
-	runner_id
-	rating
-	order_time
-	pickup_time
-	Time between order and pickup
-	Delivery duration
-	Average speed
-	Total number of pizzas

```sql
SELECT 
	customer_id,
    t1.order_id,
    t2.runner_id,
	order_time,
    pickup_time,
    CONCAT(TIME_TO_SEC(TIMEDIFF(pickup_time, order_time)), " second") AS time_diff_order_pickup,
    CONCAT(CAST(duration AS UNSIGNED), " minutes") AS delivery_duration,
    CONCAT(ROUND((CAST(distance AS FLOAT)*60 / CAST(duration AS FLOAT)), 2), " km / hr") AS average_speed
FROM updated_customer_orders t1 LEFT JOIN runner_orders t2
	ON t1.order_id = t2.order_id;
```
![d3](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/763ae409-2bf6-44ae-a67c-464945267274)

---

__4. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre travelled - how much money does Pizza Runner have left over after these deliveries?__

```sql
SELECT 
	t1.order_id,
    order_time,
    customer_id,
    pizza_id,
    (
    CASE
    WHEN pizza_id = 1 THEN CONCAT("$", 12)
    WHEN pizza_id = 2 THEN CONCAT('$', 10)
    END
    ) AS pizza_price,
    CONCAT("$", (CAST(distance AS UNSIGNED)*0.35)) AS delivery_price
FROM updated_customer_orders t1 LEFT JOIN runner_orders t2
	ON t1.order_id = t2.order_id;
```
![d4](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/16db1465-7d8c-481f-a2fc-986b56d3d322)
