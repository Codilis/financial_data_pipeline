from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'admin',
    'depends_on_past': False,
    'start_date': datetime(2024, 9, 14),
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(hours=1)
}

dbt_dag = DAG(
    dag_id='dbt_run_dag',
    default_args=default_args,
    description='Run dbt for all the tables!',
    schedule_interval=timedelta(days=1),
)

run_transactions_consumer = BashOperator(
    task_id='run_transactions_consumer',
    bash_command='cd /shared_volume && spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.2 /src/kafka_streams/consumer.py',
    dag=dbt_dag
)


load_silver_zone = BashOperator(
    task_id='load_silver_zone',
    bash_command='cd /shared_volume && $SPARK_HOME/sbin/stop-thriftserver.sh && spark-submit /src/load_silver_zone/main.py && $SPARK_HOME/sbin/start-thriftserver.sh --master local[*]',
    dag=dbt_dag
)


run_transactions_consumer >> load_silver_zone
