__First preparing a view that will help us to effeciently execute the further queries.__
```sql
CREATE view updated_recipes AS
(
SELECT 
	pizza_id,
	CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 1), ',', -1) AS UNSIGNED) AS toppings
FROM pizza_recipes
UNION 
SELECT 
	pizza_id,
	CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 2), ',', -1)) AS UNSIGNED) AS toppings
FROM pizza_recipes
UNION 
SELECT 
	pizza_id,
	CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 3), ',', -1)) AS UNSIGNED) AS toppings
FROM pizza_recipes
UNION 
SELECT 
	pizza_id,
	CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 4), ',', -1)) AS UNSIGNED) AS toppings
FROM pizza_recipes
UNION 
SELECT 
	pizza_id,
	CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 5), ',', -1)) AS UNSIGNED) AS toppings
FROM pizza_recipes
UNION 
SELECT 
	pizza_id,
	CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 6), ',', -1)) AS UNSIGNED) AS toppings
FROM pizza_recipes
UNION 
SELECT 
	pizza_id,
	CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 7), ',', -1)) AS UNSIGNED) AS toppings
FROM pizza_recipes
UNION 
SELECT 
	pizza_id,
	CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ',', 8), ',', -1)) AS UNSIGNED) AS toppings
FROM pizza_recipes
ORDER BY pizza_id
);

SELECT *
FROM updated_recipes;
```
![c0](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/1f70e6e8-caa7-496a-bc45-17b48108c28a)

---

__1. What are the standard ingredients for each pizza?__
```sql
SELECT 
	ur1.toppings AS ingredients_id,
    pt.topping_name 
FROM updated_recipes ur1 JOIN updated_recipes ur2
	ON ur1.pizza_id = 1 AND ur2.pizza_id = 2 AND ur1.toppings = ur2.toppings
    JOIN pizza_toppings pt
		ON ur1.toppings = pt.topping_id;
```
![c1](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/860f39d4-514c-4834-971e-f1fa29ed27c1)

---

__2. What was the most commonly added extra?__
```sql
WITH cte1 AS
(
SELECT 
	extra,
    COUNT(extra) AS exxtrs_count,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM 
(
	SELECT
		SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ",", 1), ",", -1) AS extra
	FROM customer_orders
	WHERE extras IS NOT NULL
	UNION ALL
	SELECT 
		IF(LENGTH(extras) > 1, SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ",", 2), ",", -1), NULL) AS extra 
	FROM customer_orders
	WHERE extras IS NOT NULL
) temp
WHERE extra IS NOT NULL
GROUP BY 1
)

SELECT 
	c1.extra,
    pt.topping_name
FROM cte1 c1 JOIN pizza_toppings pt 
	ON c1.extra = pt.topping_id
WHERE ranking = 1;
```
![c2](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/835fa45b-9ff5-4379-a252-a5fbae8304fa)

---

__3. What was the most common exclusion?__
```sql
WITH cte1 AS
(
SELECT 
	exclusion,
    COUNT(exclusion) AS exclusion_count,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM 
(
	SELECT
		SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ",", 1), ",", -1) AS exclusion
	FROM customer_orders
	WHERE exclusions IS NOT NULL
	UNION ALL
	SELECT 
		IF(LENGTH(exclusions) > 1, SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ",", 2), ",", -1), NULL) AS exclusion 
	FROM customer_orders
	WHERE exclusions IS NOT NULL
) temp
WHERE exclusion IS NOT NULL
GROUP BY 1
)

SELECT 
	c1.exclusion,
    pt.topping_name
FROM cte1 c1 JOIN pizza_toppings pt 
	ON c1.exclusion = pt.topping_id
WHERE ranking = 1;
```
![c3](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/3cd6d1c9-8663-4b61-8f39-45baeea9b0ab)

---

__4. Generate an order item for each record in the customers_orders table in the format of one of the following:__
	__o Meat Lovers__
	__o Meat Lovers - Exclude Beef__
	__o Meat Lovers - Extra Bacon__
	__o Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers__


```sql
-- Creating a view for shortening the code
CREATE VIEW updated_customer_orders AS
(
SELECT 
	order_id,
    order_time,
    customer_id,
    pizza_id,
    TRIM(SUBSTRING_INDEX(exclusions, ",", 1)) AS exclusion1,
    IF(LENGTH(exclusions)>1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ",", 2), ",", -1)), NULL) AS exclusion2,
    TRIM(SUBSTRING_INDEX(extras, ",", 1)) AS extra1,
    IF(LENGTH(extras)>1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ",", 2), ",", -1)), NULL) AS extra2
FROM customer_orders
);

SELECT *
FROM updated_customer_order;
```
![c4view](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/0dfecef5-cf7f-48d6-95ad-5542134355a2)


```sql
CREATE VIEW order_item_list AS
(
SELECT 
	order_id,
    order_time,
    customer_id,
    CONCAT(
		(
        CASE
        WHEN pizza_id = 1 THEN 'Meat Lovers'
        WHEN pizza_id = 2 THEN 'Vegetarians'
        ELSE ""
        END
        ),
        
        (
        IF(exclusion1 IS NOT NULL OR exclusion2 IS NOT NULL, " - Exclude ", "")
        ),
        
        (
        CASE
        WHEN exclusion1 IS NOT NULL THEN
			(
            SELECT topping_name
            FROM pizza_toppings
            WHERE exclusion1 = topping_id
            )
		ELSE ""
        END
        ),
        
		(
        CASE
        WHEN exclusion2 IS NOT NULL THEN
			CONCAT(" ,",(
            SELECT topping_name
            FROM pizza_toppings
            WHERE exclusion2 = topping_id
            ))
		ELSE ""
        END
        ),
        
        (
        IF(extra1 IS NOT NULL OR extra2 IS NOT NULL, " - Extra ", "")
        ),
        
        (
        CASE
        WHEN extra1 IS NOT NULL THEN
			(
            SELECT topping_name
            FROM pizza_toppings
            WHERE extra1 = topping_id
            )
		ELSE ""
        END
        ),
        
		(
        CASE
        WHEN extra2 IS NOT NULL THEN
			CONCAT(" ,",(
            SELECT topping_name
            FROM pizza_toppings
            WHERE extra2 = topping_id
            ))
		ELSE ""
        END
        )
    ) AS order_items
FROM updated_customer_orders
);

SELECT *
FROM order_item_list;
```
![c4](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/113092fb-9766-4e67-aee4-ce9c0e64d8af)

---

__5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients__
	__o For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"__
```sql
WITH cte1 AS
(
	SELECT 
		pizza_id,
		GROUP_CONCAT(topping_name SEPARATOR " ,") AS ingredients
	FROM updated_recipes up JOIN pizza_toppings pt
		ON up.toppings = pt.topping_id
	GROUP BY 1
),

cte2 AS
(
	SELECT 
		order_id,
        order_time,
        customer_id,
        t1.pizza_id,
		(SELECT topping_name FROM pizza_toppings WHERE exclusion1 = topping_id) AS exclusion_1,
        (SELECT topping_name FROM pizza_toppings WHERE exclusion2 = topping_id) AS exclusion_2,
        (SELECT topping_name FROM pizza_toppings WHERE extra1 = topping_id) AS extra_1,
        (SELECT topping_name FROM pizza_toppings WHERE extra2 = topping_id) AS extra_2,
        t2.ingredients
    FROM updated_customer_orders t1 LEFT JOIN cte1 t2
		ON t1.pizza_id = t2.pizza_id
        LEFT JOIN pizza_toppings t3 
			ON t1.exclusion1 = t3.topping_id 
),

cte3 AS 
(
	SELECT
		order_id,
        order_time,
        customer_id,
        pizza_id,
        exclusion_1,
        exclusion_2,
        extra_1,
        extra_2,
		IF(exclusion_1 IS NOT NULL, REPLACE(ingredients, exclusion_1, ""), ingredients) AS ingredient1
	FROM cte2
),

cte4 AS
(
	SELECT
		order_id,
        order_time,
        customer_id,
        pizza_id,
        exclusion_1,
        exclusion_2,
        extra_1,
        extra_2,
        IF(exclusion_2 IS NOT NULL, REPLACE(ingredient1, exclusion_2, ""), ingredient1) AS ingredient2
	FROM cte3
),

cte5 AS
(
	SELECT
		order_id,
        order_time,
        customer_id,
        pizza_id,
        exclusion_1,
        exclusion_2,
        extra_1,
        extra_2,
        IF(extra_1 IS NOT NULL, REPLACE(ingredient2, extra_1, CONCAT("2x ", extra_1)), ingredient2) AS ingredient3
	FROM cte4
),

cte6 AS
(
	SELECT
		order_id,
        order_time,
        customer_id,
        pizza_id,
		exclusion_1,
        exclusion_2,
        extra_1,
        extra_2,
        IF(extra_2 IS NOT NULL, REPLACE(ingredient3, extra_2, CONCAT("2x ", extra_2)), ingredient3) AS ingredient_list
	FROM cte5
)

SELECT *
FROM cte6;
```
![c5](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/d5a7e295-b64b-4a79-b165-577c59cd8d4d)

---

__6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?__

```sql
WITH cte1 AS
(
SELECT 
	*,
	ROW_NUMBER() OVER() AS row_num
FROM updated_customer_orders
),

cte2 AS
(
SELECT 
	row_num,
    order_id,
    toppings,
    t1.pizza_id,
    exclusion1,
    exclusion2,
    extra1,
    extra2
FROM cte1 t1 LEFT JOIN updated_recipes t2
	ON t1.pizza_id = t2.pizza_id
),

exclusion_count AS 
(
SELECT 
	CAST(exclusion1 AS UNSIGNED) AS exclusions,
    COUNT(DISTINCT row_num) AS count1
FROM cte2
WHERE exclusion1 IS NOT NULL
GROUP BY 1
UNION 
SELECT 
	CAST(TRIM(exclusion2) AS UNSIGNED) AS exclusions,
    COUNT(DISTINCT row_num) AS count1
FROM cte2
WHERE exclusion2 IS NOT NULL
GROUP BY 1
),

extra_count AS 
(
SELECT 
	CAST(extra1 AS UNSIGNED) AS extras,
    COUNT(DISTINCT row_num) AS count2
FROM cte2
WHERE extra1 IS NOT NULL
GROUP BY 1
UNION 
SELECT 
	CAST(TRIM(extra2) AS UNSIGNED) AS extras,
    COUNT(DISTINCT row_num) AS count2
FROM cte2
WHERE extra2 IS NOT NULL
GROUP BY 1
),

topping_count AS 
(
SELECT 
	toppings,
    COUNT(DISTINCT row_num) AS count3
FROM cte2
GROUP BY 1
)

SELECT 
	t1.toppings,
    t4.topping_name,
    (count3 - IF(count1 IS NULL, 0, count1) + IF(count2 IS NULL, 0, count2)) AS ingredient_count 
FROM topping_count t1 LEFT JOIN exclusion_count t2
	ON t1.toppings = t2.exclusions
    LEFT JOIN extra_count t3
		ON t1.toppings = t3.extras
        LEFT JOIN pizza_toppings t4
			ON t1.toppings = t4.topping_id
ORDER BY 3 DESC;
```
![c6](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/4ad7f121-e69a-4a88-83ed-2a0c7935e62e)
