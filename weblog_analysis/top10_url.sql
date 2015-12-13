SELECT count(*) as count, url
FROM tokenized_access_logs
WHERE url LIKE "%\/product\/%"
GROUP BY url
ORDER BY count desc
LIMIT 10;
