-- Create the tables
DROP TABLE IF EXISTS users;
CREATE EXTERNAL TABLE users (
UserID      int,
Gender      string,
Age         int,
Occupation  int,
Zipcode     int)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/users';

DROP TABLE IF EXISTS movies;
CREATE EXTERNAL TABLE movies (
MovieID     int,
Title       string,
Genres      string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/movies';

DROP TABLE IF EXISTS ratings;
CREATE EXTERNAL TABLE ratings (
UserID      int,
MovieID     int,
Rating      int,
TS          int)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/ratings';

DROP TABLE IF EXISTS movies_omni;
CREATE TABLE movies_omni (
MovieID     int,
Title       string,
Genres      string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/movies_omni';

DROP TABLE IF EXISTS occupations;
CREATE TABLE occupations (
Occupation  int,
Description string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/hive/warehouse/movielens/occupations';

-- ETL
INSERT INTO MOVIES_OMNI
SELECT movieid, title, genres_omni
from (
    select movieid, title, split(genres, '\\|') as genres_array
    from movies
) movies2
LATERAL VIEW explode(genres_array) adTable AS genres_omni;

-- Insert occupation data
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

-- Find top 5 movie genres rated by each occupation
SELECT Description, Genres, Score
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
