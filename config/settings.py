import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Database configuration
    DB_NAME = os.getenv("DB_NAME", "coingecko_db")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "witcher#571")
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    
    # API configuration
    COIN_GECKO_API_URL = "https://api.coingecko.com/api/v3"
    REQUEST_TIMEOUT = 30

settings = Settings()
