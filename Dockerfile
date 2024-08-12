# Use an official Python runtime as a parent image
FROM python:3.9-bullseye

# Set environment variables
ENV SPARK_VERSION=3.5.1 \
	SPARK_HADOOP_VERSION=3 \
	HADOOP_VERSION=3.3.6 \
	HADOOP_HOME=/opt/hadoop \
	JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
	SPARK_HOME=/opt/spark

# Install Java (required for Spark)
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	sudo \
	curl \
	vim \
	unzip \
	rsync \
	openjdk-11-jdk \
	build-essential \
	software-properties-common \
	ssh && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN curl https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -o hadoop.tar.gz
RUN curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz -o spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz
RUN wget http://www.nano-editor.org/dist/v2.4/nano-2.4.2.tar.gz

# Install dbt-core and dbt-spark
RUN pip install --no-cache-dir dbt-core==1.8.5 dbt-spark==1.8.0 markupsafe==2.0.1

# Install nano
RUN tar -xzf nano-2.4.2.tar.gz
WORKDIR /nano-2.4.2
RUN ./configure
RUN make
RUN make install
WORKDIR /
RUN rm nano-2.4.2.tar.gz


# Install Hadoop
RUN mkdir -p /opt
RUN tar -xzf hadoop.tar.gz && \
	mv hadoop-${HADOOP_VERSION} /opt && \
	mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
	rm hadoop.tar.gz	

	
# Install Spark
RUN mkdir -p /opt/spark
RUN tar xvf spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz --directory /opt/spark --strip-components 1 && \
	rm spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz

RUN mkdir -p /opt/hadoop/logs	


# Set Spark environment variables
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV HADOOP_HOME="/opt/hadoop"

ENV HADOOP_INSTALL=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin

ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"


COPY config/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY config/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY config/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY config/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
COPY config/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY hadoop hadoop



# Set the working directory
WORKDIR /financial_dataset

# Expose necessary ports
# Spark Web UI
EXPOSE 4040
# Hadoop ResourceManager Web UI
EXPOSE 8088
# Hadoop NameNode Web UI
EXPOSE 9870


ENTRYPOINT sh hadoop/start-hadoop.sh && bash
