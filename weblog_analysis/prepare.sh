#!/bin/bash 

# download & unzip data
wget http://tinyurl.com/hdfiles-zip
rm -r hdfiles
mkdir hdfiles
unzip hdfiles-zip -d hdfiles

# create weblog dir
hadoop fs -rm -r /user/hive/warehouse/weblog
hadoop fs -mkdir /user/hive/warehouse/weblog
hadoop fs -mkdir /user/hive/warehouse/weblog/original
hadoop fs -mkdir /user/hive/warehouse/weblog/tokenized

# upload web log
hadoop fs -put hdfiles/access.log.2 /user/hive/warehouse/weblog/original
