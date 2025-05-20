-- Sales Performance
-- 1.	How have total sales revenue and quantity trended month over month?


SELECT 
	dd.year_month AS month,
	SUM(f.transaction_qty) AS total_quantity,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM factsale f
JOIN dimdate dd
	ON f.transaction_date = dd.date
GROUP BY dd.year_month, dd.year, dd.month_number
ORDER BY dd.year, dd.month_number;

-- 2.	Which store generated the highest average revenue per transaction?


SELECT
	ds.store_location AS store,
    COUNT(f.transaction_id) AS total_transaction,
    ROUND(SUM(f.revenue), 2) AS total_revenue,
    ROUND(SUM(f.revenue) / COUNT(f.transaction_id), 2) AS avg_revenue_per_transaction
FROM factsale f
JOIN dimstore ds
	ON f.store_id = ds.store_id
GROUP BY ds.store_location
ORDER BY avg_revenue_per_transaction DESC;

-- 3.	What is the average unit price and quantity sold per product category?


WITH cte_count AS(
SELECT
	dp.product_category AS category,
    COUNT(f.transaction_id) AS txn_count,
    SUM(f.revenue) AS total_revenue,
    SUM(f.transaction_qty) AS total_qty
FROM dimproduct dp
JOIN factsale f
	ON dp.product_id = f.product_id
GROUP BY category
) 
SELECT 
	category,
	ROUND(total_revenue / total_qty, 2) AS avg_unite_price,
    ROUND(total_qty / txn_count, 2) AS avg_quantity_per_transaction
FROM cte_count
ORDER BY avg_unite_price DESC, avg_quantity_per_transaction DESC;


--  Customer Behaviour
-- 1.	What are the busiest hours of the day by total number of transactions?


SELECT 
	EXTRACT(HOUR FROM CAST(transaction_time AS TIME)) AS hour_of_day,
	COUNT(transaction_id) AS total_transactions
FROM factsale 
GROUP BY hour_of_day
ORDER BY total_transactions DESC;


-- 2.	Do weekends or weekdays have higher average revenue per transaction?


WITH cte_bin AS(
SELECT 
	CASE 
		WHEN dd.day BETWEEN 1 AND 5 THEN 'Weekday'
		ELSE 'Weekend' 
	END AS day_bin,
	SUM(f.revenue) AS total_revenue,
    COUNT(f.transaction_id) AS total_txn
FROM factsale f
JOIN dimdate dd
	ON f.transaction_date = dd.date
GROUP BY day_bin
 )
SELECT 
	day_bin,
    ROUND(total_revenue / total_txn, 2) AS avg_revenue
FROM cte_bin
ORDER BY avg_revenue DESC;

-- 3.  What is the average transaction revenue by hour of the day?


WITH cte_count AS(
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
  
--  3. Product Performance
-- 1.	Which products have the highest and lowest revenue overall?


-- Lowest
SELECT
    dp.product_id,
    dp.product_detail,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM factsale f
JOIN dimproduct dp
    ON f.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_detail
ORDER BY total_revenue ASC
LIMIT 10;


-- Highest
SELECT
    dp.product_id,
    dp.product_detail,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM factsale f
JOIN dimproduct dp
    ON f.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_detail
ORDER BY total_revenue DESC
LIMIT 10;

-- 2.	Which product categories contribute most to overall revenue?


SELECT
	dp.product_category AS product_category,
    ROUND(SUM(f.revenue), 2) AS total_revenue,
    ROUND(SUM(f.revenue) * 100.0 / SUM(SUM(f.revenue)) OVER (), 2) AS pct_of_total_revenue
FROM factsale f
JOIN dimproduct dp
	ON f.product_id = dp.product_id
GROUP BY dp.product_category
ORDER BY total_revenue DESC;

-- 3.	Which products have the highest average unit price and are still frequently purchased?

  
 SELECT
	f.product_id AS product_id,
    dp.product_type AS product_type,
    dp.product_detail AS product_detail,
    ROUND(AVG(f.unit_price), 2) AS avg_unit_price,
    SUM(f.transaction_qty) AS  total_units_sold
FROM factsale f
JOIN dimproduct dp
	ON f.product_id = dp.product_id
GROUP BY f.product_id, dp.product_type, product_detail
ORDER BY avg_unit_price DESC, total_units_sold DESC;
 
-- 4. Operational Insights
-- 1.	Which store has the most uneven sales distribution across days of the week?


WITH weekly_sales AS (
  SELECT
		ds.store_location,
		dd.weekday,
		SUM(f.revenue) AS total_revenue
  FROM factsale f
  JOIN dimstore ds 
	ON f.store_id = ds.store_id
  JOIN dimdate dd 
	ON f.transaction_date = dd.date
  GROUP BY ds.store_location, dd.weekday
)
SELECT
	store_location,
	ROUND(STDDEV(total_revenue), 2) AS weekly_revenue_stddev
FROM weekly_sales
GROUP BY store_location
ORDER BY weekly_revenue_stddev DESC
LIMIT 1;


-- 2.	What are the peak sales hours per store location?  

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


-- 3.	How does the number of items sold vary by hour and day?          


 SELECT
	dd.weekday AS day_of_week,
	EXTRACT(HOUR FROM CAST(f.transaction_time AS TIME)) AS hour_of_day,
	SUM(f.transaction_qty) AS number_of_sold_items
FROM factsale f
JOIN dimdate dd 
	ON f.transaction_date = dd.date
GROUP BY dd.weekday, hour_of_day
ORDER BY 
  FIELD(dd.weekday, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
  hour_of_day;
 
--  5. Marketing Opportunities
-- 1.	Which products are the top sellers in the last 3 months?


SELECT
	dp.product_detail,
	SUM(f.transaction_qty) AS total_qty,
    ROUND(SUM(f.revenue), 2) AS revenue
FROM factsale f
JOIN dimproduct dp
	ON f.product_id = dp.product_id
    WHERE transaction_date >= '2023-04-01' AND transaction_date <= '2023-06-30'
GROUP BY dp.product_detail
ORDER BY total_qty DESC
LIMIT 10;

-- 2.	Which products have low sales performance but show potential for increased demand if offered with discounts or promotions?


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
		

-- 3.	Which time slots during the day show low sales volume but could be targeted with promotions to increase revenue and improve overall sales performance?

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

