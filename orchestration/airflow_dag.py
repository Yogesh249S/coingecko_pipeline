from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from ingestion.fetch_data import CoinGeckoDataFetcher
from transformation.clean_data import DataCleaner
from storage.db_operations import DatabaseManager

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

def fetch_and_store_data():
    # Initialize components
    fetcher = CoinGeckoDataFetcher()
    cleaner = DataCleaner()
    db_manager = DatabaseManager()
    
    try:
        # Fetch and store top coins
        market_data = fetcher.get_top_coins(limit=100)
        if market_data is not None:
            clean_market_data = cleaner.clean_market_data(market_data)
            if clean_market_data is not None:
                db_manager.insert_coins(clean_market_data[['coin_id', 'symbol', 'name', 'last_updated', 'extracted_at']])
                db_manager.insert_market_data(clean_market_data)
        
        # Fetch and store historical data for top 10 coins
        top_coin_ids = market_data['coin_id'].head(10).tolist()
        for coin_id in top_coin_ids:
            historical_data = fetcher.get_historical_data(coin_id, days='30')
            if historical_data is not None:
                clean_historical = cleaner.clean_historical_data(historical_data)
                if clean_historical is not None:
                    db_manager.insert_historical_prices(clean_historical)
    finally:
        db_manager.close()

with DAG(
    'coin_gecko_etl',
    default_args=default_args,
    description='ETL pipeline for CoinGecko API data',
    schedule_interval='@daily',
    catchup=False,
) as dag:
    
    run_etl = PythonOperator(
        task_id='run_coin_gecko_etl',
        python_callable=fetch_and_store_data,
    )

    run_etl
