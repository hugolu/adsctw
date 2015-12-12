#!/bin/bash

hadoop fs -rm -r /user/hive/warehouse/retail

sqoop import-all-tables \
    -m 12 \
    --connect jdbc:mysql://localhost:3306/test \
    --exclude-tables customers,departments \
    --username=hive \
    --password=hive \
    --compression-codec=snappy \
    --as-avrodatafile \
    --warehouse-dir=/user/hive/warehouse/retail

hadoop fs -rm -r /user/hive/warehouse/schema
hadoop fs -mkdir -p /user/hive/warehouse/schema
hadoop fs -put *.avsc /user/hive/warehouse/schema
