#!/bin/bash

## hack ssh connection
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
ssh-keyscan -t rsa 0.0.0.0 >> ~/.ssh/known_hosts

## install Java
sudo apt-get -y install openjdk-7-jdk

echo >> ~/.bashrc
echo -e "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64" >> ~/.bashrc
source ~/.bashrc

## install Hadoop
wget http://ftp.tc.edu.tw/pub/Apache/hadoop/core/hadoop-2.7.1/hadoop-2.7.1.tar.gz
tar zxf hadoop-2.7.1.tar.gz
sudo mv hadoop-2.7.1 /usr/local/hadoop

echo >> ~/.bashrc
echo "export HADOOP_HOME=/usr/local/hadoop" >> ~/.bashrc
echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> ~/.bashrc
echo "export CLASSPATH=\$CLASSPATH:\$(hadoop classpath)" >> ~/.bashrc
source ~/.bashrc

cp -f core-site.xml /usr/local/hadoop/etc/hadoop/core-site.xml
cp -f hdfs-site.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml
cp -f hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh

hdfs namenode -format
start-dfs.sh

## install Hive
wget http://ftp.tc.edu.tw/pub/Apache/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
tar zxf apache-hive-1.2.1-bin.tar.gz
sudo mv apache-hive-1.2.1-bin /usr/local/hive

echo >> ~/.bashrc
echo "export HIVE_HOME=/usr/local/hive" >> ~/.bashrc
echo "export PATH=\$PATH:\$HIVE_HOME/bin" >> ~/.bashrc
source ~/.bashrc

## install MySQL
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server

mysql -uroot -proot -e "INSERT INTO mysql.user(host,user,password) VALUES ('%','hive',password('hive')); GRANT ALL ON *.* TO 'hive'@localhost IDENTIFIED BY 'hive' WITH GRANT OPTION; FLUSH PRIVILEGES;"

## install Sqoop
wget http://ftp.tc.edu.tw/pub/Apache/sqoop/1.4.6/sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz
tar zxf sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz
sudo mv sqoop-1.4.6.bin__hadoop-2.0.4-alpha /usr/local/sqoop

wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz
tar zxf mysql-connector-java-5.1.38.tar.gz
sudo mv mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar /usr/local/sqoop/lib/

echo >> ~/.bashrc
echo "export SQOOP_HOME=/usr/local/sqoop" >> ~/.bashrc
echo "export PATH=\$PATH:\$SQOOP_HOME/bin" >> ~/.bashrc
source ~/.bashrc

## install Scala
wget http://downloads.typesafe.com/scala/2.11.7/scala-2.11.7.tgz
tar zxf scala-2.11.7.tgz
sudo mv scala-2.11.7 /usr/local/scala

echo >> ~/.bashrc
echo "export SCALA_HOME=/usr/local/scala" >> ~/.bashrc
echo "export PATH=\$PATH:\$SCALA_HOME/bin" >> ~/.bashrc
source ~/.bashrc

## install Spark
wget http://ftp.tc.edu.tw/pub/Apache/spark/spark-1.5.2/spark-1.5.2-bin-hadoop2.6.tgz
tar zxf spark-1.5.2-bin-hadoop2.6.tgz
sudo mv spark-1.5.2-bin-hadoop2.6 /usr/local/spark

echo >> ~/.bashrc
echo "export SPARK_HOME=/usr/local/spark" >> ~/.bashrc
echo "export PATH=\$PATH:\$SPARK_HOME/bin" >> ~/.bashrc
echo "export SPARK_DIST_CLASSPATH=\$SPARK_DIST_CLASSPATH:\$(hadoop classpath)" >> ~/.bashrc
source ~/.bashrc
