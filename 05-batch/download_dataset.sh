
set -e

TAXI_TYPE=$1 # "yellow"
YEAR=$2 # 2020

URL_PREFIX="https://github.com/DataTalksClub/nyc-tlc-data/releases/download"

for MONTH in {1..12}; do
  FMONTH=`printf "%02d" ${MONTH}`

  URL="${URL_PREFIX}/${TAXI_TYPE}/${TAXI_TYPE}_tripdata_${YEAR}-${FMONTH}.csv.gz"

  LOCAL_PREFIX="data/raw/${TAXI_TYPE}/${YEAR}/${FMONTH}"
  LOCAL_FILE="${TAXI_TYPE}_tripdata_${YEAR}_${FMONTH}.csv.gz"
  LOCAL_PATH="${LOCAL_PREFIX}/${LOCAL_FILE}"

  echo "downloading ${URL} to ${LOCAL_PATH}"
  mkdir -p ${LOCAL_PREFIX}
  wget ${URL} -O ${LOCAL_PATH}

done

#run "chmod +x download_dataset.sh" to make it executable inside bash
#then run "./download_dataset.sh yellow 2020" to download the yellow taxi data for 2020
#use "zcat data/raw/yellow/2021/01/yellow_tripdata_2021_01.csv.gz | head -m 10" to see the first 10 lines of the unzipped csv file
#use "zcat data/raw/yellow/2021/01/yellow_tripdata_2021_01.csv.gz | wc -l" to count the number of lines/rows in the unzipped csv file
#use "tree data" to see the directory structure of the data folder