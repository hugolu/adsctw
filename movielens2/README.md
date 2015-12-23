# Question: Find top 5 movie genres rated by each occupation

資料來自[MovieLens](http://grouplens.org/datasets/movielens/)，應用上課學到的知識找出各種職業對電影類別評分的Top5。

部分解法來自先前做過的練習 movielens，使用 Hive 做 ETL 的解法則參考 Cathleen Tsai 的想法。

___
## 下載資料

下載資料並解壓縮：
```
$ wget http://files.grouplens.org/datasets/movielens/ml-1m.zip
$ unzip ml-1m.zip
Archive:  ml-1m.zip
   creating: ml-1m/
  inflating: ml-1m/movies.dat
  inflating: ml-1m/ratings.dat
  inflating: ml-1m/README
  inflating: ml-1m/users.dat
```

原生資料有三個：USERS、MOVIES、RATINGS。其中MOVIES.Genres為複合值，movie與genres的關係沒拆開無法繼續分析，所以要產生第四個表格MOVIES_OMNI。

| Table | Fields |
|-------|--------|
| USERS | UserID, Gender, Age, Occupation, Zip-code |
| MOVIES | MovieID, Title, Genres |
| RATINGS | UserID, MovieID, Rating, Timestamp |
| MOVIES_OMNI | MovieID, Title, Genres |


## 預處理資料

HIVE只能處理field delimiter為單一字元的檔案，但MovieLens提供的檔案欄位是由```::```分隔，並且欄位內的值可能出現```:```，因此預處理選擇使用```<tab>```作為欄位分隔符號。
```
$ cd ml-1m
$ sed 's/::/\t/g' < users.dat > users.dat.2
$ sed 's/::/\t/g' < movies.dat > movies.dat.2
$ sed 's/::/\t/g' < ratings.dat > ratings.dat.2
```

## 上傳資料

把剛剛處理過的檔案上傳到HDFS。

```
$ hadoop fs -rm -r /user/hive/warehouse/movielens
$ hadoop fs -mkdir -p /user/hive/warehouse/movielens
$ hadoop fs -mkdir /user/hive/warehouse/movielens/users
$ hadoop fs -mkdir /user/hive/warehouse/movielens/movies
$ hadoop fs -mkdir /user/hive/warehouse/movielens/ratings
$ hadoop fs -mkdir /user/hive/warehouse/movielens/movies_omni

$ hadoop fs -put users.dat.2 /user/hive/warehouse/movielens/users
$ hadoop fs -put movies.dat.2 /user/hive/warehouse/movielens/movies
$ hadoop fs -put ratings.dat.2 /user/hive/warehouse/movielens/ratings
```


## 產生表格

使用上傳的檔案產生HIVE Table。

首先，登入HIVE SQL操作介面。
```
$ hive
```

產生users表格
```
DROP TABLE IF EXISTS users;
CREATE EXTERNAL TABLE users (
UserID      int,
Gender      string,
Age         int,
Occupation  int,
Zipcode     int)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/users';
```

產生movies表格
```
DROP TABLE IF EXISTS movies;
CREATE EXTERNAL TABLE movies (
MovieID     int,
Title       string,
Genres      string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/movies';
```

產生ratings表格
```
DROP TABLE IF EXISTS ratings;
CREATE EXTERNAL TABLE ratings (
UserID      int,
MovieID     int,
Rating      int,
TS          int)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/ratings';
```

產生movies_omni表格
```
DROP TABLE IF EXISTS movies_omni;
CREATE EXTERNAL TABLE movies_omni (
MovieID     int,
Title       string,
Genres      string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/movies_omni';
```

## ETL 資料轉換
```
INSERT INTO MOVIES_OMNI
SELECT movieid, title, genres_omni
from (
    select movieid, title, split(genres, '\\|') as genres_array
    from movies
) movies2
LATERAL VIEW explode(genres_array) adTable AS genres_omni;
```
