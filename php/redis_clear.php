<?php
/**
 * Очистка данных счётчика в Redis
 */

$counter = isset($_GET['counter']) ? (int)$_GET['counter'] : 1;

$redis = new Redis();
$redis->connect('127.0.0.1', 6379);
$redis->select(0);

$key = "counter{$counter}_data";
$deleted = $redis->del($key);

echo json_encode([
    'success' => true,
    'counter' => $counter,
    'deleted' => $deleted,
    'message' => "Очищено записей: {$deleted}"
], JSON_UNESCAPED_UNICODE);

$redis->close();
