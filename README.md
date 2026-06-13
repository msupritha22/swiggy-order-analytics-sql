#  Swiggy Order Analytics — SQL Project

A structured SQL analytics project simulating a food delivery platform (inspired by Swiggy). It covers database design, realistic data modelling, and intermediate-level business queries to extract actionable insights.

---

##  Project Structure

```
swiggy-sql-project/
│
├── schema.sql           # Table definitions & relationships
├── sample_data.sql      # ~200 rows of realistic Indian data
├── analysis_queries.sql # 5 business analysis queries
└── README.md
```

---

##  Database Schema

### Entity-Relationship Overview

```
cities ──< customers ──< orders >── restaurants ──< menu_items
                              │
                         order_items
                              │
                         deliveries >── delivery_agents
```

### Tables

| Table | Description | Rows |
|---|---|---|
| `cities` | Indian cities (Bengaluru, Mumbai, etc.) | 5 |
| `customers` | Registered Swiggy users | 30 |
| `restaurants` | Restaurants with cuisine & city info | 15 |
| `menu_items` | Items per restaurant with price & category | 30 |
| `orders` | Orders with status, amount, rating, payment | 60 |
| `order_items` | Line items linking orders to menu items | 90 |
| `delivery_agents` | Agents with vehicle type & city | 10 |
| `deliveries` | Pickup/delivery timestamps & distance | 50 |

##  Business Questions Answered

### Q1 — Repeat Order Rate per Restaurant
> *Which restaurants have the highest customer loyalty?*

**SQL Used:** CTE, GROUP BY, HAVING, CASE WHEN, ROUND
**Insight:** Restaurants with repeat rate > 50% are top loyalty candidates.

### Q2 — Peak Ordering Hour by City & Cuisine
> *When do customers order the most, by city and cuisine type?*

**SQL Used:** `HOUR()`, Window Function (`RANK`), CTE, multiple GROUP BY
**Insight:** Helps pre-position agents and trigger time-based promotions.

### Q3 — Impact of Delivery Time on Customer Rating
> *Does longer delivery time lead to lower ratings?*

**SQL Used:** `TIMESTAMPDIFF`, CASE WHEN bucketing, AVG, CTE
**Insight:** Identifies the delivery time threshold where ratings drop.

### Q4 — Customers at Churn Risk
> *Which high-value customers haven't ordered in 30+ days?*

**SQL Used:** `DATEDIFF`, MAX, HAVING, CTE, CASE WHEN risk segmentation
**Insight:** Win-back campaign target list with risk level classification.

---

### Q5 — Month-over-Month Revenue Growth by Cuisine
> *How is revenue trending each month across cuisine types?*

**SQL Used:** `LAG()` window function, `DATE_FORMAT`, CTE, COALESCE
**Insight:** Identifies growing vs declining cuisines for strategic decisions.

---

##  How to Run

1. Open MySQL Workbench (or any MySQL-compatible client)
2. Create a new database: `CREATE DATABASE swiggy_analytics;`
3. Select it: `USE swiggy_analytics;`
4. Run files in order:
   
   source schema.sql
   source sample_data.sql
   source analysis_queries.sql


> **Database:** MySQL 8.0+  
> **Compatibility:** Queries use `HOUR()`, `TIMESTAMPDIFF()`, `DATE_FORMAT()` — MySQL syntax.

---

## Key SQL Concepts Demonstrated

| Concept | Used In |
|---|---|
| CTEs (`WITH`) | Q1, Q2, Q3, Q4, Q5 |
| Window Functions (`RANK`, `LAG`) | Q2, Q5 |
| `CASE WHEN` bucketing & segmentation | Q2, Q3, Q4 |
| Date functions (`HOUR`, `DATEDIFF`, `TIMESTAMPDIFF`, `DATE_FORMAT`) | Q2, Q3, Q4, Q5 |
| Multi-table JOINs | All queries |
| Subqueries & `HAVING` | Q1, Q4 |
| `COALESCE` for null handling | Q5 |

---

## 🔗 Tools Used
- **MySQL 8.0** — query engine
- **MySQL Workbench** — development & testing
- **Draw.io** — ERD design (optional)



*Built as part of a Business Analyst & Data Analytics portfolio project.*
