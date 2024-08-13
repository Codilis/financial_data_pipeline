#!/bin/bash
set -e

hdfs dfs -mkdir financial_data

hdfs dfs -put financial_dataset/accounts.csv financial_data/accounts.csv
hdfs dfs -put financial_dataset/cards.csv financial_data/cards.csv
hdfs dfs -put financial_dataset/clients.csv financial_data/clients.csv
hdfs dfs -put financial_dataset/disps.csv financial_data/disps.csv
hdfs dfs -put financial_dataset/districts.csv financial_data/districts.csv
hdfs dfs -put financial_dataset/loans.csv financial_data/loans.csv
hdfs dfs -put financial_dataset/orders.csv financial_data/orders.csv
hdfs dfs -put financial_dataset/tkeys.csv financial_data/tkeys.csv