-- ============================================================
--  SWIGGY ORDER ANALYTICS — analysis_queries.sql
--  5 Business Questions | Intermediate SQL
--  Concepts: CTEs, Window Functions, CASE WHEN,
--            Date Functions, Subqueries, JOINs
-- ============================================================


-- ============================================================
-- QUERY 1: Repeat Order Rate per Restaurant
-- Business Question: Which restaurants have the highest
-- customer loyalty (customers who ordered 2+ times)?
--
-- Concepts: CTE, GROUP BY, HAVING, Subquery, ROUND
-- ============================================================

WITH customer_order_counts AS (
    -- Count how many times each customer ordered from each restaurant
    SELECT
        restaurant_id,
        customer_id,
        COUNT(order_id) AS order_count
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id, customer_id
),
restaurant_stats AS (
    -- Separate repeat vs total customers per restaurant
    SELECT
        restaurant_id,
        COUNT(DISTINCT customer_id)                          AS total_unique_customers,
        COUNT(DISTINCT CASE WHEN order_count >= 2
                            THEN customer_id END)            AS repeat_customers
    FROM customer_order_counts
    GROUP BY restaurant_id
)
SELECT
    r.name                                                   AS restaurant_name,
    r.cuisine_type,
    rs.total_unique_customers,
    rs.repeat_customers,
    ROUND(
        (rs.repeat_customers * 100.0) / rs.total_unique_customers, 1
    )                                                        AS repeat_order_rate_pct
FROM restaurant_stats rs
JOIN restaurants r ON r.restaurant_id = rs.restaurant_id
ORDER BY repeat_order_rate_pct DESC;

/*
  INSIGHT: Restaurants with repeat_order_rate_pct > 50% have strong
  customer loyalty. These are candidates for Swiggy's "Top Picks"
  or loyalty reward programs.
*/


-- ============================================================
-- QUERY 2: Peak Ordering Hour by City and Cuisine
-- Business Question: At what hour do customers order the most,
-- broken down by city and cuisine type?
--
-- Concepts: HOUR() date function, GROUP BY multiple columns,
--           Window Function (RANK), CTE
-- ============================================================

WITH hourly_orders AS (
    SELECT
        c.city_name,
        r.cuisine_type,
        HOUR(o.order_time)   AS order_hour,
        COUNT(o.order_id)    AS total_orders
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    JOIN cities      c ON c.city_id = r.city_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.city_name, r.cuisine_type, HOUR(o.order_time)
),
ranked AS (
    SELECT
        city_name,
        cuisine_type,
        order_hour,
        total_orders,
        -- Rank hours within each city+cuisine combination
        RANK() OVER (
            PARTITION BY city_name, cuisine_type
            ORDER BY total_orders DESC
        ) AS hour_rank
    FROM hourly_orders
)
SELECT
    city_name,
    cuisine_type,
    order_hour                                       AS peak_hour_24h,
    CASE
        WHEN order_hour < 12 THEN CONCAT(order_hour, ':00 AM')
        WHEN order_hour = 12 THEN '12:00 PM'
        ELSE CONCAT(order_hour - 12, ':00 PM')
    END                                              AS peak_hour_label,
    total_orders
FROM ranked
WHERE hour_rank = 1
ORDER BY city_name, cuisine_type;

/*
  INSIGHT: Knowing peak hours per city and cuisine helps Swiggy
  pre-position delivery agents and offer targeted promotions
  (e.g., lunchtime discounts on Biryani in Bengaluru).
*/


-- ============================================================
-- QUERY 3: Impact of Delivery Time on Customer Rating
-- Business Question: Does longer delivery time lead to lower ratings?
--
-- Concepts: TIMESTAMPDIFF, CASE WHEN bucketing,
--           AVG aggregate, GROUP BY, CTE
-- ============================================================

WITH delivery_times AS (
    SELECT
        o.order_id,
        o.customer_rating,
        -- Calculate delivery duration in minutes
        TIMESTAMPDIFF(MINUTE, d.pickup_time, d.delivered_time) AS delivery_minutes
    FROM orders    o
    JOIN deliveries d ON d.order_id = o.order_id
    WHERE o.customer_rating IS NOT NULL
      AND d.pickup_time IS NOT NULL
      AND d.delivered_time IS NOT NULL
),
bucketed AS (
    SELECT
        order_id,
        customer_rating,
        delivery_minutes,
        -- Group deliveries into time buckets
        CASE
            WHEN delivery_minutes <= 20 THEN '1. Under 20 min'
            WHEN delivery_minutes <= 30 THEN '2. 21–30 min'
            WHEN delivery_minutes <= 45 THEN '3. 31–45 min'
            ELSE                              '4. Over 45 min'
        END AS delivery_bucket
    FROM delivery_times
)
SELECT
    delivery_bucket,
    COUNT(order_id)                          AS total_orders,
    ROUND(AVG(customer_rating), 2)           AS avg_customer_rating,
    ROUND(AVG(delivery_minutes), 1)          AS avg_delivery_minutes
FROM bucketed
GROUP BY delivery_bucket
ORDER BY delivery_bucket;

/*
  INSIGHT: A drop in avg_customer_rating for orders above 45 min
  confirms that slow delivery hurts satisfaction — Swiggy should
  enforce SLA alerts for agents when delivery approaches 40 min.
*/


-- ============================================================
-- QUERY 4: Customers at Churn Risk
-- Business Question: Which customers haven't ordered in the last
-- 30 days and had 3+ prior orders (high-value churn risk)?
--
-- Concepts: MAX aggregate, DATEDIFF, HAVING, Subquery,
--           CTE, CASE WHEN (risk segmentation)
-- ============================================================

WITH customer_activity AS (
    SELECT
        customer_id,
        COUNT(order_id)                                         AS total_orders,
        MAX(order_time)                                         AS last_order_date,
        ROUND(SUM(total_amount - discount_amount), 2)           AS total_spend
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
    HAVING COUNT(order_id) >= 3
),
churn_candidates AS (
    SELECT
        ca.customer_id,
        c.full_name,
        c.email,
        ci.city_name,
        ca.total_orders,
        ca.total_spend,
        ca.last_order_date,
        DATEDIFF('2024-03-10', ca.last_order_date) AS days_since_last_order
    FROM customer_activity ca
    JOIN customers c  ON c.customer_id = ca.customer_id
    JOIN cities    ci ON ci.city_id = c.city_id
)
SELECT
    full_name,
    email,
    city_name,
    total_orders,
    total_spend,
    last_order_date,
    days_since_last_order,
    -- Classify churn risk level
    CASE
        WHEN days_since_last_order BETWEEN 30 AND 44 THEN 'Medium Risk'
        WHEN days_since_last_order >= 45             THEN 'High Risk'
        ELSE 'Active'
    END AS churn_risk_level
FROM churn_candidates
WHERE days_since_last_order >= 30
ORDER BY days_since_last_order DESC, total_spend DESC;

/*
  INSIGHT: High-risk customers (45+ days inactive, 3+ orders) are
  ideal targets for win-back campaigns — a personalised coupon
  from their favourite restaurant can reactivate them cost-effectively.
*/


-- ============================================================
-- QUERY 5: Month-over-Month Revenue Growth by Cuisine
-- Business Question: How is revenue growing each month
-- across cuisine types?
--
-- Concepts: Window Function (LAG), CTE, DATE_FORMAT,
--           ROUND, CASE WHEN, GROUP BY
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_time, '%Y-%m')       AS order_month,
        r.cuisine_type,
        ROUND(
            SUM(o.total_amount - o.discount_amount), 2
        )                                         AS net_revenue
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_time, '%Y-%m'), r.cuisine_type
),
revenue_with_lag AS (
    SELECT
        order_month,
        cuisine_type,
        net_revenue,
        -- Pull prior month's revenue for the same cuisine
        LAG(net_revenue) OVER (
            PARTITION BY cuisine_type
            ORDER BY order_month
        ) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT
    order_month,
    cuisine_type,
    net_revenue,
    prev_month_revenue,
    -- Month-over-month change in absolute value
    ROUND(net_revenue - COALESCE(prev_month_revenue, 0), 2)  AS revenue_change,
    -- Month-over-month % growth (null for first month)
    CASE
        WHEN prev_month_revenue IS NULL OR prev_month_revenue = 0
            THEN NULL
        ELSE
            ROUND(
                ((net_revenue - prev_month_revenue) / prev_month_revenue) * 100, 1
            )
    END                                                       AS mom_growth_pct
FROM revenue_with_lag
ORDER BY cuisine_type, order_month;

/*
  INSIGHT: Cuisines with consistent positive MoM growth are worth
  promoting with banner ads. Cuisines showing decline need
  investigation — are restaurants closing, ratings dropping,
  or is a competitor taking share?
*/
