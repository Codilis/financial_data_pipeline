zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties &
echo "Zookeeper Started";
kafka-server-start.sh /opt/kafka/config/server.properties &
echo "Server Started 1";
kafka-server-start.sh /opt/kafka/config/server-1.properties &
echo "Server Started 2";
kafka-server-start.sh /opt/kafka/config/server-2.properties &
echo "Server Started 3";
kafka-topics.sh --create --topic transaction_stream --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1;