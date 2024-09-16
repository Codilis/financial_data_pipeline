# from pyspark import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import os
from utils import get_hdfs_files, get_table_name, get_table_columns, get_pk_columns
from utils import get_view_columns, get_create_table_query
import logging

logging.getLogger("py4j.java_gateway").setLevel(logging.ERROR)

DATABASE_NAME='silver_zone'


class LoadSiverZone():
    def __init__(self):
        self.spark = self.get_spark_session()

    def get_spark_session(self):
        spark = SparkSession.builder \
            .appName("LoadSilverZone") \
            .config("spark.ui.showConsoleProgress", "false") \
            .enableHiveSupport() \
            .getOrCreate()

        spark.sparkContext.setLogLevel(logLevel='ERROR')
        return spark

    def create_database(self):
        self.spark.sql(f"CREATE DATABASE IF NOT EXISTS {DATABASE_NAME}")

    def read_file(self, file):
        file_type = os.path.splitext(file)[1]
        if file_type == '.csv':
            df = self.spark.read.format("csv").option("header", "true").option("inferSchema", "true").load(file)
        elif file_type == '':
            df = self.spark.read.parquet(file)
        return df
    
    def stop_spark(self):
        self.spark.stop()
        
    def full_refresh_data(self, file, df):
        table_name = get_table_name(file)

        query = get_create_table_query(DATABASE_NAME, table_name)
        self.spark.sql(query)

        df.createOrReplaceTempView("source_data")

        table_columns = ",".join(get_table_columns(table_name))
        view_columns = ",".join(get_view_columns(table_name))

        self.spark.sql(f"TRUNCATE TABLE {DATABASE_NAME}.{table_name}")
        self.spark.sql(f"INSERT INTO {DATABASE_NAME}.{table_name} ({table_columns}) SELECT {view_columns} FROM source_data")

        print(table_name, "Full Refreshed")


    def incremental_load(self, file, new_data):
        table_name = get_table_name(file)
        query = get_create_table_query(DATABASE_NAME, table_name)
        self.spark.sql(query)

        pk_columns = get_pk_columns(table_name)
        view_columns = get_view_columns(table_name)
        table_columns = get_table_columns(table_name)

        table_cols = ",".join(table_columns)
        view_cols = ",".join(view_columns)

        existing_data = self.spark.sql(f"SELECT {table_cols} from {DATABASE_NAME}.{table_name}")

        print(existing_data.show(5))
        print(new_data.show(5))

        pk_cols = []
        for column_name, new_column_name in pk_columns:
            pk_cols.append(col(f"f.{new_column_name}") == col(f"s.{column_name}"))


        insert_view_cols = []
        insert_table_cols = []
        for i in range(len(view_columns)):
            insert_view_cols.append(col(f"s.{view_columns[i]}").alias(table_columns[i]))
            insert_table_cols.append(col(f"f.{table_columns[i]}").alias(table_columns[i]))


        updated_data = existing_data.alias("f") \
                        .join(new_data.alias("s"), *pk_cols, "inner") \
                        .select(
                            *insert_view_cols
                        )
        
        inserted_data = new_data.alias("s") \
                         .join(existing_data.alias("f"), *pk_cols, "left_anti") \
                         .select(
                            *insert_view_cols
                        )

        existed_data = existing_data.alias("f") \
                         .join(new_data.alias("s"), *pk_cols, "left_anti") \
                         .select(
                            *insert_table_cols
                        )

        updated_data.union(inserted_data).union(existed_data).createOrReplaceTempView("source_data")
        
        self.spark.sql(f"TRUNCATE TABLE {DATABASE_NAME}.{table_name}")
        self.spark.sql(f"INSERT INTO {DATABASE_NAME}.{table_name} ({table_cols}) SELECT {view_cols} FROM source_data")

        print(table_name, "Incremental Load done")


if __name__ == '__main__':
    silver_zone = LoadSiverZone()

    hdfs_files = get_hdfs_files('data')

    silver_zone.create_database()

    for file in hdfs_files:
        if 'transactions' in file:
            try:
                df = silver_zone.read_file(file)
                silver_zone.incremental_load(file, df)
            except Exception as e:
                print("Failed For file", file, ":", e)
    
    silver_zone.stop_spark()