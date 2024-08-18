from pyspark.sql import SparkSession
import os

kafka_topic = os.environ.get("KAFKA_TOPIC", '')
checkpoint_location = f"/checkpoint/dev/financial_data_pipeline/{kafka_topic}/"

spark = SparkSession.builder \
    .appName("KafkaToHadoopStreaming") \
    .config("spark.sql.streaming.checkpointLocation", checkpoint_location) \
    .getOrCreate()

# schema for the incoming data
schema = """
    id LONG,
    account_id STRING,
    date DATE,
    type STRING,
    operation STRING,
    amount DOUBLE,
    balance DOUBLE,
    k_symbol STRING,
    bank STRING,
    account LONG
"""

# Read from Kafka
df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "localhost:9092") \
    .option("subscribe", kafka_topic) \
    .load()

# Define the schema of the data (if known) and cast the value to string
parsed_df = df.selectExpr("CAST(value AS STRING)") \
    .selectExpr("CAST(value AS STRING) as json") \
    .selectExpr("from_json(json, '{}') as data".format(schema)) \
    .select("data.*")

# Write the stream to HDFS in csv format
query = parsed_df.writeStream \
    .outputMode("append") \
    .format("parquet") \
    .option("path", "/user/root/data/transactions") \
    .option("checkpointLocation", checkpoint_location) \
    .start()

query.awaitTermination()
