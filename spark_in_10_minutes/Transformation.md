# Transformation

以下用一些簡單的範例，示範各種transformation的用法。

參考資料
- [Transformations(中)](https://taiwansparkusergroup.gitbooks.io/spark-programming-guide-zh-tw/content/programming-guide/rdds/transformations.html)
- [Transformations(英)](http://spark.apache.org/docs/latest/programming-guide.html#transformations)
- [Apache Spark: Examples of Transformations](http://www.supergloo.com/fieldnotes/apache-spark-examples-of-transformations/)
- [RDD function calls](http://homepage.cs.latrobe.edu.au/zhe/ZhenHeSparkRDDAPIExamples.html)

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

## sortBy
This function sorts the input RDD's data and stores it in a new RDD. The first parameter requires you to specify a function which  maps the input data into the key that you want to sortBy. The second parameter (optional) specifies whether you want the data to be sorted in ascending or descending order.

Listing Variants
- def sortBy[K](f: (T) ⇒ K, ascending: Boolean = true, numPartitions: Int = this.partitions.size)(implicit ord: Ordering[K], ctag: ClassTag[K]): RDD[T]
```scala
scala> val nums = sc.parallelize(Array(5, 7, 1, 3, 2, 1))

scala> nums.sortBy(n => +n, true).collect
res40: Array[Int] = Array(1, 1, 2, 3, 5, 7)

scala> nums.sortBy(n => -n, true).collect
res41: Array[Int] = Array(7, 5, 3, 2, 1, 1)

scala> nums.sortBy(n => +n, false).collect
res42: Array[Int] = Array(7, 5, 3, 2, 1, 1)

scala> nums.sortBy(n => -n, false).collect
res43: Array[Int] = Array(1, 1, 2, 3, 5, 7)
```
```scala
scala> val z = sc.parallelize(Array(("H", 10), ("A", 26), ("Z", 1), ("L", 5)))

scala> z.sortBy(c => c._1, true).collect
res44: Array[(String, Int)] = Array((A,26), (H,10), (L,5), (Z,1)) // sort by key

scala> z.sortBy(c => c._2, true).collect
res45: Array[(String, Int)] = Array((Z,1), (L,5), (H,10), (A,26)) // sort by value
```

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
```scala
scala> val x = sc.parallelize(List('A','B','C'))
scala> val y = sc.parallelize(List(1,2,3))

scala> x.cartesian(y).count
res11: Long = 9

scala> x.cartesian(y).collect
res12: Array[(Char, Int)] = Array((A,1), (A,2), (A,3), (B,1), (B,2), (B,3), (C,1), (C,2), (C,3))
```

## pipe(command, [envVars])
Pipe each partition of the RDD through a shell command, e.g. a Perl or bash script. RDD elements are written to the process's stdin and lines output to its stdout are returned as an RDD of strings.
```scala
scala> val a = sc.parallelize(1 to 9, 3)

scala> a.pipe("head -n 1").collect
res18: Array[String] = Array(1, 4, 7)

scala> a.pipe("tail -n 1").collect
res19: Array[String] = Array(3, 6, 9)
```

## coalesce(numPartitions)
Decrease the number of partitions in the RDD to numPartitions. Useful for running operations more efficiently after filtering down a large dataset.
```scala
scala> val y = sc.parallelize(1 to 10, 10)
scala> y.partitions.length
res22: Int = 10

scala> val z = y.coalesce(2, false)
scala> z.partitions.length
res23: Int = 2
```

## repartition(numPartitions)
Reshuffle the data in the RDD randomly to create either more or fewer partitions and balance it across them. This always shuffles all data over the network.
```scala
scala> val y = sc.parallelize(1 to 10, 10)
scala> y.partitions.length
res31: Int = 10

scala> val z = y.repartition(2)
scala> z.partitions.length
res32: Int = 2
```

## repartitionAndSortWithinPartitions(partitioner)
Repartition the RDD according to the given partitioner and, within each resulting partition, sort records by their keys. This is more efficient than calling repartition and then sorting within each partition because it can push the sorting down into the shuffle machinery.
```scala
scala> val randRDD = sc.parallelize(List( (2,"cat"), (6, "mouse"),(7, "cup"), (3, "book"), (4, "tv"), (1, "screen"), (5, "heater")), 3)
scala> val rPartitioner = new org.apache.spark.RangePartitioner(3, randRDD)

scala> def myfunc(index: Int, iter: Iterator[(Int, String)]) : Iterator[String] = {
  iter.toList.map(x => "[partID:" +  index + ", val: " + x + "]").iterator
}

// first we will do range partitioning which is not sorted
scala> val partitioned = randRDD.partitionBy(rPartitioner)
scala> partitioned.mapPartitionsWithIndex(myfunc).foreach(println)
[partID:0, val: (2,cat)]
[partID:0, val: (3,book)]
[partID:0, val: (1,screen)]
[partID:1, val: (4,tv)]
[partID:1, val: (5,heater)]
[partID:2, val: (6,mouse)]
[partID:2, val: (7,cup)]


// now lets repartition but this time have it sorted
scala> val partitioned = randRDD.repartitionAndSortWithinPartitions(rPartitioner)
scala> partitioned.mapPartitionsWithIndex(myfunc).foreach(println)
[partID:0, val: (1,screen)]
[partID:0, val: (2,cat)]
[partID:0, val: (3,book)]
[partID:1, val: (4,tv)]
[partID:1, val: (5,heater)]
[partID:2, val: (6,mouse)]
[partID:2, val: (7,cup)]
```

## aggregate
The aggregate function allows the user to apply two different reduce functions to the RDD. The first reduce function is applied within each partition to reduce the data within each partition into a single result. The second reduce function is used to combine the different reduced results of all partitions together to arrive at one final result. The ability to have two separate reduce functions for intra partition versus across partition reducing adds a lot of flexibility. For example the first reduce function can be the max function and the second one can be the sum function. The user also specifies an initial value. Here are some important facts.

- The initial value is applied at both levels of reduce. So both at the intra partition reduction and across partition reduction.
- Both reduce functions have to be commutative and associative.
- Do not assume any execution order for either partition computations or combining partitions.
- Why would one want to use two input data types? Let us assume we do an archaeological site survey using a metal detector. While walking through the site we take GPS coordinates of important findings based on the output of the metal detector. Later, we intend to draw an image of a map that highlights these locations using the aggregate function. In this case the zeroValue could be an area map with no highlights. The possibly huge set of input data is stored as GPS coordinates across many partitions. seqOp (first reducer) could convert the GPS coordinates to map coordinates and put a marker on the map at the respective position. combOp (second reducer) will receive these highlights as partial maps and combine them into a single final output map.

Listing Variants
- def aggregate[U: ClassTag](zeroValue: U)(seqOp: (U, T) => U, combOp: (U, U) => U): U

```scala
scala> val z = sc.parallelize(List(1,2,3,4,5,6), 2)

// lets first print out the contents of the RDD with partition labels
scala> def myfunc(index: Int, iter: Iterator[(Int)]) : Iterator[String] = {
  iter.toList.map(x => "[partID:" +  index + ", val: " + x + "]").iterator
}

scala> z.mapPartitionsWithIndex(myfunc).foreach(println)
[partID:0, val: 1]
[partID:0, val: 2]
[partID:0, val: 3]
[partID:1, val: 4]
[partID:1, val: 5]
[partID:1, val: 6]

scala> z.aggregate(0)(math.max(_, _), _ + _)
res1: Int = 9
// This example returns 9 since the initial value is 0
// reduce of partition 0 will be max(0, 1, 2, 3) = 3
// reduce of partition 1 will be max(0, 4, 5, 6) = 6
// final reduce across partitions will be 0 + 3 + 6 = 9
// note the final reduce include the initial value

scala> z.aggregate(5)(math.max(_, _), _ + _)
res2: Int = 16
// This example returns 16 since the initial value is 5
// reduce of partition 0 will be max(5, 1, 2, 3) = 5
// reduce of partition 1 will be max(5, 4, 5, 6) = 6
// final reduce across partitions will be 5 + 5 + 6 = 16
// note the final reduce include the initial value
```
```scala
scala> def myfunc[T](index: Int, iter: Iterator[(T)]) : Iterator[String] = {
  iter.toList.map(x => "[partID:" +  index + ", val: " + x + "]").iterator
}

scala> val z = sc.parallelize(List("a","b","c","d","e","f"),2)
scala> z.mapPartitionsWithIndex(myfunc).foreach(println)
[partID:0, val: a]
[partID:0, val: b]
[partID:0, val: c]
[partID:1, val: d]
[partID:1, val: e]
[partID:1, val: f]

scala> val result = z.aggregate("")(_+_, _+_)
result: String = abcdef
// the initial value is ""
// reduce of partition 0 will be "" + "a" + "b" + "c" = "abc"
// reduce of partition 1 will be "" + "d" + "e" + "f" = "def"
// final reduce across partitions will be "" + "abc" + "def" = "abcdef"
// note the final reduce include the initial value

scala> val result = z.aggregate("x")(_+_, _+_)
result: String = xxabcxdef
// the initial value is "x"
// reduce of partition 0 will be "x" + "a" + "b" + "c" = "xabc"
// reduce of partition 1 will be "x" + "d" + "e" + "f" = "xdef"
// final reduce across partitions will be "x" + "xabc" + "xdef" = "xxabcxdef"
// note the final reduce include the initial value
```
```scala
scala> def myfunc[T](index: Int, iter: Iterator[(T)]) : Iterator[String] = {
  iter.toList.map(x => "[partID:" +  index + ", val: " + x + "]").iterator
}

scala> val z = sc.parallelize(List("12","23","345","4567"),2)
scala> z.mapPartitionsWithIndex(myfunc).foreach(println)
[partID:0, val: 12]
[partID:0, val: 23]
[partID:1, val: 345]
[partID:1, val: 4567]

scala> val result = z.aggregate("")((x,y) => math.max(x.length, y.length).toString, (x,y) => x + y)
result: String = 24
// the initial value is ""
// reduce of partition 0 will be max("".length, "12".length).toString="2", max("2".length, "34".length).toString="2"
// reduce of partition 1 will be max("".length, "345".length).toString="3", max("3".length, "4567".length).toString = "4"
// final reduce across partitions will be "" + "2" + "4" = "24"
// note the final reduce include the initial value

scala> val result = z.aggregate("")((x,y) => math.min(x.length, y.length).toString, (x,y) => x + y)
res2: String = 11
// the initial value is ""
// reduce of partition 0 will be min("".length, "12".length).toString="0", min("0".length, "23".length).toString = "1"
// reduce of partition 1 will be min("".length, "345".length).toString="0", min("0".length, "4567".length).toString = "1"
// final reduce across partitions will be "" + "1" + "1" = "11"
// note the final reduce include the initial value
```
```scala
scala> def myfunc[T](index: Int, iter: Iterator[(T)]) : Iterator[String] = {
  iter.toList.map(x => "[partID:" +  index + ", val: " + x + "]").iterator
}

scala> val z = sc.parallelize(List("12","23","345",""),2)
scala> z.mapPartitionsWithIndex(myfunc).foreach(println)
[partID:0, val: 12]
[partID:0, val: 23]
[partID:1, val: 345]
[partID:1, val: ]

scala> z.aggregate("")((x,y) => math.min(x.length, y.length).toString, (x,y) => x + y)
scala> val result = z.aggregate("")((x,y) => math.min(x.length, y.length).toString, (x,y) => x + y)
result: String = 10
// the initial value is ""
// reduce of partition 0 will be min("".length, "12".length).toString="0", min("0".length, "23".length).toString = "1"
// reduce of partition 1 will be min("".length, "345".length).toString="0", min("0".length, "".length).toString = "0"
// final reduce across partitions will be "" + "1" + "0" = "10"
// note the final reduce include the initial value
```

## aggregateByKey(zeroValue)(seqOp, combOp, [numTasks])
When called on a dataset of (K, V) pairs, returns a dataset of (K, U) pairs where the values for each key are aggregated using the given combine functions and a neutral "zero" value. Allows an aggregated value type that is different than the input value type, while avoiding unnecessary allocations. Like in groupByKey, the number of reduce tasks is configurable through an optional second argument.
```scala
scala> val pairRDD = sc.parallelize(List( ("cat",2), ("cat", 5), ("mouse", 4),("cat", 12), ("dog", 12), ("mouse", 2)), 2)

// lets have a look at what is in the partitions
scala> def myfunc(index: Int, iter: Iterator[(String, Int)]) : Iterator[String] = {
  iter.toList.map(x => "[partID:" +  index + ", val: " + x + "]").iterator
}
scala> pairRDD.mapPartitionsWithIndex(myfunc).foreach(println)
[partID:0, val: (cat,2)]
[partID:0, val: (cat,5)]
[partID:0, val: (mouse,4)]
[partID:1, val: (cat,12)]
[partID:1, val: (dog,12)]
[partID:1, val: (mouse,2)]

scala> pairRDD.aggregateByKey(0)(math.max(_, _), _ + _).foreach(println)
(dog,12)
(cat,17)
(mouse,6)
// the initial value is 0
// reduce of partition 0 will be (cat, max(0,2,5)=5), (mouse, max(0,4)=4)
// reduce of partition 1 will be (cat, max(0,12)=12), (dog, max(0,12)=12), (mouse, max(0,2)=2)
// final reduce across partitions will be (dog, 12=12), (cat, 5+12=17), (mouse, 4+2=6)
// note the final reduce include the initial value

scala> pairRDD.aggregateByKey(10)(math.max(_, _), _ + _).foreach(println)
(dog,12)
(cat,22)
(mouse,20)
// the initial value is 10
// reduce of partition 0 will be (cat, max(10,2,5)=10), (mouse, max(10,4)=10)
// reduce of partition 1 will be (cat, max(10,12)=12), (dog, max(10,12)=12), (mouse, max(10,2)=10)
// final reduce across partitions will be (dog, 12=12), (cat, 10+12=22), (mouse, 10+10=20)
// note the final reduce include the initial value

scala> pairRDD.aggregateByKey(100)(math.max(_, _), _ + _).foreach(println)
(dog,100)
(cat,200)
(mouse,200)
// the initial value is 100
// reduce of partition 0 will be (cat, max(100,2,5)=100), (mouse, max(100,4)=100)
// reduce of partition 1 will be (cat, max(100,12)=100), (dog, max(100,12)=100), (mouse, max(100,2)=100)
// final reduce across partitions will be (dog, 100), (cat, 100+100=200), (mouse, 100+100=200)
// note the final reduce include the initial value
```
