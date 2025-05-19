
import requests
import pandas as pd
from datetime import datetime
#from config.settings import settings


import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from config.settings import settings



class CoinGeckoDataFetcher:
    BASE_URL = "https://api.coingecko.com/api/v3"
    
    def __init__(self):
        self.session = requests.Session()
    
    def get_top_coins(self, limit=100):
        """Fetch top cryptocurrencies by market cap"""
        endpoint = f"{self.BASE_URL}/coins/markets"
        params = {
            'vs_currency': 'usd',
            'order': 'market_cap_desc',
            'per_page': limit,
            'page': 1,
            'sparkline': False
        }
        
        try:
            response = self.session.get(endpoint, params=params)
            response.raise_for_status()
            return pd.DataFrame(response.json())
        except requests.exceptions.RequestException as e:
            print(f"Error fetching data: {e}")
            return None
    
    def get_historical_data(self, coin_id, days='max'):
        """Fetch historical price data for a specific coin"""
        endpoint = f"{self.BASE_URL}/coins/{coin_id}/market_chart"
        params = {
            'vs_currency': 'usd',
            'days': days
        }
        
        try:
            response = self.session.get(endpoint, params=params)
            response.raise_for_status()
            data = response.json()
            
            # Convert to DataFrame
            prices = pd.DataFrame(data['prices'], columns=['timestamp', 'price'])
            prices['date'] = pd.to_datetime(prices['timestamp'], unit='ms')
            prices['coin_id'] = coin_id
            return prices
        except requests.exceptions.RequestException as e:
            print(f"Error fetching historical data: {e}")
            return None

if __name__ == "__main__":
    fetcher = CoinGeckoDataFetcher()
    top_coins = fetcher.get_top_coins(limit=10)
    print(top_coins.head())


