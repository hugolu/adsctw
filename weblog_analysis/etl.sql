-- Create intermediate access log table
DROP TABLE IF EXISTS intermediate_access_logs;
CREATE TABLE intermediate_access_logs (
    ip              string,
    day             string,
    method          string,
    url             string,
    http_version    string,
    code1           string,
    code2           string,
    dash            string,
    user_agent      string)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
    "input.regex" = "([^ ]*) - - \\[([^\\]]*)\\] \"([^\ ]*) ([^\ ]*) ([^\ ]*)\" (\\d*) (\\d*) \"([^\"]*)\" \"([^\"]*)\"",
    "output.format.string" = "%1$s %2$s %3$s %4$s %5$s %6$s %7$s %8$s %9$s"
)
LOCATION '/user/hive/warehouse/weblog/original';

-- Create tokenized access log table
DROP TABLE IF EXISTS tokenized_access_logs;
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

-- copy log
ADD JAR hdfiles/hive-contrib.jar;

INSERT OVERWRITE TABLE tokenized_access_logs
SELECT * FROM intermediate_access_logs;

-- query logs
SELECT * FROM tokenized_access_logs limit 10;
