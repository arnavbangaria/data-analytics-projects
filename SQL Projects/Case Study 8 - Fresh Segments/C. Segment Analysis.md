__1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year__
```sql
WITH filter1 AS 
(
SELECT 
	interest_id,
    COUNT(month_year) AS month_count
FROM interest_metrics
GROUP BY 1
),

filtered_dataset AS 
(
SELECT *
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM filter1 WHERE month_count>6)
ORDER BY interest_id
),

comp_cte AS
(
SELECT 
	interest_id,
    COUNT(month_year) AS month_count,
    MAX(composition) AS max_comp,
    MIN(composition) AS min_comp
FROM filtered_dataset
GROUP BY 1
),

max_composition AS
(
SELECT 
	ROW_NUMBER() OVER() AS rn_no,
	interest_id AS max_composition_interest_id,
    max_comp
FROM comp_cte
ORDER BY max_comp DESC
LIMIT 10
),

min_composition AS
(
SELECT 
	ROW_NUMBER() OVER() AS rn_no,
	interest_id AS min_composition_interest_id,
    min_comp
FROM comp_cte
ORDER BY min_comp
LIMIT 10
)

SELECT 
	max_composition_interest_id,
    max_comp,
    min_composition_interest_id,
    min_comp
FROM max_composition t1 JOIN min_composition t2
	ON t1.rn_no = t2.rn_no;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/81a11ea4-1b3d-4e6c-9cfd-77114b4e0eb4)

---

__2. Which 5 interests had the lowest average ranking value?__
```sql
CREATE VIEW filtered_dataset AS
(
WITH filter1 AS 
(
SELECT 
	interest_id,
    COUNT(month_year) AS month_count
FROM interest_metrics
GROUP BY 1
)

SELECT *
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM filter1 WHERE month_count>6)
ORDER BY interest_id
);

SELECT 
	t1.interest_id,
    t2.interest_name,
    AVG(ranking) AS avg_ranking
FROM filtered_dataset t1 LEFT JOIN interest_map t2 
	ON t1.interest_id = t2.id
GROUP BY 1, 2
ORDER BY 3
LIMIT 5;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/2cbdd43e-947a-4b7b-8f10-04b27ebfee81)

---

__3. Which 5 interests had the largest standard deviation in their percentile_ranking value?__
```sql
WITH cte1 AS
(
	SELECT 
		interest_id,
		percentile_ranking,
		ROUND(STDDEV(percentile_ranking) OVER(PARTITION BY interest_id), 2) AS stnd_dev
	FROM filtered_dataset
)

SELECT 
	t1.interest_id,
    t2.interest_name,
    ROUND(AVG(stnd_dev), 2) AS standard_dev
FROM cte1 t1 LEFT JOIN interest_map t2
	ON t1.interest_id = t2.id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/2a3d3966-6f8e-499a-a521-48a836062b75)

---

__4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?__
```sql
WITH cte1 AS
(
	SELECT 
		interest_id,
		percentile_ranking,
		ROUND(STDDEV(percentile_ranking) OVER(PARTITION BY interest_id), 2) AS stnd_dev
	FROM filtered_dataset
),

cte2 AS
(
SELECT 
	interest_id,
    ROUND(AVG(stnd_dev), 2) AS standard_dev
FROM cte1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5
)

SELECT 
	t1.interest_id,
    t2.interest_name,
    ROUND(AVG(composition), 2) AS avg_comp,
    MIN(percentile_ranking) AS min_percent_rank,
    MAX(percentile_ranking) AS max_percent_rank
FROM interest_metrics t1 LEFT JOIN interest_map t2
	ON t1.interest_id = t2.id
WHERE t1.interest_id IN (SELECT interest_id FROM cte2)
GROUP BY 1, 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/663634ed-11ee-4222-8a39-c9026d24b800)

---

__5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?__
```
After reviewing above data we can interfere that average composition for these segments are low to drive composition and ranking we can add following product or service
- Live Concert Fans - Merchandize or discount ads for corresponsing concerts
- Pregnancy Resource Research - Platform ads that provide data regarding pregnancy that can be food resource, health, wellbeing, etc
- Entertainment and Tabloid Magazine Readers - Latest Celebrity Gossips website ads
- Oregon Trip Planners - Providing user experience of trips as social proof
- Personalized Gift Shopper - New gift ideas ads
```
