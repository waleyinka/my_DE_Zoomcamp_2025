# Module 4 Homework

For this homework, the following datasets were used:

- Green Taxi dataset (2019 and 2020): 7,778,101 records
- Yellow Taxi dataset (2019 and 2020): 109,047,518 records
- For Hire Vehicle dataset (2019): 43,244,696 records

### Table of contents

- [Preparing dataset for FHV](#preparing-dataset-for-fhv)
- [Question 1](#question-1)
- [Question 2](#question-2)
- [Question 3](#question-3)
- [Question 4](#question-4)
- [Question 5](#question-5)
- [Question 6](#question-6)
- [Question 7](#question-7)



## Preparing dataset for FHV

- Upload dataset csv's into Google Cloud Storage Bucket

- Created external table for Yellow Datasets (ext_yellow_taxi) and Green Datasets (ext_green_taxi) inside BigQuery

- Create final table for FHV in BigQuery

## Question 1

**Understanding dbt model resolution**

Provided you've got the following sources.yaml:

```yaml

version: 2

sources:
  - name: raw_nyc_tripdata
    database: "{{ env_var('DBT_BIGQUERY_PROJECT', 'dtc_zoomcamp_2025') }}"
    schema:   "{{ env_var('DBT_BIGQUERY_SOURCE_DATASET', 'raw_nyc_tripdata') }}"
    tables:
      - name: ext_green_taxi
      - name: ext_yellow_taxi

```

with the following env variables setup where dbt runs:

```bash
export DBT_BIGQUERY_PROJECT=myproject
export DBT_BIGQUERY_DATASET=my_nyc_tripdata
```

What does this .sql model compile to?

```sql

select * 
from {{ source('raw_nyc_tripdata', 'ext_green_taxi' ) }}
```

**Resolution:**

- env_var('DBT_BIGQUERY_PROJECT', 'dtc_zoomcamp_2025') resolves to myproject.
- env_var('DBT_BIGQUERY_SOURCE_DATASET', 'raw_nyc_tripdata') resolves to raw_nyc_tripdata.

source('raw_nyc_tripdata', 'ext_green_taxi') will resolve to:

```myproject.raw_nyc_tripdata.ext_green_taxi```

The .sql model compiles to:

```select * from `myproject.raw_nyc_tripdata.ext_green_taxi` ```



## Question 2

**dbt Variables & Dynamic Models**

Say you have to modify the following dbt_model (fct_recent_taxi_trips.sql) to enable Analytics Engineers
to dynamically control the date range.

- In development, you want to process only the last 7 days of trips
- In production, you need to process the last 30 days for analytics

```sql

select *
from {{ ref('fact_taxi_trips') }}
where pickup_datetime >= CURRENT_DATE - INTERVAL '30' DAY

```

What would you change to accomplish that in a such way that command line arguments takes precedence 
over ENV_VARs, which takes precedence over DEFAULT value?

```sql

select *
from {{ ref('fact_taxi_trips') }}
where pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", env_var("DAYS_BACK", 30)) }}' DAY

```

- `var("days_back", ...)`: Looks for a command-line argument first.

- `env_var("DAYS_BACK", "30")`: If no command-line argument is found, it falls back to the DAYS_BACK environment variable.

- `"30"`: If neither is found, it defaults to 30 days.




## Question 3

**dbt Data Lineage and Execution**

Considering the data lineage below **and** that taxi_zone_lookup is the **only** materialization build (from a .csv seed file):

![image](./homework_q3.png)

Select the option that does NOT apply for materializing `fct_taxi_monthly_zone_revenue`:

*Explanation:*

✅ `dbt run`
Runs all models, so it applies for materializing fct_taxi_monthly_zone_revenue.

✅ `dbt run --select +models/core/dim_taxi_trips.sql+ --target prod`
The + before and after means it runs dim_taxi_trips and all its dependencies and dependents, which includes `fct_taxi_monthly_zone_revenue`.

✅ `dbt run --select +models/core/fct_taxi_monthly_zone_revenue.sql`
The + ensures dependencies `like dim_taxi_trips` are run, so this applies.

✅ `dbt run --select +models/core/`
Runs all models in core/, which includes `dim_taxi_trips` and `fct_taxi_monthly_zone_revenue`, so it applies.

❌ `dbt run --select models/staging/+`
This only runs staging models (`stg_green_tripdata`, `stg_yellow_tripdata`, etc.), not `fct_taxi_monthly_zone_revenue`.
Since `fct_taxi_monthly_zone_revenue` is in `core/`, this option does NOT apply.