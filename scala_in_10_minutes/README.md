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

如果想要印出這個串列的內容，過去的編程方式(Imperative Programming)會是這麼寫
```scala
for (number <- numbers) {
	print(number)
}
```

___
未完待續
