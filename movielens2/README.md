# Question: Find top 5 movie genres rated by each occupation

資料來自[MovieLens](http://grouplens.org/datasets/movielens/)，應用上課學到的知識找出各種職業對電影類別評分的Top5。

部分解法來自先前做過的練習 movielens，使用 Hive 做 ETL 的解法則參考 Cathleen Tsai 的想法。

如果沒有時間詳讀以下內容，可透過以下指令快速得到結果。
```
$ ./prepare.sh
$ hive -f adsc.sql
```

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
CREATE TABLE movies_omni (
MovieID     int,
Title       string,
Genres      string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/movies_omni';
```

## 資料轉換：ETL
- 使用```split(string str, string pat)```將```movies.genres```欄位裡的字串轉成陣列
- 使用```explode()```，根據一列欄位裡的array或map的值，展開成多列
- 用法請參考[Hive Operators and User-Defined Functions (UDFs)](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF)
```
INSERT INTO MOVIES_OMNI
SELECT movieid, title, genres_omni
from (
    select movieid, title, split(genres, '\\|') as genres_array
    from movies
) movies2
LATERAL VIEW explode(genres_array) adTable AS genres_omni;
```

## 轉換關係：MovieID → Genres

將ratings表格中關於MovieID的關係，轉換成對應Genres。
```
SELECT r.UserID, r.MovieID, m.Genres, r.Rating
FROM ratings r, movies_omni m
WHERE r.MovieID = m.MovieID;
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
SELECT Occupation, Genres, Rating
FROM (
    SELECT r.UserID, m.Genres, r.Rating
    FROM ratings r, movies_omni m
    WHERE r.MovieID = m.MovieID
    ) r2 LEFT JOIN users u ON u.UserID = r2.UserID;
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
SELECT Occupation, Genres, AVG(cast(Rating as float)) Score
FROM (
    SELECT r.UserID, m.Genres, r.Rating
    FROM ratings r, movies_omni m
    WHERE r.MovieID = m.MovieID
    ) r2 LEFT JOIN users u ON u.UserID = r2.UserID
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

參考[How to select TOP N rows from a table for each group?](http://www.sql-ex.ru/help/select16.php)，使用```RANK()```找出各群組前五名的資料。
```
SELECT Occupation, Genres, Score
FROM (
    SELECT Occupation, Genres, Score, RANK() OVER(PARTITION BY Occupation ORDER BY Score DESC) num
    FROM (
        SELECT Occupation, Genres, AVG(cast(Rating as float)) Score
        FROM (
            SELECT r.UserID, m.Genres, r.Rating
            FROM ratings r, movies_omni m
            WHERE r.MovieID = m.MovieID
        ) r2 LEFT JOIN users u ON u.UserID = r2.UserID
        GROUP BY Occupation, Genres
        ORDER BY Occupation, Score DESC
    ) r3
) r4
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

## 將Occupation換成有意義的文字

創建occupations表格。
```
DROP TABLE Occupations;
CREATE TABLE Occupations (
Occupation  int,
Description string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/occupations';
```

根據ml-1m/README對於Occupation的描述，寫入資料。
```
INSERT INTO occupations (occupation, description) values
(0, "other"),
(1, "academic/educator"),
(2, "artist"),
(3, "clerical/admin"),
(4, "college/grad student"),
(5, "customer service"),
(6, "doctor/health care"),
(7, "executive/managerial"),
(8, "farmer"),
(9, "homemaker"),
(10, "K-12 student"),
(11, "lawyer"),
(12, "programmer"),
(13, "retired"),
(14, "sales/marketing"),
(15, "scientist"),
(16, "self-employed"),
(17, "technician/engineer"),
(18, "tradesman/craftsman"),
(19, "unemployed"),
(20, "writer");
```

輸出容易閱讀的結果
```
SELECT o.Description, Genres, Score
FROM (
    SELECT Occupation, Genres, Score, RANK() OVER(PARTITION BY Occupation ORDER BY Score DESC) num
    FROM (
        SELECT Occupation, Genres, AVG(cast(Rating as float)) Score
        FROM (
            SELECT r.UserID, m.Genres, r.Rating
            FROM ratings r, movies_omni m
            WHERE r.MovieID = m.MovieID
        ) r2 LEFT JOIN users u ON u.UserID = r2.UserID
        GROUP BY Occupation, Genres
        ORDER BY Occupation, Score DESC
    ) r3
) r4 LEFT JOIN occupations o ON o.Occupation = r4.Occupation
WHERE num <= 5;
```

登登登，答案是
```
other	Film-Noir	4.058154787931788
other	Documentary	3.8545454545454545
other	War	3.8523344191096633
other	Drama	3.743350155365053
other	Animation	3.675085079706251
academic/educator	Film-Noir	4.082613390928726
academic/educator	Documentary	3.9848866498740554
academic/educator	War	3.882950382950383
academic/educator	Drama	3.7542926169863957
academic/educator	Musical	3.7015856511567455
artist	Film-Noir	4.114
artist	Documentary	4.028933092224231
artist	War	3.859375
artist	Drama	3.732216053546412
artist	Mystery	3.71964461994077
clerical/admin	Film-Noir	4.07533234859675
clerical/admin	War	3.9276923076923076
clerical/admin	Musical	3.857048748353096
clerical/admin	Documentary	3.8526315789473684
clerical/admin	Animation	3.822104466313399
college/grad student	Film-Noir	4.03954802259887
college/grad student	Documentary	3.9628865979381445
college/grad student	War	3.8641072516758075
college/grad student	Drama	3.7487943783585176
college/grad student	Crime	3.723449684366877
customer service	Film-Noir	4.027355623100304
customer service	Documentary	3.88659793814433
customer service	Animation	3.7669404517453797
customer service	War	3.7566765578635013
customer service	Drama	3.7399905793688175
doctor/health care	Documentary	4.013245033112582
doctor/health care	Film-Noir	4.0113475177304965
doctor/health care	War	4.005054432348367
doctor/health care	Drama	3.8717555121406644
doctor/health care	Crime	3.802857142857143
executive/managerial	Film-Noir	4.030026809651474
executive/managerial	Documentary	3.9151343705799153
executive/managerial	War	3.9111640145345197
executive/managerial	Drama	3.7666632380168688
executive/managerial	Crime	3.736324101625086
farmer	Documentary	3.9
farmer	Film-Noir	3.8780487804878048
farmer	War	3.7804878048780486
farmer	Western	3.7058823529411766
farmer	Drama	3.627544910179641
homemaker	War	3.8795180722891565
homemaker	Musical	3.845821325648415
homemaker	Documentary	3.8
homemaker	Animation	3.797979797979798
homemaker	Drama	3.7911849710982657
K-12 student	Film-Noir	4.212765957446808
K-12 student	War	3.88014440433213
K-12 student	Drama	3.7821666666666665
K-12 student	Crime	3.6870848708487083
K-12 student	Mystery	3.6366120218579234
lawyer	Film-Noir	4.145251396648045
lawyer	Documentary	4.141361256544503
lawyer	War	3.947634069400631
lawyer	Drama	3.763534218590398
lawyer	Mystery	3.741304347826087
programmer	Film-Noir	4.130357142857143
programmer	War	3.941926345609065
programmer	Documentary	3.8442211055276383
programmer	Drama	3.8402067406051468
programmer	Western	3.7734082397003745
retired	Film-Noir	4.1610576923076925
retired	War	4.085756897837435
retired	Documentary	3.9705882352941178
retired	Drama	3.9490466798159107
retired	Mystery	3.946291560102302
sales/marketing	Film-Noir	4.126050420168068
sales/marketing	Documentary	3.9177631578947367
sales/marketing	War	3.9073170731707316
sales/marketing	Drama	3.7880179042809594
sales/marketing	Animation	3.7610568638713384
scientist	Film-Noir	4.190476190476191
scientist	Documentary	3.9875
scientist	War	3.933114035087719
scientist	Animation	3.8478048780487804
scientist	Drama	3.8360695026962253
self-employed	Film-Noir	4.105582524271845
self-employed	Documentary	3.9334916864608074
self-employed	War	3.9261069580218515
self-employed	Drama	3.791982533810419
self-employed	Crime	3.7375690607734806
technician/engineer	Film-Noir	4.050860719874804
technician/engineer	Documentary	4.024128686327078
technician/engineer	War	3.93970778620307
technician/engineer	Drama	3.80015756302521
technician/engineer	Animation	3.734375
tradesman/craftsman	Film-Noir	3.88265306122449
tradesman/craftsman	War	3.8734491315136474
tradesman/craftsman	Western	3.753205128205128
tradesman/craftsman	Animation	3.748663101604278
tradesman/craftsman	Drama	3.738553237604985
unemployed	Film-Noir	4.044444444444444
unemployed	Documentary	3.727272727272727
unemployed	War	3.693103448275862
unemployed	Crime	3.6340852130325816
unemployed	Drama	3.6193078324225865
writer	Film-Noir	4.104602510460251
writer	Documentary	3.9679144385026737
writer	War	3.7983933661570357
writer	Animation	3.699773413897281
writer	Musical	3.669849430774881
```

- 使用 hortonworks sandbox VM - Time taken: 73.78 seconds
- 使用原先在 ubuntu 上面自架的 hadoop - Time taken: 28.078 seconds

> hortonworks 是個吃資源的怪獸，跑起又很慢 (昏倒)
