<?php
ob_start(); // Буфер вывода — чтобы ob_clean() всегда работал и Notice не попадал в ответ
// ===============================================================================
// MySQL Universal API v1.0
// Универсальный API для работы с MySQL из AutoIt
// Поддержка простого формата и JSON ответов
// ===============================================================================
// 
// ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ФУНКЦИЙ!
// ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ИЗМЕНЕНИИ ПАРАМЕТРОВ И КЛЮЧЕЙ!
//
// ПОДДЕРЖИВАЕМЫЕ ОПЕРАЦИИ:
// ===============================================================================
// ОСНОВНЫЕ ОПЕРАЦИИ:
// sql - выполнение произвольного SQL запроса
// params - параметры для подстановки в запрос (разделитель |)
// format - формат ответа: simple (по умолчанию) или json
//
// ВСПОМОГАТЕЛЬНЫЕ ОПЕРАЦИИ:
// get_key - получение актуального ключа доступа
// ping - проверка доступности API
// ===============================================================================

require_once 'mysql_config.php';
require_once 'mysql_functions.php';

// CORS — разрешаем запросы из WebView2 (file:// origin = null) и локальных SCADA приложений
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

// Установка заголовков для корректной работы с UTF-8 и русским языком
header('Content-Type: text/html; charset=utf-8');

// ===============================================================================
// СИСТЕМА ЗАЩИТЫ ПО USER-AGENT (только в продакшен режиме)
// ===============================================================================
if (!$debug_mode) {
    // В продакшен режиме проверяем User-Agent для защиты от несанкционированного доступа
    $user_agent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';
    
    // Разрешённые User-Agent клиенты:
    // - MySQL_API_Client       — AutoIt au3 библиотека (POST запросы)
    // - MySQL_API_Preact_Client — WebView2/Preact фронтенд (GET/POST запросы)
    $allowed_agents = array(
        'MySQL_API_Client/1.0 keytIHYxLjkuMiAtIDIwMTQtMDMtMjYNCiogaHR0cDovL2pxdWVyeXVpLmNvbQ0KKiBJbmNsdWRlc',
        'MySQL_API_Preact_Client/1.0 keytIHYxLjkuMiAtIDIwMTQtMDMtMjYNCiogaHR0cDovL2pxdWVyeXVpLmNvbQ0KKiBJbmNsdWRlc',
    );

    $agent_allowed = false;
    foreach ($allowed_agents as $allowed) {
        if (strpos($user_agent, $allowed) !== false) {
            $agent_allowed = true;
            break;
        }
    }

    if (!$agent_allowed) {
        // Неразрешённый User-Agent — отказываем в доступе без объяснений
        http_response_code(403);
        die('Access denied');
    }
}

// ===============================================================================
// СЛУЖЕБНЫЕ ФУНКЦИИ
// ===============================================================================

// Получение параметров из GET или POST запроса
function getParam($name, $default = null) {
    // Совместимая замена ?? оператора для PHP 5.6+
    if (isset($_POST[$name])) {
        return $_POST[$name];
    } elseif (isset($_GET[$name])) {
        return $_GET[$name];
    } else {
        return $default;
    }
}

// Получение ключа доступа (совместимость со старым API)
if (getParam('get_my_key') === $secret_admin_password) {
    ob_clean();
    die(trim($api_secret_key));
}

// Быстрая проверка доступности API (БЕЗ ключа для скорости)
if (getParam('ping') === '1') {
    ob_clean();
    die('PONG');
}

// Быстрая проверка доступности API (С ключом для совместимости)
if (getParam('ping') && getParam('key') === $api_secret_key) {
    ob_clean();
    die('PONG');
}

// Проверка ключа доступа
if (!getParam('key')) {
    http_response_code(403);
    if ($show_access_error_details) {
        die('ERROR:Access denied - API key is required');
    } else {
        die('ERROR:Access denied');
    }
}

if (getParam('key') !== $api_secret_key) {
    http_response_code(403);
    $remote_addr = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : 'unknown';
    logError("Invalid API key attempt: " . getParam('key') . " from IP: " . $remote_addr);
    if ($show_access_error_details) {
        die('ERROR:Access denied - Invalid API key');
    } else {
        die('ERROR:Access denied');
    }
}

// ===============================================================================
// ОСНОВНАЯ ЛОГИКА ОБРАБОТКИ ЗАПРОСОВ
// ===============================================================================

// Получение параметров запроса (поддержка GET и POST)
// Если передан флаг sql_b64=1 — sql и params закодированы в base64 (новые клиенты)
// Без флага — для POST $_POST уже декодирован PHP автоматически, для GET нужен urldecode
$use_b64 = (getParam('sql_b64', '0') === '1');
$is_post = ($_SERVER['REQUEST_METHOD'] === 'POST');

$sql = getParam('sql');
if ($sql) {
    if ($use_b64) {
        $sql = base64_decode($sql);
    } elseif (!$is_post) {
        $sql = urldecode($sql);
    }
    // POST без b64 — $_POST уже декодирован, ничего не делаем
} else {
    $sql = '';
}

$params_str = getParam('params');
if ($params_str) {
    if ($use_b64) {
        $params_str = base64_decode($params_str);
    } elseif (!$is_post) {
        $params_str = urldecode($params_str);
    }
} else {
    $params_str = '';
}

$format = getParam('format', 'simple');

// Параметр columns=1 — добавить имена колонок в ответ (по умолчанию 0, au3 не использует)
$with_columns = (getParam('columns', '0') === '1');

// Проверка наличия SQL запроса
if (empty($sql)) {
    if ($format === 'json') {
        echo json_encode(array('status' => 'error', 'error' => 'SQL query is required'));
    } else {
        echo 'ERROR:SQL query is required';
    }
    exit;
}

// Парсинг параметров
$params = array();
if (!empty($params_str)) {
    $params = explode('|', $params_str);
}

// Выполнение запроса
try {
    $result = executeQuery($sql, $params);
    
    if ($result === false) {
        throw new Exception(getLastDatabaseError());
    }
    
    // Форматирование ответа
    if ($format === 'json') {
        formatJSONResponse($result, $sql, $with_columns);
    } else {
        formatSimpleResponse($result, $sql, $with_columns);
    }
    
} catch (Exception $e) {
    logError("Query error: " . $e->getMessage() . " | SQL: " . $sql);
    
    if ($format === 'json') {
        echo json_encode(array('status' => 'error', 'error' => $e->getMessage()));
    } else {
        echo 'ERROR:' . $e->getMessage();
    }
}

?>