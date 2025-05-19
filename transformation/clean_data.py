import pandas as pd
from datetime import datetime

class DataCleaner:
    @staticmethod
    def clean_market_data(df):
        """Clean and transform market data"""
        if df is None or df.empty:
            return None
            
        # Select relevant columns
        columns = ['id', 'symbol', 'name', 'current_price', 'market_cap', 
                  'total_volume', 'price_change_percentage_24h',
                  'circulating_supply', 'total_supply', 'last_updated']
        df = df[columns].copy()
        
        # Rename columns
        df.columns = ['coin_id', 'symbol', 'name', 'price_usd', 'market_cap_usd',
                     'volume_24h_usd', 'price_change_24h_pct', 
                     'circulating_supply', 'total_supply', 'last_updated']
        
        # Convert types
        df['last_updated'] = pd.to_datetime(df['last_updated'])
        numeric_cols = ['price_usd', 'market_cap_usd', 'volume_24h_usd',
                       'price_change_24h_pct', 'circulating_supply', 'total_supply']
        df[numeric_cols] = df[numeric_cols].apply(pd.to_numeric, errors='coerce')
        
        # Add metadata
        df['extracted_at'] = datetime.utcnow()
        
        return df
    
    @staticmethod
    def clean_historical_data(df):
        """Clean historical price data"""
        if df is None or df.empty:
            return None
            
        # Ensure we have the required columns
        if not all(col in df.columns for col in ['timestamp', 'price', 'date', 'coin_id']):
            raise ValueError("DataFrame missing required columns")
        
        # Convert types
        df['timestamp'] = pd.to_numeric(df['timestamp'])
        df['price'] = pd.to_numeric(df['price'])
        
        # Add metadata
        df['extracted_at'] = datetime.utcnow()
        
        return df
