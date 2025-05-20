# Coffee Shop Sales Analysis

This project analyzes sales data from a coffee shop to answer key business questions using SQL. The goal is to uncover insights into sales performance, customer behavior, product performance, operational efficiency, and marketing opportunities. Additionally, Power BI visualizations have been created to support data insights for better decision-making.

---

## Dataset

- **factsale**: Contains transactional sales data (transaction ID, date, time, quantity, revenue, etc.)
- **dimdate**: Date dimension table for joining dates with attributes (year, month, weekday, etc.)
- **dimstore**: Store information (store ID, location, etc.)
- **dimproduct**: Product information (product ID, category, detail, type, etc.)

---

## Business Questions & SQL Queries



###  1. Sales Performance

**1.1. How have total sales revenue and quantity trended month over month?**
```sql
SELECT 
	dd.year_month AS month,
	SUM(f.transaction_qty) AS total_quantity,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM factsale f
JOIN dimdate dd ON f.transaction_date = dd.date
GROUP BY dd.year_month, dd.year, dd.month_number
ORDER BY dd.year, dd.month_number;
```
![Sales Performance](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/main/powerbi_charts/sales_1.png)

#### Insight  
Sales revenue and quantity show a consistent upward trend from January to June 2023, indicating growing demand.

#### Recommendation  
Continue investing in promotions and inventory to support this positive sales momentum.

---

**1.2. Which store generated the highest average revenue per transaction?**
```sql
SELECT
	ds.store_location AS store,
    COUNT(f.transaction_id) AS total_transaction,
    ROUND(SUM(f.revenue), 2) AS total_revenue,
    ROUND(SUM(f.revenue) / COUNT(f.transaction_id), 2) AS avg_revenue_per_transaction
FROM factsale f
JOIN dimstore ds ON f.store_id = ds.store_id
GROUP BY ds.store_location
ORDER BY avg_revenue_per_transaction DESC;
```

![Average Revenue Per Transaction by Store](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/sales_2.png)

#### Insight  
Lower Manhattan leads in average revenue per transaction despite fewer transactions.

#### Recommendation  
Focus upselling efforts and premium product placement in Lower Manhattan to maximize revenue.

---

**1.3. What is the average unit price and quantity sold per product category?**
```sql
WITH cte_count AS (
	SELECT
		dp.product_category AS category,
		COUNT(f.transaction_id) AS txn_count,
		SUM(f.revenue) AS total_revenue,
		SUM(f.transaction_qty) AS total_qty
	FROM dimproduct dp
	JOIN factsale f ON dp.product_id = f.product_id
	GROUP BY category
) 
SELECT 
	category,
	ROUND(total_revenue / total_qty, 2) AS avg_unite_price,
	ROUND(total_qty / txn_count, 2) AS avg_quantity_per_transaction
FROM cte_count
ORDER BY avg_unite_price DESC, avg_quantity_per_transaction DESC;
```

![Average Unit Price and Quantity per Category](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/sales_3.png)

#### Insight  
Higher-priced items like Coffee Beans are bought in smaller quantities; lower-priced items like Tea and Flavours are bought more frequently.

#### Recommendation  
Promote bundles pairing high-priced and popular low-priced products to boost overall sales.

---

###  2. Customer Behaviour

**2.1. What are the busiest hours of the day by total number of transactions?**
```sql
SELECT 
	EXTRACT(HOUR FROM CAST(transaction_time AS TIME)) AS hour_of_day,
	COUNT(transaction_id) AS total_transactions
FROM factsale 
GROUP BY hour_of_day
ORDER BY total_transactions DESC;
```

![Busiest Hours by Transactions](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/customer_1.png)

#### Insight  
The peak transaction hours are between 7 AM and 11 AM, with 10 AM being the busiest hour.

#### Recommendation  
Optimize staffing and inventory availability during these peak morning hours to improve customer experience and reduce wait times.

---

**2.2. Do weekends or weekdays have higher average revenue per transaction?**
```sql
WITH cte_bin AS (
	SELECT 
		CASE 
			WHEN dd.day BETWEEN 1 AND 5 THEN 'Weekday'
			ELSE 'Weekend' 
		END AS day_bin,
		SUM(f.revenue) AS total_revenue,
		COUNT(f.transaction_id) AS total_txn
	FROM factsale f
	JOIN dimdate dd ON f.transaction_date = dd.date
	GROUP BY day_bin
)
SELECT 
	day_bin,
	ROUND(total_revenue / total_txn, 2) AS avg_revenue
FROM cte_bin
ORDER BY avg_revenue DESC;
```

![Average Revenue: Weekends vs Weekdays](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/customer_2.png)

#### Insight  
Weekends generate slightly higher average revenue per transaction compared to weekdays.

#### Recommendation  
Consider weekend promotions or special offers to capitalize on higher spending behavior.

---

**2.3. What is the average transaction revenue by hour of the day?**
```sql
WITH cte_count AS (
	SELECT 
		EXTRACT(HOUR FROM CAST(transaction_time AS TIME)) AS hour_of_day,
		COUNT(transaction_id) AS txn_count,
		SUM(revenue) AS total_revenue
	FROM factsale 
	GROUP BY hour_of_day
)
SELECT
	hour_of_day,
	ROUND(total_revenue / txn_count, 2) AS avg_revenue
FROM cte_count
ORDER BY avg_revenue DESC;
```

![Average Transaction Revenue by Hour](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/customer_3.png)

#### Insight  
The highest average transaction revenues occur during late evening (8 PM) and morning hours (6-11 AM).

#### Recommendation  
Explore targeted marketing campaigns during these high-value hours to maximize revenue per transaction.

---

###  3. Product Performance

**3.1. Which products have the highest and lowest revenue overall?**

_Lowest:_
```sql
SELECT
	dp.product_id,
	dp.product_detail,
	ROUND(SUM(f.revenue), 2) AS total_revenue
FROM factsale f
JOIN dimproduct dp ON f.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_detail
ORDER BY total_revenue ASC
LIMIT 10;
```

![Product Revenue Overview](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/product_1_low.png)

_Highest:_
```sql
SELECT
	dp.product_id,
	dp.product_detail,
	ROUND(SUM(f.revenue), 2) AS total_revenue
FROM factsale f
JOIN dimproduct dp ON f.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_detail
ORDER BY total_revenue DESC
LIMIT 10;
```

![Products with Highest Revenue](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/product_1_high.png)

#### Insight  
The highest revenues come from large-sized coffee and hot chocolate products, while smaller tea and chocolate products generate lower total revenue.

#### Recommendation  
Focus marketing and supply efforts on high-revenue large-sized products while exploring growth opportunities for smaller tea products.

---

**3.2. Which product categories contribute most to overall revenue?**
```sql
SELECT
	dp.product_category AS product_category,
	ROUND(SUM(f.revenue), 2) AS total_revenue,
	ROUND(SUM(f.revenue) * 100.0 / SUM(SUM(f.revenue)) OVER (), 2) AS pct_of_total_revenue
FROM factsale f
JOIN dimproduct dp ON f.product_id = dp.product_id
GROUP BY dp.product_category
ORDER BY total_revenue DESC;
```


![Product Categories Revenue Contribution](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/product_2.png)

#### Insight  
Coffee and Tea together account for over 66% of total revenue, making them the dominant product categories.

#### Recommendation  
Prioritize product development, promotions, and inventory management for Coffee and Tea categories.

---

**3.3. Which products have the highest average unit price and are still frequently purchased?**
```sql
SELECT
	f.product_id AS product_id,
	dp.product_type AS product_type,
	dp.product_detail AS product_detail,
	ROUND(AVG(f.unit_price), 2) AS avg_unit_price,
	SUM(f.transaction_qty) AS total_units_sold
FROM factsale f
JOIN dimproduct dp ON f.product_id = dp.product_id
GROUP BY f.product_id, dp.product_type, product_detail
ORDER BY avg_unit_price DESC, total_units_sold DESC;
```

![High Average Unit Price and Frequent Purchases](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/product_3.png)

#### Insight  
Premium beans and specialty items have the highest unit prices and maintain steady sales volumes, indicating strong niche demand.

#### Recommendation  
Maintain premium pricing strategies on specialty products while exploring opportunities to increase unit sales through targeted campaigns.

---

###  4. Operational Insights

**4.1. Which store has the most uneven sales distribution across days of the week?**
```sql
WITH weekly_sales AS (
	SELECT
		ds.store_location,
		dd.weekday,
		SUM(f.revenue) AS total_revenue
	FROM factsale f
	JOIN dimstore ds ON f.store_id = ds.store_id
	JOIN dimdate dd ON f.transaction_date = dd.date
	GROUP BY ds.store_location, dd.weekday
)
SELECT
	store_location,
	ROUND(STDDEV(total_revenue), 2) AS weekly_revenue_stddev
FROM weekly_sales
GROUP BY store_location
ORDER BY weekly_revenue_stddev DESC
LIMIT 1;
```

![Uneven Sales Distribution by Store and Day](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/operation_1.png)

#### Insight
Astoria has the most uneven sales distribution across days of the week, indicated by the highest weekly revenue standard deviation of 962.7.

#### Recommendation
Focus on stabilizing sales in Astoria by analyzing factors causing daily fluctuations and implementing targeted marketing or operational improvements.

---

**4.2. What are the peak sales hours per store location?**
```sql
WITH sales_by_hour AS (
	SELECT
		ds.store_location,
		EXTRACT(HOUR FROM CAST(f.transaction_time AS TIME)) AS hour_of_day,
		SUM(f.transaction_qty) AS number_of_sold_items
	FROM factsale f
	JOIN dimstore ds ON f.store_id = ds.store_id
	GROUP BY ds.store_location, hour_of_day
),
ranked_sales AS (
	SELECT *,
		RANK() OVER (PARTITION BY store_location ORDER BY number_of_sold_items DESC) AS rnk
	FROM sales_by_hour
)
SELECT store_location, hour_of_day, number_of_sold_items
FROM ranked_sales
WHERE rnk = 1
ORDER BY number_of_sold_items DESC;
```

![Peak Sales Hours per Store Location](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/operation_2.png)

#### Insight
All stores show peak sales at 10 AM, with Hell’s Kitchen having the highest number of items sold (9,873) during this hour.

#### Recommendation
Optimize staffing and inventory availability around the 10 AM peak to better meet customer demand.

---

**4.3. How does the number of items sold vary by hour and day?**
```sql
SELECT
	dd.weekday AS day_of_week,
	EXTRACT(HOUR FROM CAST(f.transaction_time AS TIME)) AS hour_of_day,
	SUM(f.transaction_qty) AS number_of_sold_items
FROM factsale f
JOIN dimdate dd ON f.transaction_date = dd.date
GROUP BY dd.weekday, hour_of_day
ORDER BY 
	FIELD(dd.weekday, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
	hour_of_day;
```

![Number of Items Sold by Hour and Day](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/operation_3.png)

#### Insight
Number of items sold gradually rises from 6 AM, peaks at 10 AM, then declines throughout the day, with the lowest sales around 8 PM across all days.

#### Recommendation
Schedule staff breaks and inventory restocking during low sales hours, and consider promotions during slower afternoon and evening periods to boost sales.

---

###  5. Marketing Opportunities

**5.1. Which products are the top sellers in the last 3 months?**
```sql
SELECT
	dp.product_detail,
	SUM(f.transaction_qty) AS total_qty,
	ROUND(SUM(f.revenue), 2) AS revenue
FROM factsale f
JOIN dimproduct dp ON f.product_id = dp.product_id
WHERE transaction_date >= '2023-04-01' AND transaction_date <= '2023-06-30'
GROUP BY dp.product_detail
ORDER BY total_qty DESC
LIMIT 10;
```

![Top Selling Products in Last 3 Months](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/marketing_1.png)

#### Insight
The top-selling products in the last 3 months include Dark Chocolate Lg, Latte, and Earl Grey Rg, with quantities sold near or above 2900 units each, generating significant revenue.

#### Recommendation
Focus marketing efforts and inventory management on these top sellers to maintain and increase sales, including bundling promotions or loyalty rewards for these products.

---

**5.2. Which products have low sales performance but show potential for increased demand if offered with discounts or promotions?**
```sql
WITH last_3_month_sale AS (
	SELECT
		dp.product_detail,
		SUM(f.transaction_qty) AS total_qty,
		CASE
			WHEN f.transaction_date BETWEEN '2023-01-01' AND '2023-03-31' THEN 'Q1'
			WHEN f.transaction_date BETWEEN '2023-04-01' AND '2023-06-30' THEN 'Q2'
		END AS period
	FROM factsale f
	JOIN dimproduct dp ON f.product_id = dp.product_id
	GROUP BY dp.product_detail, period
),
growth_calc AS (
	SELECT
		product_detail,
		total_qty,
		period,
		LAG(total_qty) OVER (PARTITION BY product_detail ORDER BY period) AS previous_qty
	FROM last_3_month_sale
)
SELECT
	product_detail,
	total_qty,
	previous_qty,
	total_qty - previous_qty AS qty_change
FROM growth_calc
WHERE period = 'Q2'
ORDER BY qty_change DESC;
```

![Products with Low Sales but Potential](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/marketing_2.png)

#### Insight
Several products such as "I Need My Bean! Latte cup," "Civet Cat," and "I Need My Bean! Diner mug" have low sales volumes but show potential for growth if offered with discounts or promotions, evidenced by their relatively small but consistent sales and notable quantity changes in other related products.

#### Recommendation
Introduce targeted discount campaigns or promotional bundles for these low-performing products to boost awareness and trial, potentially increasing overall demand and expanding customer interest.

---

**5.3. Which time slots during the day show low sales volume but could be targeted with promotions to increase revenue and improve overall sales performance?**
```sql
SELECT
	CASE
		WHEN transaction_time BETWEEN '06:00' AND '12:00' THEN 'Morning'
		WHEN transaction_time BETWEEN '12:01' AND '17:00' THEN 'Afternoon'
		ELSE 'Evening' 
	END AS time_slot,
	SUM(transaction_qty) AS total_qty,
	ROUND(SUM(revenue), 2) AS total_revenue
FROM factsale
GROUP BY time_slot
ORDER BY total_qty ASC;
```
![Low Sales Time Slots for Promotion](https://raw.githubusercontent.com/PetrovicsRobert/coffee-shop-sales-analysis/refs/heads/main/powerbi_charts/marketing_3.png)

#### Insight
Sales volumes are lowest in the Evening time slot compared to Morning and Afternoon, with only 32,797 items sold generating approximately $105k in revenue.

#### Recommendation
Launch time-limited promotions or happy hour deals during the Evening to attract more customers, improve sales during slower periods, and balance daily revenue streams.

---
