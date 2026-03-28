<?php
/**
 * Redis SCADA API - Чтение данных
 * Поддерживает чтение 1 счётчика, нескольких или всех сразу
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Только GET запросы
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'error' => 'Метод не разрешён. Используйте GET'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Параметры Redis
$redisHost = '127.0.0.1';
$redisPort = 6379;
$redisDb = 0;

// Параметры запроса
$count = isset($_GET['count']) ? (int)$_GET['count'] : 1000;
$counter = isset($_GET['counter']) ? (int)$_GET['counter'] : null;
$counters = isset($_GET['counters']) ? $_GET['counters'] : null;

try {
    // Подключение к Redis
    $redis = new Redis();
    $connected = $redis->connect($redisHost, $redisPort, 2.0);
    
    if (!$connected) {
        throw new Exception('Не удалось подключиться к Redis');
    }
    
    $redis->select($redisDb);
    
    // Вариант 1: Один счётчик
    if ($counter !== null) {
        if ($counter < 1 || $counter > 100) {
            throw new Exception('Номер счётчика должен быть от 1 до 100');
        }
        
        $key = "counter{$counter}_data";
        // ВАЖНО: LPUSH добавляет в начало, поэтому 0 = самый новый элемент
        $start = 0;
        $end = $count - 1;
        $data = $redis->lRange($key, $start, $end);
        
        // Парсим JSON
        $parsedData = [];
        if ($data !== false && !empty($data)) {
            foreach ($data as $item) {
                $decoded = json_decode($item, true);
                if ($decoded !== null) {
                    $parsedData[] = $decoded;
                }
            }
        }
        
        echo json_encode([
            'success' => true,
            'counter' => $counter,
            'count' => count($parsedData),
            'data' => $parsedData
        ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    }
    // Вариант 2: Несколько счётчиков или все
    elseif ($counters !== null) {
        $result = [
            'success' => true,
            'counters' => []
        ];
        
        // Определяем список счётчиков
        if ($counters === 'all') {
            // Получаем все ключи counter*_data
            $keys = $redis->keys('counter*_data');
            $counterList = [];
            foreach ($keys as $key) {
                if (preg_match('/counter(\d+)_data/', $key, $matches)) {
                    $counterList[] = (int)$matches[1];
                }
            }
            sort($counterList);
        } else {
            // Парсим список через запятую
            $counterList = array_map('intval', explode(',', $counters));
        }
        
        // Читаем данные для каждого счётчика
        foreach ($counterList as $cnt) {
            if ($cnt < 1 || $cnt > 100) {
                continue;
            }
            
            $key = "counter{$cnt}_data";
            // ВАЖНО: LPUSH добавляет в начало, поэтому 0 = самый новый элемент
            $start = 0;
            $end = $count - 1;
            $data = $redis->lRange($key, $start, $end);
            
            // Парсим JSON
            $parsedData = [];
            if ($data !== false && !empty($data)) {
                foreach ($data as $item) {
                    $decoded = json_decode($item, true);
                    if ($decoded !== null) {
                        $parsedData[] = $decoded;
                    }
                }
            }
            
            $result['counters'][$cnt] = [
                'count' => count($parsedData),
                'data' => $parsedData
            ];
        }
        
        echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    } else {
        throw new Exception('Укажите параметр counter (номер) или counters (список через запятую или "all")');
    }
    
    $redis->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
