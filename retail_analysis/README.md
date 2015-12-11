# 熱門銷售分析

這是應用數據科學實戰營第一天的上課內容，把它弄成筆記方便日後參考。

想跳過解說，可以執行下面流程，快速得到結果。
```
$ ./prepare.sh                    # 下載、解壓、匯入mysql
$ hive -f load.sql                # sqoop: mysql→hive
$ ./import.sh                     # 手動產生表格
$ hive -f create_tables.sql       # 自動產生表格
$ hive -f top10_catetory.sql      # 找出10個最受歡迎的熱門商品類別
$ hive -f top10_best_sellers.sql  # 找出10個最受歡迎的熱門商品
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
## 手動產生表格

```
DROP TABLE customers;
CREATE TABLE customers (
    customer_id         int,
    customer_fname      string,
    customer_lname      string,
    customer_email      string,
    customer_password   string,
    customer_street     string,
    customer_city       string,
    customer_state      string,
    customer_zipcode    string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

load data local inpath '/tmp/customers.txt' into table customers;
```

```
DROP TABLE departments;
CREATE TABLE departments (
    department_id       int,
    department_name     string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

load data local inpath '/tmp/departments.txt' into table departments;
```

## 使用Sqoop匯出表格資料

```
hadoop fs -rm -r /user/hive/warehouse/retail

sqoop import-all-tables \
    -m 12 \
    --connect jdbc:mysql://localhost:3306/test \
    --exclude-tables customers,departments \
    --username=hive \
    --password=hive \
    --compression-codec=snappy \
    --as-avrodatafile \
    --warehouse-dir=/user/hive/warehouse/retail
```

# 上傳schema

```
hadoop fs -rm -r /user/hive/warehouse/schema
hadoop fs -mkdir -p /user/hive/warehouse/schema
hadoop fs -put *.avsc /user/hive/warehouse/schema
```

## 自動產生表格
```
DROP TABLE categories;
CREATE EXTERNAL TABLE categories
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
STORED AS
INPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
LOCATION 'hdfs:///user/hive/warehouse/retail/categories'
TBLPROPERTIES ('avro.schema.url'='hdfs:///user/hive/warehouse/schema/categories.avsc');
```
```
DROP TABLE products;
CREATE EXTERNAL TABLE products
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
STORED AS
INPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
LOCATION 'hdfs:///user/hive/warehouse/retail/products'
TBLPROPERTIES ('avro.schema.url'='hdfs:///user/hive/warehouse/schema/products.avsc');
```
```
DROP TABLE orders;
CREATE EXTERNAL TABLE orders
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
STORED AS
INPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
LOCATION 'hdfs:///user/hive/warehouse/retail/orders'
TBLPROPERTIES ('avro.schema.url'='hdfs:///user/hive/warehouse/schema/orders.avsc');
```
```
DROP TABLE order_items;
CREATE EXTERNAL TABLE order_items
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
STORED AS
INPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
LOCATION 'hdfs:///user/hive/warehouse/retail/order_items'
TBLPROPERTIES ('avro.schema.url'='hdfs:///user/hive/warehouse/schema/order_items.avsc');
```

## 找出 Top 10 歡迎類別

```
SELECT c.category_name, count(order_item_quantity) as count
FROM order_items oi
INNER JOIN products p ON oi.order_item_product_id = p.product_id
INNER JOIN categories c ON c.category_id = p.product_category_id
GROUP BY c.category_name
ORDER BY count desc
limit 10;
```

## 找出 Top 10 歡迎商品

```
SELECT p.product_id, p.product_name, r.revenue
FROM products p
INNER JOIN (
    SELECT oi.order_item_product_id, sum(oi.order_item_subtotal) as revenue
    FROM order_items oi
    INNER JOIN orders o ON oi.order_item_order_id = o.order_id
    WHERE o.order_status <> 'CANCELED'
    AND o.order_status <> 'SUSPECTED_FRAUD'
    GROUP BY oi.order_item_product_id
) r
ON p.product_id = r.order_item_product_id
ORDER BY r.revenue desc
limit 10;
```
