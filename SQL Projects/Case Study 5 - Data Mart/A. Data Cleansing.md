In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
1. Convert the week_date to a DATE format
2. Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
3. Add a month_number with the calendar month for each week_date value as the 3rd column
4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
5. Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
  - 1 for Young Adults 
  - 2 for Middle Aged
  - 3 or 4 for Retirees    
	- C for Couples
  - F for Families

<br>

Add a new demographic column using the following mapping for the first letter in the segment values:
1. Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
2. Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

<br>

__TEST TABLE TO GET THE REQUIRED OUTPUT__
```sql
WITH cte1 AS 
(
SELECT 
	STR_TO_DATE(week_date, "%d/%m/%y") AS txn_date,
    WEEKOFYEAR(STR_TO_DATE(week_date, "%d/%m/%y")) AS week_num,
    MONTH(STR_TO_DATE(week_date, "%d/%m/%y")) AS month_num,
    YEAR(STR_TO_DATE(week_date, "%d/%m/%y")) AS cal_year,
    region, 
    platform, 
    segment,
    (
		CASE 
		WHEN (SUBSTRING(segment, -1) = '1') THEN 'Young Adults'
		WHEN (SUBSTRING(segment, -1) = '2') THEN 'Middle Aged'
		WHEN (SUBSTRING(segment, -1) IN ('3', '4')) THEN 'Retirees'
		ELSE 'Unknown'
		END
    ) AS age_band,
    (
		CASE 
		WHEN SUBSTRING(segment, 1, 1) = 'C' THEN 'Couples'
		WHEN SUBSTRING(segment, 1, 1) = 'F' THEN 'Families'   
		ELSE 'Unknown'
		END
    ) AS demographics,
    customer_type,
    transactions,
    sales,
    ROUND((sales / transactions), 2) AS avg_transactions
FROM weekly_sales
)

SELECT *
FROM cte1;
```

---

__ACTUAL INSERTION OPERATION__
```sql
CREATE TABLE weekly_sales_2 (
	txn_date DATE,
    week_number INT,
    month_number INT,
    calendar_year INT,
    cust_region VARCHAR(13),
    txn_platform VARCHAR(7),
    cust_segment VARCHAR(4),
	age_band VARCHAR(20),
    demographic VARCHAR(15),
    cust_type VARCHAR(8),
    txn INT,
    txn_sales INT,
    avg_txn FLOAT
);
```

```sql
INSERT INTO weekly_sales_2(txn_date, week_number, month_number, calendar_year, cust_region, txn_platform, cust_segment, age_band, demographic, cust_type, txn, txn_sales, avg_txn)
SELECT 
	STR_TO_DATE(week_date, "%d/%m/%y"),
    WEEKOFYEAR(STR_TO_DATE(week_date, "%d/%m/%y")),
    MONTH(STR_TO_DATE(week_date, "%d/%m/%y")),
    YEAR(STR_TO_DATE(week_date, "%d/%m/%y")),
    region, 
    platform, 
    segment,
    (
		CASE 
		WHEN (SUBSTRING(segment, -1) = '1') THEN 'Young Adults'
		WHEN (SUBSTRING(segment, -1) = '2') THEN 'Middle Aged'
		WHEN (SUBSTRING(segment, -1) IN ('3', '4')) THEN 'Retirees'
		ELSE 'Unknown'
		END
    ),
    (
		CASE 
		WHEN SUBSTRING(segment, 1, 1) = 'C' THEN 'Couples'
		WHEN SUBSTRING(segment, 1, 1) = 'F' THEN 'Families'   
		ELSE 'Unknown'
		END
    ),
    customer_type,
    transactions,
    sales,
    ROUND((sales / transactions), 2)
FROM weekly_sales;

RENAME TABLE weekly_sales_2 TO clean_weekly_sales;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/c2d592b3-93e8-4826-bed7-6be81ee790eb)
