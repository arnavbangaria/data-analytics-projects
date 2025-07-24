/*
RECOMMEND THE THREE ALBUMS FROM THE NEW RECORD LABEL THAT SHOULD BE PRIORITISED FOR ADVERTISING AND PROMOTION IN THE USA BASED ON GENRE SALES ANALYSIS.

APPROACH
- extracting data of last 3 months
- filtering the top 3 genre by sales in USA
- finding albums with high number of tracks in these three genre 
- evaluating sales of these albums
*/
WITH last_3_months AS (
	SELECT *
	FROM TrackInvoiceDetails
	WHERE billing_country = "USA"
		AND (invoice_date BETWEEN DATE_SUB((SELECT MAX(invoice_date) FROM TrackInvoiceDetails), INTERVAL 3 MONTH)  
			AND (SELECT MAX(invoice_date) FROM TrackInvoiceDetails))
),

top_3_genre AS (
	SELECT *
	FROM (
		SELECT 
			g.genre_id,
			g.name AS genre_name,
			SUM(unit_price*quantity) AS total_sales,
			RANK() OVER(ORDER BY SUM(unit_price*quantity) DESC) AS rank_by_sales
		FROM last_3_months l 
		JOIN genre g 
			ON g.genre_id = l.genre_id
		GROUP BY g.genre_id, g.name
	) gere_ranks
	WHERE rank_by_sales <= 3
),

album_rankings AS (
	SELECT 
		album_id,
		album_title,
		COUNT(
		CASE WHEN genre_id = 1 THEN track_id END
		) AS rock_track_cnt,
		COUNT(
		CASE WHEN genre_id = 3 THEN track_id END
		) AS metal_track_cnt,
		COUNT(
		CASE WHEN genre_id = 9 THEN track_id END
		) AS pop_track_cnt,
		SUM(total_sales) AS album_total_sales,
		DENSE_RANK() OVER(ORDER BY SUM(total_sales) DESC) rank_by_sales
	FROM TrackSalesByCountry
	WHERE billing_country = "USA"
		AND genre_id IN (
			SELECT genre_id FROM top_3_genre
		)
	GROUP BY album_id, album_title
	ORDER BY album_total_sales DESC, rock_track_cnt DESC, metal_track_cnt DESC, pop_track_cnt DESC
)

SELECT *
FROM album_rankings
WHERE rank_by_sales <= 3;


/*
DETERMINE THE TOP-SELLING GENRES IN COUNTRIES OTHER THAN THE USA AND IDENTIFY ANY COMMONALITIES OR DIFFERENCES.

APPROACH 
- aggregating total sales in USA and in Other Region
- ranking all genre by sales in USA
- ranking all genre by sales in other regions
- comparing them side by side and flagging genre based on rank in USA and in Other Region
*/
WITH genre_wise_sales AS (
	SELECT 
		genre_id,
		genre_name,
		SUM(
		CASE WHEN billing_country = "USA" THEN total_sales END
		) AS sales_in_USA,
		SUM(
		CASE WHEN billing_country != "USA" THEN total_sales END
		) AS sales_in_Others
	FROM TrackSalesByCountry
	GROUP BY genre_id, genre_name
	ORDER BY genre_id
) 

SELECT 
	genre_id,
    genre_name,
    sales_in_USA,
    sales_in_Others,
    RANK() OVER(ORDER BY sales_in_USA DESC) AS rank_by_sales_USA,
    RANK() OVER(ORDER BY sales_in_Others DESC) AS rank_by_sales_Others,
    (
		CASE 
		WHEN (RANK() OVER(ORDER BY sales_in_USA DESC) > RANK() OVER(ORDER BY sales_in_Others DESC)) THEN "Higher in USA"
		WHEN (RANK() OVER(ORDER BY sales_in_USA DESC) < RANK() OVER(ORDER BY sales_in_Others DESC)) THEN "Lower in USA"
        ELSE "Same in USA"
        END
    ) AS rank_status 
FROM genre_wise_sales;


/*
CUSTOMER PURCHASING BEHAVIOR ANALYSIS: 
HOW DO THE PURCHASING HABITS (FREQUENCY, BASKET SIZE, SPENDING AMOUNT) OF LONG-TERM CUSTOMERS DIFFER FROM THOSE OF NEW CUSTOMERS? 
WHAT INSIGHTS CAN THESE PATTERNS PROVIDE ABOUT CUSTOMER LOYALTY AND RETENTION STRATEGIES?

APPROACH
- making a view to customer track purchase data using invoice_line and invoice table
- generating CTE that gives invoice details of all invoices customer wise
- creating customer segmentation and using aggregation to discover customer wise purchase trends
- assuming that customers who have first and last purchase months difference above 36 are long-term customers
- flagging customers as long-term and new customers based on first and recent purchase date
- finding frequency of purchase, basket size and spending amount etc. for each customer
*/

CREATE VIEW CustomerTrackInvoice AS (
	SELECT 
		i1.invoice_line_id,
		i1.invoice_id,
		i1.track_id,
		i1.unit_price,
		i1.quantity,
		i2.customer_id,
		i2.invoice_date,
		i2.billing_city,
		i2.billing_country
	FROM invoice_line i1
	LEFT JOIN invoice i2
		ON i1.invoice_id = i2.invoice_id
);

SELECT *
FROM CustomerTrackInvoice;

WITH customer_invoice_data AS (
	SELECT 
		customer_id,
		invoice_id,
		invoice_date,
		COALESCE(TIMESTAMPDIFF(DAY, LAG(invoice_date, 1) OVER(PARTITION BY customer_id ORDER BY invoice_date), invoice_date), "-") AS days_before_last_purchase,
		COUNT(quantity) AS track_count,
		COUNT(DISTINCT track_id) AS unique_track_count,
		SUM(unit_price*quantity) AS total_purchase_amount
	FROM CustomerTrackInvoice
	GROUP BY customer_id, invoice_id, invoice_date
),

customer_segmentation AS (
	SELECT 
		customer_id,
		(
			CASE
			WHEN TIMESTAMPDIFF(MONTH, MIN(invoice_date), MAX(invoice_date)) <= 36 THEN "New"
			ELSE "Long-Term"
			END
		) AS customer_type,
		TIMESTAMPDIFF(MONTH, MIN(invoice_date), MAX(invoice_date)) AS since_months, 
		COUNT(invoice_id) cnt_of_purchases,
		ROUND(AVG(days_before_last_purchase)) AS avg_purchase_frequency_in_days,
		SUM(track_count) AS total_track_count,
		SUM(unique_track_count) AS total_unique_tracks,
		ROUND(AVG(total_purchase_amount), 2) AS avg_purchase_amount,
		SUM(total_purchase_amount) AS total_amount_spent,
		ROUND(SUM(track_count) / COUNT(invoice_id)) AS avg_basket_size
	FROM customer_invoice_data
	GROUP BY customer_id
	ORDER BY customer_id
)

SELECT 
	customer_type,
    COUNT(customer_id) AS customer_count,
    ROUND((COUNT(customer_id)*100 / (SELECT COUNT(DISTINCT customer_id) FROM customer_segmentation)), 2) AS percent_of_customers,
    ROUND(AVG(cnt_of_purchases)) AS avg_purchases_made,
    ROUND(AVG(avg_purchase_frequency_in_days)) AS purchase_frequency_in_days,
    ROUND(AVG(avg_purchase_amount), 2) AS avg_amount_per_purchase,
    SUM(total_amount_spent) AS total_spents,
    ROUND(AVG(avg_basket_size)) AS basket_size
FROM customer_segmentation
GROUP BY customer_type;


/*
PRODUCT AFFINITY ANALYSIS: 
WHICH MUSIC GENRES, ARTISTS, OR ALBUMS ARE FREQUENTLY PURCHASED TOGETHER BY CUSTOMERS? 
HOW CAN THIS INFORMATION GUIDE PRODUCT RECOMMENDATIONS AND CROSS-SELLING INITIATIVES?

APPROACH 
- first joining CustomerTrackInvoice (invoice_line and invoice together) table with album, genre, track and artist table
- using genre_id, album_id and artist_id to group them in a single bundle
- using group by to aggregate quantity which will give how many times combo is bought
- using group by to aggregate distinct customers count who bought the combo 
*/
WITH base_table AS (
	SELECT 
		t.track_id,
		t.name AS track_name,
		g.genre_id,
		g.name AS genre_name,
		a.album_id,
		a.title AS album_title,
		r.artist_id,
		r.name AS artist_name,
		c.quantity,
		c.customer_id
	FROM CustomerTrackInvoice c
	JOIN track t
		ON c.track_id = t.track_id
	JOIN album a 
		ON t.album_id = a.album_id
	JOIN artist r 
		ON r.artist_id = a.artist_id
	JOIN genre g
		ON t.genre_id = g.genre_id
)

SELECT 
	genre_id,
	genre_name,
	album_id,
	album_title,
	artist_id,
	artist_name,
	COALESCE(SUM(quantity), 0) AS total_times_combo_purchased,
	COALESCE(COUNT(DISTINCT customer_id), 0) AS combo_bought_by_customers
FROM base_table
GROUP BY genre_id, genre_name, album_id, album_title, artist_id, artist_name
ORDER BY total_times_combo_purchased DESC, combo_bought_by_customers DESC;


/*
REGIONAL MARKET ANALYSIS: 
DO CUSTOMER PURCHASING BEHAVIORS AND CHURN RATES VARY ACROSS DIFFERENT GEOGRAPHIC REGIONS OR STORE LOCATIONS? 
HOW MIGHT THESE CORRELATE WITH LOCAL DEMOGRAPHIC OR ECONOMIC FACTORS?

APPROACH 
- joining customer geographical data with purchase data
- ranking country by total_sales in lifetime then selecting Top 10 countries
- ranking cities in these countries based on total_sales contribution 
- filtering the cities as entry point in these country based on ranking (i.e. rank 1 for top priority) 
- generating year wise sales in these selected cities to see customer or sales change over the year
- comparing starting and recent year sales to estimate if market is growing or not
*/
CREATE VIEW EntryCityPerCountry AS (
	WITH customer_transactions AS (
		SELECT 
			t.invoice_id,
			t.track_id,
			t.unit_price,
			t.quantity,
			t.track_name,
			t.album_id,
			t.genre_id,
			t.invoice_date,
			t.customer_id,
			c.city,
			c.state,
			c.country,
			c.support_rep_id
		FROM TrackInvoiceDetails t
		JOIN customer c
			ON c.customer_id = t.customer_id
	),

	country_wise_rank AS (
		SELECT 
			DENSE_RANK() OVER(ORDER BY SUM(unit_price*quantity) DESC) AS country_rank,
			country,
			COUNT(DISTINCT customer_id) AS cnt_of_customer,
			COUNT(DISTINCT invoice_id) AS cnt_of_invoice,
			COUNT(DISTINCT track_id) AS cnt_of_tracks,
			SUM(unit_price*quantity) AS sales_generated,
			ROUND(
				SUM(unit_price*quantity)*100 / (
					SELECT SUM(unit_price*quantity) FROM customer_transactions c1
				)
			, 2) AS "%_of_total_country_sale"
		FROM customer_transactions c
		GROUP BY country
		ORDER BY sales_generated DESC, cnt_of_tracks DESC, cnt_of_invoice DESC, cnt_of_customer DESC
	),

	entry_city_ranking AS (
		SELECT 
			country,
			city,
			COUNT(DISTINCT customer_id) AS cnt_of_customer,
			COUNT(DISTINCT invoice_id) AS cnt_of_invoice,
			COUNT(DISTINCT track_id) AS cnt_of_tracks,
			SUM(unit_price*quantity) AS sales_generated,
			ROUND(
				SUM(unit_price*quantity)*100 / (
					SELECT SUM(unit_price*quantity) FROM customer_transactions c1
					WHERE c1.country = c.country
				)
			, 2) AS "%_of_total_country_sale",
			RANK() OVER(PARTITION BY country ORDER BY SUM(unit_price*quantity) DESC) AS priority_of_entry
		FROM customer_transactions c
		WHERE country IN (
			SELECT country FROM country_wise_rank
			WHERE country_rank <= 10
		)
		GROUP BY country, city
		ORDER BY country, sales_generated DESC, cnt_of_tracks DESC, cnt_of_invoice DESC, cnt_of_customer DESC
	)

	SELECT *
	FROM entry_city_ranking
	WHERE priority_of_entry = 1
);

SELECT *
FROM EntryCityPerCountry;

WITH customer_transactions AS (
	SELECT 
		t.invoice_id,
		t.track_id,
		t.unit_price,
		t.quantity,
		t.track_name,
		t.album_id,
		t.genre_id,
		t.invoice_date,
		t.customer_id,
		c.city,
		c.state,
		c.country,
		c.support_rep_id
	FROM TrackInvoiceDetails t
	JOIN customer c
		ON c.customer_id = t.customer_id
),

city_year_comparison AS (
	SELECT 
		country,
		city,
		EXTRACT(YEAR FROM invoice_date) AS years,
		COUNT(DISTINCT customer_id) AS cnt_of_customers,
		COUNT(DISTINCT invoice_id) AS cnt_of_purchases,
		COUNT(DISTINCT track_id) AS cnt_of_tracks_sold,
		SUM(unit_price*quantity) AS total_sales_per_year
	FROM customer_transactions
	WHERE city IN (
		SELECT city FROM EntryCityPerCountry
	)
	GROUP BY country, city, years
	HAVING years IN (2019, 2020)
),

city_comparison_2019_2020 AS (
	SELECT 
		DISTINCT country,
		city,
		(
			SELECT total_sales_per_year FROM city_year_comparison c1
			WHERE c1.country = c.country AND c1.city = c.city AND c1.years = 2019
		) AS total_sales_in_2019,
		(
			SELECT total_sales_per_year FROM city_year_comparison c1
			WHERE c1.country = c.country AND c1.city = c.city AND c1.years = 2020
		) AS total_sales_in_2020,
		(
			SELECT cnt_of_customers FROM city_year_comparison c1
			WHERE c1.country = c.country AND c1.city = c.city AND c1.years = 2019
		) AS cnt_of_customers_in_2019,
		(
			SELECT cnt_of_customers FROM city_year_comparison c1
			WHERE c1.country = c.country AND c1.city = c.city AND c1.years = 2020
		) AS cnt_of_customers_in_2020
	FROM city_year_comparison c
)

SELECT 
	*,
    ROUND(((total_sales_in_2020 - total_sales_in_2019)*100 / total_sales_in_2019), 2) AS percent_change_in_sales,
    ROUND(((cnt_of_customers_in_2020 - cnt_of_customers_in_2019)*100 / cnt_of_customers_in_2019), 2) AS churn_rate
FROM city_comparison_2019_2020 
ORDER BY percent_change_in_sales DESC;


/*
CUSTOMER RISK PROFILING: 
Based on customer profiles (age, gender, location, purchase history), which customer segments are more likely to churn or pose a higher risk of reduced spending? 
What factors contribute to this risk?

APPROACH 
- first finding customer that have high risk and storing in view
- using count of tracks and purchase amount of individual customers each year
- deriving change from previous year using lag function
- counting the no. of years which have a decrease (negative change) in tracks and amount 
- finding if the decrease is happening in 2020 or not using a column
- using both the above mention condition to find high risk customers
- then analysing geographical and purchase history of these customers
*/
CREATE VIEW HighRiskCustomer AS (
	WITH cust_purchase_this_year AS (
		SELECT 
			customer_id,
			EXTRACT(YEAR FROM invoice_date) AS years,
			COUNT(quantity) AS this_year_track_cnt,
			SUM(unit_price*quantity) AS this_year_purchase_amt
		FROM TrackInvoiceDetails
		GROUP BY customer_id, years
		ORDER BY customer_id, years
	),

	cust_purchase_change AS (
		SELECT 
			customer_id,
			years,
			this_year_track_cnt,
			this_year_purchase_amt,
			COALESCE(ROUND((this_year_track_cnt - (LAG(this_year_track_cnt, 1) OVER(PARTITION BY customer_id ORDER BY years)))*100 / (LAG(this_year_track_cnt, 1) OVER(PARTITION BY customer_id ORDER BY years))), 0) AS track_change,
			COALESCE(ROUND((this_year_purchase_amt - (LAG(this_year_purchase_amt, 1) OVER(PARTITION BY customer_id ORDER BY years)))*100 / (LAG(this_year_purchase_amt, 1) OVER(PARTITION BY customer_id ORDER BY years))), 0) AS purchase_change
		FROM cust_purchase_this_year
	),

	cust_risk_data AS (
		SELECT 
			customer_id,
			SUM(CASE WHEN track_change < 0 THEN 1 ELSE 0 END) AS decrease_count,
			SUM(
			CASE WHEN years=2020 THEN IF(track_change > 0, 1, 0) ELSE 0 END
			) AS increase_in_2020
		FROM cust_purchase_change
		GROUP BY customer_id
		ORDER BY decrease_count DESC
	)

	SELECT *
	FROM customer
	WHERE customer_id IN (
		SELECT customer_id
		FROM cust_risk_data 
		WHERE decrease_count >= 2 
			AND increase_in_2020 = 0
	)
);


-- geographical 
SELECT 
	country,
    (
		SELECT COUNT(DISTINCT customer_id) FROM customer c
        WHERE c.country = h.country
    ) AS cnt_of_total_customer,
    COUNT(DISTINCT customer_id) AS cnt_of_risky_customer,
    ROUND(COUNT(DISTINCT customer_id)*100 / (
		SELECT COUNT(DISTINCT customer_id) FROM customer c
        WHERE c.country = h.country
    )) AS percent_of_risky_customer
FROM HighRiskCustomer h
GROUP BY country
ORDER BY percent_of_risky_customer DESC, cnt_of_risky_customer DESC;


-- finding purchase history of high risk customers
-- genre id
SELECT 
    genre_id,
    (
		SELECT name FROM genre g
        WHERE g.genre_id = t.genre_id
    ) AS genre_name,
    COUNT(DISTINCT customer_id) AS cnt_of_risky_customer,
    (
		SELECT COUNT(DISTINCT customer_id) FROM TrackInvoiceDetails t1
        WHERE t1.genre_id = t.genre_id
    ) AS cnt_of_customer,
    ROUND(COUNT(DISTINCT customer_id)*100 / (
		SELECT COUNT(DISTINCT customer_id) FROM TrackInvoiceDetails t1
        WHERE t1.genre_id = t.genre_id
    )) AS percent_of_risky_customer
FROM TrackInvoiceDetails t
WHERE customer_id IN (
	SELECT customer_id FROM HighRiskCustomer
)
GROUP BY genre_id
ORDER BY percent_of_risky_customer DESC, cnt_of_risky_customer DESC;


-- album 
SELECT 
    album_id,
    (
		SELECT title FROM album a
        WHERE a.album_id = t.album_id
    ) AS album_title,
    COUNT(DISTINCT customer_id) AS cnt_of_risky_customer,
    (
		SELECT COUNT(DISTINCT customer_id) FROM TrackInvoiceDetails t1
        WHERE t1.album_id = t.album_id
    ) AS cnt_of_customer,
    ROUND(COUNT(DISTINCT customer_id)*100 / (
		SELECT COUNT(DISTINCT customer_id) FROM TrackInvoiceDetails t1
        WHERE t1.album_id = t.album_id
    )) AS percent_of_risky_customer
FROM TrackInvoiceDetails t
WHERE customer_id IN (
	SELECT customer_id FROM HighRiskCustomer
)
GROUP BY album_id
ORDER BY percent_of_risky_customer DESC, cnt_of_risky_customer DESC;


-- track count and purchase amount
SELECT 
	customer_id,
    (
		SELECT (
			CASE WHEN TIMESTAMPDIFF(MONTH, MIN(invoice_date), MAX(invoice_date)) <= 36 THEN "New"
            ELSE "Long-Term"
            END
        )
        FROM CustomerTrackInvoice c
        WHERE c.customer_id = t.customer_id
    ) AS customer_type,
    COUNT(DISTINCT invoice_id) AS cnt_of_purchases_made,
    SUM(quantity) AS cnt_of_tracks,
    SUM(unit_price*quantity) AS tot_purchase_amount
FROM TrackInvoiceDetails t
WHERE customer_id IN (
	SELECT customer_id FROM HighRiskCustomer
)
GROUP BY customer_id;


/*
CUSTOMER LIFETIME VALUE MODELLING: 
How can you leverage customer data (tenure, purchase history, engagement) to predict the lifetime value of different customer segments? 
This could inform targeted marketing and loyalty program strategies. Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?

- using TrackInvoiceDetails view to find major parameters of Customer Lifecycle 
- ranking album, genre and artist by sales and count of tracks
- using subquery to take table with rank 1 to find top genre, top artist and top album
- finding the amount it contributes to overall lifetime value
- deriving the final table as given below
*/
WITH customer_lifetime_analysis AS (
	SELECT 
		t.customer_id,
        CONCAT(c.first_name, " ", c.last_name) AS customer_name,
        c.city,
        c.country,
		MIN(invoice_date) AS first_purchase_date,
		MAX(invoice_date) AS last_purchase_date,
		TIMESTAMPDIFF(MONTH, MIN(invoice_date), MAX(invoice_date)) AS tenure_in_month,
		IF(YEAR(MAX(invoice_date)) = 2020, "No", "Yes") AS churn_in_2020,
		IF(TIMESTAMPDIFF(MONTH, MIN(invoice_date), MAX(invoice_date)) <= 36, "New", "Long-Term") AS customer_type,
		SUM(unit_price*quantity) AS lifetime_value,
		COUNT(DISTINCT invoice_id) AS lifetime_purchase_cnt,
		SUM(quantity) AS lifetime_track_cnt,
		ROUND(TIMESTAMPDIFF(DAY, MIN(invoice_date), MAX(invoice_date)) / (COUNT(DISTINCT invoice_id))) AS frequency_of_purchase 
	FROM TrackInvoiceDetails t
    JOIN customer c
		ON t.customer_id = c.customer_id
	GROUP BY t.customer_id
),

customer_album_analysis AS (
	SELECT 
		t.customer_id,
        t.album_id,
        a.title AS album_title,
        a.artist_id,
        art.name AS artist_name,
        SUM(unit_price*quantity) AS tot_album_purchase_amt,
        COUNT(track_id) AS track_cnt_in_album,
        RANK() OVER(PARTITION BY customer_id ORDER BY SUM(unit_price*quantity) DESC, COUNT(track_id) DESC, a.title) AS album_rnk_by_value
	FROM TrackInvoiceDetails t
    JOIN album a
		ON t.album_id = a.album_id
	JOIN artist art 
		ON a.artist_id = art.artist_id
    GROUP BY t.customer_id, t.album_id
),

customer_genre_analysis AS (
	SELECT 
		t.customer_id,
        t.genre_id,
        g.name AS genre_name,
        SUM(unit_price*quantity) AS tot_genre_purchase_amt,
        COUNT(track_id) AS track_cnt_in_genre,
        RANK() OVER(PARTITION BY customer_id ORDER BY SUM(unit_price*quantity) DESC, COUNT(track_id) DESC) AS genre_rnk_by_value
	FROM TrackInvoiceDetails t
    JOIN genre g
		ON t.genre_id = g.genre_id
    GROUP BY t.customer_id, t.genre_id, g.name
)

SELECT 
	la.customer_id, 
    la.customer_name, 
    la.city, 
    la.country, 
    (
		CASE WHEN la.customer_id IN (SELECT DISTINCT customer_id FROM HighRiskCustomer) THEN "Yes"
        ELSE "No"
        END
    ) AS is_risky_customer,
    la.first_purchase_date, 
    la.last_purchase_date, 
    la.tenure_in_month, 
    (
		CASE 
        WHEN DATE_SUB((SELECT MAX(invoice_date) FROM TrackInvoiceDetails), INTERVAL 6 MONTH) < la.last_purchase_date THEN "Yes" 
        ELSE "No"
		END
    ) AS purchase_in_last_6_month,
    la.churn_in_2020, 
    la.customer_type, 
    la.lifetime_value, 
    la.lifetime_purchase_cnt, 
    la.lifetime_track_cnt, 
    la.frequency_of_purchase, 
    aa.album_title AS fav_album_of_cust,
    aa.track_cnt_in_album,
    aa.artist_name AS fav_artist_of_cust, 
    aa.tot_album_purchase_amt AS tot_purchase_amt,
    ROUND((aa.tot_album_purchase_amt / la.lifetime_value), 2) AS percent_of_lifetime_value_a,
	ga.genre_name AS fav_genre_of_cust, 
    ga.track_cnt_in_genre,
    ga.tot_genre_purchase_amt, 
    ROUND((ga.tot_genre_purchase_amt / la.lifetime_value), 2) AS percent_of_lifetime_value_g
FROM customer_lifetime_analysis la
JOIN (
	SELECT *
	FROM customer_album_analysis
    WHERE album_rnk_by_value = 1
) aa
	ON aa.customer_id = la.customer_id
JOIN (
	SELECT *
    FROM customer_genre_analysis
    WHERE genre_rnk_by_value = 1
) ga
	ON ga.customer_id = la.customer_id;
    
    
/*
HOW CAN YOU ALTER THE "ALBUMS" TABLE TO ADD A NEW COLUMN NAMED "RELEASEYEAR" OF TYPE INTEGER TO STORE THE RELEASE YEAR OF EACH ALBUM?
*/
DESC album;

ALTER TABLE album
ADD COLUMN release_year INT;

DESC album;


/*
CHINOOK IS INTERESTED IN UNDERSTANDING THE PURCHASING BEHAVIOR OF CUSTOMERS BASED ON THEIR GEOGRAPHICAL LOCATION. 
THEY WANT TO KNOW THE AVERAGE TOTAL AMOUNT SPENT BY CUSTOMERS FROM EACH COUNTRY, ALONG WITH THE NUMBER OF CUSTOMERS AND THE AVERAGE NUMBER OF TRACKS PURCHASED PER CUSTOMER. 
WRITE AN SQL QUERY TO PROVIDE THIS INFORMATION.
*/
WITH base_table AS (
	SELECT 
		c.country,
		SUM(l.unit_price*l.quantity) AS tot_amount_spent,
		COUNT(DISTINCT c.customer_id) AS cnt_of_customers,
		SUM(l.quantity) AS tot_tracks_purchased
	FROM invoice_line l
	JOIN invoice i
		ON i.invoice_id = l.invoice_id
	JOIN customer c
		ON c.customer_id = i.customer_id
	GROUP BY c.country
)

SELECT 
	country,
    cnt_of_customers,
    ROUND((tot_amount_spent / cnt_of_customers), 2) AS avg_tot_amount_spent_per_cust,
    ROUND((tot_tracks_purchased / cnt_of_customers)) AS avg_cnt_of_tracks_purchased_per_cust
FROM base_table
ORDER BY cnt_of_customers DESC;