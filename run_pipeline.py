from ingestion.fetch_data import CoinGeckoDataFetcher
from transformation.clean_data import DataCleaner
from storage.db_operations import DatabaseManager

def run_pipeline():
    # Initialize components
    fetcher = CoinGeckoDataFetcher()
    cleaner = DataCleaner()
    db_manager = DatabaseManager()
    
    try:
        print("Fetching market data...")
        market_data = fetcher.get_top_coins(limit=100)
        
        if market_data is not None:
            print("Cleaning market data...")
            clean_market_data = cleaner.clean_market_data(market_data)
            
            if clean_market_data is not None:
                print("Storing coin metadata...")
                db_manager.insert_coins(clean_market_data[['coin_id', 'symbol', 'name', 'last_updated', 'extracted_at']])
                
                print("Storing market data...")
                db_manager.insert_market_data(clean_market_data)
                
                # Fetch and store historical data for top 10 coins

                print(type(market_data))

                #-----
                #print(market_data if isinstance(market_data, dict) else market_data[0])
                #-------
                print(market_data if isinstance(market_data, dict) else market_data.iloc[0])



                #-----------
                #top_coin_ids = market_data['coin_id'].head(10).tolist()
                #----------

                if 'coin_id' in market_data.columns:
                    top_coin_ids = market_data['coin_id'].head(10).tolist()
                elif 'id' in market_data.columns:
                    top_coin_ids = market_data['id'].head(10).tolist()
                else:
                    print("No suitable coin identifier column found!")
                    top_coin_ids = []



                for coin_id in top_coin_ids:
                    print(f"Fetching historical data for {coin_id}...")
                    historical_data = fetcher.get_historical_data(coin_id, days='30')
                    
                    if historical_data is not None:
                        clean_historical = cleaner.clean_historical_data(historical_data)
                        if clean_historical is not None:
                            print(f"Storing historical data for {coin_id}...")
                            db_manager.insert_historical_prices(clean_historical)
        
        print("Pipeline completed successfully!")
    except Exception as e:
        print(f"Pipeline failed: {e}")
    finally:
        db_manager.close()

if __name__ == "__main__":
    run_pipeline()
