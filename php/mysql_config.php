<?php
// ===============================================================================
// MySQL API Configuration v1.1 - Universal Compatible Version
// Универсальная совместимая версия для PHP 5.6+ и MySQL 5.7+
// ===============================================================================

// Включаем отображение ошибок для диагностики (только на локальном сервере)
$server_host = isset($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : '';
$is_local_server = ($server_host === 'localhost' || 
                   $server_host === '127.0.0.1' || 
                   strpos($server_host, '127.0.0.1') !== false ||
                   strpos($server_host, 'localhost') !== false);

if ($is_local_server) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    ini_set('log_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
}

// ===============================================================================
// DATABASE SETTINGS
// ===============================================================================

// Настройки для локального сервера (OpenServer)
$db_host_local = 'localhost';
$db_user_local = 'root';
$db_pass_local = '';
$db_name_local = 'scada_mysql';

// Настройки для хостинга (заполнить своими данными)
$db_host_remote = 'localhost';
$db_user_remote = 'YOUR_DB_USER';
$db_pass_remote = 'YOUR_DB_PASS';
$db_name_remote = 'YOUR_DB_NAME';

// Выбор настроек в зависимости от окружения
if ($is_local_server) {
    $db_host = $db_host_local;
    $db_user = $db_user_local;
    $db_pass = $db_pass_local;
    $db_name = $db_name_local;
} else {
    $db_host = $db_host_remote;
    $db_user = $db_user_remote;
    $db_pass = $db_pass_remote;
    $db_name = $db_name_remote;
}

// ===============================================================================
// SECURITY SETTINGS
// ===============================================================================

// Основной ключ доступа к API
$api_secret_key = 'test_local_key_12345';

// Секретный пароль для получения ключа (совместимость со старым API)
$secret_admin_password = 'super_admin_pass';

// ===============================================================================
// API SETTINGS
// ===============================================================================

// Максимальное количество записей в одном запросе
$max_records_limit = 1000;

// Таймаут выполнения запросов (секунды)
$query_timeout = 30;

// ⚠️ ВРЕМЕННО: debug и детали ошибок включены для диагностики хостинга
$debug_mode = $is_local_server;
$show_access_error_details = $is_local_server;

?>