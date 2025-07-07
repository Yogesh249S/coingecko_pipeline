#!/bin/bash

# Cryptocurrency Data Pipeline Setup Script

set -e  # Exit on any error

echo "🚀 Setting up Cryptocurrency Data Pipeline..."

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p dags logs plugins spark-apps init-db data/checkpoints

# Create requirements file for Airflow
echo "📋 Creating requirements.txt..."
cat > requirements.txt << EOF
apache-airflow==2.7.1
kafka-python==2.0.2
requests==2.31.0
pandas==2.0.3
psycopg2-binary==2.9.7
cassandra-driver==3.28.0
pyspark==3.4.1
EOF

# Copy the SQL initialization script
echo "🗄️ Setting up database initialization..."
#cp 01-init-crypto-db.sql init-db/

# Create Airflow configuration
echo "⚙️ Creating Airflow configuration..."
mkdir -p config
cat > config/airflow.cfg << EOF
[core]
dags_folder = /opt/airflow/dags
base_log_folder = /opt/airflow/logs
logging_level = INFO
executor = CeleryExecutor
sql_alchemy_conn = postgresql+psycopg2://crypto_user:crypto_pass@postgres:5432/crypto_db
load_examples = False

[celery]
broker_url = redis://redis:6379/0
result_backend = db+postgresql://crypto_user:crypto_pass@postgres:5432/crypto_db

[webserver]
base_url = http://localhost:8080
web_server_port = 8080
EOF

# Create Spark application submission script
echo "⚡ Creating Spark submission script..."
#cat > spark-apps/submit_crypto_processor.sh << 'EOF'
#!/bin/bash

export USER=root
export HOME=/tmp

# Submit Spark streaming application
#spark-submit \
#    --master spark://spark-master:7077 \
#    --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0,com.datastax.spark:spark-cassandra-connector_2.12:3.4.0 \
#    --conf spark.cassandra.connection.host=cassandra \
#    --conf spark.cassandra.connection.port=9042 \
#    --conf spark.sql.adaptive.enabled=true \
#    --conf spark.sql.adaptive.coalescePartitions.enabled=true \
#    --conf spark.streaming.stopGracefullyOnShutdown=true \
#    --driver-memory 1g \
#    --executor-memory 2g \
#    --executor-cores 2 \
#    /opt/spark-apps/crypto_stream_processor.py
#EOF

docker exec -e USER=root -it  claude_coingecko-spark-master-1 spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.0,com.datastax.spark:spark-cassandra-connector_2.12:3.4.0 \
  --conf spark.jars.ivy=/tmp/.ivy2 \
  --conf spark.hadoop.fs.defaultFS=file:/// \
  --conf spark.cassandra.connection.host=cassandra \
  --conf spark.cassandra.connection.port=9042 \
  --conf spark.sql.adaptive.enabled=true \
  --conf spark.sql.adaptive.coalescePartitions.enabled=true \
  --conf spark.streaming.stopGracefullyOnShutdown=true \
  --driver-memory 1g \
  --executor-memory 2g \
  --executor-cores 2 \
  /opt/spark-apps/crypto_stream_processor.py



chmod +x spark-apps/submit_crypto_processor.sh

# Copy the Spark streaming application
cp crypto_stream_processor.py spark-apps/

# Copy the Airflow DAG
cp crypto_data_pipeline.py dags/

# Create Kafka topic creation script
echo "📡 Creating Kafka setup script..."
cat > setup_kafka.sh << 'EOF'
#!/bin/bash

echo "⏳ Waiting for Kafka to be ready..."
sleep 30

echo "📡 Creating Kafka topics..."

# Create crypto_prices topic with 3 partitions for load distribution
docker-compose exec kafka kafka-topics --create \
    --topic crypto_prices \
    --bootstrap-server localhost:9092 \
    --partitions 3 \
    --replication-factor 1 \
    --config retention.ms=604800000

# Create crypto_alerts topic for real-time alerts
docker-compose exec kafka kafka-topics --create \
    --topic crypto_alerts \
    --bootstrap-server localhost:9092 \
    --partitions 2 \
    --replication-factor 1 \
    --config retention.ms=86400000

# List created topics
echo "✅ Created topics:"
docker-compose exec kafka kafka-topics --list --bootstrap-server localhost:9092
EOF

chmod +x setup_kafka.sh

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > monitor_pipeline.sh << 'EOF'
#!/bin/bash

echo "🔍 Cryptocurrency Data Pipeline Status"
echo "======================================"

# Check Docker containers
echo "📦 Container Status:"
docker-compose ps

echo ""
echo "📡 Kafka Topics:"
docker-compose exec kafka kafka-topics --list --bootstrap-server localhost:9092 2>/dev/null || echo "Kafka not ready"

echo ""
echo "🗄️ Cassandra Status:"
docker-compose exec cassandra cqlsh -e "DESCRIBE KEYSPACES;" 2>/dev/null || echo "Cassandra not ready"

echo ""
echo "🌐 Service URLs:"
echo "- Airflow UI: http://localhost:8080 (admin/admin)"
echo "- Spark UI: http://localhost:8081"
echo "- Kafka: localhost:9092"
echo "- PostgreSQL: localhost:5432 (crypto_user/crypto_pass)"
echo "- Cassandra: localhost:9042"
EOF

chmod +x monitor_pipeline.sh

# Create data quality check script
echo "🔬 Creating data quality check script..."
cat > check_data_quality.py << 'EOF'
#!/usr/bin/env python3

import psycopg2
from cassandra.cluster import Cluster
import json
from datetime import datetime, timedelta

def check_postgresql_data():
    """Check PostgreSQL data quality"""
    try:
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            database='crypto_db',
            user='crypto_user',
            password='crypto_pass'
        )
        
        cur = conn.cursor()
        
        # Check recent pipeline runs
        cur.execute("""
            SELECT COUNT(*) as total_runs,
                   COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_runs,
                   MAX(end_time) as latest_run
            FROM crypto_analytics.pipeline_runs 
            WHERE execution_date >= NOW() - INTERVAL '24 hours'
        """)
        
        result = cur.fetchone()
        print(f"📊 Pipeline Runs (24h): {result[0]} total, {result[1]} successful")
        print(f"🕐 Latest run: {result[2]}")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ PostgreSQL check failed: {e}")

def check_cassandra_data():
    """Check Cassandra data quality"""
    try:
        cluster = Cluster(['localhost'])
        session = cluster.connect('crypto_data')
        
        # Check recent data
        rows = session.execute("""
            SELECT coin_id, COUNT(*) as record_count 
            FROM crypto_prices 
            WHERE timestamp >= ? 
            GROUP BY coin_id
        """, [datetime.now() - timedelta(hours=1)])
        
        print("📈 Recent Data (1h):")
        for row in rows:
            print(f"  {row.coin_id}: {row.record_count} records")
        
        session.shutdown()
        cluster.shutdown()
        
    except Exception as e:
        print(f"❌ Cassandra check failed: {e}")

if __name__ == "__main__":
    print("🔬 Data Quality Check")
    print("====================")
    check_postgresql_data()
    print()
    check_cassandra_data()
EOF

chmod +x check_data_quality.py

# Create cleanup script
echo "🧹 Creating cleanup script..."
cat > cleanup.sh << 'EOF'
#!/bin/bash

echo "🧹 Cleaning up Cryptocurrency Data Pipeline..."

# Stop and remove containers
docker-compose down -v

# Remove created directories (optional)
read -p "🗑️ Remove data directories? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf logs/* data/* 
    echo "✅ Data directories cleaned"
fi

echo "✅ Cleanup completed"
EOF

chmod +x cleanup.sh

# Create main startup script
echo "🎯 Creating main startup script..."
cat > start_pipeline.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Cryptocurrency Data Pipeline..."

# Start all services
echo "📦 Starting Docker containers..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 60

# Setup Kafka topics
echo "📡 Setting up Kafka topics..."
./setup_kafka.sh

echo "⚡ Starting Spark streaming job..."
docker-compose exec spark-master /opt/spark-apps/submit_crypto_processor.sh &

echo "✅ Pipeline started successfully!"
echo ""
echo "🌐 Access URLs:"
echo "- Airflow UI: http://localhost:8080 (admin/admin)"
echo "- Spark UI: http://localhost:8081"
echo ""
echo "📊 Monitor with: ./monitor_pipeline.sh"
echo "🔬 Check data quality with: python3 check_data_quality.py"
echo "🛑 Stop with: docker-compose down"
EOF

chmod +x start_pipeline.sh

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "1. Start the pipeline: ./start_pipeline.sh"
echo "2. Monitor status: ./monitor_pipeline.sh"  
echo "3. Check data quality: python3 check_data_quality.py"
echo "4. Access Airflow UI: http://localhost:8080 (admin/admin)"
echo ""
echo "📋 Key files created:"
echo "- docker-compose.yml: Container orchestration"
echo "- dags/crypto_data_pipeline.py: Airflow DAG"
echo "- spark-apps/crypto_stream_processor.py: Spark streaming app"
echo "- init-db/01-init-crypto-db.sql: Database initialization"
echo ""
echo "🎉 Happy data engineering!"
