# WebLog 分析

這是應用數據科學實戰營第一天的上課內容，把它弄成筆記方便日後參考。

想跳過解說，可以執行下面流程，快速得到結果。
```
$ prepare.sh              # 準備rawdata，上傳到hadoop
$ hive -f etl.sql         # 建立intermedia table(for ETL)，建立tokenized table(for query)
$ hive -f top10_url.sql   # 查詢最常造訪的前十個產品URL
___
