#!/bin/bash
set -e

zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties &
echo "Zookeeper Started";
kafka-server-start.sh /opt/kafka/config/server.properties &
echo "Server Started 1";
kafka-topics.sh --create --topic transaction_stream --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1;
nohup spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.2 /src/kafka_streams/consumer.py &