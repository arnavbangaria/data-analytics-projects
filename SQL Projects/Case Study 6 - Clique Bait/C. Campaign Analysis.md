Generate a table that has 1 single row for every unique visit_id record and has the following columns:
- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

__USER INSIGHTS VIEW__
```sql
CREATE VIEW user_insights AS
(
WITH cte1 AS 
(
SELECT 
	DISTINCT visit_id,
	user_id,
	MIN(event_time) OVER(PARTITION BY visit_id ORDER BY event_time) AS visit_start_time
FROM events e JOIN users u
	ON e.cookie_id = u.cookie_id
),

cte2 AS
(
SELECT 
	visit_id,
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
    ) AS cart_adds,
    SUM(
		CASE 
        WHEN event_type = 4 THEN 1
        ELSE 0
        END
    ) AS ad_impressions,
	SUM(
		CASE 
        WHEN event_type = 5 THEN 1
        ELSE 0
        END
    ) AS ad_clicks,
	IF(
		SUM(
			CASE
			WHEN event_type = 3 THEN 1
			ELSE 0
			END
		) > 0, 1, 0) purchase
FROM events
GROUP BY visit_id
),

cte3 AS
(
SELECT 
	visit_id,
    GROUP_CONCAT(DISTINCT page_name ORDER BY sequence_number SEPARATOR ', ') AS cart_products
FROM events e JOIN page_hierarchy ph
	ON e.page_id = ph.page_id
WHERE event_type = 2
GROUP BY visit_id
)

SELECT 
	cte1.visit_id,
    user_id,
    visit_start_time,
    page_view,
    cart_adds,
    purchase,
    campaign_name,
    ad_impressions,
    ad_clicks,
    cart_products
FROM cte1 JOIN cte2
	ON cte1.visit_id = cte2.visit_id
	JOIN campaign_identifier ci
		ON cte1.visit_start_time > ci.start_date AND cte1.visit_start_time < ci.end_date
        JOIN cte3
			ON cte1.visit_id = cte3.visit_id AND cte2.visit_id = cte3.visit_id
);

SELECT *
FROM user_insights;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/46325ba2-00c1-4fcb-9b72-9c77a9c59c9b)


__1. no. of users who got impressions and clicks per campaign?__
```sql
SELECT 
	campaign_name,
    SUM(
		CASE WHEN ad_impressions > 0 THEN 1
        ELSE 0
        END
    ) AS user_with_impressions,
    SUM(
		CASE WHEN ad_impressions = 0 THEN 1
        ELSE 0
        END
    ) AS user_without_impressions,
	SUM(
		CASE WHEN ad_clicks > 0 THEN 1
        ELSE 0
        END
    ) AS user_with_clicks,
    SUM(
		CASE WHEN ad_clicks = 0 THEN 1
        ELSE 0
        END
    ) AS user_without_clicks
FROM user_insights
GROUP BY campaign_name;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/bc8ae249-1942-4c6c-b320-e6b480b465ae)


---

__2. Does clicking on an impressions lead to higher purchase rate?__
```sql
SELECT 
	campaign_name,
    ROUND(AVG(
		CASE WHEN ad_clicks > 0 THEN cart_adds
        END
    ), 2) AS avg_cart_adds_with_ads_click,
    ROUND(AVG(
		CASE WHEN ad_clicks = 0 THEN cart_adds
        END
    ), 2) AS avg_cart_adds_without_ads_clicks
FROM user_insights
WHERE purchase = 1
GROUP BY campaign_name;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/4dbc1d4f-0626-4bb0-92ca-ec7f30866195)
