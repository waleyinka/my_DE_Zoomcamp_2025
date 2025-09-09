**1. Create a new model `fct_taxi_trips_quarterly_revenue.sql`**

- First, we will go to dbt and edit the file [`dm_monthly_zone_revenue`](../../04_analytics_engineering/taxi_rides_ny/models/core/dm_monthly_zone_revenue.sql) by adding new date formats, to help our calculations. Don't forget to add the `group by` at the end.

```sql
{{ config(materialized='table') }}

with trips_data as (
    select *,
        EXTRACT(YEAR FROM pickup_datetime) AS year,
        EXTRACT(QUARTER FROM pickup_datetime) AS quarter,
        EXTRACT(MONTH FROM pickup_datetime) AS month,
        CONCAT(EXTRACT(YEAR FROM pickup_datetime), '/Q', EXTRACT(QUARTER FROM pickup_datetime)) AS year_quarter

    from {{ ref('fact_trips') }}
)
    select 
    -- Reveneue grouping
    pickup_zone as revenue_zone,
    {{ dbt.date_trunc("month", "pickup_datetime") }} as revenue_month,

    service_type,

    -- Add new date components
    year,
    quarter,
    month,
    year_quarter,

    -- Revenue calculation
    sum(fare_amount) as revenue_monthly_fare,
    sum(extra) as revenue_monthly_extra,
    sum(mta_tax) as revenue_monthly_mta_tax,
    sum(tip_amount) as revenue_monthly_tip_amount,
    sum(tolls_amount) as revenue_monthly_tolls_amount,
    sum(ehail_fee) as revenue_monthly_ehail_fee,
    sum(improvement_surcharge) as revenue_monthly_improvement_surcharge,
    sum(total_amount) as revenue_monthly_total_amount,

    -- Additional calculations
    count(tripid) as total_monthly_trips,
    avg(passenger_count) as avg_monthly_passenger_count,
    avg(trip_distance) as avg_monthly_trip_distance

    from trips_data
    group by 1,2,3, 4, 5, 6, 7

```


- The, we will go to dbt, create a file `fct_taxi_trips_quarterly_revenue.sql` inside `models/core` directory.

- At the beginning of the file, set the materialization type:

``` sql
{{
    config(
        materialized='table'
    )
}}
```


- Since the existing model [`dm_monthly_zone_revenue`](../../04_analytics_engineering/taxi_rides_ny/models/core/dm_monthly_zone_revenue.sql) already unifies and enriches the data, we will use it as a reference instead of staging models:

```sql
WITH quarterly_revenue AS (
    SELECT
        year,
        quarter,
        year_quarter,
        service_type,
        SUM(revenue_monthly_total_amount) AS total_revenue
    FROM {{ ref('dm_monthly_zone_revenue') }}
    GROUP BY 1, 2, 3, 4
),

```

**2. Compute the Quarterly Revenues for each year for based on `total_amount`**
**3. Compute the Quarterly YoY (Year-over-Year) revenue growth**

Append to the file [`fct_taxi_trips_quarterly_revenue.sql`](../../04_analytics_engineering/taxi_rides_ny/models/core/fct_taxi_trips_quarterly_revenue.sql):


```sql
yoy_revenue AS (
    SELECT
        qr.year,
        qr.quarter,
        qr.year_quarter,
        qr.service_type,
        qr.total_revenue,
        LAG(qr.total_revenue) OVER (
            PARTITION BY qr.service_type, qr.quarter
            ORDER BY qr.year
        ) AS prev_year_revenue,
        ROUND(
            (qr.total_revenue - LAG(qr.total_revenue) OVER (
                PARTITION BY qr.service_type, qr.quarter
                ORDER BY qr.year
            )) / NULLIF(LAG(qr.total_revenue) OVER (
                PARTITION BY qr.service_type, qr.quarter
                ORDER BY qr.year
            ), 0) * 100, 2
        ) AS yoy_growth
    FROM quarterly_revenue qr
)

SELECT
    year,
    quarter,
    year_quarter,
    service_type,
    total_revenue,         -- Aggregated revenue (correct comparison)
    prev_year_revenue,     -- Revenue from the same quarter in the previous year
    yoy_growth             -- Correct YoY Growth after aggregation
FROM yoy_revenue

```

Our lineage graph will look like this:

<img scr="lineage_q5.png" width="80%">

**Considering the YoY Growth in 2020, which were the yearly quarters with the best (or less worse) and worst results for green, and yellow:**

>> green: {best: 2020/Q1, worst: 2020/Q2}, yellow: {best: 2020/Q1, worst: 2020/Q2}

*Explanation*

Run in BigQuery:

```sql
SELECT yoy_growth, year, quarter, service_type, total_revenue, prev_year_revenue
FROM `your_project.your_schema.fct_taxi_trips_quarterly_revenue` 
WHERE year=2020
ORDER BY yoy_growth DESC
LIMIT 10

```

The result makes sense, considering we had COVID during the period.