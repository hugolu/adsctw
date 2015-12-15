## 銷售組合分析

# Question: Find 10 most popular item combinations in orders

## 進入spark-shell
```
$ spark-shell --jars hdfiles/avro-mapred.jar \
--conf spark.serializer=org.apache.spark.serializer.KryoSerializer
```

## 載入DRR
```
import org.apache.avro.generic.GenericRecord
import org.apache.avro.mapred.{AvroInputFormat, AvroWrapper}
import org.apache.hadoop.io.NullWritable

val warehouse = "hdfs://sandbox.hortonworks.com:8020/user/adsctw/warehouse/"
val order_items_path = warehouse + "order_items"
val products_path = warehouse + "products"

// Load order_items and products data into RDDs
val order_items = sc.hadoopFile[AvroWrapper[GenericRecord], NullWritable, AvroInputFormat[GenericRecord]](order_items_path)
val products = sc.hadoopFile[AvroWrapper[GenericRecord], NullWritable, AvroInputFormat[GenericRecord]](products_path)
```

### order_items
| Field                    | Type       | Null | Key | Default | Extra          |
|--------------------------|------------|------|-----|---------|----------------|
| order_item_id            | int(11)    | NO   | PRI | NULL    | auto_increment |
| order_item_order_id      | int(11)    | NO   |     | NULL    |                |
| order_item_product_id    | int(11)    | NO   |     | NULL    |                |
| order_item_quantity      | tinyint(4) | NO   |     | NULL    |                |
| order_item_subtotal      | float      | NO   |     | NULL    |                |
| order_item_product_price | float      | NO   |     | NULL    |                |

### products
| Field               | Type         | Null | Key | Default | Extra          |
|---------------------|--------------|------|-----|---------|----------------|
| product_id          | int(11)      | NO   | PRI | NULL    | auto_increment |
| product_category_id | int(11)      | NO   |     | NULL    |                |
| product_name        | varchar(45)  | NO   |     | NULL    |                |
| product_description | varchar(255) | NO   |     | NULL    |                |
| product_price       | float        | NO   |     | NULL    |                |
| product_image       | varchar(255) | NO   |     | NULL    |                |

## 找出每筆訂單中，商品與銷售數量的關係

Next, we extract the fields from order_items and products that we care about and get a list of every product, its name and quantity, grouped by order.

### 從 order_itmes 找出 ( product_id , (order_id, quantity) ) 的關係
```
// Map order_items to ( product_id , (order_id, quantity) )

val orders_mapped = order_items.map { order_item =>

  // ignore all fields except the field with info
  val (order_item_info, other_useless_info) = order_item

  // get the Avro datum of order_item_info
  val order_item_avro = order_item_info.datum

  // return a tuple of ( product_id , (order_id, quantity) )
  (
    order_item_avro.get("order_item_product_id"),
    (
      order_item_avro.get("order_item_order_id"),
      order_item_avro.get("order_item_quantity")
    )
  )
}
```

以上作用等同於SQL command:
```SQL
SELECT order_item_product_id, order_item_order_id, order_item_quantity
FROM order_items;
```

### 從 products 找出 ( product_id, product_name ) 的關係
```
// Map products to ( product_id, product_name )

val products_mapped = products.map { product =>

  // ignore all fields except the field with info
  val (product_info, other_useless_info) = product

  // get the Avro datum of product_info
  val product_info_avro = product_info.datum

  // return a tuple of ( product_id, product_name )
  (
    product_info_avro.get("product_id"),
    product_info_avro.get("product_name")
  )
}
```

以上作用等同於SQL command:
```SQL
SELECT product_id, product_name FROM products;
```

### 合併前兩個關係，產生 ( product_id, ( (order_id, quantity), product_name ) )
```
// Join the mapped orders and products => ( product_id, ( (order_id, quantity),product_name ) )

val joined_orders_products = orders_mapped.join(products_mapped)

// Now transform to make order_id as key,
// and a singe product name and quantity as value
// result => ( order_id, (quantity, product_name) )
```

```
val product_quantity_with_order_id = joined_orders_products.map { joined_values =>

    // Extract values from the joined values
    val (product_id, ( (order_id, quantity), product_name) ) = joined_values

    val order_id_int = scala.Int.unbox(order_id)
    val quantity_int = scala.Int.unbox(quantity)
    val product_name_str = product_name.toString

    // return a tuple of ( order_id, (quantity, product_name) )
    (
      order_id_int,
      (
        quantity_int,
        product_name_str
      )
    )
  }
```

以上作用等同於SQL command:
```
SELECT product_id, order_item_order_id, order_item_quantity, product_name
FROM order_items LEFT JOIN products ON order_items.order_item_product_id = products.product_id;
```

## 找出訂單中，兩兩商品組合的貢獻度(銷售量相乘)
```
// Finally, group all the (quantity, product_name) values by order_id
// so we get all product quantities of each order_id

val all_product_quantities_by_order_id = product_quantity_with_order_id.groupByKey()

// To evaluate most popular product co-occurences,
// we tally how many times each combination of products appears
// together in an order, and print the 10 most common combinations.

val contributions_of_product_combos = all_product_quantities_by_order_id.map { order =>

  val (order_id, product_quantity_pairs) = order

  val list_of_combo_contributions_in_order = product_quantity_pairs.toList.combinations(2).map { combo =>

    val (first_product_quantity, first_product_name) = combo(0)
    val (second_product_quantity, second_product_name) = combo(1)

    val product_name_pair =
      if (first_product_name < second_product_name)
        (first_product_name, second_product_name)
      else
        (second_product_name, first_product_name)

    val combo_contribution = first_product_quantity * second_product_quantity

    (product_name_pair, combo_contribution)
  }

  ( order_id, list_of_combo_contributions_in_order )
}
```

## 統計銷售組合的貢獻度
```
// Sum up the contributions of each product_name_pair

val combo_contributions = contributions_of_product_combos.flatMap { pair =>
    val (order_id, list_of_combo_contributions ) = pair
    list_of_combo_contributions
  }

val total_contribution_of_each_combo = combo_contributions.reduceByKey( (a,b) => a+b )
```

```
// Sort all product pairs by contribution

val contribution_as_key = total_contribution_of_each_combo.map{ pair =>

  val (product_pair, contribution) = pair

  (contribution, product_pair)

}

val sorted_contributions = contribution_as_key.sortByKey(false)
```

## 找出前十名熱門銷售組合
```
// Get top 10
val top_ten_pairs = sorted_contributions.take(10)

// Print 
println(top_ten_pairs.deep.mkString("\n"))
```
