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

## 觀察資料

```
hive> SELECT * FROM users limit 5;
OK
1	F	1	10	48067
2	M	56	16	70072
3	M	25	15	55117
4	M	45	7	2460
5	M	25	20	55455
Time taken: 0.041 seconds, Fetched: 5 row(s)
hive> SELECT * FROM movies limit 5;
OK
1	Toy Story (1995)	Animation|Children's|Comedy
2	Jumanji (1995)	Adventure|Children's|Fantasy
3	Grumpier Old Men (1995)	Comedy|Romance
4	Waiting to Exhale (1995)	Comedy|Drama
5	Father of the Bride Part II (1995)	Comedy
Time taken: 0.071 seconds, Fetched: 5 row(s)
hive> SELECT * FROM ratings limit 5;
OK
1	1193	5	978300760
1	661	3	978302109
1	914	3	978301968
1	3408	4	978300275
1	2355	5	978824291
Time taken: 0.045 seconds, Fetched: 5 row(s)
hive> SELECT * FROM movie_genres limit 5;
OK
1	Animation
1	Children's
1	Comedy
2	Adventure
2	Children's
Time taken: 0.04 seconds, Fetched: 5 row(s)
```

## 轉換關係：MovieID → Genres

將ratings表格中關於MovieID的關係，轉換成對應Genres。
```
SELECT UserID, ratings.MovieID, Genres, Rating FROM ratings, movie_genres
WHERE ratings.MovieID = movie_genres.MovieID;
```

前十筆資料，欄位依序為UserID、MovieID、Genres、Rating
```
1	1193	Drama	5
1	661	Animation	3
1	661	Children's	3
1	661	Musical	3
1	914	Musical	3
1	914	Romance	3
1	3408	Drama	4
1	2355	Animation	5
1	2355	Children's	5
1	2355	Comedy	5
```

## 轉換關係：UserId → Occupation

將剛剛產生資料的UserID轉換成對應Occupation。
```
SELECT Occupation, Genres, Rating FROM (
  SELECT UserID, ratings.MovieID, Genres, Rating FROM ratings, movie_genres
  WHERE ratings.MovieID = movie_genres.MovieID
) r
LEFT JOIN users u ON u.UserID = r.UserID
limit 10;
```

前十筆資料，欄位依序為Occupation, Genres, Rating
```
10	Drama	5
10	Animation	3
10	Children's	3
10	Musical	3
10	Musical	3
10	Romance	3
10	Drama	4
10	Animation	5
10	Children's	5
10	Comedy	5
```

## 算出評分

根據剛剛產生的資料，計算每個職業別對於每個電影分類的平均分數。
```
SELECT Occupation, Genres, AVG(cast(Rating as float)) Score FROM (
  SELECT UserID, ratings.MovieID, Genres, Rating FROM ratings, movie_genres
  WHERE ratings.MovieID = movie_genres.MovieID
) r
LEFT JOIN users u ON u.UserID = r.UserID
GROUP BY Occupation, Genres
ORDER BY Occupation, Score DESC;
```

前十筆資料，欄位依序為Occupation, Genres, Score
```
0	Film-Noir	4.058154787931788
0	Documentary	3.8545454545454545
0	War	3.8523344191096633
0	Drama	3.743350155365053
0	Animation	3.675085079706251
0	Musical	3.6574194749581084
0	Crime	3.6527724665391967
0	Western	3.6204407294832825
0	Mystery	3.5937855248200075
0	Romance	3.5739865044365335
```

## 找出Top5

使用```RANK()```找出各群組前五名的資料。
```
SELECT Occupation, Genres, Score FROM (
  SELECT Occupation, Genres, Score, RANK() OVER(PARTITION BY Occupation ORDER BY Score DESC) num FROM (
    SELECT Occupation, Genres, AVG(cast(Rating as float)) Score FROM (
      SELECT UserID, ratings.MovieID, Genres, Rating FROM ratings, movie_genres
      WHERE ratings.MovieID = movie_genres.MovieID
    ) r
    LEFT JOIN users u ON u.UserID = r.UserID
    GROUP BY Occupation, Genres
    ORDER BY Occupation, Score DESC
  ) ratings2
) X
WHERE num <= 5;
```

前十筆資料，欄位依序為Occupation, Genres, Score
```
0	Film-Noir	4.058154787931788
0	Documentary	3.8545454545454545
0	War	3.8523344191096633
0	Drama	3.743350155365053
0	Animation	3.675085079706251
1	Film-Noir	4.082613390928726
1	Documentary	3.9848866498740554
1	War	3.882950382950383
1	Drama	3.7542926169863957
1	Musical	3.7015856511567455
```
