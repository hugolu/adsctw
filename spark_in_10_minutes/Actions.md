# Actions

以下用一些簡單的範例，示範各種action的用法。

參考資料
- [Actions(中)](https://taiwansparkusergroup.gitbooks.io/spark-programming-guide-zh-tw/content/programming-guide/rdds/actions.html)
- [Actions(英)](http://spark.apache.org/docs/latest/programming-guide.html#actions)

## reduce(func)
Aggregate the elements of the dataset using a function func (which takes two arguments and returns one). The function should be commutative and associative so that it can be computed correctly in parallel.
```scala
scala> val list = List(1, 2, 3)
list: List[Int] = List(1, 2, 3)

scala> val total = list.reduce((a,b) => a+b)
total: Int = 6
```

## collect()
Return all the elements of the dataset as an array at the driver program. This is usually useful after a filter or other operation that returns a sufficiently small subset of the data.
```scala
scala> val nums = sc.parallelize(1 to 4, 2)
scala> nums.collect()
res20: Array[Int] = Array(1, 2, 3, 4)
```

## count()
Return the number of elements in the dataset.
```scala
scala> val nums = sc.parallelize(1 to 9)
scala> val count = nums.count()
count: Long = 9
```

## first()
Return the first element of the dataset (similar to take(1)).
```scala
scala> val nums = sc.parallelize(1 to 9)
scala> val first = nums.first()
first: Int = 1
```

## take(n)
Return an array with the first n elements of the dataset.
```scala
scala> import org.apache.spark.mllib.random.RandomRDDs._
scala> val u = normalRDD(sc, 100L, 10)
scala> u.take(5)
res2: Array[Double] = Array(-1.14162365738377, -0.43652608825695194, -0.5909678874166858, -0.7982175744544066, -0.03379305504514526)
```

## takeSample(withReplacement, num, [seed])
Return an array with a random sample of num elements of the dataset, with or without replacement, optionally pre-specifying a random number generator seed.
```scala
scala> val nums = sc.parallelize(1 to 9)
scala> nums.takeSample(true, 5)
res19: Array[Int] = Array(7, 9, 1, 9, 2)
scala> nums.takeSample(false, 5)
res20: Array[Int] = Array(8, 7, 4, 9, 6)
```

## takeOrdered(n, [ordering])
Return the first n elements of the RDD using either their natural order or a custom comparator.
```scala
scala> val b = sc.parallelize(List("dog", "cat", "ape", "salmon", "gnu"), 2)

scala> b.takeOrdered(6)
res19: Array[String] = Array(ape, cat, dog, gnu, salmon)

scala> b.takeOrdered(2)
res20: Array[String] = Array(ape, cat)
```

## saveAsTextFile(path)
Write the elements of the dataset as a text file (or set of text files) in a given directory in the local filesystem, HDFS or any other Hadoop-supported file system. Spark will call toString on each element to convert it to a line of text in the file.
```scala
scala> val nums = sc.parallelize(1 to 100, 4)
scala> nums.saveAsTextFile("nums")
```
```shell
$ hadoop fs -get nums
$ head -n3 nums/part-0000*
==> nums/part-00000 <==
1
2
3

==> nums/part-00001 <==
26
27
28

==> nums/part-00002 <==
51
52
53

==> nums/part-00003 <==
76
77
78
```

## saveAsSequenceFile(path) (Java and Scala)
Write the elements of the dataset as a Hadoop SequenceFile in a given path in the local filesystem, HDFS or any other Hadoop-supported file system. This is available on RDDs of key-value pairs that implement Hadoop's Writable interface. In Scala, it is also available on types that are implicitly convertible to Writable (Spark includes conversions for basic types like Int, Double, String, etc).
```scala
scala> val v = sc.parallelize(Array(("owl",3), ("gnu",4), ("dog",1), ("cat",2), ("ant",5)), 2)
scala> v.saveAsSequenceFile("hd_seq_file")
```
```
$ hadoop fs -get hd_seq_file
16/01/07 09:03:11 WARN hdfs.DFSClient: DFSInputStream has been closed already
16/01/07 09:03:11 WARN hdfs.DFSClient: DFSInputStream has been closed already
16/01/07 09:03:11 WARN hdfs.DFSClient: DFSInputStream has been closed already
$ ls hd_seq_file/
part-00000  part-00001  _SUCCESS
```

## saveAsObjectFile(path) (Java and Scala)
Write the elements of the dataset in a simple format using Java serialization, which can then be loaded using SparkContext.objectFile().
```scala
scala> val v = sc.parallelize(Array(("owl",3), ("gnu",4), ("dog",1), ("cat",2), ("ant",5)), 2)
scala> v.saveAsObjectFile("hd_obj_file")
```
```shell
$ hadoop fs -get hd_obj_file
16/01/07 09:06:12 WARN hdfs.DFSClient: DFSInputStream has been closed already
16/01/07 09:06:12 WARN hdfs.DFSClient: DFSInputStream has been closed already
16/01/07 09:06:12 WARN hdfs.DFSClient: DFSInputStream has been closed already
$ ls hd_obj_file/
part-00000  part-00001  _SUCCESS
```

## countByKey()
Only available on RDDs of type (K, V). Returns a hashmap of (K, Int) pairs with the count of each key.
```scala
scala> val c = sc.parallelize(List((3, "Gnu"), (3, "Yak"), (5, "Mouse"), (3, "Dog")), 2)
scala> c.countByKey
res24: scala.collection.Map[Int,Long] = Map(3 -> 3, 5 -> 1)
```

## foreach(func)
Run a function func on each element of the dataset. This is usually done for side effects such as updating an Accumulator or interacting with external storage systems. 
Note: modifying variables other than Accumulators outside of the foreach() may result in undefined behavior. See Understanding closures for more details.
```scala
scala> val nums = sc.parallelize(1 to 9, 3)
scala> nums.foreach(print)
123456789
```
