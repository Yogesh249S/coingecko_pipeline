'''
import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_batch

import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config.settings import settings

class DatabaseManager:
    def __init__(self):
        self.conn = None
        self.connect()
    
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = psycopg2.connect(
                dbname=settings.DB_NAME,
                user=settings.DB_USER,
                password=settings.DB_PASSWORD,
                host=settings.DB_HOST,
                port=settings.DB_PORT
            )
        except Exception as e:
            print(f"Error connecting to database: {e}")
            raise
    
    def insert_coins(self, coins_df):
        """Insert coin metadata into database"""
        query = """
            INSERT INTO coins (coin_id, symbol, name, last_updated, extracted_at)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (coin_id) DO UPDATE SET
                symbol = EXCLUDED.symbol,
                name = EXCLUDED.name,
                last_updated = EXCLUDED.last_updated,
                extracted_at = EXCLUDED.extracted_at
        """
        
        try:
            with self.conn.cursor() as cur:
                execute_batch(cur, query, coins_df[['coin_id', 'symbol', 'name', 'last_updated', 'extracted_at']].values.tolist())
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            print(f"Error inserting coins: {e}")
            raise
    
    def insert_market_data(self, market_data_df):
        """Insert market data into database"""
        query = """
            INSERT INTO coin_market_data (
                coin_id, price_usd, market_cap_usd, volume_24h_usd,
                price_change_24h_pct, circulating_supply, total_supply, extracted_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        try:
            with self.conn.cursor() as cur:
                execute_batch(cur, query, market_data_df[[
                    'coin_id', 'price_usd', 'market_cap_usd', 'volume_24h_usd',
                    'price_change_24h_pct', 'circulating_supply', 'total_supply', 'extracted_at'
                ]].values.tolist())
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            print(f"Error inserting market data: {e}")
            raise
    
    def insert_historical_prices(self, prices_df):
        """Insert historical price data into database"""
        query = """
            INSERT INTO historical_prices (coin_id, timestamp, date, price, extracted_at)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (coin_id, timestamp) DO NOTHING
        """
        
        try:
            with self.conn.cursor() as cur:
                execute_batch(cur, query, prices_df[['coin_id', 'timestamp', 'date', 'price', 'extracted_at']].values.tolist())
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            print(f"Error inserting historical prices: {e}")
            raise
    
    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
'''

import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_batch

import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from config.settings import settings

class DatabaseManager:
    def __init__(self):
        self.conn = None
        self.connect()
    
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = psycopg2.connect(
                dbname=settings.DB_NAME,
                user=settings.DB_USER,
                password=settings.DB_PASSWORD,
                host=settings.DB_HOST,
                port=settings.DB_PORT
            )
        except Exception as e:
            print(f"Error connecting to database: {e}")
            raise
    
    def insert_coins(self, coins_df):
        """Insert coin metadata into database"""
        query = """
            INSERT INTO coins (coin_id, symbol, name, last_updated, extracted_at)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (coin_id) DO UPDATE SET
                symbol = EXCLUDED.symbol,
                name = EXCLUDED.name,
                last_updated = EXCLUDED.last_updated,
                extracted_at = EXCLUDED.extracted_at
        """
        
        try:
            with self.conn.cursor() as cur:
                execute_batch(cur, query, coins_df[['coin_id', 'symbol', 'name', 'last_updated', 'extracted_at']].values.tolist())
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            print(f"Error inserting coins: {e}")
            raise
    
    def insert_market_data(self, market_data_df):
        """Insert market data into database"""
        query = """
            INSERT INTO coin_market_data (
                coin_id, price_usd, market_cap_usd, volume_24h_usd,
                price_change_24h_pct, circulating_supply, total_supply, extracted_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                price_usd = EXCLUDED.price_usd,
                market_cap_usd = EXCLUDED.market_cap_usd,
                volume_24h_usd = EXCLUDED.volume_24h_usd,
                price_change_24h_pct = EXCLUDED.price_change_24h_pct,
                circulating_supply = EXCLUDED.circulating_supply,
                total_supply = EXCLUDED.total_supply,
                extracted_at = EXCLUDED.extracted_at
        """
        
        try:
            with self.conn.cursor() as cur:
                execute_batch(cur, query, market_data_df[[
                    'coin_id', 'price_usd', 'market_cap_usd', 'volume_24h_usd',
                    'price_change_24h_pct', 'circulating_supply', 'total_supply', 'extracted_at'
                ]].values.tolist())
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            print(f"Error inserting market data: {e}")
            raise
    
    def insert_historical_prices(self, prices_df):
        """Insert historical price data into database"""
        query = """
            INSERT INTO historical_prices (coin_id, timestamp, date, price, extracted_at)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT ON CONSTRAINT unique_coin_timestamp DO NOTHING
        """
        
        try:
            with self.conn.cursor() as cur:
                execute_batch(cur, query, prices_df[['coin_id', 'timestamp', 'date', 'price', 'extracted_at']].values.tolist())
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            print(f"Error inserting historical prices: {e}")
            raise
    
    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
