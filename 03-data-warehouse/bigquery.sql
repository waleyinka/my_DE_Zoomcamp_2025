-- Query public available table
SELECT station_id, name
FROM bigquery-public-data.new_york_citibike.citibike_stations
LIMIT 100;


-- Creating external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `my-de-zoomcamp-469910.de_zoomcamp.external_yellow_tripdata`
OPTIONS (
  format = 'CSV',
  uris = ['gs://my-de-zoomcamp-469910-bucket/yellow_tripdata_2019-*.csv', 'gs://my-de-zoomcamp-469910-bucket/yellow_tripdata_2019-*.csv']
);


-- Check the external yellow trip data tabel
SELECT * 
FROM my-de-zoomcamp-469910.de_zoomcamp.external_yellow_tripdata
LIMIT 10;


-- Create a non-partitioned table from the external table
CREATE OR REPLACE TABLE my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_non_partitioned AS
SELECT * FROM my-de-zoomcamp-469910.de_zoomcamp.external_yellow_tripdata;


-- Create a partitioned table from the external table
CREATE OR REPLACE TABLE my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_partitioned
PARTITION BY
  DATE(tpep_pickup_datetime) AS
SELECT * FROM my-de-zoomcamp-469910.de_zoomcamp.external_yellow_tripdata;


-- Impact of partition
-- This query took 1.26GB of Data to run, 672ms Elapsed time and  31s Slot time consumed
SELECT DISTINCT(VendorID)
FROM my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_non_partitioned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2019-06-30';


-- This query took 105.91MB of Data to run, 290ms Elapsed time and  2s Slot time consumed
SELECT DISTINCT(VendorID)
FROM my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_partitioned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2019-06-30';


-- Let's look into the partitions to see how many rows falls into each partition
SELECT table_name, partition_id, total_rows
FROM `de_zoomcamp.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_tripdata_partitioned'
ORDER BY total_rows DESC;


-- Creating a partition and cluster table
CREATE OR REPLACE TABLE my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_partitioned_clustered
PARTITION BY DATE(tpep_pickup_datetime)
CLUSTER BY VendorID AS
SELECT * FROM my-de-zoomcamp-469910.de_zoomcamp.external_yellow_tripdata;


-- Partition vs Clustered_Partition
-- This query took 713.46MB of Data to run.
SELECT COUNT(*) as trips
FROM my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_partitioned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2020-12-31'
  AND VendorID=1;


-- This query took 564.49MB of Data to run.
SELECT COUNT(*) as trips
FROM my-de-zoomcamp-469910.de_zoomcamp.yellow_tripdata_partitioned_clustered
WHERE DATE(tpep_pickup_datetime) BETWEEN '2019-06-01' AND '2020-12-31'
  AND VendorID=1;
