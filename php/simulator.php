<?php
/**
 * Симулятор данных SCADA
 * Генерирует реалистичные данные для 7 счётчиков
 */

// Параметры симуляции
$countersCount = 7;
$pointsPerCounter = 10; // Сколько точек сгенерировать
$writeUrl = 'http://127.0.0.1/php/redis_write.php';

// Базовые значения для каждого счётчика
$baseValues = [
    1 => ['volume_flow' => 45.0, 'mass_flow' => 42.0, 'liters' => 1000, 'kg' => 950, 'density' => 0.95, 'temperature' => 25, 'pressure' => 1.2],
    2 => ['volume_flow' => 38.0, 'mass_flow' => 35.0, 'liters' => 800, 'kg' => 760, 'density' => 0.92, 'temperature' => 22, 'pressure' => 1.1],
    3 => ['volume_flow' => 52.0, 'mass_flow' => 48.0, 'liters' => 1200, 'kg' => 1140, 'density' => 0.98, 'temperature' => 28, 'pressure' => 1.3],
    4 => ['volume_flow' => 41.0, 'mass_flow' => 39.0, 'liters' => 950, 'kg' => 900, 'density' => 0.94, 'temperature' => 24, 'pressure' => 1.15],
    5 => ['volume_flow' => 48.0, 'mass_flow' => 45.0, 'liters' => 1100, 'kg' => 1045, 'density' => 0.96, 'temperature' => 26, 'pressure' => 1.25],
    6 => ['volume_flow' => 35.0, 'mass_flow' => 33.0, 'liters' => 750, 'kg' => 712, 'density' => 0.91, 'temperature' => 21, 'pressure' => 1.05],
    7 => ['volume_flow' => 55.0, 'mass_flow' => 51.0, 'liters' => 1300, 'kg' => 1235, 'density' => 0.99, 'temperature' => 29, 'pressure' => 1.35],
];

echo "🎲 Симулятор данных SCADA\n";
echo "========================\n\n";

// Генерируем данные для каждого счётчика
for ($i = 0; $i < $pointsPerCounter; $i++) {
    $timestamp = microtime(true);
    $countersData = [];
    
    foreach ($baseValues as $counterNum => $base) {
        // Добавляем случайные отклонения (±10%)
        $data = [
            'timestamp' => $timestamp,
            'volume_flow' => round($base['volume_flow'] + (rand(-100, 100) / 10), 2),
            'mass_flow' => round($base['mass_flow'] + (rand(-100, 100) / 10), 2),
            'liters' => round($base['liters'] + rand(-50, 50), 1),
            'kg' => round($base['kg'] + rand(-50, 50), 1),
            'density' => round($base['density'] + (rand(-5, 5) / 100), 3),
            'temperature' => round($base['temperature'] + (rand(-20, 20) / 10), 1),
            'pressure' => round($base['pressure'] + (rand(-10, 10) / 100), 2),
            'status' => rand(0, 100) > 5 ? 'OK' : 'WARNING', // 95% OK, 5% WARNING
            'error_code' => 0
        ];
        
        $countersData[] = [
            'counter' => $counterNum,
            'data' => $data
        ];
    }
    
    // Отправляем все 7 счётчиков одним запросом
    $payload = json_encode(['counters' => $countersData], JSON_UNESCAPED_UNICODE);
    
    $ch = curl_init($writeUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        echo "✅ Точка " . ($i + 1) . ": Записано 7 счётчиков\n";
    } else {
        echo "❌ Точка " . ($i + 1) . ": Ошибка ($httpCode)\n";
    }
    
    // Задержка между точками (имитация реального времени)
    usleep(100000); // 0.1 сек
}

echo "\n✅ Симуляция завершена!\n";
echo "📊 Всего записано: " . ($pointsPerCounter * $countersCount) . " точек\n";
