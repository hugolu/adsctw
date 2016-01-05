# Transformation

以下用一些簡單的範例，示範各種transformation的用法。

參考資料
- [Transformations(中)](https://taiwansparkusergroup.gitbooks.io/spark-programming-guide-zh-tw/content/programming-guide/rdds/transformations.html)
- [Transformations(英)](http://spark.apache.org/docs/latest/programming-guide.html#transformations)
- [Apache Spark: Examples of Transformations](http://www.supergloo.com/fieldnotes/apache-spark-examples-of-transformations/)

## map(func)
Return a new distributed dataset formed by passing each element of the source through a function func.
```scala
scala> val list = List(1, 2, 3)
list: List[Int] = List(1, 2, 3)

scala> val list2 = list.map(n => n*2)
list2: List[Int] = List(2, 4, 6)
```

## filter(func)
Return a new dataset formed by selecting those elements of the source on which func returns true.
```scala
scala> val list = List(1, 2, 3)
list: List[Int] = List(1, 2, 3)

scala> val odds = list.filter(n => n%2!=0)
odds: List[Int] = List(1, 3)
```

## flatMap(func)
Similar to map, but each input item can be mapped to 0 or more output items (so func should return a Seq rather than a single item).
```scala
scala> val list = List(List(1,2,3), List(4,5,6), List(7,8,9))
list: List[List[Int]] = List(List(1, 2, 3), List(4, 5, 6), List(7, 8, 9))

scala> val nums = list.flatMap(l => l.map(n => n*n))
nums: List[Int] = List(1, 4, 9, 16, 25, 36, 49, 64, 81)
```

## mapPartitions(func)
Similar to map, but runs separately on each partition (block) of the RDD, so func must be of type Iterator<T> => Iterator<U> when running on an RDD of type T.
```scala
scala> val values = sc.parallelize(1 to 9, 3) // 3 partitions
scala> def myfunc(iter:Iterator[Int]):Iterator[Int] = iter.toList.reverse.iterator // reverse elements in each partition
scala> values.mapPartitions(myfunc).collect // apply each patition with myfunc()
res0: Array[Int] = Array(3, 2, 1, 6, 5, 4, 9, 8, 7)
```

## mapPartitionsWithIndex(func)
Similar to mapPartitions, but also provides func with an integer value representing the index of the partition, so func must be of type (Int, Iterator<T>) => Iterator<U> when running on an RDD of type T.
```scala
scala> val values = sc.parallelize(1 to 9, 3) // 3 partitions
scala> values.mapPartitionsWithIndex((index: Int, it: Iterator[Int]) => it.toList.map(x => index+x).iterator).collect
res2: Array[Int] = Array(1, 2, 3, 5, 6, 7, 9, 10, 11)
```

## sample(withReplacement, fraction, seed)
Sample a fraction fraction of the data, with or without replacement, using a given random number generator seed.
```scala
scala> val numbers = sc.parallelize(1 to 9)

scala> val samples = numbers.sample(false, .2).collect
samples: Array[Int] = Array(2, 5, 7)

scala> val samples = numbers.sample(false, .2).collect
samples: Array[Int] = Array(3, 6)
```

## union(otherDataset)
Return a new dataset that contains the union of the elements in the source dataset and the argument.
```scala
scala> val g1 = sc.parallelize(1 to 6)
scala> val g2 = sc.parallelize(3 to 9)

scala> val g3 = g1.union(g2).collect
g3: Array[Int] = Array(1, 2, 3, 4, 5, 6, 3, 4, 5, 6, 7, 8, 9)
```

## intersection(otherDataset)
Return a new RDD that contains the intersection of elements in the source dataset and the argument.
```scala
scala> val g1 = sc.parallelize(1 to 6)
scala> val g2 = sc.parallelize(3 to 9)

scala> val g3 = g1.intersection(g2).collect
g3: Array[Int] = Array(4, 6, 3, 5)

scala> val g4 = g1.intersection(g2).collect.sorted
g4: Array[Int] = Array(3, 4, 5, 6)
```

## distinct([numTasks]))
Return a new dataset that contains the distinct elements of the source dataset.
```scala
scala> val g1 = sc.parallelize(1 to 6)
scala> val g2 = sc.parallelize(3 to 9)

scala> val g3 = g1.union(g2).distinct.collect
g3: Array[Int] = Array(4, 6, 8, 2, 1, 3, 7, 9, 5)

scala> val g4 = g1.union(g2).distinct.collect.sorted
g4: Array[Int] = Array(1, 2, 3, 4, 5, 6, 7, 8, 9)
```

## groupByKey([numTasks])
When called on a dataset of (K, V) pairs, returns a dataset of (K, Iterable<V>) pairs. 
Note: If you are grouping in order to perform an aggregation (such as a sum or average) over each key, using reduceByKey or aggregateByKey will yield much better performance. 
Note: By default, the level of parallelism in the output depends on the number of partitions of the parent RDD. You can pass an optional numTasks argument to set a different number of tasks.
```scala
scala> val words = Array("one", "two", "two", "three", "three", "three")
scala> val wordPairs = sc.parallelize(words).map(word => (word, 1))
scala> val wordCountsWithGroup = wordPairs.groupByKey.map(t => (t._1, t._2.sum)).collect
wordCountsWithGroup: Array[(String, Int)] = Array((two,2), (one,1), (three,3))
```

## reduceByKey(func, [numTasks])
When called on a dataset of (K, V) pairs, returns a dataset of (K, V) pairs where the values for each key are aggregated using the given reduce function func, which must be of type (V,V) => V. Like in groupByKey, the number of reduce tasks is configurable through an optional second argument.
```scala
scala> val words = Array("one", "two", "two", "three", "three", "three")
scala> val wordPairs = sc.parallelize(words).map(word => (word, 1))
scala> val wordCountsWithReduce = wordPairs.reduceByKey(_ + _).collect()
wordCountsWithReduce: Array[(String, Int)] = Array((two,2), (one,1), (three,3))
```

> 根據[Avoid GroupByKey](https://databricks.gitbooks.io/databricks-spark-knowledge-base/content/best_practices/prefer_reducebykey_over_groupbykey.html)的說法，reduceByKey()的做法法才能有效減少網路流量。

## aggregateByKey(zeroValue)(seqOp, combOp, [numTasks])
When called on a dataset of (K, V) pairs, returns a dataset of (K, U) pairs where the values for each key are aggregated using the given combine functions and a neutral "zero" value. Allows an aggregated value type that is different than the input value type, while avoiding unnecessary allocations. Like in groupByKey, the number of reduce tasks is configurable through an optional second argument.

## sortByKey([ascending], [numTasks])
When called on a dataset of (K, V) pairs where K implements Ordered, returns a dataset of (K, V) pairs sorted by keys in ascending or descending order, as specified in the boolean ascending argument.
```scala
scala> val words = Array("one", "two", "two", "three", "three", "three")
scala> val wordPairs = sc.parallelize(words).map(word => (word, 1))
scala> val wordCounts = wordPairs.reduceByKey(_ + _).sortByKey().collect
wordCounts: Array[(String, Int)] = Array((one,1), (three,3), (two,2))
```

## join(otherDataset, [numTasks])
When called on datasets of type (K, V) and (K, W), returns a dataset of (K, (V, W)) pairs with all pairs of elements for each key. Outer joins are supported through leftOuterJoin, rightOuterJoin, and fullOuterJoin.
```scala
scala> val prices = sc.parallelize(List(("banana", 10), ("apple", 15), ("orange", 7)))
scala> val colors = sc.parallelize(List(("apple", "red"), ("banana", "yellow"), ("lime", "green")))

scala> prices.join(colors).collect
res103: Array[(String, (Int, String))] = Array((banana,(10,yellow)), (apple,(15,red)))

scala> prices.leftOuterJoin(colors).collect
res104: Array[(String, (Int, Option[String]))] = Array((banana,(10,Some(yellow))), (orange,(7,None)), (apple,(15,Some(red))))

scala> prices.rightOuterJoin(colors).collect
res105: Array[(String, (Option[Int], String))] = Array((banana,(Some(10),yellow)), (apple,(Some(15),red)), (lime,(None,green)))
```

## cogroup(otherDataset, [numTasks])
When called on datasets of type (K, V) and (K, W), returns a dataset of (K, (Iterable<V>, Iterable<W>)) tuples. This operation is also called groupWith.
```scala
scala> val a = sc.parallelize(List(1,2,1,3))
scala> val b = a.map((_,"b"))
scala> val c = a.map((_,"c"))
scala> val d = b.cogroup(c)

scala> b.foreach(println)
(1,b)
(2,b)
(1,b)
(3,b)

scala> c.foreach(println)
(1,c)
(2,c)
(1,c)
(3,c)

scala> d.sortByKey().foreach(println)
(1,(CompactBuffer(b, b),CompactBuffer(c, c)))
(2,(CompactBuffer(b),CompactBuffer(c)))
(3,(CompactBuffer(b),CompactBuffer(c)))
```

## cartesian(otherDataset)
When called on datasets of types T and U, returns a dataset of (T, U) pairs (all pairs of elements).

## pipe(command, [envVars])
Pipe each partition of the RDD through a shell command, e.g. a Perl or bash script. RDD elements are written to the process's stdin and lines output to its stdout are returned as an RDD of strings.

## coalesce(numPartitions)
Decrease the number of partitions in the RDD to numPartitions. Useful for running operations more efficiently after filtering down a large dataset.

## repartition(numPartitions)
Reshuffle the data in the RDD randomly to create either more or fewer partitions and balance it across them. This always shuffles all data over the network.

## repartitionAndSortWithinPartitions(partitioner)
Repartition the RDD according to the given partitioner and, within each resulting partition, sort records by their keys. This is more efficient than calling repartition and then sorting within each partition because it can push the sorting down into the shuffle machinery.
