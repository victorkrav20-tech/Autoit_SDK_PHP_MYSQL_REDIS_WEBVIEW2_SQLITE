; ===============================================================================
; MySQL AutoTest v1.0
; Автоматическое тестирование MySQL Core API библиотеки
; Тестирование локального сервера, хостинга и синхронизации
; ===============================================================================
;
; ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ТЕСТОВЫХ ФУНКЦИЙ!
; ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ИЗМЕНЕНИИ ПАРАМЕТРОВ ТЕСТИРОВАНИЯ!
;
; СПИСОК ТЕСТОВЫХ ФУНКЦИЙ:
; ===============================================================================
; ОСНОВНЫЕ ТЕСТЫ:
; _TestBasicQuery() - Тест базового SQL запроса
; _TestCreateTable() - Тест создания тестовой таблицы
; _TestInsertData() - Тест вставки данных
; _TestSelectData() - Тест выборки данных
; _TestUpdateData() - Тест обновления данных
; _TestDeleteData() - Тест удаления данных
;
; ТЕСТЫ JSON ФОРМАТА:
; _TestJSONFormat() - Тест JSON формата ответов
; _TestJSONSelect() - Тест SELECT в JSON формате
; _TestJSONInsert() - Тест INSERT в JSON формате
;
; ТЕСТЫ БЕЗОПАСНОСТИ:
; _TestSecurityNoKey() - Тест без ключа доступа
; _TestSecurityWrongKey() - Тест с неверным ключом
; _TestSecurityEmptySQL() - Тест с пустым SQL запросом
; _TestSecuritySQLInjection() - Тест на SQL инъекции
;
; ТЕСТЫ WRAPPER-ФУНКЦИЙ:
; _TestWrapperSelect() - Тест wrapper-функции SELECT
; _TestWrapperInsert() - Тест wrapper-функции INSERT
; _TestWrapperSelectAdvanced() - Тест расширенного SELECT
; _TestWrapperUpdate() - Тест wrapper-функции UPDATE
; _TestWrapperDelete() - Тест wrapper-функции DELETE
; _TestWrapperSecurity() - Тест безопасности wrapper-функций
; _TestWrapperInsertSCADA() - Тест SCADA вставки с UUID v7
;
; ТЕСТЫ УТИЛИТАРНЫХ ФУНКЦИЙ:
; _TestUtilityCount() - Тест утилиты _MySQL_Count
; _TestUtilityExists() - Тест утилиты _MySQL_Exists
; _TestUtilityGetLastInsertID() - Тест утилиты _MySQL_GetLastInsertID
;
; ТЕСТЫ ПРОИЗВОДИТЕЛЬНОСТИ:
; _TestPerformance() - Тест производительности запросов
;
; ТЕСТЫ ОШИБОК И ВОССТАНОВЛЕНИЯ:
; _TestErrorHandling() - Тест обработки ошибок
; _TestConnectionFailure() - Тест недоступности сервера
;
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ:
; _RunAllTests() - Запуск всех тестов
; _PrintTestResult($sTestName, $bResult, $fTime) - Вывод результата теста
; ===============================================================================

#include-once
#include "MySQL_Core_API.au3"
#include "../Utils/Utils.au3"

; ===============================================================================
; ИНИЦИАЛИЗАЦИЯ ЛОГИРОВАНИЯ
; ===============================================================================

; Инициализация Utils для логирования MySQL AutoTest
_SDK_Utils_Init("MySQL_AutoTest", "MySQL", True, 3, 3, True)

; Инициализация системы очередей MySQL
_MySQL_InitQueue()

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ДЛЯ ТЕСТИРОВАНИЯ
; ===============================================================================

; Настройки тестирования
Global $g_sTest_TableName = "test_table"
Global $g_iTest_CycleCount = 0
Global $g_bTest_ContinuousMode = False
Global $g_iTest_DelayBetweenCycles = 1000 ; мс между циклами

; Статистика тестирования
Global $g_iTest_TotalQueries = 0
Global $g_fTest_TotalTime = 0
Global $g_iTest_SuccessCount = 0
Global $g_iTest_ErrorCount = 0

; ===============================================================================
; ТЕСТОВЫЕ ФУНКЦИИ БУДУТ ДОБАВЛЕНЫ ПОСЛЕ СОЗДАНИЯ ОСНОВНОЙ БИБЛИОТЕКИ
; ===============================================================================
; ===============================================================================
; ОСНОВНАЯ ФУНКЦИЯ ЗАПУСКА ТЕСТОВ
; ===============================================================================

; Инициализация
_Logger_ClearLog()
_Logger_ConsoleWriteUTF("🧪 MySQL AutoTest запущен")
_Logger_ConsoleWriteUTF("🔧 Тестирование библиотеки MySQL_Core_API")

; КРИТИЧНО: Инициализация очередей SQLite перед тестами
;_MySQL_InitQueue()

_RunAllTests()
; Запуск теста очереди по умолчанию
;_TestQueueSystem()

_Logger_ConsoleWriteUTF("✅ Тестирование завершено")
_Logger_ConsoleWriteUTF("📊 Нажмите любую клавишу для выхода...")
ConsoleRead()


; ===============================================================================
; ФУНКЦИЯ ЗАПУСКА ВСЕХ ТЕСТОВ (ЗАКОММЕНТИРОВАНО)
; ===============================================================================

Func _RunAllTests()
    Local $hTotalTimer = _Utils_GetTimestamp()
    Local $iTotalTests = 0
    Local $iPassedTests = 0

    _Logger_ConsoleWriteUTF("")
    _Logger_ConsoleWriteUTF("🚀 Начинаем тестирование...")
    _Logger_ConsoleWriteUTF("")

    ; Тест 1: Создание тестовой таблицы
    $iTotalTests += 1
    If _TestCreateTable() Then $iPassedTests += 1

    ; Тест 2: Базовый SELECT запрос
    $iTotalTests += 1
    If _TestBasicQuery() Then $iPassedTests += 1

    ; Тест 3: Вставка данных
    $iTotalTests += 1
    If _TestInsertData() Then $iPassedTests += 1

    ; Тест 4: Выборка данных
    $iTotalTests += 1
    If _TestSelectData() Then $iPassedTests += 1

    ; Тест 5: Обновление данных
    $iTotalTests += 1
    If _TestUpdateData() Then $iPassedTests += 1

    ; Тест 6: Удаление данных
    $iTotalTests += 1
    If _TestDeleteData() Then $iPassedTests += 1

    ; Тест 7: Обработка ошибок
    $iTotalTests += 1
    If _TestErrorHandling() Then $iPassedTests += 1

    ; Тест 8: JSON формат SELECT
    $iTotalTests += 1
    If _TestJSONSelect() Then $iPassedTests += 1

    ; Тест 9: JSON формат INSERT
    $iTotalTests += 1
    If _TestJSONInsert() Then $iPassedTests += 1

    ; Тест 10: Безопасность - без ключа
    $iTotalTests += 1
    If _TestSecurityNoKey() Then $iPassedTests += 1

    ; Тест 11: Безопасность - неверный ключ
    $iTotalTests += 1
    If _TestSecurityWrongKey() Then $iPassedTests += 1

    ; Тест 12: Безопасность - пустой SQL
    $iTotalTests += 1
    If _TestSecurityEmptySQL() Then $iPassedTests += 1

    ; Тест 13: Wrapper-функция _MySQL_Select
    $iTotalTests += 1
    If _TestWrapperSelect() Then $iPassedTests += 1

    ; Тест 14: Wrapper-функция _MySQL_Insert
    $iTotalTests += 1
    If _TestWrapperInsert() Then $iPassedTests += 1

    ; Тест 15: Wrapper-функция _MySQL_Select с условиями
    $iTotalTests += 1
    If _TestWrapperSelectAdvanced() Then $iPassedTests += 1

    ; Тест 16: Wrapper-функция _MySQL_Update
    $iTotalTests += 1
    If _TestWrapperUpdate() Then $iPassedTests += 1

    ; Тест 17: Wrapper-функция _MySQL_Delete
    $iTotalTests += 1
    If _TestWrapperDelete() Then $iPassedTests += 1

    ; Тест 18: Безопасность wrapper-функций (обязательное WHERE)
    $iTotalTests += 1
    If _TestWrapperSecurity() Then $iPassedTests += 1

    ; Тест 19: Wrapper _MySQL_InsertSCADA (с автоматическим UUID v7)
    $iTotalTests += 1
    If _TestWrapperInsertSCADA() Then $iPassedTests += 1

    ; Тест 20: Утилита _MySQL_Count (подсчет записей)
    $iTotalTests += 1
    If _TestUtilityCount() Then $iPassedTests += 1

    ; Тест 21: Утилита _MySQL_Exists (проверка существования)
    $iTotalTests += 1
    If _TestUtilityExists() Then $iPassedTests += 1

    ; Тест 22: Утилита _MySQL_GetLastInsertID (получение ID)
    $iTotalTests += 1
    If _TestUtilityGetLastInsertID() Then $iPassedTests += 1

    Local $fTotalTime = _Utils_GetElapsedTime($hTotalTimer)

    _Logger_ConsoleWriteUTF("")
    _Logger_ConsoleWriteUTF("📊 ИТОГИ ТЕСТИРОВАНИЯ:")
    _Logger_ConsoleWriteUTF("   Всего тестов: " & $iTotalTests)
    _Logger_ConsoleWriteUTF("   Пройдено: " & $iPassedTests)
    _Logger_ConsoleWriteUTF("   Провалено: " & ($iTotalTests - $iPassedTests))
    _Logger_ConsoleWriteUTF("   Общее время: " & StringFormat("%.2f", $fTotalTime) & "мс")

    ; Записываем итоги в файл лога через Logger V2
    _Logger_Write("========================================", 1)
    _Logger_Write("📊 ИТОГИ ТЕСТИРОВАНИЯ MySQL AutoTest", 1)
    _Logger_Write("========================================", 1)
    _Logger_Write("Всего тестов: " & $iTotalTests, 1)
    _Logger_Write("Пройдено: " & $iPassedTests, 3)
    _Logger_Write("Провалено: " & ($iTotalTests - $iPassedTests), ($iTotalTests - $iPassedTests > 0 ? 2 : 1))
    _Logger_Write("Общее время: " & StringFormat("%.2f", $fTotalTime) & "мс", 1)

    If $iPassedTests = $iTotalTests Then
        _Logger_ConsoleWriteUTF("🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!")
        _Logger_Write("🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!", 3)
    Else
        _Logger_ConsoleWriteUTF("⚠️ НЕКОТОРЫЕ ТЕСТЫ ПРОВАЛЕНЫ!")
        _Logger_Write("⚠️ НЕКОТОРЫЕ ТЕСТЫ ПРОВАЛЕНЫ!", 2)
    EndIf

    ; Показываем статус очередей
    Local $aQueueStatus = _MySQL_GetQueueStatus()
    If $aQueueStatus[0] > 0 Or $aQueueStatus[1] > 0 Then
        _Logger_ConsoleWriteUTF("")
        _Logger_ConsoleWriteUTF("🔄 СТАТУС ОЧЕРЕДЕЙ:")
        _Logger_ConsoleWriteUTF("   Локальная очередь: " & $aQueueStatus[0] & " запросов")
        _Logger_ConsoleWriteUTF("   Удаленная очередь: " & $aQueueStatus[1] & " запросов")
    EndIf

    ; Предлагаем тест очередей
    _Logger_ConsoleWriteUTF("")
    _Logger_ConsoleWriteUTF("🧪 Хотите протестировать систему очередей?")
    _Logger_ConsoleWriteUTF("   Нажмите 'Q' для запуска теста очередей")
    _Logger_ConsoleWriteUTF("   Нажмите любую другую клавишу для выхода")

   ; Local $sKey = InputBox("Тест очередей", "Введите 'Q' для теста очередей или любой символ для выхода:", "", "", 300, 150)
   ; If StringUpper($sKey) = "Q" Then
   ;     _TestQueueSystem()
   ; EndIf
EndFunc



; ===============================================================================
; ТЕСТ СИСТЕМЫ ОЧЕРЕДЕЙ (АКТИВНЫЙ)
; ===============================================================================

; ===============================================================================
; Функция: _TestCreateTable
; Описание: Тест создания тестовых таблиц (test_table, test_users, test_products)
; ===============================================================================
Func _TestCreateTable()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Создание тестовых таблиц"
    Local $bAllSuccess = True

    ; ===== ТАБЛИЦА 1: test_table (основная тестовая) =====
    _Logger_ConsoleWriteUTF("   📋 Создание test_table...")
    _MySQL_Query("DROP TABLE IF EXISTS " & $g_sTest_TableName)

    Local $sSQL1 = "CREATE TABLE " & $g_sTest_TableName & " (" & _
                  "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                  "name VARCHAR(100) NOT NULL, " & _
                  "value VARCHAR(255), " & _
                  "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" & _
                  ")"

    Local $bResult1 = _MySQL_Query($sSQL1)
    If Not $bResult1 Then
        _Logger_ConsoleWriteUTF("   ❌ Ошибка создания test_table: " & _MySQL_GetLastError())
        $bAllSuccess = False
    Else
        _Logger_ConsoleWriteUTF("   ✅ test_table создана")
    EndIf

    ; ===== ТАБЛИЦА 2: test_users (для тестов 4, 5, 9) =====
    _Logger_ConsoleWriteUTF("   📋 Создание test_users...")
    _MySQL_Query("DROP TABLE IF EXISTS test_users")

    Local $sSQL2 = "CREATE TABLE test_users (" & _
                  "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                  "username VARCHAR(50) NOT NULL, " & _
                  "email VARCHAR(100), " & _
                  "status VARCHAR(20) DEFAULT 'active', " & _
                  "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" & _
                  ")"

    Local $bResult2 = _MySQL_Query($sSQL2)
    If Not $bResult2 Then
        _Logger_ConsoleWriteUTF("   ❌ Ошибка создания test_users: " & _MySQL_GetLastError())
        $bAllSuccess = False
    Else
        _Logger_ConsoleWriteUTF("   ✅ test_users создана")

        ; Вставляем тестовые данные в test_users
        _MySQL_Query("INSERT INTO test_users (username, email, status) VALUES ('john_doe', 'john@example.com', 'active')")
        _MySQL_Query("INSERT INTO test_users (username, email, status) VALUES ('jane_smith', 'jane@example.com', 'active')")
        _MySQL_Query("INSERT INTO test_users (username, email, status) VALUES ('bob_wilson', 'bob@example.com', 'inactive')")
        _Logger_ConsoleWriteUTF("   ✅ Добавлено 3 тестовых пользователя")
    EndIf

    ; ===== ТАБЛИЦА 3: test_products (для теста 6) =====
    _Logger_ConsoleWriteUTF("   📋 Создание test_products...")
    _MySQL_Query("DROP TABLE IF EXISTS test_products")

    Local $sSQL3 = "CREATE TABLE test_products (" & _
                  "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                  "name VARCHAR(100) NOT NULL, " & _
                  "price DECIMAL(10,2), " & _
                  "category VARCHAR(50), " & _
                  "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" & _
                  ")"

    Local $bResult3 = _MySQL_Query($sSQL3)
    If Not $bResult3 Then
        _Logger_ConsoleWriteUTF("   ❌ Ошибка создания test_products: " & _MySQL_GetLastError())
        $bAllSuccess = False
    Else
        _Logger_ConsoleWriteUTF("   ✅ test_products создана")

        ; Вставляем тестовые данные в test_products
        _MySQL_Query("INSERT INTO test_products (name, price, category) VALUES ('Laptop', 1200.00, 'Electronics')")
        _MySQL_Query("INSERT INTO test_products (name, price, category) VALUES ('Mouse', 25.50, 'Electronics')")
        _MySQL_Query("INSERT INTO test_products (name, price, category) VALUES ('Keyboard', 75.00, 'Electronics')")
        _MySQL_Query("INSERT INTO test_products (name, price, category) VALUES ('Monitor', 350.00, 'Electronics')")
        _MySQL_Query("INSERT INTO test_products (name, price, category) VALUES ('Premium Headset', 650.00, 'Audio')")
        _Logger_ConsoleWriteUTF("   ✅ Добавлено 5 тестовых продуктов")
    EndIf

    Local $fTime = _Utils_GetElapsedTime($hTimer)

    If $bAllSuccess Then
        _Logger_ConsoleWriteUTF("   ✅ Все таблицы созданы и заполнены")
    EndIf

    _PrintTestResult($sTestName, $bAllSuccess, $fTime)
    Return $bAllSuccess
EndFunc

; ===============================================================================
; Функция: _TestBasicQuery
; Описание: Тест базового SELECT запроса
; ===============================================================================
Func _TestBasicQuery()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Базовый SELECT запрос"

    Local $aResult = _MySQL_Query("SELECT 1 as test_value, 'Hello World' as test_string")
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = IsArray($aResult) And UBound($aResult) > 0

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   📊 Получено: " & $aResult[0][0] & ", " & $aResult[0][1])
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestInsertData
; Описание: Тест вставки данных
; ===============================================================================
Func _TestInsertData()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Вставка данных"

    Local $sSQL = "INSERT INTO " & $g_sTest_TableName & " (name, value) VALUES ('Test User', 'Test Value')"
    Local $bResult = _MySQL_Query($sSQL)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    _PrintTestResult($sTestName, $bResult, $fTime)
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestSelectData
; Описание: Тест выборки данных
; ===============================================================================
Func _TestSelectData()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Выборка данных"

    Local $sSQL = "SELECT * FROM test_users LIMIT 10"
    Local $aResult = _MySQL_Query($sSQL)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = IsArray($aResult)

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   📊 Найдено записей: " & UBound($aResult))
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestUpdateData
; Описание: Тест обновления данных
; ===============================================================================
Func _TestUpdateData()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Обновление данных"

    Local $sSQL = "UPDATE test_users SET status = 'inactive' WHERE username = 'john_doe'"
    Local $bResult = _MySQL_Query($sSQL)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    _PrintTestResult($sTestName, $bResult, $fTime)
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestDeleteData
; Описание: Тест удаления данных
; ===============================================================================
Func _TestDeleteData()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Удаление данных"

    Local $sSQL = "DELETE FROM test_products WHERE price > 500"
    Local $bResult = _MySQL_Query($sSQL)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    _PrintTestResult($sTestName, $bResult, $fTime)
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestErrorHandling
; Описание: Тест обработки ошибок
; ===============================================================================
Func _TestErrorHandling()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Обработка ошибок"

    ; Намеренно неверный SQL запрос
    Local $bResult = _MySQL_Query("SELECT * FROM nonexistent_table_12345")
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    ; Ожидаем что запрос провалится
    Local $bSuccess = ($bResult = False) And (_MySQL_GetLastError() <> "")

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   🔍 Ошибка корректно обработана: " & _MySQL_GetLastError())
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
; ===============================================================================

; ===============================================================================
; Функция: _PrintTestResult
; Описание: Вывод результата теста
; ===============================================================================
Func _PrintTestResult($sTestName, $bResult, $fTime)
    Local $sStatus = $bResult ? "✅ ПРОЙДЕН" : "❌ ПРОВАЛЕН"
    Local $sTimeStr = StringFormat("%.2f", $fTime) & "мс"

    _Logger_ConsoleWriteUTF($sStatus & " | " & $sTestName & " (" & $sTimeStr & ")")

    If Not $bResult Then
        Local $sError = _MySQL_GetLastError()
        If $sError <> "" Then
            _Logger_ConsoleWriteUTF("   🔍 Ошибка: " & $sError)
        EndIf
    EndIf

    _Logger_WriteToFile($sStatus & " " & $sTestName & " за " & $sTimeStr)
EndFunc
; ===============================================================================
; ТЕСТЫ JSON ФОРМАТА
; ===============================================================================

; ===============================================================================
; Функция: _TestJSONSelect
; Описание: Тест SELECT запроса в JSON формате
; ===============================================================================
Func _TestJSONSelect()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "JSON формат SELECT"

    Local $aResult = _MySQL_Query("SELECT 1 as test_id, 'JSON Test' as test_name", 0, $MYSQL_SERVER_LOCAL, True)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = IsArray($aResult) And UBound($aResult) > 0

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   📊 JSON данные получены: " & UBound($aResult) & " строк")
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestJSONInsert
; Описание: Тест INSERT запроса в JSON формате
; ===============================================================================
Func _TestJSONInsert()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "JSON формат INSERT"

    Local $sSQL = "INSERT INTO test_users (username, email) VALUES ('json_user', 'json@example.com')"
    Local $bResult = _MySQL_Query($sSQL, 0, $MYSQL_SERVER_LOCAL, True)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    If $bResult Then
        _Logger_ConsoleWriteUTF("   📊 JSON INSERT успешен")
    EndIf

    _PrintTestResult($sTestName, $bResult, $fTime)
    Return $bResult
EndFunc

; ===============================================================================
; ТЕСТЫ БЕЗОПАСНОСТИ
; ===============================================================================

; ===============================================================================
; Функция: _TestSecurityNoKey
; Описание: Тест запроса без ключа доступа
; ===============================================================================
Func _TestSecurityNoKey()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Безопасность - без ключа"

    ; Формируем URL без ключа
    Local $sURL = $g_sMySQL_LocalHost & "mysql_api.php?sql=SELECT%201"
    Local $sResponse = _MySQL_HttpRequest($sURL, $g_iMySQL_Timeout)
    Local $iHTTPStatus = @extended
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    ; Любой ответ с ERROR: считается успешной блокировкой
    Local $iError = @error
    Local $bSuccess = StringInStr($sResponse, "ERROR:") > 0

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   🛡️ Доступ корректно заблокирован: " & StringLeft($sResponse, 50))
    Else
        _Logger_ConsoleWriteUTF("   ❌ Неожиданный ответ (Err:" & $iError & "): '" & $sResponse & "'")
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestSecurityWrongKey
; Описание: Тест запроса с неверным ключом
; ===============================================================================
Func _TestSecurityWrongKey()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Безопасность - неверный ключ"

    ; Формируем URL с неверным ключом
    Local $sURL = $g_sMySQL_LocalHost & "mysql_api.php?key=wrong_key_12345&sql=SELECT%201"
    Local $sResponse = _MySQL_HttpRequest($sURL, $g_iMySQL_Timeout)
    Local $iHTTPStatus = @extended
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    ; Любой ответ с ERROR: считается успешной блокировкой
    Local $iError = @error
    Local $bSuccess = StringInStr($sResponse, "ERROR:") > 0

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   🛡️ Неверный ключ заблокирован: " & StringLeft($sResponse, 50))
    Else
        _Logger_ConsoleWriteUTF("   ❌ Неожиданный ответ (Err:" & $iError & "): '" & $sResponse & "'")
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestSecurityEmptySQL
; Описание: Тест запроса с пустым SQL
; ===============================================================================
Func _TestSecurityEmptySQL()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Безопасность - пустой SQL"

    ; Запрос с пустым SQL
    Local $bResult = _MySQL_Query("", 0, $MYSQL_SERVER_LOCAL, False)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    ; Ожидаем что запрос провалится
    Local $bSuccess = ($bResult = False) And StringInStr(_MySQL_GetLastError(), "required") > 0

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   🛡️ Пустой SQL заблокирован: " & _MySQL_GetLastError())
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; ТЕСТЫ WRAPPER-ФУНКЦИЙ
; ===============================================================================

; ===============================================================================
; Функция: _TestWrapperSelect
; Описание: Тест wrapper-функции _MySQL_Select
; ===============================================================================
Func _TestWrapperSelect()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Wrapper _MySQL_Select"

    ; Сначала создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_users")
    Local $sCreateSQL = "CREATE TABLE test_wrapper_users (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "name VARCHAR(50), " & _
                        "email VARCHAR(100), " & _
                        "status VARCHAR(20)" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Добавляем тестовые данные
    _MySQL_Query("INSERT INTO test_wrapper_users (name, email, status) VALUES ('Alice', 'alice@test.com', 'active')")
    _MySQL_Query("INSERT INTO test_wrapper_users (name, email, status) VALUES ('Bob', 'bob@test.com', 'inactive')")

    ; Тестируем простой SELECT через wrapper
    Local $aResult = _MySQL_Select("test_wrapper_users", "*")
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = IsArray($aResult) And UBound($aResult) >= 2

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   ✅ Получено " & UBound($aResult) & " записей через _MySQL_Select")
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_Select: " & _MySQL_GetLastError())
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_users")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestWrapperInsert
; Описание: Тест wrapper-функции _MySQL_Insert
; ===============================================================================
Func _TestWrapperInsert()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Wrapper _MySQL_Insert"

    ; Создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_products")
    Local $sCreateSQL = "CREATE TABLE test_wrapper_products (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "name VARCHAR(100), " & _
                        "price DECIMAL(10,2), " & _
                        "category VARCHAR(50)" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Тестируем INSERT через wrapper
    Local $sData = "name=Test Product|price=99.99|category=Electronics"
    Local $bResult = _MySQL_Insert("test_wrapper_products", $sData)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bResult

    If $bSuccess Then
        ; Проверяем что данные действительно вставились
        Local $aCheck = _MySQL_Select("test_wrapper_products", "*")
        If IsArray($aCheck) And UBound($aCheck) >= 1 Then
            _Logger_ConsoleWriteUTF("   ✅ Данные вставлены через _MySQL_Insert и найдены в таблице")
        Else
            $bSuccess = False
            _Logger_ConsoleWriteUTF("   ❌ Данные не найдены после вставки")
        EndIf
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_Insert: " & _MySQL_GetLastError())
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_products")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestWrapperSelectAdvanced
; Описание: Тест _MySQL_Select с условиями WHERE, ORDER BY, LIMIT
; ===============================================================================
Func _TestWrapperSelectAdvanced()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Wrapper _MySQL_Select расширенный"

    ; Создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_advanced")
    Local $sCreateSQL = "CREATE TABLE test_wrapper_advanced (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "name VARCHAR(50), " & _
                        "score INT, " & _
                        "active BOOLEAN DEFAULT TRUE" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Добавляем тестовые данные
    _MySQL_Insert("test_wrapper_advanced", "name=Alice|score=95|active=1")
    _MySQL_Insert("test_wrapper_advanced", "name=Bob|score=87|active=1")
    _MySQL_Insert("test_wrapper_advanced", "name=Charlie|score=92|active=0")
    _MySQL_Insert("test_wrapper_advanced", "name=Diana|score=98|active=1")

    ; Тестируем SELECT с условиями: только активные, сортировка по score, лимит 2
    Local $aResult = _MySQL_Select("test_wrapper_advanced", "name,score", "active=1", "score DESC", 2)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = IsArray($aResult) And UBound($aResult) = 2

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   ✅ Получено " & UBound($aResult) & " записей с условиями WHERE/ORDER BY/LIMIT")
        ; Проверяем что сортировка работает (первая запись должна иметь больший score)
        If UBound($aResult) >= 2 Then
            ; Проверяем что у нас двумерный массив и есть минимум 2 колонки
            If UBound($aResult, 2) >= 2 Then
                Local $iFirstScore = Int($aResult[0][1])
                Local $iSecondScore = Int($aResult[1][1])
                If $iFirstScore >= $iSecondScore Then
                    _Logger_ConsoleWriteUTF("   ✅ Сортировка работает корректно: " & $iFirstScore & " >= " & $iSecondScore)
                Else
                    $bSuccess = False
                    _Logger_ConsoleWriteUTF("   ❌ Ошибка сортировки: " & $iFirstScore & " < " & $iSecondScore)
                EndIf
            Else
                _Logger_ConsoleWriteUTF("   ⚠️ Массив не двумерный или недостаточно колонок для проверки сортировки")
            EndIf
        EndIf
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка расширенного SELECT: " & _MySQL_GetLastError())
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_advanced")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc
; ===============================================================================
; Функция: _TestWrapperUpdate
; Описание: Тест wrapper-функции _MySQL_Update
; ===============================================================================
Func _TestWrapperUpdate()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Wrapper _MySQL_Update"

    ; Создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_update")
    Local $sCreateSQL = "CREATE TABLE test_wrapper_update (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "name VARCHAR(50), " & _
                        "status VARCHAR(20), " & _
                        "score INT DEFAULT 0" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Добавляем тестовые данные
    _MySQL_Insert("test_wrapper_update", "name=John|status=active|score=85")
    _MySQL_Insert("test_wrapper_update", "name=Jane|status=active|score=92")
    _MySQL_Insert("test_wrapper_update", "name=Bob|status=inactive|score=78")

    ; Тестируем UPDATE через wrapper
    Local $sUpdateData = "status=updated|score=100"
    Local $bResult = _MySQL_Update("test_wrapper_update", $sUpdateData, "name = 'John'")
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bResult

    If $bSuccess Then
        ; Проверяем что данные действительно обновились
        Local $aCheck = _MySQL_Select("test_wrapper_update", "*", "name = 'John'")
        If IsArray($aCheck) And UBound($aCheck) >= 1 Then
            ; Проверяем что статус и score обновились
            Local $bStatusUpdated = False
            Local $bScoreUpdated = False

            If UBound($aCheck, 2) >= 4 Then
                $bStatusUpdated = ($aCheck[0][2] = "updated")
                $bScoreUpdated = (Int($aCheck[0][3]) = 100)
            EndIf

            If $bStatusUpdated And $bScoreUpdated Then
                _Logger_ConsoleWriteUTF("   ✅ Данные обновлены через _MySQL_Update: status=" & $aCheck[0][2] & ", score=" & $aCheck[0][3])
            Else
                $bSuccess = False
                _Logger_ConsoleWriteUTF("   ❌ Данные не обновились корректно")
            EndIf
        Else
            $bSuccess = False
            _Logger_ConsoleWriteUTF("   ❌ Запись не найдена после обновления")
        EndIf
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_Update: " & _MySQL_GetLastError())
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_update")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestWrapperDelete
; Описание: Тест wrapper-функции _MySQL_Delete
; ===============================================================================
Func _TestWrapperDelete()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Wrapper _MySQL_Delete"

    ; Создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_delete")
    Local $sCreateSQL = "CREATE TABLE test_wrapper_delete (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "name VARCHAR(50), " & _
                        "status VARCHAR(20)" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Добавляем тестовые данные
    _MySQL_Insert("test_wrapper_delete", "name=Alice|status=active")
    _MySQL_Insert("test_wrapper_delete", "name=Bob|status=inactive")
    _MySQL_Insert("test_wrapper_delete", "name=Charlie|status=inactive")
    _MySQL_Insert("test_wrapper_delete", "name=Diana|status=active")

    ; Проверяем количество записей до удаления
    Local $aBeforeDelete = _MySQL_Select("test_wrapper_delete", "*")
    Local $iCountBefore = IsArray($aBeforeDelete) ? UBound($aBeforeDelete) : 0

    ; Тестируем DELETE через wrapper (удаляем неактивных пользователей)
    Local $bResult = _MySQL_Delete("test_wrapper_delete", "status = 'inactive'")
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bResult

    If $bSuccess Then
        ; Проверяем что данные действительно удалились
        Local $aAfterDelete = _MySQL_Select("test_wrapper_delete", "*")
        Local $iCountAfter = IsArray($aAfterDelete) ? UBound($aAfterDelete) : 0

        ; Должно остаться 2 активных пользователя (Alice и Diana)
        If $iCountBefore = 4 And $iCountAfter = 2 Then
            _Logger_ConsoleWriteUTF("   ✅ Удаление через _MySQL_Delete: было " & $iCountBefore & ", стало " & $iCountAfter & " записей")

            ; Проверяем что остались только активные
            Local $bOnlyActive = True
            For $i = 0 To UBound($aAfterDelete) - 1
                If UBound($aAfterDelete, 2) >= 3 And $aAfterDelete[$i][2] <> "active" Then
                    $bOnlyActive = False
                    ExitLoop
                EndIf
            Next

            If Not $bOnlyActive Then
                $bSuccess = False
                _Logger_ConsoleWriteUTF("   ❌ Остались неактивные записи после удаления")
            EndIf
        Else
            $bSuccess = False
            _Logger_ConsoleWriteUTF("   ❌ Неверное количество записей: было " & $iCountBefore & ", стало " & $iCountAfter)
        EndIf
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_Delete: " & _MySQL_GetLastError())
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_wrapper_delete")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestWrapperSecurity
; Описание: Тест безопасности wrapper-функций (обязательное WHERE)
; ===============================================================================
Func _TestWrapperSecurity()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Wrapper безопасность WHERE"

    ; Тест 1: UPDATE без WHERE должен провалиться
    Local $bUpdateResult = _MySQL_Update("test_table", "status=test", "")
    Local $bUpdateFailed = ($bUpdateResult = False)

    ; Тест 2: DELETE без WHERE должен провалиться
    Local $bDeleteResult = _MySQL_Delete("test_table", "")
    Local $bDeleteFailed = ($bDeleteResult = False)

    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bUpdateFailed And $bDeleteFailed

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   🛡️ Безопасность работает: UPDATE и DELETE без WHERE заблокированы")
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка безопасности: операции без WHERE не заблокированы")
    EndIf

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestWrapperInsertSCADA
; Описание: Тест wrapper-функции _MySQL_InsertSCADA (с автоматическим UUID v7)
; ===============================================================================
Func _TestWrapperInsertSCADA()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Wrapper _MySQL_InsertSCADA"

    ; Создаем тестовую таблицу SCADA с UUID
    _MySQL_Query("DROP TABLE IF EXISTS test_scada_sensors")
    Local $sCreateSQL = "CREATE TABLE test_scada_sensors (" & _
                        "id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, " & _
                        "uuid CHAR(36) NOT NULL, " & _
                        "event_date DATE NOT NULL, " & _
                        "event_datetime DATETIME(3) NOT NULL, " & _
                        "sensor_id VARCHAR(50) NOT NULL, " & _
                        "temperature DOUBLE(15,4), " & _
                        "status VARCHAR(20), " & _
                        "UNIQUE KEY idx_date_uuid (event_date, uuid), " & _
                        "INDEX idx_date (event_date)" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Тестируем InsertSCADA через wrapper (UUID генерируется автоматически)
    Local $sData = "sensor_id=TEMP_001|temperature=25.5|status=online"
    Local $bResult = _MySQL_InsertSCADA("test_scada_sensors", $sData)
    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bResult

    If $bSuccess Then
        ; Проверяем что данные действительно вставились с UUID
        Local $aCheck = _MySQL_Select("test_scada_sensors", "*")
        If IsArray($aCheck) And UBound($aCheck) >= 1 Then
            ; Проверяем что UUID, event_date, event_datetime заполнены
            If UBound($aCheck, 2) >= 7 Then
                Local $sUUID = $aCheck[0][1]
                Local $sEventDate = $aCheck[0][2]
                Local $sEventDateTime = $aCheck[0][3]
                Local $sSensorID = $aCheck[0][4]
                Local $fTemp = $aCheck[0][5]

                ; Проверяем формат UUID (36 символов с дефисами)
                Local $bUUIDValid = (StringLen($sUUID) = 36 And StringMid($sUUID, 9, 1) = "-")

                ; Проверяем формат даты (YYYY-MM-DD)
                Local $bDateValid = (StringLen($sEventDate) = 10 And StringMid($sEventDate, 5, 1) = "-")

                ; Проверяем формат даты/времени (YYYY-MM-DD HH:MM:SS)
                Local $bDateTimeValid = (StringLen($sEventDateTime) >= 19 And StringMid($sEventDateTime, 11, 1) = " ")

                If $bUUIDValid And $bDateValid And $bDateTimeValid Then
                    _Logger_ConsoleWriteUTF("   ✅ SCADA данные вставлены с UUID: " & $sUUID)
                    _Logger_ConsoleWriteUTF("   📅 event_date: " & $sEventDate)
                    _Logger_ConsoleWriteUTF("   ⏰ event_datetime: " & $sEventDateTime)
                    _Logger_ConsoleWriteUTF("   🌡️ sensor_id=" & $sSensorID & ", temp=" & $fTemp)

                    ; Парсим timestamp из UUID
                    Local $sParsedTime = _Utils_ParseUUIDv7Timestamp($sUUID)
                    If $sParsedTime <> "" Then
                        _Logger_ConsoleWriteUTF("   🔍 Время из UUID: " & $sParsedTime)
                    EndIf
                Else
                    $bSuccess = False
                    _Logger_ConsoleWriteUTF("   ❌ Неверный формат UUID/даты/времени")
                EndIf
            Else
                $bSuccess = False
                _Logger_ConsoleWriteUTF("   ❌ Недостаточно колонок в результате")
            EndIf
        Else
            $bSuccess = False
            _Logger_ConsoleWriteUTF("   ❌ Данные не найдены после вставки")
        EndIf
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_InsertSCADA: " & _MySQL_GetLastError())
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_scada_sensors")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestUtilityCount
; Описание: Тест утилитарной функции _MySQL_Count
; ===============================================================================
Func _TestUtilityCount()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Утилита _MySQL_Count"

    ; Создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_utility_count")
    Local $sCreateSQL = "CREATE TABLE test_utility_count (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "name VARCHAR(50), " & _
                        "status VARCHAR(20)" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Добавляем тестовые данные
    _MySQL_Insert("test_utility_count", "name=Alice|status=active")
    _MySQL_Insert("test_utility_count", "name=Bob|status=active")
    _MySQL_Insert("test_utility_count", "name=Charlie|status=inactive")
    _MySQL_Insert("test_utility_count", "name=Diana|status=active")
    _MySQL_Insert("test_utility_count", "name=Eve|status=inactive")

    ; Тест 1: Подсчет всех записей (без WHERE)
    Local $iCountAll = _MySQL_Count("test_utility_count")
    Local $bTest1 = ($iCountAll = 5)

    ; Тест 2: Подсчет активных записей (с WHERE)
    Local $iCountActive = _MySQL_Count("test_utility_count", "status='active'")
    Local $bTest2 = ($iCountActive = 3)

    ; Тест 3: Подсчет неактивных записей (с WHERE)
    Local $iCountInactive = _MySQL_Count("test_utility_count", "status='inactive'")
    Local $bTest3 = ($iCountInactive = 2)

    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bTest1 And $bTest2 And $bTest3

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   ✅ _MySQL_Count работает корректно:")
        _Logger_ConsoleWriteUTF("      Всего: " & $iCountAll & " (ожидалось 5)")
        _Logger_ConsoleWriteUTF("      Активных: " & $iCountActive & " (ожидалось 3)")
        _Logger_ConsoleWriteUTF("      Неактивных: " & $iCountInactive & " (ожидалось 2)")
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_Count:")
        _Logger_ConsoleWriteUTF("      Всего: " & $iCountAll & " (ожидалось 5) - " & ($bTest1 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      Активных: " & $iCountActive & " (ожидалось 3) - " & ($bTest2 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      Неактивных: " & $iCountInactive & " (ожидалось 2) - " & ($bTest3 ? "OK" : "FAIL"))
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_utility_count")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestUtilityExists
; Описание: Тест утилитарной функции _MySQL_Exists
; ===============================================================================
Func _TestUtilityExists()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Утилита _MySQL_Exists"

    ; Создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_utility_exists")
    Local $sCreateSQL = "CREATE TABLE test_utility_exists (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "email VARCHAR(100) UNIQUE, " & _
                        "username VARCHAR(50)" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Добавляем тестовые данные
    _MySQL_Insert("test_utility_exists", "email=alice@test.com|username=alice")
    _MySQL_Insert("test_utility_exists", "email=bob@test.com|username=bob")

    ; Тест 1: Проверка существующего email
    Local $bExistsAlice = _MySQL_Exists("test_utility_exists", "email='alice@test.com'")
    Local $bTest1 = ($bExistsAlice = True)

    ; Тест 2: Проверка несуществующего email
    Local $bExistsCharlie = _MySQL_Exists("test_utility_exists", "email='charlie@test.com'")
    Local $bTest2 = ($bExistsCharlie = False)

    ; Тест 3: Проверка существующего username
    Local $bExistsBob = _MySQL_Exists("test_utility_exists", "username='bob'")
    Local $bTest3 = ($bExistsBob = True)

    ; Тест 4: Проверка несуществующего username
    Local $bExistsDiana = _MySQL_Exists("test_utility_exists", "username='diana'")
    Local $bTest4 = ($bExistsDiana = False)

    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bTest1 And $bTest2 And $bTest3 And $bTest4

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   ✅ _MySQL_Exists работает корректно:")
        _Logger_ConsoleWriteUTF("      alice@test.com существует: " & $bExistsAlice & " (ожидалось True)")
        _Logger_ConsoleWriteUTF("      charlie@test.com существует: " & $bExistsCharlie & " (ожидалось False)")
        _Logger_ConsoleWriteUTF("      username 'bob' существует: " & $bExistsBob & " (ожидалось True)")
        _Logger_ConsoleWriteUTF("      username 'diana' существует: " & $bExistsDiana & " (ожидалось False)")
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_Exists:")
        _Logger_ConsoleWriteUTF("      alice@test.com: " & $bExistsAlice & " - " & ($bTest1 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      charlie@test.com: " & $bExistsCharlie & " - " & ($bTest2 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      username 'bob': " & $bExistsBob & " - " & ($bTest3 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      username 'diana': " & $bExistsDiana & " - " & ($bTest4 ? "OK" : "FAIL"))
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_utility_exists")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; Функция: _TestUtilityGetLastInsertID
; Описание: Тест утилитарной функции _MySQL_GetLastInsertID
; ===============================================================================
Func _TestUtilityGetLastInsertID()
    Local $hTimer = _Utils_GetTimestamp()
    Local $sTestName = "Утилита _MySQL_GetLastInsertID"

    ; Создаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_utility_lastid")
    Local $sCreateSQL = "CREATE TABLE test_utility_lastid (" & _
                        "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                        "name VARCHAR(50)" & _
                        ")"
    _MySQL_Query($sCreateSQL)

    ; Тест 1: Вставка первой записи и получение ID
    _MySQL_Insert("test_utility_lastid", "name=First Record")
    Local $iFirstID = _MySQL_GetLastInsertID()
    Local $bTest1 = ($iFirstID > 0)

    ; Тест 2: Вставка второй записи и получение ID
    _MySQL_Insert("test_utility_lastid", "name=Second Record")
    Local $iSecondID = _MySQL_GetLastInsertID()
    Local $bTest2 = ($iSecondID > $iFirstID)

    ; Тест 3: Вставка третьей записи и получение ID
    _MySQL_Insert("test_utility_lastid", "name=Third Record")
    Local $iThirdID = _MySQL_GetLastInsertID()
    Local $bTest3 = ($iThirdID > $iSecondID)

    ; Тест 4: Проверка что ID действительно соответствуют записям
    Local $aCheck = _MySQL_Select("test_utility_lastid", "*", "id=" & $iThirdID)
    Local $bTest4 = (IsArray($aCheck) And UBound($aCheck) = 1 And $aCheck[0][1] = "Third Record")

    Local $fTime = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bTest1 And $bTest2 And $bTest3 And $bTest4

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("   ✅ _MySQL_GetLastInsertID работает корректно:")
        _Logger_ConsoleWriteUTF("      Первая вставка ID: " & $iFirstID)
        _Logger_ConsoleWriteUTF("      Вторая вставка ID: " & $iSecondID & " (больше предыдущего)")
        _Logger_ConsoleWriteUTF("      Третья вставка ID: " & $iThirdID & " (больше предыдущего)")
        _Logger_ConsoleWriteUTF("      Проверка записи: найдена 'Third Record' с ID=" & $iThirdID)
    Else
        _Logger_ConsoleWriteUTF("   ❌ Ошибка _MySQL_GetLastInsertID:")
        _Logger_ConsoleWriteUTF("      Первая вставка ID: " & $iFirstID & " - " & ($bTest1 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      Вторая вставка ID: " & $iSecondID & " - " & ($bTest2 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      Третья вставка ID: " & $iThirdID & " - " & ($bTest3 ? "OK" : "FAIL"))
        _Logger_ConsoleWriteUTF("      Проверка записи - " & ($bTest4 ? "OK" : "FAIL"))
    EndIf

    ; Очищаем тестовую таблицу
    _MySQL_Query("DROP TABLE IF EXISTS test_utility_lastid")

    _PrintTestResult($sTestName, $bSuccess, $fTime)
    Return $bSuccess
EndFunc

; ===============================================================================
; ТЕСТ СИСТЕМЫ ОЧЕРЕДЕЙ
; ===============================================================================

; ===============================================================================
; Функция: _TestQueueSystem
; Описание: Тест системы очередей с циклом вставки данных на оба сервера
; ===============================================================================
Func _TestQueueSystem()
    _Logger_ConsoleWriteUTF("")
    _Logger_ConsoleWriteUTF("🔄 ТЕСТ СИСТЕМЫ ОЧЕРЕДЕЙ (ЛОКАЛЬНЫЙ + УДАЛЕННЫЙ)")

    ; ИСПРАВЛЕНИЕ: Проверяем существующие очереди вместо их очистки
    Local $aQueueStatus = _MySQL_GetQueueStatus()
    If $aQueueStatus[0] > 0 Or $aQueueStatus[1] > 0 Then
        _Logger_ConsoleWriteUTF("📋 НАЙДЕНЫ СУЩЕСТВУЮЩИЕ ОЧЕРЕДИ:")
        _Logger_ConsoleWriteUTF("   📊 Локальная очередь: " & $aQueueStatus[0] & " записей")
        _Logger_ConsoleWriteUTF("   📊 Удаленная очередь: " & $aQueueStatus[1] & " записей")
        _Logger_ConsoleWriteUTF("🔄 Сначала попробуем обработать существующие очереди...")
        _Logger_ConsoleWriteUTF("")

        ; Пытаемся обработать существующие очереди
        _MySQL_ProcessQueue()

        ; Показываем статус после попытки обработки
        Local $aNewStatus = _MySQL_GetQueueStatus()
        _Logger_ConsoleWriteUTF("📊 Статус после попытки обработки:")
        _Logger_ConsoleWriteUTF("   📊 Локальная очередь: " & $aNewStatus[0] & " записей")
        _Logger_ConsoleWriteUTF("   📊 Удаленная очередь: " & $aNewStatus[1] & " записей")
        _Logger_ConsoleWriteUTF("")
    Else
        _Logger_ConsoleWriteUTF("📭 Очереди пусты, начинаем новый тест")
    EndIf

    _Logger_ConsoleWriteUTF("⚠️ ИНСТРУКЦИЯ:")
    _Logger_ConsoleWriteUTF("   1. Сейчас начнется цикл вставки данных каждые 5 секунд")
    _Logger_ConsoleWriteUTF("   2. Тестируем ЛОКАЛЬНЫЙ и УДАЛЕННЫЙ серверы")
    _Logger_ConsoleWriteUTF("   3. Отключите OpenServer для тестирования локальных очередей")
    _Logger_ConsoleWriteUTF("   4. Отключите интернет для тестирования удаленных очередей")
    _Logger_ConsoleWriteUTF("   5. Наблюдайте как запросы добавляются в разные очереди")
    _Logger_ConsoleWriteUTF("   6. Включите серверы обратно и наблюдайте обработку очередей")
    _Logger_ConsoleWriteUTF("🛑 Нажмите Ctrl+Break для остановки")
    _Logger_ConsoleWriteUTF("")

    ; Создаем тестовые таблицы на обоих серверах (UTF8MB4 для совместимости с MySQL 8.0 + UUID v7)
    _Logger_ConsoleWriteUTF("🏠 Создание таблицы на ЛОКАЛЬНОМ сервере:")
    Local $bLocalTableCreated = _MySQL_Query("CREATE TABLE IF NOT EXISTS queue_test (id INT AUTO_INCREMENT PRIMARY KEY, uuid CHAR(36) UNIQUE, name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, message TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, created TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_uuid (uuid))", 0, $MYSQL_SERVER_LOCAL)
    If Not $bLocalTableCreated Then
        _Logger_ConsoleWriteUTF("⚠️ Локальная таблица не создана (возможно сервер недоступен)")
    Else
        _Logger_ConsoleWriteUTF("✅ Локальная таблица queue_test готова (UTF8MB4 + UUID v7)")
    EndIf

    _Logger_ConsoleWriteUTF("🌐 Создание таблицы на УДАЛЕННОМ сервере:")
    Local $bRemoteTableCreated = _MySQL_Query("CREATE TABLE IF NOT EXISTS queue_test (id INT AUTO_INCREMENT PRIMARY KEY, uuid CHAR(36) UNIQUE, name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, message TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci, created TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX idx_uuid (uuid))", 0, $MYSQL_SERVER_REMOTE)
    If Not $bRemoteTableCreated Then
        _Logger_ConsoleWriteUTF("⚠️ Удаленная таблица не создана (возможно сервер недоступен)")
    Else
        _Logger_ConsoleWriteUTF("✅ Удаленная таблица queue_test готова (UTF8MB4 + UUID v7)")
    EndIf

    _Logger_ConsoleWriteUTF("🔄 Начинаем цикл тестирования...")

    Local $iCounter = 1
    While 1
        _Logger_ConsoleWriteUTF("📡 Цикл #" & $iCounter & ":")

        ; Генерируем UUID v7 для каждой записи
        Local $sUUID = _Utils_GenerateUUIDv7()

        ; Данные для вставки (с русскими символами + UUID)
        Local $sData = "uuid=" & $sUUID & "|name=ТестОчереди" & $iCounter & "|message=Тестовое сообщение " & $iCounter & " с русскими символами: ёЁ и спецсимволами 'кавычки'|created=" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC

        ; 1. Тестируем ЛОКАЛЬНЫЙ сервер
        _Logger_ConsoleWriteUTF("🏠 Тест локального сервера:")
        Local $bLocalResult = _MySQL_Insert("queue_test", $sData, $MYSQL_SERVER_LOCAL)
        If $bLocalResult Then
            _Logger_ConsoleWriteUTF("✅ Локальная запись " & $iCounter & " отправлена успешно (UUID: " & $sUUID & ")")
        Else
            _Logger_ConsoleWriteUTF("📝 Локальная запись " & $iCounter & " добавлена в очередь (UUID: " & $sUUID & "): " & _MySQL_GetLastError())
        EndIf

        ; 2. Тестируем УДАЛЕННЫЙ сервер
        _Logger_ConsoleWriteUTF("🌐 Тест удаленного сервера:")
        Local $bRemoteResult = _MySQL_Insert("queue_test", $sData, $MYSQL_SERVER_REMOTE)
        If $bRemoteResult Then
            _Logger_ConsoleWriteUTF("✅ Удаленная запись " & $iCounter & " отправлена успешно (UUID: " & $sUUID & ")")
        Else
            _Logger_ConsoleWriteUTF("📝 Удаленная запись " & $iCounter & " добавлена в очередь (UUID: " & $sUUID & "): " & _MySQL_GetLastError())
        EndIf

        ; 3. Тестируем SELECT на локальном (НЕ должен добавляться в очередь)
        _Logger_ConsoleWriteUTF("🔍 Тест SELECT на локальном:")
        Local $aLocalCheck = _MySQL_Select("queue_test", "*", "", "", 1, $MYSQL_SERVER_LOCAL)
        If Not IsArray($aLocalCheck) Then
            _Logger_ConsoleWriteUTF("❌ Локальный SELECT не выполнился (правильно НЕ добавлен в очередь)")
        Else
            _Logger_ConsoleWriteUTF("✅ Локальный SELECT выполнился успешно")
        EndIf

        ; 4. Тестируем SELECT на удаленном (НЕ должен добавляться в очередь)
        _Logger_ConsoleWriteUTF("🔍 Тест SELECT на удаленном:")
        Local $aRemoteCheck = _MySQL_Select("queue_test", "*", "", "", 1, $MYSQL_SERVER_REMOTE)
        If Not IsArray($aRemoteCheck) Then
            _Logger_ConsoleWriteUTF("❌ Удаленный SELECT не выполнился (правильно НЕ добавлен в очередь)")
        Else
            _Logger_ConsoleWriteUTF("✅ Удаленный SELECT выполнился успешно")
        EndIf

        ; Показываем статус очередей
        Local $aQueueStatus = _MySQL_GetQueueStatus()
        If $aQueueStatus[0] > 0 Or $aQueueStatus[1] > 0 Then
            _Logger_ConsoleWriteUTF("📊 Очереди: Local=" & $aQueueStatus[0] & ", Remote=" & $aQueueStatus[1])
        EndIf

        _Logger_ConsoleWriteUTF("")
        $iCounter += 1
        Sleep(5000) ; 5 секунд
    WEnd

    _Logger_ConsoleWriteUTF("✅ Тестирование завершено")
    _Logger_ConsoleWriteUTF("📊 Нажмите любую клавишу для выхода...")
EndFunc

#cs
; ===============================================================================
; ОСТАЛЬНЫЕ ТЕСТОВЫЕ ФУНКЦИИ (ЗАКОММЕНТИРОВАНЫ)
; ===============================================================================
#ce