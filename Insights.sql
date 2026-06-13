-- EDA(Exploratory Data Analysis)

SELECT * FROM customers;
SELECT * FROM restaurents;
SELECT * FROM orders;
SELECT * FROM riders;
SELECT * FROM deliveries;

--Import Datasets

SELECT COUNT(*) FROM customers
WHERE customer_name IS NULL OR reg_date IS NULL;

SELECT COUNT(*) FROM restaurents
WHERE restaurent_name IS NULL OR city IS NULL OR opening_hours IS NULL;

SELECT COUNT(*) FROM orders
WHERE order_item IS NULL OR order_date IS NULL OR order_time IS NULL OR order_status IS NULL OR total_amount IS NULL;

--------------------------------
--Analysis and Reports
--------------------------------
-- Q-1 Write a query to find the top 3 most frequently ordered dishes by customer
-- called "Taylor Bell" in the last one year.

SELECT 
    customer_name,
	dishes,
	total_orders
FROM
    (SELECT
       c.customer_id,
       c.customer_name,
       o.order_item AS dishes,
       count(*) AS total_orders,
       DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) as rank
    FROM orders AS o
    JOIN customers AS c ON o.customer_id = c.customer_id
    WHERE 
        o.order_date >= CURRENT_DATE - INTERVAL '1 YEAR' AND c.customer_name = 'Sandra White'
    GROUP BY 1, 2, 3 
    ORDER BY 1, 4) AS t1
WHERE rank <=3;


-- Q-2 Identify the time slots during which the most orders are placed, based on 
-- 2-hour intervals.

APPROACH 1:
SELECT 
   CASE
       WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
	   WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
   END AS time_slot,
   COUNT(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;

APPROACH 2:
SELECT
    FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 as start_time,
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2+2 as end_time,
	COUNT(*) AS total_orders
FROM orders
GROUP BY 1,2
ORDER BY 3 DESC;

--Q-3 Find the average order value per customer who has placed more than 10 orders

SELECT 
    --o.customer_id,
	c.customer_name,
	AVG(o.total_amount) as aov
FROM orders as o
  JOIN customers as c 
  ON o.customer_id = c.customer_id
GROUP BY 1
HAVING COUNT(o.order_id) > 5;

-- Q-4 List the customers who have spent more than 5k in total on food orders.

SELECT 
    c.customer_name,
	SUM(o.total_amount) as total_spent
FROM orders as o
JOIN customers as c ON o.customer_id = c.customer_id
GROUP BY 1
HAVING SUM(o.total_amount) > 4000;

--Q-5 Write a query to find orders that were placed but not delivered.

SELECT 
    r.restaurent_name,
	r.city,
	COUNT(o.order_id) AS orders_not_delivered
FROM orders as o
LEFT JOIN restaurents as r ON o.restaurent_id = r.restaurent_id
LEFT JOIN deliveries as d ON o.order_id = d.order_id
WHERE d.delivery_status = 'Not Delivered'
GROUP BY 1,2
ORDER BY orders_not_delivered DESC;

-- Q-6 Rank restaurents by their total revenue from the last year, including
--their name, total revenue, and rank within their city.

WITH RestaurentRevenue AS (
    SELECT 
        r.city,
        r.restaurent_name,
        SUM(o.total_amount) as revenue   
    FROM orders as o 
    JOIN restaurents as r ON r.restaurent_id = o.restaurent_id
    GROUP BY 1,2
)
SELECT
   city,
   restaurent_name,
   revenue,
   RANK() OVER(PARTITION BY city ORDER BY revenue DESC) as rank
FROM RestaurentRevenue;

--Q-7 Identify the most popular dish in each city based on the number of orders

SELECT *
FROM 
(SELECT
  r.city,
  o.order_item as dish,
  COUNT(order_id) as total_orders,
  RANK() OVER (PARTITION BY r.city ORDER BY COUNT(order_id) DESC) as rank
FROM orders as o
JOIN restaurents as r ON r.restaurent_id = o.restaurent_id
GROUP BY 1,2
) as t1
WHERE rank = 1

--Q-8 Payment method popularity by Average Order Value (AOV)
 SELECT
     payment_method,
	 COUNT(order_id) AS transaction_count,
	 ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
	 ROUND(AVG(total_amount)::numeric, 2) AS average_order_value
FROM orders
WHERE order_status = 'Completed'
GROUP BY payment_method
ORDER BY average_order_value DESC;

--Q-9 Find the number of 5-star, 4-star, and 3-star ratings each rider has.
--riders receive this rating based on delivery time.
--if orders are delivered less than 15 minutes of order received time the rider get 5-star rating,
--if they deliver 15 and 20 minutes they get 4-star rating,
--if they delives after 20 minutes they get 3-star rating.

SELECT
   rider_id,
   stars,
   COUNT(*) as total_stars
FROM
(
  SELECT
    rider_id,
    delivery_took_time,
    CASE 
       WHEN delivery_took_time < 15 THEN '5_star'
	   WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4_star'
	   ELSE '3_star'
    END AS stars

  FROM 
   (
     SELECT
      o.order_id,
	  o.order_time,
	  d.rider_id,
	  d.delivery_time,
	  EXTRACT(EPOCH FROM (
	     d.delivery_time - o.order_time +
	     CASE 
		     WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
	         ELSE INTERVAL '0 day'
		 END
	  ))/60 AS delivery_took_time
     FROM orders as o
     JOIN deliveries AS d
     ON o.order_id = d.order_id
     WHERE delivery_status = 'Delivered'
  ) AS t1
) as t2
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- Q-10 Find customers who haven't placed an order in 2026 but did in 2025.

SELECT DISTINCT customer_id 
FROM orders 
WHERE 
    EXTRACT(YEAR FROM order_date)=2025
	AND
	customer_id NOT IN 
	(SELECT DISTINCT customer_id FROM ORDERS
	WHERE EXTRACT(YEAR FROM order_date) = 2026);

--Q-11 Calculate and compare the order cancellation rate for each restaurent between
-- the current year and previous year

WITH cancel_ratio_25 AS (
    SELECT
       o.restaurent_id,
	   COUNT(o.order_id) AS total_orders,
	   COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders as o
    LEFT JOIN deliveries as d ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2025
    GROUP BY o.restaurent_id
),
cancel_ratio_26 AS (
    SELECT 
	  o.restaurent_id,
      COUNT(o.order_id) AS total_orders,
	  COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
    FROM orders as o
    LEFT JOIN deliveries as d ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM order_date) = 2025
    GROUP BY o.restaurent_id
),
last_year_data AS (
    SELECT
	    restaurent_id,
		total_orders,
		not_delivered,
		ROUND((not_delivered::numeric/total_orders::numeric) * 100, 2) AS cancel_ratio
    FROM cancel_ratio_25
),
current_year_data AS (
   SELECT
       restaurent_id,
	   total_orders,
	   not_delivered,
	   ROUND((not_delivered::numeric/total_orders::numeric) * 100, 2) AS cancel_ratio
   FROM cancel_ratio_26
)

SELECT 
   c.restaurent_id AS restaurent_id,
   c.cancel_ratio AS current_year_cancel_ratio,
   l.cancel_ratio AS last_year_cancel_ratio
FROM current_year_data AS c
JOIN last_year_data AS l
ON c.restaurent_id = l.restaurent_id;

--Q-12 Determine each rider's average delivery time.

SELECT 
    o.order_id,
	o.order_time,
	d.delivery_time,
	d.rider_id,
	d.delivery_time - o.order_time AS time_difference,
	EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
	CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
	INTERVAL '0 day' END))/60 as time_difference_insec
FROM orders as o
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered';
















