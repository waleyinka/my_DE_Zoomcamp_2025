{{
    config(
        materialized='view'
    )
}}

SELECT
    -- Surrogate trip ID (always generates a hash even if fields are NULL)
    TO_HEX(
        MD5(
            CAST(
                COALESCE(CAST(dispatching_base_num AS STRING), '_dbt_utils_surrogate_key_null_') 
                || '-' || 
                COALESCE(CAST(pickup_datetime AS STRING), '_dbt_utils_surrogate_key_null_') 
                AS STRING
            )
        )

    ) AS tripid,

    -- Base info
    dispatching_base_num,
    affiliated_base_number,

    -- Timestamps safely cast
    SAFE_CAST(pickup_datetime AS TIMESTAMP) AS pickup_datetime,
    SAFE_CAST(dropOff_datetime AS TIMESTAMP) AS dropoff_datetime,

    -- Date dimensions
    EXTRACT(YEAR FROM SAFE_CAST(pickup_datetime AS TIMESTAMP)) AS year,
    EXTRACT(MONTH FROM SAFE_CAST(pickup_datetime AS TIMESTAMP)) AS month,

    -- Location Info
    SAFE_CAST(PUlocationID AS INT64) AS pickup_locationid,
    SAFE_CAST(DOlocationID AS INT64) AS dropoff_locationid,

    -- Additional fields
    SAFE_CAST(sr_flag AS INT64) AS sr_flag

FROM {{ source('staging','fhv_tripdata') }}

-- WHERE dispatching_base_num IS NOT NULL

-- LIMIT 100  -- Limits preview rows for dbt
