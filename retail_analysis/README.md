# 熱門銷售分析

這是應用數據科學實戰營第一天的上課內容，把它弄成筆記方便日後參考。

想跳過解說，可以執行下面流程，快速得到結果。
```
$ ./prepare.sh
```

___

## 下載&解壓檔案
```
$ wget http://tinyurl.com/hdfiles-zip
$ rm -r hdfiles
$ mkdir hdfiles
$ unzip hdfiles-zip -d hdfiles
```

## 匯入mysql資料庫
```
mysql -uhive -phive -e "DROP DATABASE IF EXISTS test"
mysql -uhive -phive -e "CREATE DATABASE test"
mysql -uhive -phive test < hdfiles/retail_db.sql
mysql -uhive -phive -e "SHOW TABLES" test
```
