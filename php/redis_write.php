<?php
/**
 * Redis SCADA API - Запись данных
 * Поддерживает запись 1 счётчика или нескольких сразу
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Обработка preflight запроса
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Только POST запросы
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'error' => 'Метод не разрешён. Используйте POST'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Параметры Redis
$redisHost = '127.0.0.1';
$redisPort = 6379;
$redisDb = 0;
$maxHistorySize = 5000; // Максимум точек в истории

try {
    // Получаем JSON из body
    $input = file_get_contents('php://input');
    $json = json_decode($input, true);
    
    if ($json === null) {
        throw new Exception('Неверный формат JSON');
    }
    
    // Подключение к Redis
    $redis = new Redis();
    $connected = $redis->connect($redisHost, $redisPort, 2.0);
    
    if (!$connected) {
        throw new Exception('Не удалось подключиться к Redis');
    }
    
    $redis->select($redisDb);
    
    $written = 0;
    
    // Вариант 1: Один счётчик
    if (isset($json['counter']) && isset($json['data'])) {
        $counter = (int)$json['counter'];
        $data = $json['data'];
        
        // Валидация
        if ($counter < 1 || $counter > 100) {
            throw new Exception('Номер счётчика должен быть от 1 до 100');
        }
        
        if (!is_array($data)) {
            throw new Exception('Поле data должно быть объектом');
        }
        
        // Добавляем timestamp если его нет
        if (!isset($data['timestamp'])) {
            $data['timestamp'] = microtime(true);
        }
        
        // Записываем в Redis
        $key = "counter{$counter}_data";
        $redis->lPush($key, json_encode($data, JSON_UNESCAPED_UNICODE));
        $redis->lTrim($key, 0, $maxHistorySize - 1);
        
        $written = 1;
    }
    // Вариант 2: Несколько счётчиков
    elseif (isset($json['counters']) && is_array($json['counters'])) {
        foreach ($json['counters'] as $item) {
            if (!isset($item['counter']) || !isset($item['data'])) {
                continue;
            }
            
            $counter = (int)$item['counter'];
            $data = $item['data'];
            
            // Валидация
            if ($counter < 1 || $counter > 100) {
                continue;
            }
            
            if (!is_array($data)) {
                continue;
            }
            
            // Добавляем timestamp если его нет
            if (!isset($data['timestamp'])) {
                $data['timestamp'] = microtime(true);
            }
            
            // Записываем в Redis
            $key = "counter{$counter}_data";
            $redis->lPush($key, json_encode($data, JSON_UNESCAPED_UNICODE));
            $redis->lTrim($key, 0, $maxHistorySize - 1);
            
            $written++;
        }
    } else {
        throw new Exception('Неверная структура данных. Ожидается counter+data или counters[]');
    }
    
    $redis->close();
    
    // Успешный ответ
    echo json_encode([
        'success' => true,
        'written' => $written,
        'message' => "Записано записей: {$written}"
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
