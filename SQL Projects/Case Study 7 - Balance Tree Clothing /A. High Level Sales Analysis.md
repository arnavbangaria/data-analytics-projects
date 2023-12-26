__1. What was the total quantity sold for all products?__
```sql
SELECT 
	pd.product_name, 
    s.prod_id, 
    SUM(s.qty) AS total_quantity_per_product
FROM sales AS s LEFT JOIN product_details AS pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2
ORDER BY total_quantity_per_product DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/9ef7996c-c200-4d1b-9d45-83c2b5ae966a)

---

__2. What is the total generated revenue for all products before dicounts?__
```sql
SELECT 
	pd.product_name, 
    s.prod_id, 
    SUM(s.qty*s.price) AS total_revenue_before_discount
FROM sales AS s LEFT JOIN product_details AS pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2
ORDER BY total_revenue_before_discount DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/6f10beb3-f852-477e-a779-7056ef1da545)

---

__3. What was the total discount amount for all products?__
```sql
SELECT 
	pd.product_name, 
    s.prod_id, 
    SUM(ROUND(s.qty*s.price*(s.discount/100))) AS discount_amount_for_all_products
FROM sales AS s LEFT JOIN product_details AS pd 
	ON s.prod_id = pd.product_id
GROUP BY 1, 2
ORDER BY 3 DESC;
```
![image](https://github.com/arnavbangaria/data-analytics-projects/assets/98005484/49b8849f-3c98-4b82-9de3-97c586dfed5c)
