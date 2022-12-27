-- members table
SELECT *
FROM dannys_diner.members

-- menu table
SELECT *
FROM dannys_diner.menu

--sales table
SELECT *
FROM dannys_diner.sales
LIMIT 5

-- 1. total amount spent by each customer
SELECT sale.customer_id AS customer,
SUM(menus.price) AS total_amt
FROM dannys_diner.menu as menus
JOIN dannys_diner.sales as sale
 ON menus.product_id = sale.product_id
GROUP BY customer
ORDER BY total_amt DESC

-- 2. how many days each customer visited restaurant

SELECT customer_id, 
COUNT(DISTINCT order_date) AS no_of_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY no_of_days DESC

-- 3. first item from the menu purchased by each customer

WITH customer_rank AS(
SELECT s.customer_id, 
RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS _rank,
m.product_name
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id

)

SELECT DISTINCT customer_id,
product_name
FROM customer_rank
WHERE _rank = 1

-- 4. most purchased item on the menu

SELECT m.product_name, COUNT(s.product_id) AS total
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
 ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total DESC
LIMIT 1


-- 5. most popular item for each customer

WITH most_popular AS(
 SELECT s.customer_id,
 m.product_name,
 RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS _rank,
 COUNT(s.product_id) AS most_ordered
 FROM dannys_diner.sales s
 JOIN dannys_diner.menu m
  ON s.product_id = m.product_id
 GROUP BY s.customer_id,m.product_name

)

SELECT customer_id,
product_name,
most_ordered
FROM most_popular
WHERE _rank = 1


-- 6. item first purchased by customer after they became member

WITH first_item AS(

 SELECT m.customer_id,
 mu.product_name,
 s.order_date,
 m.join_date,
 RANK() OVER (PARTITION BY m.customer_id ORDER BY s.product_id) AS _rank
 FROM dannys_diner.members m
 JOIN dannys_diner.sales s
  ON m.customer_id = s.customer_id
 JOIN dannys_diner.menu mu 
  ON s.product_id = mu.product_id
 WHERE s.order_date >= m.join_date


)

SELECT customer_id,
product_name,
join_date,
order_date
FROM first_item
WHERE _rank = 1


-- 7. item purchased just before customer became member

WITH before_item AS (

 SELECT m.customer_id, mu.product_name, m.join_date,s.order_date,
 RANK() OVER(PARTITION BY m.customer_id ORDER BY s.order_date DESC) AS _rank
 FROM dannys_diner.members m
 JOIN dannys_diner.sales s 
  ON m.customer_id = s.customer_id
 JOIN dannys_diner.menu mu
  ON s.product_id = mu.product_id
 WHERE s.order_date < m.join_date

)

SELECT customer_id,
product_name,
join_date,
order_date
FROM before_item
WHERE _rank = 1


-- 8. total items and amount spent for each member before they became member

SELECT s.customer_id,
COUNT(DISTINCT s.product_id) AS total_unique_items,
SUM(mu.price) AS amount_spent
FROM dannys_diner.members m
JOIN dannys_diner.sales s
 ON m.customer_id = s.customer_id
JOIN dannys_diner.menu mu
 ON s.product_id = mu.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id


-- 9. total points for each customer where each 1$ spent = 10 points and sushi has 2x points

SELECT s.customer_id, 
SUM (CASE 
     WHEN s.product_id = 1 THEN 20*price
     ELSE 10 * price END)
AS total_points
FROM dannys_diner.menu mu 
JOIN dannys_diner.sales s 
 ON s.product_id = mu.product_id
GROUP BY s.customer_id


-- 10. 2x points on all items for A and B in first week after joining (including join date) - total points at the end of january

WITH members_date AS (

 SELECT *,
 join_date + 6 AS valid_date,
 '2021-01-31' :: DATE AS end_date
 FROM dannys_diner.members 

)

SELECT s.customer_id,
SUM (CASE 
     WHEN s.product_id = 1 THEN 20*price
     WHEN s.order_date BETWEEN md.join_date AND md.valid_date THEN 20*price
     ELSE 10 * price END)
AS total_points

FROM members_date md
JOIN dannys_diner.sales s
 ON md.customer_id = s.customer_id
JOIN dannys_diner.menu mu 
 ON s.product_id = mu.product_id

WHERE s.order_date < end_date
GROUP BY s.customer_id


-- Bonus Question 1

--Recreate the following table output using the available data:
/*customer_id	order_date	product_name	price	member
A	2021-01-01	curry	15	N
A	2021-01-01	sushi	10	N
A	2021-01-07	curry	15	Y
A	2021-01-10	ramen	12	Y
A	2021-01-11	ramen	12	Y
A	2021-01-11	ramen	12	Y
B	2021-01-01	curry	15	N
B	2021-01-02	curry	15	N
B	2021-01-04	sushi	10	N
B	2021-01-11	sushi	10	Y
B	2021-01-16	ramen	12	Y
B	2021-02-01	ramen	12	Y
C	2021-01-01	ramen	12	N
C	2021-01-01	ramen	12	N
C	2021-01-07	ramen	12	N*/

SELECT s.customer_id,
s.order_date,
mu.product_name,
price,
CASE 
 WHEN s.order_date < m.join_date THEN 'N'
 WHEN s.order_date >= m.join_date THEN 'Y'
 ELSE 'N' END AS member
FROM dannys_diner.menu AS mu 
LEFT JOIN dannys_diner.sales AS s
 ON mu.product_id = s.product_id
LEFT JOIN dannys_diner.members AS m 
 ON s.customer_id = m.customer_id
ORDER BY s.customer_id, s.order_date


-- Bonus Question 2

--Recreate the following table output using the available data:
/*customer_id	order_date	product_name	price	member	ranking
A	2021-01-01	curry	15	N	null
A	2021-01-01	sushi	10	N	null
A	2021-01-07	curry	15	Y	1
A	2021-01-10	ramen	12	Y	2
A	2021-01-11	ramen	12	Y	3
A	2021-01-11	ramen	12	Y	3
B	2021-01-01	curry	15	N	null
B	2021-01-02	curry	15	N	null
B	2021-01-04	sushi	10	N	null
B	2021-01-11	sushi	10	Y	1
B	2021-01-16	ramen	12	Y	2
B	2021-02-01	ramen	12	Y	3
C	2021-01-01	ramen	12	N	null
C	2021-01-01	ramen	12	N	null
C	2021-01-07	ramen	12	N	null*/

WITH rank_all_data AS (

 SELECT s.customer_id,
 s.order_date,
 mu.product_name,
 price,
 CASE 
  WHEN s.order_date < m.join_date THEN 'N'
  WHEN s.order_date >= m.join_date THEN 'Y'
  ELSE 'N' END AS member
 FROM dannys_diner.menu AS mu 
 LEFT JOIN dannys_diner.sales AS s
  ON mu.product_id = s.product_id
 LEFT JOIN dannys_diner.members AS m 
  ON s.customer_id = m.customer_id
 ORDER BY s.customer_id, s.order_date

)

SELECT *,
CASE 
 WHEN member = 'N' THEN null
 ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS _rank
FROM rank_all_data








