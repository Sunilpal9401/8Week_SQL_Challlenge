CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 12:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 12:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-02 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  /* --------------------
   Table Transformation
   --------------------*/
   -- data type check
--customer_orders
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'customer_orders';

--runner_orders
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'runner_orders';

--Update tables

--1. customer_order
/*
Cleaning customer_orders
- Identify records with null or 'null' values
- updating null or 'null' values to ''
- blanks '' are not null because it indicates the customer asked for no extras or exclusions
*/

--Blanks indicate that the customer requested no extras/exclusions for the pizza,
-- whereas null values would be ambiguous on this.

DROP TABLE IF EXISTS updated_customer_orders;
CREATE TEMP TABLE updated_customer_orders AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE 
      WHEN exclusions IS NULL 
        OR exclusions LIKE 'null' THEN ''
      ELSE exclusions 
    END AS exclusions,
    CASE 
      WHEN extras IS NULL
        OR extras LIKE 'null' THEN ''
      ELSE extras 
    END AS extras,
    order_time
  FROM pizza_runner.customer_orders
);
SELECT * FROM updated_customer_orders;


--2. runner_orders
/*
- pickup time, distance, duration is of the wrong type
- records have nulls in these columns when the orders are cancelled
- convert text 'null' to null values
- units (km, minutes) need to be removed from distance and duration
*/

DROP TABLE IF EXISTS updated_runner_orders;
CREATE TEMP TABLE updated_runner_orders AS (
  SELECT
    order_id,
    runner_id,
    CASE WHEN pickup_time LIKE 'null' THEN null ELSE pickup_time END::timestamp AS pickup_time,
    NULLIF(regexp_replace(distance, '[^0-9.]','','g'), '')::numeric AS distance,
    NULLIF(regexp_replace(duration, '[^0-9.]','','g'), '')::numeric AS duration,
    CASE WHEN cancellation IN ('null', 'NaN', '') THEN null ELSE cancellation END AS cancellation
  FROM pizza_runner.runner_orders);
SELECT * FROM updated_runner_orders;

-- data type check
--updated_customer_orders
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'updated_customer_orders'

--updated_runner_orders
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'updated_runner_orders'


/* --------------------
   Case Study Questions:
   Pizza Metrics
   --------------------*/


-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS pizza_count
FROM updated_customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT (DISTINCT order_id) AS order_count
FROM updated_customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT
  runner_id,
  COUNT(order_id) AS successful_orders
FROM updated_runner_orders
WHERE cancellation IS NULL
OR cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY runner_id
ORDER BY successful_orders DESC;

-- 4. How many of each type of pizza was delivered?
SELECT
  pn.pizza_name,
  COUNT(co.*) AS pizza_type_count
FROM updated_customer_orders AS co
INNER JOIN pizza_runner.pizza_names AS pn
   ON co.pizza_id = pn.pizza_id
INNER JOIN pizza_runner.runner_orders AS ro
   ON co.order_id = ro.order_id
WHERE cancellation IS NULL
OR cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
  customer_id,
  SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meat_lovers,
  SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM updated_customer_orders
GROUP BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT MAX(pizza_count) AS max_count
FROM (
  SELECT
    co.order_id,
    COUNT(co.pizza_id) AS pizza_count
  FROM updated_customer_orders AS co
  INNER JOIN updated_runner_orders AS ro
    ON co.order_id = ro.order_id
  WHERE 
    ro.cancellation IS NULL
    OR ro.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
  GROUP BY co.order_id) AS mycount;
  
  -- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  co.customer_id,
  SUM (CASE WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 1 ELSE 0 END) AS changes,
  SUM (CASE WHEN co.exclusions IS NULL OR co.extras IS NULL THEN 1 ELSE 0 END) AS no_change
FROM updated_customer_orders AS co
INNER JOIN updated_runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  OR ro.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY co.customer_id
ORDER BY co.customer_id;


-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
  SUM(CASE WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1 ELSE 0 END) as pizza_count
FROM updated_customer_orders AS co
INNER JOIN updated_runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  OR ro.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
  
  -- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
  DATE_PART('hour', order_time::TIMESTAMP) AS hour_of_day,
  COUNT(*) AS pizza_count
FROM updated_customer_orders
WHERE order_time IS NOT NULL
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- 10. What was the volume of orders for each day of the week?
SELECT
  TO_CHAR(order_time, 'Day') AS day_of_week,
  COUNT(*) AS pizza_count
FROM updated_customer_orders
GROUP BY 
  day_of_week, 
  DATE_PART('dow', order_time)
ORDER BY day_of_week;

/* --------------------
   Case Study Questions:
   Runner and Customer Experience
   --------------------*/


-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH runner_signups AS (
  SELECT
    runner_id,
    registration_date,
    registration_date - ((registration_date - '2021-01-01') % 7)  AS start_of_week
  FROM pizza_runner.runners
)
SELECT
  start_of_week,
  COUNT(runner_id) AS signups
FROM runner_signups
GROUP BY start_of_week
ORDER BY start_of_week;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH runner_pickups AS (
  SELECT
    ro.runner_id,
    ro.order_id,
    co.order_time,
    ro.pickup_time,
    (pickup_time - order_time) AS time_to_pickup
  FROM updated_runner_orders AS ro
  INNER JOIN updated_customer_orders AS co
    ON ro.order_id = co.order_id
)
SELECT 
  runner_id,
  date_part('minutes', AVG(time_to_pickup)) AS avg_arrival_minutes
FROM runner_pickups
GROUP BY runner_id
ORDER BY runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_count AS (
  SELECT
    order_id,
    order_time,
    COUNT(pizza_id) AS pizzas_order_count
  FROM updated_customer_orders
  GROUP BY order_id, order_time
), 
prepare_time AS (
  SELECT
    ro.order_id,
    co.order_time,
    ro.pickup_time,
    co.pizzas_order_count,
    (pickup_time - order_time) AS time_to_pickup
  FROM updated_runner_orders AS ro
  INNER JOIN order_count AS co
    ON ro.order_id = co.order_id
  WHERE pickup_time IS NOT NULL
)

SELECT
  pizzas_order_count,
  AVG(time_to_pickup) AS avg_time
FROM prepare_time
GROUP BY pizzas_order_count
ORDER BY pizzas_order_count;

-- What was the average distance travelled for each runner?
SELECT
  runner_id,
  ROUND(AVG(distance), 2) AS avg_distance
FROM updated_runner_orders
GROUP BY runner_id
ORDER BY runner_id;

-- What was the difference between the longest and shortest delivery times for all orders?
SELECT
  MAX(duration) - MIN(duration) AS difference
FROM updated_runner_orders;


-- What was the average speed for each runner for each delivery and do you notice any trend for these values?

WITH order_count AS (
  SELECT
    order_id,
    order_time,
    COUNT(pizza_id) AS pizzas_count
  FROM updated_customer_orders
  GROUP BY 
    order_id, 
    order_time
)
  SELECT
    ro.order_id,
    ro.runner_id,
    co.pizzas_count,
    ro.distance,
    ro.duration,
    ROUND(60 * ro.distance / ro.duration, 2) AS speed
  FROM updated_runner_orders AS ro
  INNER JOIN order_count AS co
    ON ro.order_id = co.order_id
  WHERE pickup_time IS NOT NULL
  ORDER BY speed DESC
  
  /*Finding:
Orders shown in decreasing order of average speed:
While the fastest order only carried 1 pizza and the slowest order carried 3 pizzas,
there is no clear trend that more pizzas slow down the delivery speed of an order.  
*/

-- What is the successful delivery percentage for each runner?
SELECT
  runner_id,
  COUNT(pickup_time) as delivered,
  COUNT(order_id) AS total,
  ROUND(100 * COUNT(pickup_time) / COUNT(order_id)) AS delivery_percent
FROM updated_runner_orders
GROUP BY runner_id
ORDER BY runner_id;


