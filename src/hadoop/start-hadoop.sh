#!/bin/bash
set -e

ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa;
cat /root/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys;
service ssh start;
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
export HDFS_NAMENODE_USER="root";
export HDFS_DATANODE_USER="root";
export HDFS_SECONDARYNAMENODE_USER="root";
export YARN_RESOURCEMANAGER_USER="root";
export YARN_NODEMANAGER_USER="root";
hdfs namenode -format;
$HADOOP_HOME/sbin/start-dfs.sh;
$HADOOP_HOME/sbin/start-yarn.sh;
hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/root
$SPARK_HOME/sbin/start-thriftserver.sh --master local[*]
sh /hadoop/load-data.sh
rm -rf /data
rm -rf /hadoop
