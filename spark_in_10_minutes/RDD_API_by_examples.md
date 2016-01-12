# RDD API by Examples

之前練習操作 RDD Transformation & Action，找到一篇[Spark RDD API Examples](http://homepage.cs.latrobe.edu.au/zhe/ZhenHeSparkRDDAPIExamples.html)，裡面的說明與範例非常簡潔易懂，值得細細品味。以下按照網頁列出API的順序，紀錄理解的筆記與練習的過程。

基本的RDD API把每筆資料視為單一值。然而，使用者有時想操作key-value，因此，Spark擴充RDD介面以提供額外功能，這些函式就能處理key-value。這些特殊的函式有:

| 標記 | 名稱 | 說明 |
|------|------|------|
| [Double] | DoubleRDDFunctions | 這些擴充的方法包含許多總計數值的方法。如果資料轉換成 double type，就能使用這些方法。 |
| [Pair] | PairRDDFunctions | 這些擴充的方法能處理 tuple 結構，第一個項目是key，第二個項目是value。 |
| [Ordered] | OrderedRDDFunctions | 這些擴充的方法能處理 key 可以排序的 tuple 結構。 |
| [SeqFile] | SequenceFileRDDFunctions | 這些擴充的方法讓使用者可以從RDD產生Hadoop sequence file。 (把記憶體上的資料結構寫到檔案中，之後讀出能還原成原先的模樣) |
___

## aggregate

The aggregate function allows the user to apply two different reduce functions to the RDD. 
The first reduce function is applied within each partition to reduce the data within each partition into a single result. 
The second reduce function is used to combine the different reduced results of all partitions together to arrive at one final result. 
The ability to have two separate reduce functions for intra partition versus across partition reducing adds a lot of flexibility. For example the first reduce function can be the max function and the second one can be the sum function. The user also specifies an initial value. Here are some important facts.

- The initial value is applied at both levels of reduce. So both at the intra partition reduction and across partition reduction.
- Both reduce functions have to be commutative and associative.
- Do not assume any execution order for either partition computations or combining partitions.
- Why would one want to use two input data types? Let us assume we do an archaeological site survey using a metal detector. While walking through the site we take GPS coordinates of important findings based on the output of the metal detector. Later, we intend to draw an image of a map that highlights these locations using the aggregate function. In this case the zeroValue could be an area map with no highlights. The possibly huge set of input data is stored as GPS coordinates across many partitions. seqOp (first reducer) could convert the GPS coordinates to map coordinates and put a marker on the map at the respective position. combOp (second reducer) will receive these highlights as partial maps and combine them into a single final output map.

定義
```
def aggregate[U: ClassTag](zeroValue: U)(seqOp: (U, T) => U, combOp: (U, U) => U): U
```

範例
```
scala> val z = sc.parallelize(List(1,2,3,4,5,6), 2)
scala> z.aggregate(0)(math.max(_, _), _ + _)
res0: Int = 9
```
- 初始值
  - Partition 0: 1, 2, 3
  - Partition 1: 4, 5, 6
  - zeroValue: 0
- 第一次 reduce
  - Partition 0: max(0, 1, 2, 3) = 3
  - Partition 1: max(0, 4, 5, 6) = 6
- 第二次 reduce
  - 0 + 3 + 6 = 9
  
範例
```
scala>val z = sc.parallelize(List(1,2,3,4,5,6), 2)
scala>z.aggregate(5)(math.max(_, _), _ + _)
res1: Int = 16
```
- 初始值
  - Partition 0: 1, 2, 3
  - Partition 1: 4, 5, 6
  - zeroValue: 5
- 第一次 reduce
  - Partition 0: max(5, 1, 2, 3) = 5
  - Partition 1: max(5, 4, 5, 6) = 6
- 第二次 reduce 
  - 5 + 5 + 6 = 16

範例
```
scala> val z = sc.parallelize(List("a","b","c","d","e","f"),2)
scala> z.aggregate("")(_ + _, _+_)
res2: String = abcdef
```
- 初始值
  - Partition 0: "a", "b", "c"
  - Partition 1: "d", "e", "f"
  - zeroValue: ""
- 第一次 reduce
  - Partition 0: "" + "a" + "b" + "c" = "abc"
  - Partition 1: "" + "d" + "e" + "f" = "def"
- 第二次 reduce 
  - "" + "abc" + "def" = "abcdef"

範例
```
scala> val z = sc.parallelize(List("a","b","c","d","e","f"),2)
scala> z.aggregate("x")(_ + _, _+_)
res3: String = xxabcxdef
```
- 初始值
  - Partition 0: "a", "b", "c"
  - Partition 1: "d", "e", "f"
  - zeroValue: "x"
- 第一次 reduce
  - Partition 0: "x" + "a" + "b" + "c" = "xabc"
  - Partition 1: "x" + "d" + "e" + "f" = "xdef"
- 第二次 reduce 
  - "x" + "xabc" + "xdef" = "xxabcxdef"

範例
```
scala> val z = sc.parallelize(List("12","23","345","4567"),2)
scala> z.aggregate("")((x,y) => math.max(x.length, y.length).toString, (x,y) => x + y)
res4: String = 24
```
- 初始值
  - Partition 0: "12", "23"
  - Partition 1: "345", "4567"
  - zeroValue: ""
- 第一次 reduce
  - Partition 0: max("".length, "12".length, "34".length).toString = "2"
  - Partition 1: max("".length, "345".length, "4567".length).toString = "4"
- 第二次 reduce 
  - "" + "2" + "4" = "24"

範例
```
scala> val z = sc.parallelize(List("12","23","345","4567"),2)
scala> z.aggregate("")((x,y) => math.min(x.length, y.length).toString, (x,y) => x + y)
res5: String = 11
```
- 初始值
  - Partition 0: "12", "23"
  - Partition 1: "345", "4567"
  - zeroValue: ""
- 第一次 reduce
  - Partition 0: min("".length, "12".length).toString = "0", min("0".length, "34".length).toString = "1"
  - Partition 1: min("".length, "345".length).toString = "0", min("0".length, "4567".length).toString = "1"
- 第二次 reduce 
  - "" + "1" + "1" = "11"

範例
```
scala> val z = sc.parallelize(List("12","23","345",""),2)
scala> z.aggregate("")((x,y) => math.min(x.length, y.length).toString, (x,y) => x + y)
res6: String = 10
```


<< 未完待續 >>
