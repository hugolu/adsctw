#!/bin/bash

## Java
echo -e "\n==== checking Java"
java -version

## Hadoop
echo -e "\n==== checking Hadoop"
hadoop fs -mkdir -p /user/hadoop
hadoop fs -rm -r -f input output
hadoop fs -mkdir input
hadoop fs -put /usr/local/hadoop/etc/hadoop/*.xml input
hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar grep input output 'hadoop' 2>/dev/null
hadoop fs -cat output/*

## Hive
echo -e "\n==== checking Hive"
echo "select 1+1"
hive -e "select 1+1" 2>/dev/null

## MySQL
echo -e "\n==== checking MySQL"
echo "select 1+1"
mysql -uhive -phive -e "select 1+1"

## Scala
echo -e "\n==== checking Scala"
scala -e 'println("Hello World!")' 2>/dev/null

## Spark
echo -e "\n==== checking Spark"
run-example SparkPi 2>/dev/null
