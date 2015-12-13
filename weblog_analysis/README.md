# WebLog 分析

這是應用數據科學實戰營第一天的上課內容，把它弄成筆記方便日後參考。

想跳過解說，可以執行下面流程，快速得到結果。
```
$ prepare.sh              # 準備rawdata，上傳到hadoop
$ hive -f etl.sql         # 建立intermedia table(for ETL)，建立tokenized table(for query)
$ hive -f top10_url.sql   # 查詢最常造訪的前十個產品URL
```
___
## 準備工作

下載、解壓檔案
```
$ wget http://tinyurl.com/hdfiles-zip
$ rm -r hdfiles
$ mkdir hdfiles
$ unzip hdfiles-zip -d hdfiles
```

在hdfs上，建立weblog相關目錄
```
$ hadoop fs -rm -r /user/hive/warehouse/weblog
$ hadoop fs -mkdir /user/hive/warehouse/weblog
$ hadoop fs -mkdir /user/hive/warehouse/weblog/original
$ hadoop fs -mkdir /user/hive/warehouse/weblog/tokenized
```

上傳rawdata
```
$ hadoop fs -put hdfiles/access.log.2 /user/hive/warehouse/weblog/original
```

## ETL (Extract, Transform, Load)

登入```hive```，進行以下操作。
```
$ hive
```

產生中間表格，透過regex(正規表示式)解析字串。
```
CREATE TABLE intermediate_access_logs (
    ip              string,
    day             string,
    method          string,
    url             string,
    http_version    string,
    code1           string,
    code2           string,c
    dash            string,
    user_agent      string)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
    "input.regex" = "([^ ]*) - - \\[([^\\]]*)\\] \"([^\ ]*) ([^\ ]*) ([^\ ]*)\" (\\d*) (\\d*) \"([^\"]*)\" \"([^\"]*)\"",
    "output.format.string" = "%1$s %2$s %3$s %4$s %5$s %6$s %7$s %8$s %9$s"
)
LOCATION '/user/hive/warehouse/weblog/original';
```

產生最終表格，可以正常query。
```
CREATE TABLE tokenized_access_logs (
    ip              string,
    day             string,
    method          string,
    url             string,
    http_version    string,
    code1           string,
    code2           string,
    dash            string,
    user_agent      string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/user/hive/warehouse/weblog/tokenized';
```

將中間表格的資料寫入到最終表格。
```
ADD JAR hdfiles/hive-contrib.jar;

INSERT OVERWRITE TABLE tokenized_access_logs
SELECT * FROM intermediate_access_logs;
```

比較中間表格、最終表格
- 相同處：都可以查詢
- 相異處：最終表格可以insert，但中間表格的regex無法反向，不能insert data

## 進階查詢

查詢最常造訪的前十個產品URL。
```
SELECT count(*) as count, url
FROM tokenized_access_logs
WHERE url LIKE "%\/product\/%"
GROUP BY url
ORDER BY count desc
LIMIT 10;
```
___
## 解釋ETL過程的Regex

```
$ head -n1 hdfiles/access.log.2
79.133.215.123 - - [14/Jun/2014:10:30:13 -0400] "GET /home HTTP/1.1" 200 1671 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36"
```

觀察原始資料各欄位

| Fields | Regex | Explanation |
|-------|-------|-------------|
|```79.133.215.123```|```([^ ]*)```|取出不含空白字元的字串 for ip|
|```- -```|無意義，忽略|
|```[14/Jun/2014:10:30:13 -0400]```|```\\[([^\\]]*)\\]```|由```[]```包圍，但裡面不含```\```的字串 for day|
|```"GET /home HTTP/1.1"```|```\"([^\ ]*) ([^\ ]*) ([^\ ]*)\"```|由```""```包圍，裡面取出三個不含空白字元的字串 for method, url, http_version|
|```200 1671```|```(\\d*) (\\d*)```|取出兩個由數字組成的字串 for code1, code2|
|```"-"```|```\"([^\"]*)\"```|由```""```包圍，但裡面不含```\```的字串 for dash|
|```"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36"```|```\"([^\"]*)\"```|由```""```包圍，但裡面不含```\```的字串 for user_agent|
