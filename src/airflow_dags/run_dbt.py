from airflow import DAG
from airflow.utils.dates import days_ago
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

run_dbt = BashOperator(
    task_id='run_dbt',
    bash_command='cd /src/hadoop_to_spark && dbt run --exclude transactions',
    dag=dbt_dag
)

run_transactions_consumer = BashOperator(
    task_id='transactions_consumer',
    bash_command='cd /src/kafka_streams && spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.2 consumer.py',
    dag=dbt_dag
)


run_dbt_transactions = BashOperator(
    task_id='kafka_producer_check',
    bash_command='cd /src/hadoop_to_spark && dbt run --select transactions',
    dag=dbt_dag
)


run_dbt >> run_transactions_consumer >> run_dbt_transactions
