<?php
/**
 * Redis Sensors API - Запись данных датчиков 21 танка
 * Компактный формат: [timestamp, temp1-21, level1-21]
 * Кольцевой буфер: 10000 записей
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
$maxHistorySize = 10000; // Кольцевой буфер на 10000 записей
$redisKey = 'MemoGraph:sensors_memograph_all_online'; // Ключ с namespace

try {
    // Получаем JSON из body
    $input = file_get_contents('php://input');
    $json = json_decode($input, true);
    
    if ($json === null) {
        throw new Exception('Неверный формат JSON');
    }
    
    // Проверяем наличие поля data
    if (!isset($json['data']) || !is_array($json['data'])) {
        throw new Exception('Отсутствует поле data или оно не является массивом');
    }
    
    $data = $json['data'];
    
    // Валидация: должно быть 43 элемента (1 timestamp + 21 temp + 21 level)
    if (count($data) !== 43) {
        throw new Exception('Неверное количество элементов. Ожидается 43 (timestamp + 21 temp + 21 level), получено: ' . count($data));
    }
    
    // Валидация: первый элемент должен быть timestamp (число)
    if (!is_numeric($data[0])) {
        throw new Exception('Первый элемент должен быть timestamp (число)');
    }
    
    $timestamp = $data[0];
    
    // Валидация: все остальные элементы должны быть числами
    for ($i = 1; $i < 43; $i++) {
        if (!is_numeric($data[$i])) {
            throw new Exception("Элемент #{$i} не является числом");
        }
    }
    
    // Подключение к Redis
    $redis = new Redis();
    $connected = $redis->connect($redisHost, $redisPort, 2.0);
    
    if (!$connected) {
        throw new Exception('Не удалось подключиться к Redis');
    }
    
    $redis->select($redisDb);
    
    // Формируем строку для записи (CSV в квадратных скобках для проверки целостности)
    // Формат: [timestamp,temp1-21,level1-21]
    $dataString = '[' . implode(',', $data) . ']';
    
    // Валидация целостности перед записью
    if ($dataString[0] !== '[' || substr($dataString, -1) !== ']') {
        throw new Exception('Ошибка формирования данных: нарушена целостность');
    }
    
    // Записываем в Redis LIST (в начало списка)
    $redis->lPush($redisKey, $dataString);
    
    // Обрезаем до maxHistorySize (кольцевой буфер)
    $redis->lTrim($redisKey, 0, $maxHistorySize - 1);
    
    // Получаем текущий размер истории
    $historySize = $redis->lLen($redisKey);
    
    $redis->close();
    
    // Успешный ответ
    echo json_encode([
        'success' => true,
        'timestamp' => $timestamp,
        'sensors_count' => 42, // 21 temp + 21 level
        'history_size' => $historySize,
        'message' => 'Данные успешно записаны в Redis'
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => isset($timestamp) ? $timestamp : null
    ], JSON_UNESCAPED_UNICODE);
}
