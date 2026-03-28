<?php
// ===============================================================================
// MySQL API Functions v1.0
// Вспомогательные функции для работы с MySQL API
// Функции подключения, выполнения запросов и форматирования ответов
// ===============================================================================
// 
// ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ФУНКЦИЙ!
// ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ИЗМЕНЕНИИ ПАРАМЕТРОВ ФУНКЦИЙ!
//
// СПИСОК ФУНКЦИЙ:
// ===============================================================================
// ФУНКЦИИ ПОДКЛЮЧЕНИЯ:
// getDatabaseConnection() - Получение подключения к БД
// closeDatabaseConnection($link) - Закрытие подключения
//
// ФУНКЦИИ ВЫПОЛНЕНИЯ ЗАПРОСОВ:
// executeQuery($sql, $params) - Выполнение SQL запроса с параметрами
// getLastDatabaseError() - Получение последней ошибки БД
//
// ФУНКЦИИ ФОРМАТИРОВАНИЯ ОТВЕТОВ:
// formatSimpleResponse($result, $sql) - Форматирование в простой формат
// formatJSONResponse($result, $sql) - Форматирование в JSON формат
//
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ:
// _notEmpty($value) - Проверка на непустое значение
// logError($message) - Логирование ошибок
// isSelectQuery($sql) - Проверка является ли запрос SELECT
// ===============================================================================

// Глобальная переменная для хранения последней ошибки БД
$last_db_error = '';

// ===============================================================================
// ФУНКЦИИ ПОДКЛЮЧЕНИЯ
// ===============================================================================

/**
 * Получение подключения к базе данных
 * @return mysqli|false Объект подключения или false при ошибке
 */
function getDatabaseConnection() {
    global $db_host, $db_user, $db_pass, $db_name, $last_db_error;
    
    $link = mysqli_connect($db_host, $db_user, $db_pass, $db_name);
    
    if (!$link) {
        $last_db_error = mysqli_connect_error();
        logError("Database connection failed: " . $last_db_error);
        return false;
    }
    
    // КРИТИЧНО: Устанавливаем кодировку UTF-8 для корректной работы с русским языком
    // Используем UTF8MB4 для совместимости с MySQL 8.0 и поддержки эмодзи
    if (!mysqli_set_charset($link, "utf8mb4")) {
        // Fallback на UTF8 для старых версий MySQL
        if (!mysqli_set_charset($link, "utf8")) {
            $last_db_error = mysqli_error($link);
            logError("Failed to set charset: " . $last_db_error);
            mysqli_close($link);
            return false;
        }
    }
    
    // ДОПОЛНИТЕЛЬНО: SET NAMES для совместимости с хостингом (как в varka.php)
    $charset = mysqli_character_set_name($link);
    $query = "SET NAMES " . $charset;
    $result = mysqli_query($link, $query);
    if (!$result) {
        $last_db_error = "Failed to execute SET NAMES: " . mysqli_error($link);
        logError($last_db_error);
        mysqli_close($link);
        return false;
    }
    
    return $link;
}

/**
 * Закрытие подключения к базе данных
 * @param mysqli $link Объект подключения
 */
function closeDatabaseConnection($link) {
    if ($link) {
        mysqli_close($link);
    }
}

// ===============================================================================
// ФУНКЦИИ ВЫПОЛНЕНИЯ ЗАПРОСОВ
// ===============================================================================

/**
 * Выполнение SQL запроса с параметрами
 * @param string $sql SQL запрос
 * @param array $params Массив параметров для подстановки
 * @return array|bool|int Результат запроса или false при ошибке
 */
function executeQuery($sql, $params = array()) {
    global $last_db_error, $query_timeout;
    
    $link = getDatabaseConnection();
    if (!$link) {
        return false;
    }
    
    // Установка таймаута
    mysqli_options($link, MYSQLI_OPT_CONNECT_TIMEOUT, $query_timeout);
    
    try {
        // Подготовка запроса
        $stmt = mysqli_prepare($link, $sql);
        if (!$stmt) {
            $last_db_error = mysqli_error($link);
            closeDatabaseConnection($link);
            return false;
        }
        
        // Привязка параметров если есть
        if (!empty($params)) {
            $types = str_repeat('s', count($params)); // Все параметры как строки
            mysqli_stmt_bind_param($stmt, $types, ...$params);
        }
        
        // Выполнение запроса
        if (!mysqli_stmt_execute($stmt)) {
            $last_db_error = mysqli_stmt_error($stmt);
            mysqli_stmt_close($stmt);
            closeDatabaseConnection($link);
            return false;
        }
        
        // Обработка результата в зависимости от типа запроса
        if (isSelectQuery($sql)) {
            // SELECT запрос - возвращаем данные
            $result = mysqli_stmt_get_result($stmt);
            if (!$result) {
                $last_db_error = mysqli_stmt_error($stmt);
                mysqli_stmt_close($stmt);
                closeDatabaseConnection($link);
                return false;
            }
            
            $data = array();
            while ($row = mysqli_fetch_row($result)) {
                $data[] = $row;
            }
            
            // Получаем имена колонок
            $fields = mysqli_fetch_fields($result);
            $columns = array();
            if ($fields) {
                foreach ($fields as $field) {
                    $columns[] = $field->name;
                }
            }
            
            mysqli_free_result($result);
            mysqli_stmt_close($stmt);
            closeDatabaseConnection($link);
            
            return array('rows' => $data, 'columns' => $columns);
            
        } else {
            // INSERT/UPDATE/DELETE/CREATE и другие запросы
            $affected_rows = mysqli_stmt_affected_rows($stmt);
            
            // Для INSERT запросов также возвращаем last_insert_id
            $last_insert_id = 0;
            if (stripos(trim($sql), 'INSERT') === 0) {
                $last_insert_id = mysqli_insert_id($link);
            }
            
            mysqli_stmt_close($stmt);
            closeDatabaseConnection($link);
            
            // Возвращаем массив с affected_rows и last_insert_id для INSERT
            if ($last_insert_id > 0) {
                return array('affected_rows' => $affected_rows, 'last_insert_id' => $last_insert_id);
            }
            
            return $affected_rows;
        }
        
    } catch (Exception $e) {
        $last_db_error = $e->getMessage();
        if (isset($stmt)) mysqli_stmt_close($stmt);
        closeDatabaseConnection($link);
        return false;
    }
}

/**
 * Получение последней ошибки базы данных
 * @return string Описание ошибки
 */
function getLastDatabaseError() {
    global $last_db_error;
    return $last_db_error;
}

// ===============================================================================
// ФУНКЦИИ ФОРМАТИРОВАНИЯ ОТВЕТОВ
// ===============================================================================

/**
 * Форматирование ответа в простой формат (совместимость со старым API)
 * @param mixed $result Результат запроса
 * @param string $sql SQL запрос
 * @param bool $with_columns Добавить строку с именами колонок (columns=1)
 */
function formatSimpleResponse($result, $sql, $with_columns = false) {
    if (isSelectQuery($sql)) {
        // SELECT запрос - выводим данные в формате <start_string>
        $rows = is_array($result) && isset($result['rows']) ? $result['rows'] : array();
        $columns = is_array($result) && isset($result['columns']) ? $result['columns'] : array();

        if ($with_columns && !empty($columns)) {
            // Отдельный тег для имён колонок — не путается с данными
            echo "<start_columns>" . implode(';', $columns) . "</start_columns><br>";
        }

        if (!empty($rows)) {
            foreach ($rows as $row) {
                echo "<start_string>";
                echo implode(';', $row);
                echo "</start_string><br>";
            }
        }
        // Если данных нет, ничего не выводим (пустой результат)
    } else {
        // Другие запросы - выводим статус
        if ($result !== false) {
            // Проверяем если это массив с last_insert_id (INSERT запрос)
            if (is_array($result) && isset($result['last_insert_id'])) {
                if ($result['affected_rows'] > 0) {
                    echo "AFFECTED:" . $result['affected_rows'] . "|LASTID:" . $result['last_insert_id'];
                } else {
                    echo "SUCCESS:Query executed successfully|LASTID:" . $result['last_insert_id'];
                }
            } elseif (is_numeric($result) && $result > 0) {
                echo "AFFECTED:" . $result;
            } else {
                echo "SUCCESS:Query executed successfully";
            }
        } else {
            echo "ERROR:" . getLastDatabaseError();
        }
    }
}

/**
 * Форматирование ответа в JSON формат
 * @param mixed $result Результат запроса
 * @param string $sql SQL запрос
 * @param bool $with_columns Добавить массив columns в ответ
 */
function formatJSONResponse($result, $sql, $with_columns = false) {
    if (isSelectQuery($sql)) {
        $rows = is_array($result) && isset($result['rows']) ? $result['rows'] : array();
        $columns = is_array($result) && isset($result['columns']) ? $result['columns'] : array();

        $response = array(
            'status' => 'success',
            'data'   => $rows,
            'count'  => count($rows),
        );
        if ($with_columns && !empty($columns)) {
            $response['columns'] = $columns;
        }
        echo json_encode($response);
    } else {
        // Другие запросы
        if ($result !== false) {
            if (is_array($result) && isset($result['last_insert_id'])) {
                echo json_encode(array(
                    'status'         => 'success',
                    'affected_rows'  => $result['affected_rows'],
                    'last_insert_id' => $result['last_insert_id'],
                    'message'        => 'Query executed successfully'
                ));
            } else {
                echo json_encode(array(
                    'status'        => 'success',
                    'affected_rows' => is_numeric($result) ? (int)$result : 0,
                    'message'       => 'Query executed successfully'
                ));
            }
        } else {
            echo json_encode(array('status' => 'error', 'error' => getLastDatabaseError()));
        }
    }
}

// ===============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// ===============================================================================

/**
 * Проверка на непустое значение
 * @param mixed $value Значение для проверки
 * @return bool True если значение не пустое
 */
function _notEmpty($value) {
    return isset($value) && !empty($value);
}

/**
 * Логирование ошибок
 * @param string $message Сообщение для логирования
 */
function logError($message) {
    global $debug_mode;
    if ($debug_mode) {
        error_log("[MySQL API] " . date('Y-m-d H:i:s') . " - " . $message);
    }
}

/**
 * Проверка является ли запрос SELECT
 * @param string $sql SQL запрос
 * @return bool True если это SELECT запрос
 */
function isSelectQuery($sql) {
    return stripos(trim($sql), 'SELECT') === 0;
}

?>