#!/bin/bash

# download & unzip data source
rm -rf ml-1m*
wget http://files.grouplens.org/datasets/movielens/ml-1m.zip
unzip ml-1m.zip

# cook raw data
cd ml-1m
sed 's/::/\t/g' < users.dat > users.dat.2
sed 's/::/\t/g' < movies.dat > movies.dat.2
sed 's/::/\t/g' < ratings.dat > ratings.dat.2

# upload data
hadoop fs -rm -r /user/hive/warehouse/movielens
hadoop fs -mkdir -p /user/hive/warehouse/movielens
hadoop fs -mkdir /user/hive/warehouse/movielens/users
hadoop fs -mkdir /user/hive/warehouse/movielens/movies
hadoop fs -mkdir /user/hive/warehouse/movielens/ratings

hadoop fs -put users.dat.2 /user/hive/warehouse/movielens/users
hadoop fs -put movies.dat.2 /user/hive/warehouse/movielens/movies
hadoop fs -put ratings.dat.2 /user/hive/warehouse/movielens/ratings

hadoop fs -ls /user/hive/warehouse/movielens/users
hadoop fs -ls /user/hive/warehouse/movielens/movies
hadoop fs -ls /user/hive/warehouse/movielens/ratings
