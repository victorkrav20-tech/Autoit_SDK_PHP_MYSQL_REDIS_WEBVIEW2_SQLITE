<?php
/**
 * Redis API для получения данных датчиков
 * Использует PhpRedis расширение
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Параметры подключения
$redisHost = '127.0.0.1';
$redisPort = 6379;
$redisDb = 0;

// Параметры запроса
$count = isset($_GET['count']) ? (int)$_GET['count'] : 1000;
$key = isset($_GET['key']) ? $_GET['key'] : 'sensor_data';

try {
    // Подключение к Redis
    $redis = new Redis();
    $connected = $redis->connect($redisHost, $redisPort, 2.0); // timeout 2 сек
    
    if (!$connected) {
        throw new Exception('Не удалось подключиться к Redis');
    }
    
    // Выбор базы данных
    $redis->select($redisDb);
    
    // Получение данных из LIST (последние N элементов)
    // LRANGE key 0 -1 получает все элементы
    // LRANGE key -1000 -1 получает последние 1000
    $start = -$count;
    $end = -1;
    $data = $redis->lRange($key, $start, $end);
    
    // Если данных нет, возвращаем пустой массив
    if ($data === false || empty($data)) {
        echo json_encode([
            'success' => true,
            'count' => 0,
            'data' => [],
            'message' => 'Нет данных в Redis'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Парсим JSON данные
    $parsedData = [];
    foreach ($data as $item) {
        $decoded = json_decode($item, true);
        if ($decoded !== null) {
            $parsedData[] = $decoded;
        }
    }
    
    // Возвращаем результат
    echo json_encode([
        'success' => true,
        'count' => count($parsedData),
        'data' => $parsedData,
        'redis_key' => $key,
        'requested_count' => $count
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
    $redis->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
