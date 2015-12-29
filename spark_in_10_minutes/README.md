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
```shell
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
___
## 快速開始 ##

以下練習參考，使用```spark-shell```操作文件```sample.txt```。

參考資料
 - [Spark Quick Start](https://spark.apache.org/docs/latest/quick-start.html)
 - [Spark Examples](http://spark.apache.org/examples.html)

進入spark shell會看到```scala> ```提示符號，敲入兩行動作，得到一些錯誤訊息
```scala
scala> val textFile = sc.textFile("sample.txt")
scala> textFile.count()
org.apache.hadoop.mapred.InvalidInputException: Input path does not exist: hdfs://localhost:9000/user/hadoop/sample.txt
...
```

想當然，```sample.txt```還沒放上去，發生錯誤是應該的，順便也窺知spark-shell預設檔案的路徑在```hdfs://localhost:9000/user/hadoop/sample.txt```，使用另一個console上傳檔案
```shell
$ hadoop fs -put sample.txt /user/hadoop
```

檔案上傳後再執行剛剛載入```sample.txt```的動作。
```scala
scala> val textFile = sc.textFile("sample.txt")
```

計算檔案行數
```scala
scala> val num = textFile.count() // Number of items in this RDD
num: Long = 3
```

找出檔案第一行
```scala
scala> val str = textFile.first() // First item in this RDD
str: String = Deer Bear River
```

找出含有```Car```的行數
```scala
scala> val linesWithCar = textFile.filter(line => line.contains("Car"))
scala> linesWithCar.foreach(println)
Car Car River
Deer Car Bear
```

算出含有```Car```的行數
```scala
scala> val num = textFile.filter(line => line.contains("Car")).count()
num: Long = 2
```

計算每個字串出現的次數
```scala
scala> val counts = textFile.flatMap(line => line.split(" ")).map(word => (word, 1)).reduceByKey(_ + _)
scala> counts.foreach(println)
(Deer,2)
(Bear,2)
(Car,3)
(River,2)
```

將結果輸出到檔案
```scala
scala> counts.saveAsTextFile("wordcount")
```

將檔案拉回本機，然後秀出結果
```shell
$ hadoop fs -get /user/hadoop/wordcount
$ cat wordcount/part-00000
(Deer,2)
(Bear,2)
(Car,3)
(River,2)
```
