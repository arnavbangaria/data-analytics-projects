__1. What day of the week is used for each week_date value?__
```sql
SELECT 
	DAYNAME(txn_date) AS start_day, 
    COUNT(txn_date) AS count
FROM clean_weekly_sales
GROUP BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/111cf629-2637-412d-9c5a-302edbb0b9fc)

---

__2. What range of week numbers are missing from the dataset?__
```sql
SELECT 
	week_number,
    COUNT(week_number) AS weeks
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/ed05d633-2397-4c5c-a8e2-45a2a8f15005)

---

__3. How many total transactions were there for each year in the dataset?__
```sql
SELECT 
	calendar_year,
	COUNT(txn) AS tot_txn_count
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 1;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/3e8079ab-5a97-4810-a1e0-684993f07353)

---

__4. What is the total sales for each region for each month?__
```sql
SELECT 
	cust_region,
	month_number,
    SUM(txn_sales) AS tot_sales
FROM clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/50dfda27-a268-4a75-831f-005272d3b7b2)

---

__5. What is the total count of transactions for each platform?__
```sql
SELECT
	txn_platform,
    COUNT(txn) AS tot_txn
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/51e8f548-2f9c-42f4-af34-c0ae37a02a79)

---

__6. What is the percentage of sales for Retail vs Shopify for each month?__
```sql
SELECT
	txn_platform,
    CONCAT((COUNT(txn) / (SELECT COUNT(*) FROM clean_weekly_sales))*100, " %") AS sales_percent
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 2 DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/b1682772-3895-45a5-997a-138d3c01adb1)

---

__7. What is the percentage of sales by demographic for each year in the dataset?__
```sql
SELECT
	demographic,
    calendar_year,
    CONCAT((COUNT(*) / (SELECT COUNT(*) FROM clean_weekly_sales))*100, " %") AS percentage
FROM clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/e54d7f8b-3666-4d41-9af9-43c4e89c5274)

---

__8. Which age_band and demographic values contribute the most to Retail sales?__
```sql
SELECT
	age_band,
    	demographic,
    	CONCAT((SUM(txn_sales) / (SELECT SUM(txn_sales) FROM clean_weekly_sales))*100, " %") AS percent
FROM clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6cba89f7-3649-49b0-afe2-b5908eebe27e)

---

__9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?__
```sql
SELECT
	calendar_year,
    txn_platform,
    ROUND(AVG(avg_txn), 2) AS avg_trans_size
FROM clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/5bb7ce5e-5831-4e3a-8eb7-2e8957825f97)
