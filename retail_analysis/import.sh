#!/bin/bash

mysql -uhive -phive test -e "SELECT * FROM customers INTO outfile '/tmp/customers.txt' FIELDS TERMINATED BY '\t'";
mysql -uhive -phive test -e "SELECT * FROM departments INTO outfile '/tmp/departments.txt' FIELDS TERMINATED BY '\t'";

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
