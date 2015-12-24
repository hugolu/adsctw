# Scala 簡易教學 #

如同營長 Cray 說過，想在短時間內講解 Scala 是不可能的，但我還是想挑戰這個不可能。

話先說前頭，這份文件不是詳細的教學，有興趣繼續挖下去的請參考下面連結。

- [語言技術：Scala Gossip](http://openhome.cc/Gossip/Scala/)
- [Scala 课堂!](https://twitter.github.io/scala_school/zh_cn/)

以下程式碼可以直接複制貼上到scala interactive shell，直接觀察實驗結果。
___
## Imperative Programming vs Declarative Programming ##

長久以來使用C, Java, PHP, JS，太習慣命令式編程方式(Imperative Programming)，什麼流程都要控制、所有步驟都要自己操心，剛接觸Scala會很不習慣，因為這種語言不需要告訴程式該怎麼做，而是透過宣告的方式(Declarative Programming)告訴它你想要什麼結果。

宣告一個列整數
```
val numbers = List(1,2,3,4)
```

如果想要印出這個串列的內容，過去的編程方式(Imperative Programming)會是這麼寫 - 使用迴圈，逐一列印串列裡的值
```scala
for (number <- numbers) {
    println(number)
}
```

使用```println()```列印加上new line，執行結果
```
1
2
3
4
```

換成宣告方式(Declarative Programming)程式看起來會是像這樣 - 迴圈內的控制流程不見了，取而代之的是呼叫```foreach()```並傳入一個函式```println```
```scala
numbers.foreach(println)
```

## Function ##

剛剛提到函式(Function)，現在來看看如何定義。

Scala 定義函式的方法有兩種，第一種是透過```def```宣告
```
def square(n: Int): Int = {
    return n*n
}
```

- ```def``` 後面開始定義函式
- ```square``` 是函式名稱
- ```(n: Int)``` 定義函式的輸入參數
- ```:``` 左邊函式名稱；右邊宣告函式回傳值
- ```: Int``` 是函式回傳一個整數值
- ```{}``` 定義函式的內容

呼叫方式如下
```scala
scala> square(3)
res2: Int = 9
```

第二種定義方式，把函式當成變數。quot良葛格的一句話：「在Scala中，函式是一級（First-class）公民，也就是說，在Scala中，函式是物件。」
```
val square: (Int)=>Int = {
    (n:Int) =>
    n*n
}
```

呵呵，這個有點費解了。剛接觸function programming(把函式當成變數傳遞的編程方式)的人會被這樣的宣告方式嚇一跳，依序拆解如下

- ```val``` 宣告一個變數 (value)
- ```square``` 是函式名稱
- ```:``` 左邊是變數名稱；右邊宣告回傳值
- ```(Int)=>Int``` 回傳值的型態(type)，在這個例子中是一個函式 (輸入```Int```，輸出```Int```)
- ```=``` 左邊放變數的值，在這例子中是放函式的內容
- ```{}``` 定義匿名函式(anonymous function)的內容，為什麼說是匿名函式呢？因為就算沒有```=```左半邊的東西，右半邊的```{}```還是可以獨立存在，只是你宣告的時候如果沒有傳給一個變數來儲存，因為匿名所以將來也沒辦法呼叫。

再來說明```{}```裡面的東東
- ``` (n:Int)``` 接收一個變數```n```，型態為```Int```
- ```=>``` 左邊宣告匿名函式的輸入參數，右邊定義函式的內容
- ```n*n``` 函式內容，把```n```執行平方運算，在Scala匿名函式中，最後一行的值預設會回傳，故省略```return```

呼叫方式跟之前一樣
```scala
scala> square(3)
res4: Int = 9
```

## Functional Programming ##

呼～難的部分解決了，接下來解釋如何把函式當成變數傳給另一個函式的方法(Passing a function literal as a function argument)，有點繞口不是嗎 ;)

來看一個很常見的```map()```函式，順便觀察執行結果
```
scala> val squares = numbers.map(square)
squares: List[Int] = List(1, 4, 9, 16)
```

把 ```square``` 換成我們剛剛寫的匿名函式，效果是一樣的
```
scala> val squares = numbers.map({(n:Int) => n*n})
squares: List[Int] = List(1, 4, 9, 16)
```
___
未完待續
