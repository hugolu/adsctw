#!/bin/bash

# download & unzip data
wget http://tinyurl.com/hdfiles-zip
rm -r hdfiles
mkdir hdfiles
unzip hdfiles-zip -d hdfiles

# import data to mysql
mysql -uhive -phive -e "DROP DATABASE IF EXISTS test"
mysql -uhive -phive -e "CREATE DATABASE test"
mysql -uhive -phive test < hdfiles/retail_db.sql
mysql -uhive -phive -e "SHOW TABLES" test

# export two tables
mysql -uhive -phive test -e "SELECT * FROM customers INTO outfile '/tmp/customers.txt' FIELDS TERMINATED BY '\t'";
mysql -uhive -phive test -e "SELECT * FROM departments INTO outfile '/tmp/departments.txt' FIELDS TERMINATED BY '\t'";

