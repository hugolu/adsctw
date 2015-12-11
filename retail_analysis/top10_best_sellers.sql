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
