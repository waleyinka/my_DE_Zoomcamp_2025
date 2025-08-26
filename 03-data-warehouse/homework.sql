# IMPORTANT NOTE:

For this homework we will be using the Yellow Taxi Trip Records for January 2024 - June 2024 NOT the entire year of data Parquet Files from the
New York City Taxi Data found here: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
If you are using orchestration such as Kestra, Mage, Airflow or Prefect etc. do not load the data into Big Query using the orchestrator.
Stop with loading the files into a bucket.

# BIG QUERY SETUP:
Create an external table using the Yellow Taxi Trip Records.
Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table)

-- CREATE AN EXTERNAL TABLE USING THE PARQUET TAXI TRIP RECORDS IN GOOGLE CLOUD STORAGE BUCKET
CREATE OR REPLACE EXTERNAL TABLE `my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://my-de-zoomcamp-469910-bucket/yellow_tripdata_2024-*.parquet', 'gs://my-de-zoomcamp-469910-bucket/yellow_tripdata_2024-*.parquet']
);


-- CREATE A REGULAR/MATERIALIZED TABLE USING THE PARQUET TAXI TRIP RECORDS IN GOOGLE CLOUD STORAGE BUCKET
CREATE OR REPLACE TABLE `my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_materialized`
AS
SELECT *
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_external;




-- QUESTION 1: WHAT IS COUNT OF RECORDS FOR THE 2024 YELLOW TAXI DATA?
SELECT COUNT(*)
FROM
  #USING EITHER THE MATERIALIZED TABLE OR EXTERNAL
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_external;

-- ANSWER: 20332093




-- QUESTION 2i: WRITE A QUERY TO COUNT DISTINCT NUMBER OF PULocationIDs FOR THE ENTIRE DATASET ON BOTH THE TABLES (EXT. & MAT.),WHAT IS THE ESTIMATED AMOUNT OF DATA THAT WILL BE READ WHEN THIS QUERY IS EXECUTED ON BOTH TABLES (EXT. & MAT.)

#FOR EXTERNAL TABLE
SELECT COUNT(PULocationID)
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_external;
-- ANSWER: This query will process 0B on EXTERNAL TABLE when run.

#FOR MATERIALIZED TABLE
SELECT COUNT(PULocationID)
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_materialized;
-- ANSWER: This query will process 155.12B on MATERIALIZED TABLE when run.




-- QUESTION 3: WRITE A QUERY TO RETRIEVE THE PULocationID FROM THE TABLE (NO THE EXTERNAL TABLE) IN BIGQUERY. NOW WRITE A QUERY TO RETIREVE THE PULocationID AND DOLocationID ON THE SAME TABLE. WHY ARE THE ESTIMATED NUMBER OF BYTES DIFFERENT?

SELECT PULocationID
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_materialized;
  --This query will process 155.12 MB when run.

SELECT
  PULocationID,
  DOLocationID
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_materialized;
  --This query will process 310.24 MB when run.

-- ANSWER: BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID)requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.




-- QUESTION 4: HOW MANY RECORDS HAVE A fare_amount OF 0

SELECT COUNT(*)
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_materialized
WHERE fare_amount = 0;
-- ANSWER: 8333 records




-- QUESTION 5: WHAT IS THE BEST STRATEGY TO MAKE OPTIMIZED TABLE IN BIGQUERY IF YOUR QUERY WILL ALWAYS FILTER BASED ON tpep_dropoff_datetime AND order THE RESULTS BY VendorID (CREATE A NEW TABLE WITH THIS STRATEGY)

CREATE OR REPLACE TABLE my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_part_clust
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * FROM my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_external;
-- ANSWER: Partition by tpep_dropoff_datetime and Cluster on VendorID




-- QUESTION 6: WRITE A QUERY TO RETRIEVE THE DISTINCT VendorIDs BETWEEN tpep_dropoff_datetime 2024-03-01 AND 2024-03-15(INCLUSIVE). USE THE MATERIALIZED TABLE YOU CREATED EARLIER IN YOUR FROM CLAUSE AND NOTE THE ESTIMATED BYTES. NOW CHANGE THE TABLE IN THE FROM CLAUSE TO THE PARTITIONED TABLE YOU CREATED FOR QUESTION 5 AND NOTE THE ESTIMATED BYTES PROCESSED. WHAT ARE THESE VALUES?

SELECT DISTINCT VendorID
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_materialized
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';
--ANSWER: This query will process 310.24 MB when run.

SELECT DISTINCT VendorID
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_part_clust
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';
--ANSWER: This query will process 26.84 MB when run.




-- QUESTION 7: WHERE IS THE DATA STORED IN EXTERNAL TABLE YOU CREATED?
--ANSWER: GCP Bucket




-- QUESTION 8: IT IS THE BEST PRACTICE IN BIG QUERY TO ALWAYS CLUSTER YOUR DATA:
-- ANSWER: False




-- QUESTION 9: WRITE A SELECT COUNT(*) QUERY FROM THE MATERIALIZED TABLE YOU CREATED. HOW MANY BYTES DOES IT ESTIMATES WILL BE READ? WHY?

SELECT COUNT(*)
FROM
  my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_materialized;
--ANSWER: This query will process 0 B when run. Because the record dataset is in metadata and stored inside GCP Bucket