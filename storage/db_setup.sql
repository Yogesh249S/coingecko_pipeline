-- Database setup for cryptocurrency data
/*
CREATE TABLE IF NOT EXISTS coins (
    coin_id VARCHAR(50) PRIMARY KEY,
    symbol VARCHAR(10),
    name VARCHAR(100),
    last_updated TIMESTAMP,
    extracted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS coin_market_data (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) REFERENCES coins(coin_id),
    price_usd DECIMAL(20, 6),
    market_cap_usd DECIMAL(30, 2),
    volume_24h_usd DECIMAL(30, 2),
    price_change_24h_pct DECIMAL(10, 4),
    circulating_supply DECIMAL(30, 2),
    total_supply DECIMAL(30, 2),
    extracted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS historical_prices (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) REFERENCES coins(coin_id),
    timestamp BIGINT,
    date TIMESTAMP,
    price DECIMAL(20, 6),
    extracted_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_historical_prices_coin_id ON historical_prices(coin_id);
CREATE INDEX IF NOT EXISTS idx_historical_prices_date ON historical_prices(date);


-- Updated database setup for cryptocurrency data with conflict resolution fixes

CREATE TABLE IF NOT EXISTS coins (
    coin_id VARCHAR(50) PRIMARY KEY,
    symbol VARCHAR(10),
    name VARCHAR(100),
    last_updated TIMESTAMP,
    extracted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS coin_market_data (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) REFERENCES coins(coin_id),
    price_usd DECIMAL(20, 6),
    market_cap_usd DECIMAL(30, 2),
    volume_24h_usd DECIMAL(30, 2),
    price_change_24h_pct DECIMAL(10, 4),
    circulating_supply DECIMAL(30, 2),
    total_supply DECIMAL(30, 2),
    extracted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS historical_prices (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) REFERENCES coins(coin_id),
    timestamp BIGINT,
    date TIMESTAMP,
    price DECIMAL(20, 6),
    extracted_at TIMESTAMP,
    -- Added unique constraint for upsert operations
    UNIQUE (coin_id, timestamp)
);

--ALTER TABLE historical_prices
--ADD CONSTRAINT unique_coin_date UNIQUE (coin_id, date);

ALTER TABLE historical_prices
ADD CONSTRAINT unique_coin_timestamp UNIQUE (coin_id, timestamp);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_historical_prices_coin_id ON historical_prices(coin_id);
CREATE INDEX IF NOT EXISTS idx_historical_prices_date ON historical_prices(date);

*/


-- new code 

-- Database setup for cryptocurrency data pipeline
-- Updated with proper unique constraints for upsert operations

-- Coin metadata table
CREATE TABLE IF NOT EXISTS coins (
    coin_id VARCHAR(50) PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    last_updated TIMESTAMP,
    extracted_at TIMESTAMP NOT NULL
);

-- Market data table
CREATE TABLE IF NOT EXISTS coin_market_data (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) REFERENCES coins(coin_id) ON DELETE CASCADE,
    price_usd DECIMAL(20, 6) NOT NULL,
    market_cap_usd DECIMAL(30, 2),
    volume_24h_usd DECIMAL(30, 2),
    price_change_24h_pct DECIMAL(10, 4),
    circulating_supply DECIMAL(30, 2),
    total_supply DECIMAL(30, 2),
    extracted_at TIMESTAMP NOT NULL
);

-- Historical prices table with embedded unique constraint
CREATE TABLE IF NOT EXISTS historical_prices (
    id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) REFERENCES coins(coin_id) ON DELETE CASCADE,
    timestamp BIGINT NOT NULL,
    date TIMESTAMP NOT NULL,
    price DECIMAL(20, 6) NOT NULL,
    extracted_at TIMESTAMP NOT NULL,
    CONSTRAINT unique_coin_timestamp UNIQUE (coin_id, timestamp)
);

-- Indexes for query optimization
CREATE INDEX IF NOT EXISTS idx_historical_coin_id ON historical_prices(coin_id);
CREATE INDEX IF NOT EXISTS idx_historical_date ON historical_prices(date);
