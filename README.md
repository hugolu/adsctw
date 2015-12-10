# 應用數據科學實戰營

這是[應用數據科學實戰營-助教班](http://201512-ta.adsctw.com/)課程的練習

## Question: Find top 5 movie genres rated by each occupation

資料來自[MovieLens](http://grouplens.org/datasets/movielens/)，應用上課學到的知識找出各種職業對電影類別評分的Top5。

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

原生資料有三個：USERS、MOVIES、RATINGS。其中MOVIES.Genres為複合值，movie與genres的關係沒拆開無法繼續分析，所以要產生第四個表格MOVIE_GENRES。

| Table | Fields |
|-------|--------|
| USERS | UserID, Gender, Age, Occupation, Zip-code |
| MOVIES | MovieID, Title, Genres |
| RATINGS | UserID, MovieID, Rating, Timestamp |
| MOVIE_GENRES | MovieID, GenresID |

## 資料預處理

HIVE只能處理field delimiter為單一字元的檔案，但MovieLens提供的檔案欄位是由```::```分隔，並且欄位內的值可能出現```:```，因此預處理選擇使用```<tab>```作為欄位分隔符號。
```
$ cd ml-1m
$ sed 's/::/\t/g' < users.dat > users.dat.2
$ sed 's/::/\t/g' < movies.dat > movies.dat.2
$ sed 's/::/\t/g' < ratings.dat > ratings.dat.2
```

另外，由於對HIVE提供的ETL功能不熟悉，選擇透過ruby script處理MOVIES產生MOVIE_GENRES。
```
$ awk -F '\t' '{print $1 "\t" $3}' < movies.dat.2 > movie_genres.dat
$ ./movie_genres.rb movie_genres.dat movie_genres.dat.2
```

## 上傳資料

把剛剛處理過的檔案上傳到HDFS。

```
$ hadoop fs -rm -r /user/hive/warehouse/movielens
$ hadoop fs -mkdir /user/hive/warehouse/movielens
$ hadoop fs -mkdir /user/hive/warehouse/movielens/users
$ hadoop fs -mkdir /user/hive/warehouse/movielens/movies
$ hadoop fs -mkdir /user/hive/warehouse/movielens/ratings
$ hadoop fs -mkdir /user/hive/warehouse/movielens/movie_genres

$ hadoop fs -put users.dat.2 /user/hive/warehouse/movielens/users
$ hadoop fs -put movies.dat.2 /user/hive/warehouse/movielens/movies
$ hadoop fs -put ratings.dat.2 /user/hive/warehouse/movielens/ratings
$ hadoop fs -put movie_genres.dat.2 /user/hive/warehouse/movielens/movie_genres

$ hadoop fs -ls /user/hive/warehouse/movielens/users
$ hadoop fs -ls /user/hive/warehouse/movielens/movies
$ hadoop fs -ls /user/hive/warehouse/movielens/ratings
$ hadoop fs -ls /user/hive/warehouse/movielens/movie_genres
```

## 產生表格

使用上傳的檔案產生HIVE Table。

首先，登入HIVE SQL操作介面。
```
$ hive
```

產生users表格
```
DROP TABLE users;
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
DROP TABLE movies;
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
DROP TABLE ratings;
CREATE EXTERNAL TABLE ratings (
UserID      int,
MovieID     int,
Rating      int,
TS          int)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/ratings';
```

產生movie_genres表格
```
DROP TABLE movie_genres;
CREATE EXTERNAL TABLE movie_genres (
MovieID     int,
Genres      string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/movie_genres';
```
