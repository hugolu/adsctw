SELECT c.category_name, count(order_item_quantity) as count
FROM order_items oi
INNER JOIN products p ON oi.order_item_product_id = p.product_id
INNER JOIN categories c ON c.category_id = p.product_category_id
GROUP BY c.category_name
ORDER BY count desc
limit 10;
