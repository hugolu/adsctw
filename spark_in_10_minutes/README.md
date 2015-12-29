# Spark 簡易教學 #

## 設置環境 ##

在我自行安裝的系統上，無法順利執行 spark-shell，原因是 classpath 沒有定義，錯誤訊息看起來像...
```shell
$ spark-shell
Exception in thread "main" java.lang.NoClassDefFoundError: org/apache/hadoop/fs/FSDataInputStream
	at org.apache.spark.deploy.SparkSubmitArguments$$anonfun$mergeDefaultSparkProperties$1.apply(SparkSubmitArguments.scala:117)
	...
```

請執行以下動作
```
$ export SPARK_HOME=/usr/local/spark
$ export PATH=$PATH:$SPARK_HOME/bin
$ export CLASSPATH=$CLASSPATH:$(hadoop classpath)
$ export SPARK_DIST_CLASSPATH=$SPARK_DIST_CLASSPATH:$(hadoop classpath)
```

就可以看到以下訊息
```shell
$ spark-shell
15/12/29 01:19:12 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
15/12/29 01:19:12 INFO spark.SecurityManager: Changing view acls to: hadoop
15/12/29 01:19:12 INFO spark.SecurityManager: Changing modify acls to: hadoop
15/12/29 01:19:12 INFO spark.SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users with view permissions: Set(hadoop); users with modify permissions: Set(hadoop)
15/12/29 01:19:13 INFO spark.HttpServer: Starting HTTP Server
15/12/29 01:19:13 INFO server.Server: jetty-8.y.z-SNAPSHOT
15/12/29 01:19:13 INFO server.AbstractConnector: Started SocketConnector@0.0.0.0:53667
15/12/29 01:19:13 INFO util.Utils: Successfully started service 'HTTP class server' on port 53667.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 1.5.2
      /_/

Using Scala version 2.10.4 (OpenJDK 64-Bit Server VM, Java 1.7.0_91)
```
