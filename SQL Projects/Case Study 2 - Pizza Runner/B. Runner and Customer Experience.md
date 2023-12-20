__1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)__
```sql
WITH updated_runners AS (
	SELECT runner_id, WEEK(registration_date) AS week_count
    FROM runners
)

SELECT week_count, COUNT(*) AS runner_signup
FROM updated_runners
GROUP BY week_count;
```
![b1](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/ffece0ac-7570-4cca-9f0f-d822e205551d)

---

__2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?__
```sql
WITH pickup_time_diff AS (
SELECT runner_id, ABS(MINUTE(ro.pickup_time) - MINUTE(co.order_time)) AS time_diff
FROM customer_orders AS co JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
)

SELECT runner_id, AVG(time_diff) AS average_time
FROM pickup_time_diff
WHERE time_diff IS NOT NULL
GROUP BY runner_id;
```
![b2](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/177f0266-d0e0-41ed-a6be-51d3266507c1)

---

__3. Is there any relationship between the number of pizzas and how long the order takes to prepare?__
```sql
WITH pickup_time_diff AS (
	SELECT co.order_id, ABS(MINUTE(ro.pickup_time) - MINUTE(co.order_time)) AS time_diff
	FROM customer_orders AS co JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
)

SELECT 
	order_id, 
    COUNT(order_id) AS pizza_count, 
	AVG(time_diff) AS average_time
FROM pickup_time_diff
WHERE time_diff IS NOT NULL
GROUP BY order_id;
```
![b3](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/008667e1-97d6-478e-8b5a-87d6b7ac5df7)

---

__4. What was the average distance travelled for each customer?__
```sql
WITH distance_travelled AS (
	SELECT co.customer_id, CAST(ro.distance AS UNSIGNED) AS new_distance
	FROM customer_orders AS co JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
)

SELECT customer_id, CONCAT(ROUND(AVG(new_distance)), ' KM') AS average_distance 
FROM distance_travelled
GROUP BY customer_id;
```
![b4](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/3218c966-4c79-43a5-91bb-e18b738b4571)

---

__5. What was the difference between the longest and shortest delivery times for all orders?__
```sql
WITH new_runner_order AS (
	SELECT CAST(duration AS UNSIGNED) AS distance
    FROM runner_orders
    WHERE pickup_time <> "null"
)	

SELECT (MAX(distance) - MIN(distance)) AS time_diff
FROM new_runner_order;
```
![b5](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/eda6889b-6254-452a-bbf9-f4ee9f7ad21f)

---

__6. What was the average speed for each runner for each delivery and do you notice any trend for these values?__
```sql
WITH speed_calculation AS (
	SELECT 
		co.order_id, 
		AVG(CAST(distance AS UNSIGNED)) AS distance_covered,
        AVG((CAST(duration AS UNSIGNED))/60) AS time_taken
    FROM customer_orders AS co JOIN runner_orders AS ro
		ON co.order_id = ro.order_id
	WHERE pickup_time <> "null"
    GROUP BY co.order_id
)

SELECT *, CONCAT(ROUND(distance_covered / time_taken), '  KM/HR') AS average_speed
FROM speed_calculation;
```
![b6](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/fb24893f-2b83-486f-9264-5dcdc48965e0)

---

__7. What is the successful delivery percentage for each runner?__
```sql
SELECT 
	runner_id,
    COUNT(order_id) total_orders,
    CONCAT(
		ROUND(
			100 * SUM(
				CASE 
				WHEN cancellation IS NULL THEN 1
				ELSE 0
				END
				) / COUNT(*) 
			, 0)
		, " %") AS success_rate
FROM runner_orders
GROUP BY runner_id;
```
![b7](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/83d906a3-3604-4b0f-9daa-d435e1f740dc)
