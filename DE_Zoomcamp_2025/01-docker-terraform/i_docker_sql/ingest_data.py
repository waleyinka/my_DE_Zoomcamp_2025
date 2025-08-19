"""
#!/usr/bin/env python
# coding: utf-8


import argparse, os, sys
from time import time
import pandas as pd 
import pyarrow.parquet as pq
from sqlalchemy import create_engine


def main(params):

    user = params.user
    password = params.password
    host = params.host
    port = params.port
    db = params.db
    tb = params.tb
    url = params.url
    
    # Get the name of the file from url
    file_name = url.rsplit('/', 1)[-1].strip()
    print(f'Downloading {file_name} ...')
    # Download file from url
    os.system(f'curl {url.strip()} -o {file_name}')
    print('\n')

    # Create SQL engine
    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{db}')

    # Read file based on csv or parquet
    if '.csv' in file_name:
        df = pd.read_csv(file_name, nrows=10)
        df_iter = pd.read_csv(file_name, iterator=True, chunksize=100000)
    elif '.parquet' in file_name:
        file = pq.ParquetFile(file_name)
        df = next(file.iter_batches(batch_size=10)).to_pandas()
        df_iter = file.iter_batches(batch_size=100000)
    else: 
        print('Error. Only .csv or .parquet files allowed.')
        sys.exit()


    # Create the table
    df.head(0).to_sql(name=tb, con=engine, if_exists='replace')


    # Insert values
    t_start = time()
    count = 0
    for batch in df_iter:
        count+=1

        if '.parquet' in file_name:
            batch_df = batch.to_pandas()
        else:
            batch_df = batch

        print(f'inserting batch {count}...')

        b_start = time()
        batch_df.to_sql(name=tb, con=engine, if_exists='append')
        b_end = time()

        print(f'inserted! time taken {b_end-b_start:10.3f} seconds.\n')
        
    t_end = time()   
    print(f'Completed! Total time taken was {t_end-t_start:10.3f} seconds for {count} batches.')    



if __name__ == '__main__':
    #Parsing arguments 
    parser = argparse.ArgumentParser(description='Loading data from .paraquet file link to a Postgres datebase.')

    parser.add_argument('--user', help='Username for Postgres.')
    parser.add_argument('--password', help='Password to the username for Postgres.')
    parser.add_argument('--host', help='Hostname for Postgres.')
    parser.add_argument('--port', help='Port for Postgres connection.')
    parser.add_argument('--db', help='Databse name for Postgres')
    parser.add_argument('--tb', help='Destination table name for Postgres.')
    parser.add_argument('--url_parquet', help='URL for .paraquet file.')
    parser.add_argument('--url_csv', help='URL for CSV file.')

    args = parser.parse_args()
    main(args)
"""

#!/usr/bin/env python
# coding: utf-8

import argparse
import os
import sys
from time import time
import pandas as pd
import pyarrow.parquet as pq
from sqlalchemy import create_engine


def ingest_file(url, engine, base_table_name):
    file_name = url.rsplit('/', 1)[-1].strip()
    print(f'Downloading {file_name} ...')
    os.system(f'curl {url} -o "{file_name}"')
    print()

    if file_name.endswith('.csv'):
        df = pd.read_csv(file_name, nrows=10)
        df_iter = pd.read_csv(file_name, iterator=True, chunksize=100000)
        table_name = f"{base_table_name}_csv"
    elif file_name.endswith('.parquet'):
        file = pq.ParquetFile(file_name)
        df = next(file.iter_batches(batch_size=10)).to_pandas()
        df_iter = file.iter_batches(batch_size=100000)
        table_name = f"{base_table_name}_parquet"
    else:
        print('Error: Only .csv or .parquet files allowed.')
        sys.exit(1)

    print(f'Creating table {table_name}...')
    df.head(0).to_sql(name=table_name, con=engine, if_exists='replace')

    t_start = time()
    count = 0
    for batch in df_iter:
        count += 1
        batch_df = batch.to_pandas() if file_name.endswith('.parquet') else batch

        print(f'Inserting batch {count} into {table_name}...')
        b_start = time()
        batch_df.to_sql(name=table_name, con=engine, if_exists='append')
        b_end = time()
        print(f'Inserted batch {count} in {b_end - b_start:.3f} seconds.\n')

    t_end = time()
    print(f'Completed ingestion of {file_name}. Total time: {t_end - t_start:.3f} seconds for {count} batches.\n')


def main(params):
    # Create SQL engine
    engine = create_engine(f'postgresql://{params.user}:{params.password}@{params.host}:{params.port}/{params.db}')

    if params.url_csv:
        ingest_file(params.url_csv, engine, params.tb)
    if params.url_parquet:
        ingest_file(params.url_parquet, engine, params.tb)

    if not params.url_csv and not params.url_parquet:
        print("Error: Please provide at least one URL (--url_csv or --url_parquet).")
        sys.exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Load CSV and/or Parquet files into Postgres.')

    parser.add_argument('--user', required=True, help='Username for Postgres.')
    parser.add_argument('--password', required=True, help='Password for Postgres user.')
    parser.add_argument('--host', required=True, help='Postgres host.')
    parser.add_argument('--port', required=True, help='Postgres port.')
    parser.add_argument('--db', required=True, help='Postgres database name.')
    parser.add_argument('--tb', required=True, help='Base table name for Postgres.')
    parser.add_argument('--url_csv', help='URL to CSV file.')
    parser.add_argument('--url_parquet', help='URL to Parquet file.')

    args = parser.parse_args()
    main(args)
