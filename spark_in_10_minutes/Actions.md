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

## count()
Return the number of elements in the dataset.

## first()
Return the first element of the dataset (similar to take(1)).

## take(n)
Return an array with the first n elements of the dataset.

## takeSample(withReplacement, num, [seed])
Return an array with a random sample of num elements of the dataset, with or without replacement, optionally pre-specifying a random number generator seed.

## takeOrdered(n, [ordering])
Return the first n elements of the RDD using either their natural order or a custom comparator.

## saveAsTextFile(path)
Write the elements of the dataset as a text file (or set of text files) in a given directory in the local filesystem, HDFS or any other Hadoop-supported file system. Spark will call toString on each element to convert it to a line of text in the file.

## saveAsSequenceFile(path) (Java and Scala)
Write the elements of the dataset as a Hadoop SequenceFile in a given path in the local filesystem, HDFS or any other Hadoop-supported file system. This is available on RDDs of key-value pairs that implement Hadoop's Writable interface. In Scala, it is also available on types that are implicitly convertible to Writable (Spark includes conversions for basic types like Int, Double, String, etc).

## saveAsObjectFile(path) (Java and Scala)
Write the elements of the dataset in a simple format using Java serialization, which can then be loaded using SparkContext.objectFile().

## countByKey()
Only available on RDDs of type (K, V). Returns a hashmap of (K, Int) pairs with the count of each key.

## foreach(func)
Run a function func on each element of the dataset. This is usually done for side effects such as updating an Accumulator or interacting with external storage systems. 
Note: modifying variables other than Accumulators outside of the foreach() may result in undefined behavior. See Understanding closures for more details.
