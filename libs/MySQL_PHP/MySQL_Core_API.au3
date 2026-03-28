; ===============================================================================
; Название: MySQL_Core_API.au3
; Описание: Единая библиотека для работы с MySQL через HTTP API
; Версия: 2.0 (объединённая из 4 модулей)
; Дата: 23.02.2026
; Автор: SDK Team
;
; Зависимости:
;   - Utils.au3 (логирование через Logger V2)
;   - JSON.au3 (парсинг JSON ответов)
;   - WinHttp.au3 (HTTP клиент)
;
; Функции (31):
;
; 🎯 CRUD Wrapper-функции (рекомендуемые):
;   _MySQL_Select($sTable, $sColumns, $sWhere, $sOrderBy, $iLimit, $iServer, $bJSON)
;   _MySQL_Insert($sTable, $sData, $iServer, $bJSON)
;   _MySQL_Update($sTable, $sData, $sWhere, $iServer, $bJSON)
;   _MySQL_Delete($sTable, $sWhere, $iServer, $bJSON)
;
; 🏭 SCADA функции (UUID v7 + timestamp):
;   _MySQL_InsertSCADA($sTable, $sData, $iServer, $bJSON)
;
; 🔧 Утилитарные функции:
;   _MySQL_Count($sTable, $sWhere, $iServer)
;   _MySQL_Exists($sTable, $sWhere, $iServer)
;   _MySQL_GetLastInsertID($iServer)
;
; 📝 Основная функция:
;   _MySQL_Query($sSQL, $aParams, $iServer, $bJSON)
;
; 🏗️ Построение и парсинг запросов:
;   _MySQL_BuildURL($sHost)
;   _MySQL_BuildPostData($sSQL, $aParams, $sKey, $bJSON)
;   _MySQL_ParseSimpleResponse($sResponse)
;   _MySQL_ParseJSONResponse($sResponse)
;   _URIEncode($vData)
;   _MySQL_HttpRequest($sURL, $iTimeout, $sPostData)
;
; 🌐 Ping и проверка доступности:
;   _MySQL_PingTCP_Local()
;   _MySQL_PingTCP_Remote()
;   _MySQL_PingTCP_Internal($sHost, $iPort)
;   _MySQL_GetLastError()
;   _MySQL_SetDebugMode($bEnabled)
;   _MySQL_QuickPing($sHost)
;
; 📋 Система очередей FIFO:
;   _MySQL_InitQueue()
;   _MySQL_AddToQueue($sSQL, $aParams, $iServer, $bJSON)
;   _MySQL_ProcessQueue($iServer)
;   _MySQL_ProcessSingleQueue($iServer)
;   _MySQL_LoadQueueFromFile($iServer)
;   _MySQL_SaveQueueToFile($iServer)
;   _MySQL_MoveToErrorLog($sRecord, $sError)
;   _MySQL_GetQueueStatus()
;   _MySQL_ClearQueues()
;   _MySQL_ClearQueue($iServer)
;
; Примеры использования:
;   #include "..\..\libs\MySQL_PHP\MySQL_Core_API.au3"
;   _SDK_Utils_Init("MyApp", "MySQL")
;   
;   ; SELECT
;   Local $aUsers = _MySQL_Select("users", "*", "status='active'", "name ASC", 10)
;   
;   ; INSERT
;   _MySQL_Insert("users", "name=John|email=john@test.com|status=active")
;   
;   ; UPDATE
;   _MySQL_Update("users", "status=inactive", "email='john@test.com'")
;   
;   ; DELETE
;   _MySQL_Delete("users", "status='inactive' AND last_login < '2025-01-01'")
;   
;   ; SCADA (автоматический UUID v7 + timestamp)
;   _MySQL_InsertSCADA("sensors", "sensor_id=TEMP_001|temp=25.5|status=online")
;   
;   ; Утилиты
;   Local $iCount = _MySQL_Count("users", "status='active'")
;   Local $bExists = _MySQL_Exists("users", "email='test@test.com'")
;   Local $iLastID = _MySQL_GetLastInsertID()
;
; ===============================================================================

; Подключение необходимых библиотек

#include-once
#include "../Utils/Utils.au3"
#include "../json/JSON.au3"
#include "../Winhttp/WinHttp.au3"
#include <Array.au3>
#include <String.au3>

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ И НАСТРОЙКИ
; ===============================================================================

; Настройки серверов (ИСПРАВЛЕНО: используем 127.0.0.1 вместо localhost)
Global $g_sMySQL_LocalHost = "http://127.0.0.1/php/"
Global $g_sMySQL_RemoteHost = "http://YOUR_HOST/php/"
Global $g_sMySQL_LocalKey = "test_local_key_12345"
Global $g_sMySQL_RemoteKey = "test_local_key_12345"

; Рабочие переменные
Global $g_sMySQL_LastError = ""
Global $g_iMySQL_LastInsertID = 0 ; Последний ID вставки (сохраняется из ответа INSERT)
Global $g_iMySQL_Timeout = 100 ; Таймаут в миллисекундах (0.1 секунды - очень агрессивный)
Global $g_bMySQL_DebugMode = True

; Константы для выбора сервера (используются как константы, но объявлены как Global для совместимости с модулями)
Global $MYSQL_SERVER_LOCAL = 2
Global $MYSQL_SERVER_REMOTE = 1
Global $MYSQL_SERVER_BOTH = 3

; SQLite база данных для очередей (открывается/закрывается при каждой операции)
Global $g_sMySQLQueueDBPath = ""  ; Путь к SQLite базе очередей

; Контроль повторных попыток
Global $g_iLastLocalAttempt = 0      ; Время последней попытки локальной очереди
Global $g_iLastRemoteAttempt = 0     ; Время последней попытки удаленной очереди
Global $g_iQueueRetryInterval = 30000  ; Интервал повторных попыток (0.5 сек)

; Флаги состояния (критично для производительности)
Global $g_bLocalQueueActive = False   ; Есть ли локальная очередь
Global $g_bRemoteQueueActive = False  ; Есть ли удаленная очередь

; Защита от зацикливания
Global $g_iMaxRetryCount = 10         ; Максимальное количество попыток перед сбросом счетчика

Func _MySQL_Select($sTable, $sColumns = "*", $sWhere = "", $sOrderBy = "", $iLimit = 0, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
    Local $hTotalTimer = _Utils_GetTimestamp()

    ; Таймер 1: Подготовка SQL запроса
    Local $hPrepTimer = _Utils_GetTimestamp()
    Local $sSQL = "SELECT " & $sColumns & " FROM " & $sTable

    ; Добавляем условие WHERE если указано
    If $sWhere <> "" Then
        $sSQL &= " WHERE " & $sWhere
    EndIf

    ; Добавляем сортировку если указана
    If $sOrderBy <> "" Then
        $sSQL &= " ORDER BY " & $sOrderBy
    EndIf

    ; Добавляем лимит если указан
    If $iLimit > 0 Then
        $sSQL &= " LIMIT " & $iLimit
    EndIf
    Local $fPrepTime = _Utils_GetElapsedTime($hPrepTimer)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("📊 [MySQL] SELECT: " & $sSQL, 1)
    EndIf

    ; Таймер 2: Выполнение основного запроса
    Local $hQueryTimer = _Utils_GetTimestamp()
    Local $aResult = _MySQL_Query($sSQL, 0, $iServer, $bJSON)
    Local $fQueryTime = _Utils_GetElapsedTime($hQueryTimer)

    Local $fTotalTime = _Utils_GetElapsedTime($hTotalTimer)

    ; Детальная диагностика производительности (отключена для краткости логов)
    ; If $g_bMySQL_DebugMode Then
    ;     _Logger_Write("⏱️ [MySQL] Диагностика _MySQL_Select:", 1)
    ;     _Logger_Write("   📝 [MySQL] Подготовка SQL: " & StringFormat("%.2f", $fPrepTime) & "мс", 1)
    ;     _Logger_Write("   🔄 [MySQL] Выполнение запроса: " & StringFormat("%.2f", $fQueryTime) & "мс", 1)
    ;     _Logger_Write("   🎯 [MySQL] ИТОГО Wrapper: " & StringFormat("%.2f", $fTotalTime) & "мс", 1)
    ; EndIf

    Return $aResult
EndFunc

; ===============================================================================
; Функция: _MySQL_Insert
; Описание: Упрощенная вставка данных с детальной диагностикой производительности
; Параметры:
;   $sTable - имя таблицы (обязательный)
;   $sData - данные в формате "key1=val1|key2=val2" (обязательный)
;   $iServer - сервер: 1=хостинг, 2=локальный, 3=оба (по умолчанию локальный)
;   $bJSON - формат ответа (по умолчанию False)
; Возврат: True при успехе, False при ошибке
; Пример: _MySQL_Insert("users", "name=John|email=john@test.com|status=active")
; ===============================================================================
Func _MySQL_Insert($sTable, $sData, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
    Local $hTotalTimer = _Utils_GetTimestamp()

    ; Таймер 1: Парсинг входных данных
    Local $hParseTimer = _Utils_GetTimestamp()
    Local $aPairs = StringSplit($sData, "|")
    If $aPairs[0] = 0 Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] INSERT: Нет данных для вставки", 2)
        EndIf
        Return False
    EndIf

    Local $sCols = "", $sVals = ""

    ; Обрабатываем каждую пару ключ=значение
    For $i = 1 To $aPairs[0]
        Local $aKV = StringSplit($aPairs[$i], "=", 2) ; Флаг 2 = без счетчика в [0]
        If UBound($aKV) < 2 Then
            If $g_bMySQL_DebugMode Then
                _Logger_Write("⚠️ [MySQL] Пропускаем неверную пару: " & $aPairs[$i], 1)
            EndIf
            ContinueLoop
        EndIf

        ; Добавляем колонку
        If $sCols <> "" Then $sCols &= ","
        $sCols &= $aKV[0]

        ; Добавляем значение (экранируем одинарные кавычки)
        If $sVals <> "" Then $sVals &= ","
        Local $sValue = StringReplace($aKV[1], "'", "\'")
        $sVals &= "'" & $sValue & "'"
    Next

    ; Проверяем что получили данные
    If $sCols = "" Or $sVals = "" Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] INSERT: Не удалось разобрать данные", 2)
        EndIf
        Return False
    EndIf
    Local $fParseTime = _Utils_GetElapsedTime($hParseTimer)

    ; Таймер 2: Формирование SQL запроса
    Local $hSQLTimer = _Utils_GetTimestamp()
    Local $sSQL = "INSERT INTO " & $sTable & " (" & $sCols & ") VALUES (" & $sVals & ")"
    Local $fSQLTime = _Utils_GetElapsedTime($hSQLTimer)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("➕ [MySQL] INSERT: " & $sSQL, 1)
    EndIf

    ; Таймер 3: Выполнение запроса
    Local $hQueryTimer = _Utils_GetTimestamp()
    Local $bResult = _MySQL_Query($sSQL, 0, $iServer, $bJSON)
    Local $fQueryTime = _Utils_GetElapsedTime($hQueryTimer)

    Local $fTotalTime = _Utils_GetElapsedTime($hTotalTimer)

    ; Детальная диагностика производительности (отключена для краткости логов)
    ; If $g_bMySQL_DebugMode Then
    ;     _Logger_Write("⏱️ [MySQL] Диагностика _MySQL_Insert:", 1)
    ;     _Logger_Write("   🔍 [MySQL] Парсинг данных: " & StringFormat("%.2f", $fParseTime) & "мс", 1)
    ;     _Logger_Write("   📝 [MySQL] Формирование SQL: " & StringFormat("%.2f", $fSQLTime) & "мс", 1)
    ;     _Logger_Write("   🔄 [MySQL] Выполнение запроса: " & StringFormat("%.2f", $fQueryTime) & "мс", 1)
    ;     _Logger_Write("   🎯 [MySQL] ИТОГО Wrapper: " & StringFormat("%.2f", $fTotalTime) & "мс", 1)
    ; EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _MySQL_Update
; Описание: Упрощенное обновление данных с детальной диагностикой производительности
; Параметры:
;   $sTable - имя таблицы (обязательный)
;   $sData - данные в формате "key1=val1|key2=val2" (обязательный)
;   $sWhere - условие WHERE (обязательный для безопасности)
;   $iServer - сервер: 1=хостинг, 2=локальный, 3=оба (по умолчанию локальный)
;   $bJSON - формат ответа (по умолчанию False)
; Возврат: True при успехе, False при ошибке
; Пример: _MySQL_Update("users", "status=inactive|last_login=2026-01-01", "id > 100")
; ===============================================================================
Func _MySQL_Update($sTable, $sData, $sWhere, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
    Local $hTotalTimer = _Utils_GetTimestamp()

    ; Проверка обязательного условия WHERE для безопасности
    If $sWhere = "" Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("⚠️ [MySQL] UPDATE: Условие WHERE обязательно для безопасности", 2)
        EndIf
        Return False
    EndIf

    ; Таймер 1: Парсинг входных данных
    Local $hParseTimer = _Utils_GetTimestamp()
    Local $aPairs = StringSplit($sData, "|")
    If $aPairs[0] = 0 Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] UPDATE: Нет данных для обновления", 2)
        EndIf
        Return False
    EndIf

    Local $sSetClause = ""

    ; Обрабатываем каждую пару ключ=значение
    For $i = 1 To $aPairs[0]
        Local $aKV = StringSplit($aPairs[$i], "=", 2) ; Флаг 2 = без счетчика в [0]
        If UBound($aKV) < 2 Then
            If $g_bMySQL_DebugMode Then
                _Logger_Write("[MySQL] Пропускаем неверную пару: " & $aPairs[$i], 1)
            EndIf
            ContinueLoop
        EndIf

        ; Добавляем SET условие
        If $sSetClause <> "" Then $sSetClause &= ", "
        Local $sValue = StringReplace($aKV[1], "'", "\'")
        $sSetClause &= $aKV[0] & " = '" & $sValue & "'"
    Next

    ; Проверяем что получили данные
    If $sSetClause = "" Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] UPDATE: Не удалось разобрать данные", 2)
        EndIf
        Return False
    EndIf
    Local $fParseTime = _Utils_GetElapsedTime($hParseTimer)

    ; Таймер 2: Формирование SQL запроса
    Local $hSQLTimer = _Utils_GetTimestamp()
    Local $sSQL = "UPDATE " & $sTable & " SET " & $sSetClause & " WHERE " & $sWhere
    Local $fSQLTime = _Utils_GetElapsedTime($hSQLTimer)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔄 [MySQL] UPDATE: " & $sSQL, 1)
    EndIf

    ; Таймер 3: Выполнение запроса
    Local $hQueryTimer = _Utils_GetTimestamp()
    Local $bResult = _MySQL_Query($sSQL, 0, $iServer, $bJSON)
    Local $fQueryTime = _Utils_GetElapsedTime($hQueryTimer)

    Local $fTotalTime = _Utils_GetElapsedTime($hTotalTimer)

    ; Детальная диагностика производительности (отключена для краткости логов)
    ; If $g_bMySQL_DebugMode Then
    ;     _Logger_Write("⏱️ [MySQL] Диагностика _MySQL_Update:", 1)
    ;     _Logger_Write("   🔍 [MySQL] Парсинг данных: " & StringFormat("%.2f", $fParseTime) & "мс", 1)
    ;     _Logger_Write("   📝 [MySQL] Формирование SQL: " & StringFormat("%.2f", $fSQLTime) & "мс", 1)
    ;     _Logger_Write("   🔄 [MySQL] Выполнение запроса: " & StringFormat("%.2f", $fQueryTime) & "мс", 1)
    ;     _Logger_Write("   🎯 [MySQL] ИТОГО Wrapper: " & StringFormat("%.2f", $fTotalTime) & "мс", 1)
    ; EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _MySQL_Delete
; Описание: Упрощенное удаление данных с детальной диагностикой производительности
; Параметры:
;   $sTable - имя таблицы (обязательный)
;   $sWhere - условие WHERE (обязательный для безопасности)
;   $iServer - сервер: 1=хостинг, 2=локальный, 3=оба (по умолчанию локальный)
;   $bJSON - формат ответа (по умолчанию False)
; Возврат: True при успехе, False при ошибке
; Пример: _MySQL_Delete("users", "status='inactive' AND last_login < '2025-01-01'")
; ===============================================================================
Func _MySQL_Delete($sTable, $sWhere, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
    Local $hTotalTimer = _Utils_GetTimestamp()

    ; Проверка обязательного условия WHERE для безопасности
    If $sWhere = "" Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("⚠️ [MySQL] DELETE: Условие WHERE обязательно для безопасности", 2)
        EndIf
        Return False
    EndIf

    ; Таймер 1: Формирование SQL запроса
    Local $hSQLTimer = _Utils_GetTimestamp()
    Local $sSQL = "DELETE FROM " & $sTable & " WHERE " & $sWhere
    Local $fSQLTime = _Utils_GetElapsedTime($hSQLTimer)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🗑️ [MySQL] DELETE: " & $sSQL, 1)
    EndIf

    ; Таймер 2: Выполнение запроса
    Local $hQueryTimer = _Utils_GetTimestamp()
    Local $bResult = _MySQL_Query($sSQL, 0, $iServer, $bJSON)
    Local $fQueryTime = _Utils_GetElapsedTime($hQueryTimer)

    Local $fTotalTime = _Utils_GetElapsedTime($hTotalTimer)

    ; Детальная диагностика производительности (отключена для краткости логов)
    ; If $g_bMySQL_DebugMode Then
    ;     _Logger_Write("⏱️ [MySQL] Диагностика _MySQL_Delete:", 1)
    ;     _Logger_Write("   📝 [MySQL] Формирование SQL: " & StringFormat("%.2f", $fSQLTime) & "мс", 1)
    ;     _Logger_Write("   🔄 [MySQL] Выполнение запроса: " & StringFormat("%.2f", $fQueryTime) & "мс", 1)
    ;     _Logger_Write("   🎯 [MySQL] ИТОГО Wrapper: " & StringFormat("%.2f", $fTotalTime) & "мс", 1)
    ; EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _MySQL_InsertSCADA
; Описание: Вставка данных в SCADA таблицу с автоматическим UUID v7
;           Автоматически добавляет: uuid, event_date, event_datetime
;           Используется для критичных данных датчиков с точным временем события
; Параметры:
;   $sTable - имя таблицы (обязательный)
;   $sData - данные БЕЗ uuid/event_date/event_datetime (обязательный)
;   $iServer - сервер: 1=хостинг, 2=локальный, 3=оба (по умолчанию локальный)
;   $bJSON - формат ответа (по умолчанию False)
; Возврат: True при успехе, False при ошибке
; Пример: _MySQL_InsertSCADA("sensors", "sensor_id=001|temp=25.5|status=online")
; Примечание: Требует таблицу со структурой:
;   - uuid CHAR(36) NOT NULL
;   - event_date DATE NOT NULL
;   - event_datetime DATETIME(3) NOT NULL
;   - UNIQUE KEY idx_date_uuid (event_date, uuid)
; ===============================================================================
Func _MySQL_InsertSCADA($sTable, $sData, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
    Local $hTotalTimer = _Utils_GetTimestamp()

    ; Таймер 1: Генерация UUID и времени
    Local $hUUIDTimer = _Utils_GetTimestamp()
    Local $sUUID = _Utils_GenerateUUIDv7()
    Local $sDate = _Utils_GetDateOnly()
    Local $sDateTime = _Utils_GetDateTimeMS()
    Local $fUUIDTime = _Utils_GetElapsedTime($hUUIDTimer)

    ; Таймер 2: Формирование полных данных
    Local $hDataTimer = _Utils_GetTimestamp()
    Local $sFullData = "uuid=" & $sUUID & "|event_date=" & $sDate & "|event_datetime=" & $sDateTime & "|" & $sData
    Local $fDataTime = _Utils_GetElapsedTime($hDataTimer)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🆔 [MySQL] InsertSCADA: " & $sTable & " (UUID: " & $sUUID & ")", 1)
    EndIf

    ; Таймер 3: Вставка через обычный Insert
    Local $hInsertTimer = _Utils_GetTimestamp()
    Local $bResult = _MySQL_Insert($sTable, $sFullData, $iServer, $bJSON)
    Local $fInsertTime = _Utils_GetElapsedTime($hInsertTimer)

    Local $fTotalTime = _Utils_GetElapsedTime($hTotalTimer)

    ; Детальная диагностика производительности (отключена для краткости логов)
    ; If $g_bMySQL_DebugMode Then
    ;     _Logger_Write("⏱️ [MySQL] Диагностика _MySQL_InsertSCADA:", 1)
    ;     _Logger_Write("   🆔 [MySQL] Генерация UUID+время: " & StringFormat("%.2f", $fUUIDTime) & "мс", 1)
    ;     _Logger_Write("   📝 [MySQL] Формирование данных: " & StringFormat("%.2f", $fDataTime) & "мс", 1)
    ;     _Logger_Write("   💾 [MySQL] Вставка в БД: " & StringFormat("%.2f", $fInsertTime) & "мс", 1)
    ;     _Logger_Write("   🎯 [MySQL] ИТОГО InsertSCADA: " & StringFormat("%.2f", $fTotalTime) & "мс", 1)
    ; EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _MySQL_UpdateSCADA
; ===============================================================================
; ===============================================================================
; Функция: _MySQL_UpdateSCADA
; Описание: Обновление записи с автоматическим обновлением event_datetime
; Параметры:
;   $sTable - имя таблицы
;   $sData - данные для обновления в формате "key1=val1|key2=val2" (БЕЗ event_datetime)
;   $sWhere - условие WHERE (обязательно)
;   $iServer - сервер (по умолчанию локальный)
;   $bJSON - формат ответа (по умолчанию False)
; Возврат: True при успехе, False при ошибке
; Примечание: Автоматически обновляет event_datetime с миллисекундами
; ===============================================================================
Func _MySQL_UpdateSCADA($sTable, $sData, $sWhere, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
    Local $hTotalTimer = _Utils_GetTimestamp()

    ; Таймер 1: Генерация времени
    Local $hTimeTimer = _Utils_GetTimestamp()
    Local $sDateTime = _Utils_GetDateTimeMS()
    Local $fTimeTime = _Utils_GetElapsedTime($hTimeTimer)

    ; Таймер 2: Формирование полных данных
    Local $hDataTimer = _Utils_GetTimestamp()
    Local $sFullData = "event_datetime=" & $sDateTime & "|" & $sData
    Local $fDataTime = _Utils_GetElapsedTime($hDataTimer)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔄 [MySQL] UpdateSCADA: " & $sTable & " (DateTime: " & $sDateTime & ")", 1)
    EndIf

    ; Таймер 3: Обновление через обычный Update
    Local $hUpdateTimer = _Utils_GetTimestamp()
    Local $bResult = _MySQL_Update($sTable, $sFullData, $sWhere, $iServer, $bJSON)
    Local $fUpdateTime = _Utils_GetElapsedTime($hUpdateTimer)

    Local $fTotalTime = _Utils_GetElapsedTime($hTotalTimer)

    ; Детальная диагностика производительности (отключена для краткости логов)
    ; If $g_bMySQL_DebugMode Then
    ;     _Logger_Write("⏱️ [MySQL] Диагностика _MySQL_UpdateSCADA:", 1)
    ;     _Logger_Write("   ⏰ [MySQL] Генерация времени: " & StringFormat("%.2f", $fTimeTime) & "мс", 1)
    ;     _Logger_Write("   📝 [MySQL] Формирование данных: " & StringFormat("%.2f", $fDataTime) & "мс", 1)
    ;     _Logger_Write("   💾 [MySQL] Обновление в БД: " & StringFormat("%.2f", $fUpdateTime) & "мс", 1)
    ;     _Logger_Write("   🎯 [MySQL] ИТОГО UpdateSCADA: " & StringFormat("%.2f", $fTotalTime) & "мс", 1)
    ; EndIf

    Return $bResult
EndFunc


; ===============================================================================
; ОСНОВНЫЕ ФУНКЦИИ
; ===============================================================================

; ===============================================================================
; УТИЛИТАРНЫЕ ФУНКЦИИ (MySQL v2.0)
; ===============================================================================

; ===============================================================================
; Функция: _MySQL_Count
; Описание: Подсчет количества записей в таблице
; Параметры:
;   $sTable - имя таблицы (обязательный)
;   $sWhere - условие WHERE (опционально, без слова WHERE)
;   $iServer - сервер: 1=хостинг, 2=локальный, 3=оба (по умолчанию локальный)
; Возврат: Количество записей (Int) или -1 при ошибке
; Пример: _MySQL_Count("sensors", "status='online'")
; Пример: _MySQL_Count("users") ; Все записи
; ===============================================================================
Func _MySQL_Count($sTable, $sWhere = "", $iServer = $MYSQL_SERVER_LOCAL)
    ; Формируем SQL запрос
    Local $sSQL = "SELECT COUNT(*) as total FROM " & $sTable

    If $sWhere <> "" Then
        $sSQL &= " WHERE " & $sWhere
    EndIf

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔢 [MySQL] Count: " & $sSQL, 1)
    EndIf

    ; Выполняем запрос
    Local $aResult = _MySQL_Query($sSQL, 0, $iServer, False)

    If Not IsArray($aResult) Or UBound($aResult) = 0 Then
        Return SetError(1, 0, -1)
    EndIf

    ; Возвращаем количество
    Local $iCount = Int($aResult[0][0])

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔢 [MySQL] Count результат: " & $iCount, 1)
    EndIf

    Return $iCount
EndFunc

; ===============================================================================
; Функция: _MySQL_Exists
; Описание: Проверка существования записи в таблице
; Параметры:
;   $sTable - имя таблицы (обязательный)
;   $sWhere - условие WHERE (обязательный)
;   $iServer - сервер: 1=хостинг, 2=локальный, 3=оба (по умолчанию локальный)
; Возврат: True если запись существует, False если нет или ошибка
; Пример: _MySQL_Exists("users", "email='test@test.com'")
; Пример: If _MySQL_Exists("sensors", "uuid='" & $sUUID & "'") Then ...
; ===============================================================================
Func _MySQL_Exists($sTable, $sWhere, $iServer = $MYSQL_SERVER_LOCAL)
    ; Проверка обязательного WHERE
    If $sWhere = "" Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("⚠️ [MySQL] Exists: Условие WHERE обязательно", 2)
        EndIf
        Return SetError(1, 0, False)
    EndIf

    ; Формируем SQL запрос с LIMIT 1 для производительности
    Local $sSQL = "SELECT 1 FROM " & $sTable & " WHERE " & $sWhere & " LIMIT 1"

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔍 [MySQL] Exists: " & $sSQL, 1)
    EndIf

    ; Выполняем запрос
    Local $aResult = _MySQL_Query($sSQL, 0, $iServer, False)

    ; Если есть хотя бы одна строка - запись существует
    Local $bExists = (IsArray($aResult) And UBound($aResult) > 0)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔍 [MySQL] Exists результат: " & ($bExists ? "True" : "False"), 1)
    EndIf

    Return $bExists
EndFunc

; ===============================================================================
; Функция: _MySQL_GetLastInsertID
; Описание: Получение ID последней вставленной записи
; Параметры:
;   $iServer - сервер: 1=хостинг, 2=локальный (по умолчанию локальный) [НЕ ИСПОЛЬЗУЕТСЯ]
; Возврат: ID последней вставки (Int) или -1 при ошибке
; Пример:
;   _MySQL_Insert("users", "name=John|email=john@test.com")
;   Local $iLastID = _MySQL_GetLastInsertID()
; Примечание: Возвращает last_insert_id из последнего INSERT запроса (сохраненный из ответа PHP)
; ===============================================================================
Func _MySQL_GetLastInsertID($iServer = $MYSQL_SERVER_LOCAL)
    If $g_bMySQL_DebugMode Then
        _Logger_Write("🆔 [MySQL] GetLastInsertID: " & $g_iMySQL_LastInsertID, 1)
    EndIf

    ; Возвращаем сохраненный last_insert_id из последнего INSERT
    If $g_iMySQL_LastInsertID > 0 Then
        Return $g_iMySQL_LastInsertID
    EndIf

    ; Если last_insert_id не был сохранен, возвращаем ошибку
    Return SetError(1, 0, -1)
EndFunc

; ===============================================================================
; ОСНОВНЫЕ ФУНКЦИИ
; ===============================================================================

; ===============================================================================
; Функция: _MySQL_Query
; Описание: Универсальный SQL запрос к MySQL через HTTP API
; Параметры:
;   $sSQL - SQL запрос (обязательный)
;   $aParams - массив параметров для подстановки (опционально)
;   $iServer - сервер: 1=хостинг, 2=локальный, 3=оба (по умолчанию локальный)
;   $bJSON - формат ответа: False=простой, True=JSON (по умолчанию простой)
; Возврат:
;   SELECT запросы: двумерный массив данных или False при ошибке
;   Другие запросы: True при успехе, False при ошибке
; ===============================================================================
Func _MySQL_Query($sSQL, $aParams = 0, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
    Local $hTimer = _Utils_GetTimestamp()
    $g_sMySQL_LastError = ""

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔍 [MySQL] Query: " & StringLeft($sSQL, 50) & "...", 1)
    EndIf

    ; КРИТИЧНО: Проверяем тип запроса для логики FIFO
    Local $bIsSelect = (StringLeft(StringUpper(StringStripWS($sSQL, 3)), 6) = "SELECT")

    ; ИСПРАВЛЕНИЕ ГЛАВНОЙ ОШИБКИ: Строгий режим FIFO
    ; Если очередь активна И запрос НЕ SELECT → сразу в очередь, НЕ выполняем напрямую
    If ($g_bLocalQueueActive Or $g_bRemoteQueueActive) And Not $bIsSelect Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("📋 [MySQL] Режим FIFO: запрос добавлен в очередь (очередь активна)", 1)
        EndIf

        ; Добавляем в очередь
        Local $bAddedToQueue = _MySQL_AddToQueue($sSQL, $aParams, $iServer, $bJSON)

        ; Пытаемся обработать очередь (может быть связь уже восстановилась)
        _MySQL_ProcessQueue($iServer)

        ; Возвращаем успех (имитируем успешное выполнение для скрипта)
        Return True
    EndIf

    ; Обрабатываем очередь только для SELECT запросов или когда очередь неактивна
    If $g_bLocalQueueActive Or $g_bRemoteQueueActive Then
        _MySQL_ProcessQueue($iServer)
    EndIf

    ; НОВАЯ ЛОГИКА: TCP пинг для ВСЕХ запросов (включая SELECT)
    Local $bPingResult = False

    ; Выбираем функцию пинга в зависимости от сервера
    Switch $iServer
        Case $MYSQL_SERVER_LOCAL
            $bPingResult = _MySQL_PingTCP_Local()
        Case $MYSQL_SERVER_REMOTE
            $bPingResult = _MySQL_PingTCP_Remote()
        Case $MYSQL_SERVER_BOTH
            ; Для обоих серверов проверяем локальный (приоритет)
            $bPingResult = _MySQL_PingTCP_Local()
    EndSwitch

    If Not $bPingResult Then
        If $bIsSelect Then
            ; SELECT запросы НЕ добавляем в очередь, просто возвращаем False
            If $g_bMySQL_DebugMode Then
                _Logger_Write("🚫 [MySQL] SELECT не добавляется в очередь: " & StringLeft($sSQL, 50), 1)
            EndIf
            $g_sMySQL_LastError = "Сервер недоступен (SELECT запрос не выполнен)"
            Return False
        Else
            ; Не-SELECT запросы добавляем в очередь
            If $g_bMySQL_DebugMode Then
                _Logger_Write("📥 [MySQL] Быстрый пинг неудачен, добавляю в очередь без попытки запроса", 1)
            EndIf
            _MySQL_AddToQueue($sSQL, $aParams, $iServer, $bJSON)
            $g_sMySQL_LastError = "Сервер недоступен (быстрый пинг неудачен) - добавлено в очередь"
            Return False
        EndIf
    EndIf

    ; Таймер 1: Подготовка серверов
    Local $hServerTimer = _Utils_GetTimestamp()
    Local $aServers[0][2] ; [host, key]

    Switch $iServer
        Case $MYSQL_SERVER_LOCAL
            ReDim $aServers[1][2]
            $aServers[0][0] = $g_sMySQL_LocalHost
            $aServers[0][1] = $g_sMySQL_LocalKey

        Case $MYSQL_SERVER_REMOTE
            ReDim $aServers[1][2]
            $aServers[0][0] = $g_sMySQL_RemoteHost
            $aServers[0][1] = $g_sMySQL_RemoteKey

        Case $MYSQL_SERVER_BOTH
            ReDim $aServers[2][2]
            $aServers[0][0] = $g_sMySQL_LocalHost
            $aServers[0][1] = $g_sMySQL_LocalKey
            $aServers[1][0] = $g_sMySQL_RemoteHost
            $aServers[1][1] = $g_sMySQL_RemoteKey

        Case Else
            $g_sMySQL_LastError = "Неверный параметр сервера: " & $iServer
            Return False
    EndSwitch
    Local $fServerTime = _Utils_GetElapsedTime($hServerTimer)

    ; Выполняем запрос на выбранных серверах
    Local $aResult = False
    Local $bSuccess = False

    For $i = 0 To UBound($aServers) - 1
        ; Таймер 2: Подготовка URL и POST данных
        Local $hURLTimer = _Utils_GetTimestamp()
        Local $sURL = _MySQL_BuildURL($aServers[$i][0])
        Local $sPostData = _MySQL_BuildPostData($sSQL, $aParams, $aServers[$i][1], $bJSON)
        Local $fURLTime = _Utils_GetElapsedTime($hURLTimer)

        If $g_bMySQL_DebugMode Then
            _Logger_Write("📡 [MySQL] POST запрос к: " & $aServers[$i][0], 1)
        EndIf

        ; Таймер 3: HTTP запрос
        Local $hHTTPTimer = _Utils_GetTimestamp()
        Local $sResponse = _MySQL_HttpRequest($sURL, $g_iMySQL_Timeout, $sPostData)
        Local $iHTTPError = @error
        Local $iHTTPStatus = @extended
        Local $fHTTPTime = _Utils_GetElapsedTime($hHTTPTimer)

        ; Логируем WinHTTP ответы только для основных тестов, не для wrapper-функций
        If $g_bMySQL_DebugMode Then
            _Logger_Write("📥 [MySQL] WinHTTP ответ: " & StringLeft($sResponse, 100), 1)
        EndIf

        If $iHTTPError <> 0 Then
            ; СЕТЕВАЯ ОШИБКА - добавляем в очередь (кроме SELECT)
            Local $bAddedToQueue = _MySQL_AddToQueue($sSQL, $aParams, $aServers[$i][0] = $g_sMySQL_LocalHost ? $MYSQL_SERVER_LOCAL : $MYSQL_SERVER_REMOTE, $bJSON)
            $g_sMySQL_LastError = "Сетевая ошибка: " & $iHTTPError & " (HTTP " & $iHTTPStatus & ")" & ($bAddedToQueue ? " - добавлено в очередь" : "")
            If $g_bMySQL_DebugMode Then
                _Logger_Write("❌ [MySQL] HTTP ошибка: " & $iHTTPError & " (HTTP " & $iHTTPStatus & ")", 2)
            EndIf
            ContinueLoop
        EndIf

        ; Проверяем ответ на ошибки
        If StringInStr($sResponse, "ERROR:") = 1 Then
            ; ОШИБКА SQL - НЕ добавляем в очередь, возвращаем ошибку
            $g_sMySQL_LastError = StringTrimLeft($sResponse, 6)
            If $g_bMySQL_DebugMode Then
                _Logger_Write("❌ [MySQL] Ошибка сервера: " & $g_sMySQL_LastError, 2)
            EndIf
            ContinueLoop
        EndIf

        ; Таймер 4: Парсинг ответа
        Local $hParseTimer = _Utils_GetTimestamp()
        If $bJSON Then
            $aResult = _MySQL_ParseJSONResponse($sResponse)
        Else
            $aResult = _MySQL_ParseSimpleResponse($sResponse)
        EndIf
        Local $fParseTime = _Utils_GetElapsedTime($hParseTimer)

        $bSuccess = ($aResult <> False)

        ; Детальная диагностика производительности основного запроса (отключена для краткости логов)
        ; Local $fTotalTime = _Utils_GetElapsedTime($hTimer)
        ; If $g_bMySQL_DebugMode Then
        ;     _Logger_Write("⏱️ [MySQL] Диагностика _MySQL_Query:", 1)
        ;     _Logger_Write("   🔧 [MySQL] Подготовка серверов: " & StringFormat("%.2f", $fServerTime) & "мс", 1)
        ;     _Logger_Write("   📝 [MySQL] Формирование URL/POST: " & StringFormat("%.2f", $fURLTime) & "мс", 1)
        ;     _Logger_Write("   🌐 [MySQL] HTTP запрос: " & StringFormat("%.2f", $fHTTPTime) & "мс", 1)
        ;     _Logger_Write("   🔍 [MySQL] Парсинг ответа: " & StringFormat("%.2f", $fParseTime) & "мс", 1)
        ;     _Logger_Write("   ✅ [MySQL] Запрос выполнен за " & StringFormat("%.2f", $fTotalTime) & "мс", 3)
        ; EndIf

        ; Если не нужно выполнять на всех серверах, выходим после первого успешного
        If $iServer <> $MYSQL_SERVER_BOTH Then ExitLoop
    Next

    If Not $bSuccess Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] Все серверы недоступны", 2)
        EndIf
        Return False
    EndIf

    Return $aResult
EndFunc
; ===============================================================================
; Функция: _MySQL_BuildURL
; Описание: Формирование URL для HTTP запроса к API (только базовый URL для POST)
; Параметры: $sHost - хост сервера
; Возврат: Базовый URL для запроса
; ===============================================================================
Func _MySQL_BuildURL($sHost)
    Return $sHost & "mysql_api.php"
EndFunc

; ===============================================================================
; Функция: _MySQL_BuildPostData
; Описание: Формирование POST данных для HTTP запроса к API
; Параметры: $sSQL, $aParams, $sKey, $bJSON
; Возврат: Строка POST данных
; ===============================================================================
Func _MySQL_BuildPostData($sSQL, $aParams, $sKey, $bJSON)
    Local $sPostData = "key=" & _URIEncode($sKey)

    ; SQL кодируем через _URIEncode — PHP получает через $_POST (уже декодирован, без двойного urldecode)
    $sPostData &= "&sql=" & _URIEncode($sSQL)

    ; Добавляем параметры если есть
    If IsArray($aParams) Then
        Local $sParamsStr = ""
        For $i = 0 To UBound($aParams) - 1
            $sParamsStr &= $aParams[$i]
            If $i < UBound($aParams) - 1 Then $sParamsStr &= "|"
        Next
        $sPostData &= "&params=" & _URIEncode($sParamsStr)
    EndIf

    ; Добавляем формат ответа
    If $bJSON Then
        $sPostData &= "&format=json"
    Else
        $sPostData &= "&format=simple"
    EndIf

    Return $sPostData
EndFunc

; ===============================================================================
; Функция: _MySQL_ParseSimpleResponse
; Описание: Парсинг простого формата ответа (как в старых примерах)
; Параметры: $sResponse - ответ сервера
; Возврат: Массив данных или True/False для не-SELECT запросов
; ===============================================================================
Func _MySQL_ParseSimpleResponse($sResponse)
    ; Сбрасываем last_insert_id перед парсингом
    $g_iMySQL_LastInsertID = 0

    ; Проверяем на статус операции (для INSERT/UPDATE/DELETE/CREATE и т.д.)
    If StringInStr($sResponse, "SUCCESS:") = 1 Then
        ; Проверяем наличие LASTID в ответе
        If StringInStr($sResponse, "|LASTID:") > 0 Then
            Local $aLastID = StringRegExp($sResponse, '\|LASTID:(\d+)', 1)
            If IsArray($aLastID) And UBound($aLastID) > 0 Then
                $g_iMySQL_LastInsertID = Int($aLastID[0])
                If $g_bMySQL_DebugMode Then
                    _Logger_Write("[MySQL] Найден SUCCESS статус с LASTID: " & $g_iMySQL_LastInsertID, 3)
                EndIf
            EndIf
        Else
            If $g_bMySQL_DebugMode Then
                _Logger_Write("[MySQL] Найден SUCCESS статус", 3)
            EndIf
        EndIf
        Return True
    EndIf

    If StringInStr($sResponse, "AFFECTED:") = 1 Then
        ; Проверяем наличие LASTID в ответе
        If StringInStr($sResponse, "|LASTID:") > 0 Then
            Local $aLastID = StringRegExp($sResponse, '\|LASTID:(\d+)', 1)
            If IsArray($aLastID) And UBound($aLastID) > 0 Then
                $g_iMySQL_LastInsertID = Int($aLastID[0])
                If $g_bMySQL_DebugMode Then
                    _Logger_Write("[MySQL] Найден AFFECTED статус с LASTID: " & $g_iMySQL_LastInsertID, 3)
                EndIf
            EndIf
        Else
            If $g_bMySQL_DebugMode Then
                _Logger_Write("[MySQL] Найден AFFECTED статус", 3)
            EndIf
        EndIf
        Return True ; Можно вернуть количество затронутых строк если нужно
    EndIf

    ; Парсим данные SELECT запроса
    Local $aDataRows = StringRegExp($sResponse, '(?i)<start_string>(.*?)<\/start_string>', 3)
    If Not IsArray($aDataRows) Or UBound($aDataRows) = 0 Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("[MySQL] Нет данных SELECT или ошибка парсинга", 1)
        EndIf
        Return False ; Пустой результат или ошибка парсинга
    EndIf

    If $g_bMySQL_DebugMode Then
        _Logger_Write("[MySQL] Найдено " & UBound($aDataRows) & " строк данных", 1)
    EndIf

    Local $iTotalRows = UBound($aDataRows)

    ; Определяем количество колонок из первой строки
    Local $aFirstLine = StringSplit($aDataRows[0], ";", 1)
    Local $iCurrentCols = $aFirstLine[0]

    ; Создаем итоговый массив
    Local $aFinalTable[$iTotalRows][$iCurrentCols]

    For $i = 0 To $iTotalRows - 1
        Local $aCurrentRowData = StringSplit($aDataRows[$i], ";", 1)

        Local $iLimitJ = ($aCurrentRowData[0] < $iCurrentCols) ? $aCurrentRowData[0] : $iCurrentCols

        For $j = 0 To $iLimitJ - 1
            $aFinalTable[$i][$j] = $aCurrentRowData[$j + 1]
        Next
    Next

    Return $aFinalTable
EndFunc

; ===============================================================================
; Функция: _MySQL_ParseJSONResponse
; Описание: Парсинг JSON формата ответа
; Параметры: $sResponse - ответ сервера в JSON
; Возврат: Массив данных или True/False для не-SELECT запросов
; ===============================================================================
Func _MySQL_ParseJSONResponse($sResponse)
    Local $oData = _JSON_Parse($sResponse)

    If @error Then
        $g_sMySQL_LastError = "Ошибка парсинга JSON: " & @error
        Return False
    EndIf

    ; Проверяем статус операции
    If IsMap($oData) And MapExists($oData, "status") Then
        If $oData["status"] = "success" Then
            If MapExists($oData, "data") And IsArray($oData["data"]) Then
                Return $oData["data"] ; Возвращаем данные SELECT
            Else
                Return True ; Успешная операция без данных
            EndIf
        Else
            $g_sMySQL_LastError = MapExists($oData, "error") ? $oData["error"] : "Неизвестная ошибка"
            Return False
        EndIf
    EndIf

    ; Если это просто массив данных
    If IsArray($oData) Then
        Return $oData
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _URIEncode
; Описание: Кодирование строки для URL (простая версия)
; Параметры: $sString - строка для кодирования
; Возврат: Закодированная строка
; ===============================================================================
Func _URIEncode($vData)
    If IsBool($vData) Then Return $vData
	Local $aData = StringToASCIIArray($vData, Default, Default, 2)
	Local $sOut = '', $total = UBound($aData) - 1
	For $i = 0 To $total
		Switch $aData[$i]
			Case 45, 46, 48 To 57, 65 To 90, 95, 97 To 122, 126
				$sOut &= Chr($aData[$i])
			Case 32
				$sOut &= '+'
			Case Else
				$sOut &= '%' & Hex($aData[$i], 2)
		EndSwitch
	Next
	Return $sOut
EndFunc
; ===============================================================================
; Функция: _MySQL_HttpRequest
; Описание: HTTP запрос через WinHTTP библиотеку с таймаутом 0.5 секунды
; Параметры:
;   $sURL - URL для запроса
;   $iTimeout - таймаут в миллисекундах
;   $sPostData - данные для POST запроса (если пусто - используется GET)
; Возврат:
;   Успех: строка с ответом сервера
;   Ошибка: пустая строка, @error содержит код ошибки, @extended - HTTP статус
; ===============================================================================
Func _MySQL_HttpRequest($sURL, $iTimeout = 500, $sPostData = "")
    ; ОТЛАДКА: Засекаем время начала запроса
    Local $hRequestTimer = _Utils_GetTimestamp()

    If $g_bMySQL_DebugMode Then
        _Logger_Write("⏱️ [MySQL] WinHTTP: Начало запроса", 1)
        _Logger_Write("   🔧 [MySQL] Целевой таймаут: " & $iTimeout & "мс", 1)
        _Logger_Write("   🌐 [MySQL] URL: " & $sURL, 1)
    EndIf

    ; Парсим URL
    Local $aURL = _WinHttpCrackUrl($sURL)
    If @error Then
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] WinHTTP: Ошибка парсинга URL за " & Round($fElapsed, 2) & "мс", 2)
        EndIf
        Return SetError(1, 0, "") ; Неверный URL
    EndIf

    Local $sScheme = $aURL[0]
    Local $sHost = $aURL[2]
    Local $iPort = $aURL[3]
    Local $sPath = $aURL[6] & $aURL[7] ; path + extra info

    ; Открываем WinHTTP сессию с защищенным User-Agent
    Local $hOpen = _WinHttpOpen("MySQL_API_Client/1.0 keytIHYxLjkuMiAtIDIwMTQtMDMtMjYNCiogaHR0cDovL2pxdWVyeXVpLmNvbQ0KKiBJbmNsdWRlc")
    If @error Or Not $hOpen Then
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] WinHTTP: Ошибка открытия сессии за " & Round($fElapsed, 2) & "мс", 2)
        EndIf
        Return SetError(2, 0, "") ; Ошибка открытия сессии
    EndIf

    ; Устанавливаем таймауты (ИСПРАВЛЕНИЕ: агрессивные таймауты для быстрого определения недоступности)
    ; $iResolveTimeout - DNS разрешение (мгновенно для localhost)
    ; $iConnectTimeout - подключение к серверу (КРИТИЧНО! По умолчанию 60 сек!)
    ; $iSendTimeout - отправка данных (КРИТИЧНО! По умолчанию 30 сек!)
    ; $iReceiveTimeout - получение ответа (основной таймаут)
    Local $iQuickTimeout = $iTimeout ; Используем переданный таймаут для всех операций
    _WinHttpSetTimeouts($hOpen, $iQuickTimeout, $iQuickTimeout, $iQuickTimeout, $iQuickTimeout)

    If $g_bMySQL_DebugMode Then
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        _Logger_Write("🔧 [MySQL] WinHTTP: Агрессивные таймауты " & $iQuickTimeout & "мс установлены за " & Round($fElapsed, 2) & "мс", 1)
    EndIf

    ; Подключаемся к серверу
    Local $hConnect = _WinHttpConnect($hOpen, $sHost, $iPort)
    If @error Or Not $hConnect Then
        _WinHttpCloseHandle($hOpen)
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] WinHTTP: Ошибка подключения к " & $sHost & ":" & $iPort & " за " & Round($fElapsed, 2) & "мс", 2)
        EndIf
        Return SetError(3, 0, "") ; Ошибка подключения
    EndIf

    ; ОПРЕДЕЛЯЕМ МЕТОД: если есть данные для отправки - это POST
    Local $sMethod = ($sPostData <> "") ? "POST" : "GET"

    ; Создаем запрос (теперь с переменным методом)
    Local $iFlags = ($sScheme = "https") ? $WINHTTP_FLAG_SECURE : 0
    Local $hRequest = _WinHttpOpenRequest($hConnect, $sMethod, $sPath, Default, Default, Default, $iFlags)
    If @error Or Not $hRequest Then
        _WinHttpCloseHandle($hConnect)
        _WinHttpCloseHandle($hOpen)
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] WinHTTP: Ошибка создания " & $sMethod & " запроса за " & Round($fElapsed, 2) & "мс", 2)
        EndIf
        Return SetError(4, 0, "") ; Ошибка создания запроса
    EndIf

    ; Если это POST, нужно добавить заголовок типа данных
    If $sPostData <> "" Then
        _WinHttpAddRequestHeaders($hRequest, "Content-Type: application/x-www-form-urlencoded")
    EndIf

    If $g_bMySQL_DebugMode Then
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        _Logger_Write("📡 [MySQL] WinHTTP: " & $sMethod & " запрос подготовлен за " & Round($fElapsed, 2) & "мс, отправляю...", 1)
    EndIf

    ; Отправляем запрос (передаем данные в тело, если они есть)
    Local $bSent = _WinHttpSendRequest($hRequest, Default, $sPostData)
    If @error Or Not $bSent Then
        _WinHttpCloseHandle($hRequest)
        _WinHttpCloseHandle($hConnect)
        _WinHttpCloseHandle($hOpen)
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] WinHTTP: Ошибка отправки запроса за " & Round($fElapsed, 2) & "мс", 2)
        EndIf
        Return SetError(5, 0, "") ; Ошибка отправки
    EndIf

    ; Получаем ответ
    Local $bReceived = _WinHttpReceiveResponse($hRequest)
    If @error Or Not $bReceived Then
        _WinHttpCloseHandle($hRequest)
        _WinHttpCloseHandle($hConnect)
        _WinHttpCloseHandle($hOpen)
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] WinHTTP: Ошибка получения ответа за " & Round($fElapsed, 2) & "мс (ТАЙМАУТ?)", 2)
        EndIf
        Return SetError(6, 0, "") ; Ошибка получения ответа
    EndIf

    ; Получаем HTTP статус
    Local $iStatusCode = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE)
    If @error Then $iStatusCode = 0

    If $g_bMySQL_DebugMode Then
        Local $fElapsed = _Utils_GetElapsedTime($hRequestTimer)
        _Logger_Write("📥 [MySQL] WinHTTP: Ответ получен (HTTP " & $iStatusCode & ") за " & Round($fElapsed, 2) & "мс, читаю данные...", 1)
    EndIf

    ; Читаем данные ответа
    Local $sResponse = ""
    Local $iAvailable, $sData

    Do
        $iAvailable = _WinHttpQueryDataAvailable($hRequest)
        If @error Or $iAvailable = 0 Then ExitLoop

        $sData = _WinHttpReadData($hRequest, $iAvailable)
        If @error Then ExitLoop

        ; WinHttpReadData возвращает бинарные данные, преобразуем в строку
        $sResponse &= BinaryToString($sData, 4) ; UTF-8
    Until $iAvailable = 0

    ; Закрываем handles
    _WinHttpCloseHandle($hRequest)
    _WinHttpCloseHandle($hConnect)
    _WinHttpCloseHandle($hOpen)

    ; ОТЛАДКА: Финальное время выполнения
    Local $fTotalElapsed = _Utils_GetElapsedTime($hRequestTimer)
    If $g_bMySQL_DebugMode Then
        _Logger_Write("✅ [MySQL] WinHTTP: Запрос завершен за " & Round($fTotalElapsed, 2) & "мс (данных: " & StringLen($sResponse) & " символов)", 3)
    EndIf

    ; Проверяем HTTP статус
    If $iStatusCode >= 400 Then
        Return SetError(7, $iStatusCode, $sResponse) ; HTTP ошибка, но возвращаем ответ
    EndIf

    Return $sResponse
EndFunc
; ===============================================================================
; Функция: _MySQL_PingTCP_Local
; Описание: Быстрая проверка доступности локального сервера через TCP
; Возврат: True если доступен, False если недоступен
; ===============================================================================
Func _MySQL_PingTCP_Local()
    Return _MySQL_PingTCP_Internal("127.0.0.1", 80)
EndFunc

; ===============================================================================
; Функция: _MySQL_PingTCP_Remote
; Описание: Быстрая проверка доступности удаленного сервера через TCP
; Возврат: True если доступен, False если недоступен
; ===============================================================================
Func _MySQL_PingTCP_Remote()
    ; Извлекаем хост из URL
    Local $sHost = StringReplace($g_sMySQL_RemoteHost, "http://", "")
    $sHost = StringReplace($sHost, "https://", "")
    $sHost = StringReplace($sHost, "/php/", "")
    Return _MySQL_PingTCP_Internal($sHost, 80)
EndFunc

; ===============================================================================
; Функция: _MySQL_PingTCP_Internal
; Описание: Внутренняя функция TCP пинга с DNS резолвингом
; Параметры: $sHost - хост или IP, $iPort - порт
; Возврат: True если доступен, False если недоступен
; ===============================================================================
Func _MySQL_PingTCP_Internal($sHost, $iPort = 80)
    Local $hTimer = _Utils_GetTimestamp()

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🏓 [MySQL] Ping: " & $sHost & ":" & $iPort, 1)
    EndIf

    ; Инициализируем TCP
    TCPStartup()

    ; Резолвим домен в IP если это не IP адрес
    Local $sTargetIP = $sHost
    If Not StringRegExp($sHost, "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") Then
        $sTargetIP = TCPNameToIP($sHost)
        If $sTargetIP = "" Then
            If $g_bMySQL_DebugMode Then
                _Logger_Write("❌ [MySQL] Ping: DNS ошибка для " & $sHost, 2)
            EndIf
            Return False
        EndIf
    EndIf

    ; Пытаемся подключиться к IP адресу
    Local $iSocket = TCPConnect($sTargetIP, $iPort)
    Local $iError = @error
    Local $fElapsed = _Utils_GetElapsedTime($hTimer)

    ; Закрываем сокет если подключились
    If $iSocket <> -1 Then
        TCPCloseSocket($iSocket)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("✅ [MySQL] Ping: Сервер доступен за " & Round($fElapsed, 2) & "мс", 3)
        EndIf
        Return True
    Else
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] Ping: Сервер недоступен за " & Round($fElapsed, 2) & "мс (ошибка: " & $iError & ")", 2)
        EndIf
        Return False
    EndIf
EndFunc


; ===============================================================================
; Функция: _MySQL_GetLastError
; Описание: Получение описания последней ошибки
; Возврат: Строка с описанием ошибки
; ===============================================================================
Func _MySQL_GetLastError()
    Return $g_sMySQL_LastError
EndFunc

; ===============================================================================
; Функция: _MySQL_SetDebugMode
; Описание: Включение/отключение режима отладки
; Параметры: $bEnabled - True для включения, False для отключения
; ===============================================================================
Func _MySQL_SetDebugMode($bEnabled)
    $g_bMySQL_DebugMode = $bEnabled
    If $bEnabled Then
        _Logger_Write("🔧 [MySQL] Режим отладки MySQL включен", 1)
    Else
        _Logger_Write("🔧 [MySQL] Режим отладки MySQL отключен", 1)
    EndIf
EndFunc


; ===============================================================================
; Функция: _MySQL_QuickPing
; Описание: Быстрая проверка доступности сервера (100мс таймаут)
; Параметры: $sHost - хост для проверки
; Возврат: True если доступен, False если недоступен
; ===============================================================================
Func _MySQL_QuickPing($sHost)
    Local $hPingTimer = _Utils_GetTimestamp()

    ; Используем минимальный запрос с очень коротким таймаутом
    Local $sPingURL = $sHost & "mysql_api.php?ping=1"
    Local $sResponse = _MySQL_HttpRequest($sPingURL, 50) ; 50мс таймаут для пинга (еще более агрессивный)
    Local $iPingError = @error

    Local $fPingTime = _Utils_GetElapsedTime($hPingTimer)

    If $g_bMySQL_DebugMode Then
        If $iPingError = 0 Then
            _Logger_Write("🏓 [MySQL] Ping: Сервер доступен за " & Round($fPingTime, 2) & "мс", 3)
        Else
            _Logger_Write("🏓 [MySQL] Ping: Сервер недоступен за " & Round($fPingTime, 2) & "мс (ошибка: " & $iPingError & ")", 2)
        EndIf
    EndIf

    Return ($iPingError = 0)
EndFunc
; ===============================================================================
; Функция: _MySQL_InitQueue
; Описание: Инициализация системы очередей при старте программы
; Возврат: True при успехе
; ===============================================================================
Func _MySQL_InitQueue()
   If $g_bMySQL_DebugMode Then _Logger_Write("🔧 [MySQL] Начало инициализации очередей SQLite", 1)
    
    ; Получаем имя приложения из SDK (если инициализирован)
    Local $sAppName = "DefaultApp"
    If IsDeclared("g_sSDK_AppName") Then
        $sAppName = Eval("g_sSDK_AppName")
    EndIf
   If $g_bMySQL_DebugMode Then _Logger_Write("📝 [MySQL] Имя приложения: " & $sAppName, 1)

    ; Формируем путь к SQLite базе
    Local $sQueueDir = @ScriptDir & "\MySQL_PHP_queue\"
    $g_sMySQLQueueDBPath = $sQueueDir & $sAppName & "_queue.db"
   If $g_bMySQL_DebugMode Then _Logger_Write("📂 [MySQL] Путь к базе: " & $g_sMySQLQueueDBPath, 1)

    ; Создаем папку если не существует
    If Not FileExists($sQueueDir) Then
        DirCreate($sQueueDir)
      If $g_bMySQL_DebugMode Then  _Logger_Write("📁 [MySQL] Создана папка очередей: " & $sQueueDir, 1)
    Else
      If $g_bMySQL_DebugMode Then  _Logger_Write("📁 [MySQL] Папка очередей существует: " & $sQueueDir, 1)
    EndIf

    ; Инициализируем SQLite (если еще не инициализирован)
    If Not $g_bUtils_SQLite_Initialized Then
      If $g_bMySQL_DebugMode Then  _Logger_Write("🔌 [MySQL] Инициализация SQLite...", 1)
        _Utils_SQLite_Startup()
        If @error Then
            _Logger_Write("❌ [MySQL] Ошибка инициализации SQLite: " & @error, 2)
            Return False
        EndIf
       If $g_bMySQL_DebugMode Then _Logger_Write("✅ [MySQL] SQLite инициализирован", 1)
    Else
       If $g_bMySQL_DebugMode Then _Logger_Write("✅ [MySQL] SQLite уже инициализирован", 1)
    EndIf

    ; Открываем базу данных
  If $g_bMySQL_DebugMode Then  _Logger_Write("🔓 [MySQL] Открытие базы данных...", 1)
    Local $hDB = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
    If @error Then
        _Logger_Write("❌ [MySQL] Ошибка открытия базы очередей: " & _Utils_SQLite_GetLastError() & " | @error=" & @error, 2)
        Return False
    EndIf
   If $g_bMySQL_DebugMode Then _Logger_Write("✅ [MySQL] База данных открыта, handle: " & $hDB, 1)

    ; Проверяем существование файла базы
    If FileExists($g_sMySQLQueueDBPath) Then
      If $g_bMySQL_DebugMode Then  _Logger_Write("✅ [MySQL] Файл базы данных создан: " & FileGetSize($g_sMySQLQueueDBPath) & " байт", 1)
    Else
        _Logger_Write("❌ [MySQL] ФАЙЛ БАЗЫ ДАННЫХ НЕ СОЗДАН!", 2)
    EndIf

    ; Создаем таблицу queue если не существует
   If $g_bMySQL_DebugMode Then _Logger_Write("📋 [MySQL] Создание таблицы queue...", 1)
    Local $sQueueSchema = _
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " & _
        "uuid TEXT UNIQUE NOT NULL, " & _
        "server TEXT NOT NULL, " & _
        "sql_query TEXT NOT NULL, " & _
        "params TEXT, " & _
        "is_json INTEGER DEFAULT 0, " & _
        "retry_count INTEGER DEFAULT 0, " & _
        "created_at TEXT NOT NULL, " & _
        "last_attempt TEXT, " & _
        "status TEXT DEFAULT 'pending'"

    _Utils_SQLite_CreateTable($hDB, "queue", $sQueueSchema)
    If @error Then
        _Logger_Write("❌ [MySQL] Ошибка создания таблицы queue: " & _Utils_SQLite_GetLastError() & " | @error=" & @error, 2)
        _Utils_SQLite_Close($hDB)
        Return False
    EndIf
   If $g_bMySQL_DebugMode Then _Logger_Write("✅ [MySQL] Таблица queue создана", 1)

    ; Создаем таблицу errors если не существует
   If $g_bMySQL_DebugMode Then _Logger_Write("📋 [MySQL] Создание таблицы errors...", 1)
    Local $sErrorsSchema = _
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " & _
        "uuid TEXT, " & _
        "server TEXT NOT NULL, " & _
        "sql_query TEXT NOT NULL, " & _
        "error_message TEXT NOT NULL, " & _
        "retry_count INTEGER, " & _
        "created_at TEXT NOT NULL"

    _Utils_SQLite_CreateTable($hDB, "errors", $sErrorsSchema)
    If @error Then
        _Logger_Write("❌ [MySQL] Ошибка создания таблицы errors: " & _Utils_SQLite_GetLastError() & " | @error=" & @error, 2)
        _Utils_SQLite_Close($hDB)
        Return False
    EndIf
  If $g_bMySQL_DebugMode Then  _Logger_Write("✅ [MySQL] Таблица errors создана", 1)

    ; Создаем индексы для производительности
   If $g_bMySQL_DebugMode Then _Logger_Write("🔍 [MySQL] Создание индексов...", 1)
    _Utils_SQLite_Exec($hDB, "CREATE INDEX IF NOT EXISTS idx_queue_server_status ON queue(server, status)")
    _Utils_SQLite_Exec($hDB, "CREATE INDEX IF NOT EXISTS idx_queue_created ON queue(created_at)")
    _Utils_SQLite_Exec($hDB, "CREATE INDEX IF NOT EXISTS idx_queue_uuid ON queue(uuid)")
    _Utils_SQLite_Exec($hDB, "CREATE INDEX IF NOT EXISTS idx_errors_created ON errors(created_at)")
  If $g_bMySQL_DebugMode Then  _Logger_Write("✅ [MySQL] Индексы созданы", 1)

    ; Проверяем количество записей в очередях
   If $g_bMySQL_DebugMode Then _Logger_Write("📊 [MySQL] Подсчет записей в очередях...", 1)
    Local $iLocalCount = _Utils_SQLite_Count($hDB, "queue", "server='LOCAL' AND status='pending'")
    Local $iRemoteCount = _Utils_SQLite_Count($hDB, "queue", "server='REMOTE' AND status='pending'")
   If $g_bMySQL_DebugMode Then _Logger_Write("📊 [MySQL] Записей в очередях: Local=" & $iLocalCount & ", Remote=" & $iRemoteCount, 1)

    ; Закрываем базу
    _Utils_SQLite_Close($hDB)
  If $g_bMySQL_DebugMode Then  _Logger_Write("🔒 [MySQL] База данных закрыта", 1)

    ; Устанавливаем флаги активности очередей
    $g_bLocalQueueActive = ($iLocalCount > 0)
    $g_bRemoteQueueActive = ($iRemoteCount > 0)

    ; Логируем состояние очередей
    If $g_bLocalQueueActive Or $g_bRemoteQueueActive Then
      If $g_bMySQL_DebugMode Then  _Logger_Write("📋 [MySQL] Очереди загружены из SQLite: Local=" & $iLocalCount & ", Remote=" & $iRemoteCount, 1)
    Else
      If $g_bMySQL_DebugMode Then  _Logger_Write("📭 [MySQL] Очереди пусты (SQLite)", 1)
    EndIf

   If $g_bMySQL_DebugMode Then _Logger_Write("✅ [MySQL] Инициализация очередей завершена успешно", 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _MySQL_AddToQueue
; Описание: Добавление запроса в очередь при неудачной отправке (с фильтрацией SELECT)
; Параметры: $sSQL, $aParams, $iServer, $bJSON
; Возврат: True если добавлено, False если не добавлено (SELECT)
; ===============================================================================
Func _MySQL_AddToQueue($sSQL, $aParams, $iServer, $bJSON)
    ; КРИТИЧНО: SELECT запросы НЕ добавляем в очередь
    If StringLeft(StringUpper(StringStripWS($sSQL, 3)), 6) = "SELECT" Then
        If $g_bMySQL_DebugMode Then
            _Logger_Write("🚫 [MySQL] SELECT не добавляется в очередь: " & StringLeft($sSQL, 50), 1)
        EndIf
        Return False ; SELECT нужен немедленно
    EndIf

    ; Генерируем UUID v7 для точного времени события
    Local $sUUID = _Utils_GenerateUUIDv7()

    ; Подготавливаем данные для SQLite
    Local $sServerType = ($iServer = $MYSQL_SERVER_LOCAL) ? "LOCAL" : "REMOTE"
    Local $sParams = IsArray($aParams) ? _Utils_ArrayToString($aParams, "|") : ""
    Local $sTimestamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    Local $iIsJSON = ($bJSON ? 1 : 0)

    ; НОВОЕ: Кодируем SQL и params в Base64 для безопасного хранения
    Local $sSQLBase64 = __JSON_Base64Encode($sSQL)
    Local $sParamsBase64 = __JSON_Base64Encode($sParams)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔍 [MySQL] Добавление в SQLite очередь:", 1)
        _Logger_Write("   🆔 [MySQL] UUID: " & $sUUID, 1)
        _Logger_Write("   📅 [MySQL] Timestamp: " & $sTimestamp, 1)
        _Logger_Write("   🖥️ [MySQL] Server: " & $sServerType, 1)
        _Logger_Write("   📝 [MySQL] SQL: " & StringLeft($sSQL, 100), 1)
        _Logger_Write("   📊 [MySQL] Params: " & $sParams, 1)
        _Logger_Write("   🔧 [MySQL] JSON: " & $iIsJSON, 1)
        _Logger_Write("   🔐 [MySQL] SQL Base64: " & StringLeft($sSQLBase64, 50), 1)
    EndIf

    ; Открываем базу данных
    Local $hDB = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
    If @error Then
        _Logger_Write("❌ [MySQL] Ошибка открытия базы очередей: " & _Utils_SQLite_GetLastError(), 2)
        Return False
    EndIf

    ; Формируем INSERT запрос с UUID и Base64 данными
    Local $sInsertSQL = "INSERT INTO queue (uuid, server, sql_query, params, is_json, retry_count, created_at, status) " & _
                        "VALUES ('" & $sUUID & "', '" & $sServerType & "', '" & $sSQLBase64 & "', '" & $sParamsBase64 & "', " & $iIsJSON & ", 0, '" & $sTimestamp & "', 'pending')"

    _Utils_SQLite_Exec($hDB, $sInsertSQL)
    Local $iError = @error

    ; Закрываем базу
    _Utils_SQLite_Close($hDB)

    If $iError Then
        _Logger_Write("❌ [MySQL] Ошибка добавления в очередь: " & _Utils_SQLite_GetLastError(), 2)
        Return False
    EndIf

    ; Устанавливаем флаг активности очереди
    If $iServer = $MYSQL_SERVER_LOCAL Then
        $g_bLocalQueueActive = True
        If $g_bMySQL_DebugMode Then
            _Logger_Write("📝 [MySQL] Добавлено в локальную очередь (SQLite): " & StringLeft($sSQL, 50), 1)
        EndIf
    ElseIf $iServer = $MYSQL_SERVER_REMOTE Then
        $g_bRemoteQueueActive = True
        If $g_bMySQL_DebugMode Then
            _Logger_Write("📝 [MySQL] Добавлено в удаленную очередь (SQLite): " & StringLeft($sSQL, 50), 1)
        EndIf
    EndIf

    Return True
EndFunc

; ===============================================================================
; Функция: _MySQL_ProcessQueue
; Описание: Умная обработка очереди (минимум ресурсов)
; Параметры: $iServer - какую очередь обрабатывать (0=обе, 1=remote, 2=local)
; ===============================================================================
Func _MySQL_ProcessQueue($iServer = 0)
    ; Проверяем нужно ли обрабатывать очереди (экономия ресурсов)
    Local $iCurrentTime = _Utils_GetTimestamp()

    ; Открываем базу для проверки размера очередей (если нужен debug)
    If $g_bMySQL_DebugMode Then
        Local $hDB = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
        If Not @error Then
            Local $iLocalCount = _Utils_SQLite_Count($hDB, "queue", "server='LOCAL' AND status='pending'")
            Local $iRemoteCount = _Utils_SQLite_Count($hDB, "queue", "server='REMOTE' AND status='pending'")
            _Utils_SQLite_Close($hDB)
            
           If $g_bMySQL_DebugMode Then _Logger_Write("🔄 [MySQL] Проверка очередей (SQLite): Local=" & $iLocalCount & " (" & ($g_bLocalQueueActive ? "активна" : "неактивна") & "), Remote=" & $iRemoteCount & " (" & ($g_bRemoteQueueActive ? "активна" : "неактивна") & ")", 1)
        EndIf
    EndIf

    ; Локальная очередь
    If ($iServer = 0 Or $iServer = $MYSQL_SERVER_LOCAL) And $g_bLocalQueueActive Then
        If $iCurrentTime - $g_iLastLocalAttempt > $g_iQueueRetryInterval Then
            $g_iLastLocalAttempt = $iCurrentTime
            _MySQL_ProcessSingleQueue($MYSQL_SERVER_LOCAL)
        EndIf
    EndIf

    ; Удаленная очередь
    If ($iServer = 0 Or $iServer = $MYSQL_SERVER_REMOTE) And $g_bRemoteQueueActive Then
        If $iCurrentTime - $g_iLastRemoteAttempt > $g_iQueueRetryInterval Then
            $g_iLastRemoteAttempt = $iCurrentTime
            _MySQL_ProcessSingleQueue($MYSQL_SERVER_REMOTE)
        EndIf
    EndIf
EndFunc

; ===============================================================================
; Функция: _MySQL_ProcessSingleQueue
; Описание: Обработка одной очереди (с защитой от Poison Pill)
; Параметры: $iServer - тип сервера
; ===============================================================================
Func _MySQL_ProcessSingleQueue($iServer)
    Local $sServerName = ($iServer = $MYSQL_SERVER_LOCAL) ? "локальной" : "удаленной"
    Local $iCurrentTime = _Utils_GetTimestamp()

    ; Открываем базу данных
    Local $hDB = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
    If @error Then
        _Logger_Write("❌ [MySQL] Ошибка открытия базы очередей: " & _Utils_SQLite_GetLastError(), 2)
        Return False
    EndIf

    ; Определяем тип сервера для фильтрации
    Local $sServerType = ($iServer = $MYSQL_SERVER_LOCAL) ? "LOCAL" : "REMOTE"

    ; Проверяем количество записей в очереди
    Local $iQueueSize = _Utils_SQLite_Count($hDB, "queue", "server='" & $sServerType & "' AND status='pending'")

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔍 [MySQL] ProcessSingleQueue (SQLite): сервер=" & $sServerName & ", размер очереди=" & $iQueueSize, 1)
    EndIf

    If $iQueueSize = 0 Then
        _Utils_SQLite_Close($hDB)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("📭 [MySQL] " & $sServerName & " очередь пуста, выходим", 1)
        EndIf
        Return
    EndIf

    ; Загружаем первую запись из очереди (ORDER BY id ASC LIMIT 1 - текущее поведение)
    Local $aQueue = _Utils_SQLite_LoadTable($hDB, "queue", "server='" & $sServerType & "' AND status='pending' ORDER BY id ASC LIMIT 1")
    If @error Or Not IsArray($aQueue) Or UBound($aQueue, 1) = 0 Then
        _Utils_SQLite_Close($hDB)
        _Logger_Write("❌ [MySQL] Ошибка загрузки записи из очереди: " & _Utils_SQLite_GetLastError(), 2)
        Return False
    EndIf

    ; Извлекаем данные из первой записи
    ; Структура: [0]=id, [1]=uuid, [2]=server, [3]=sql_query, [4]=params, [5]=is_json, [6]=retry_count, [7]=created_at, [8]=last_attempt, [9]=status
    Local $iRecordID = Int($aQueue[0][0])
    Local $sUUID = $aQueue[0][1]
    Local $sSQLBase64 = $aQueue[0][3]
    Local $sParamsBase64 = $aQueue[0][4]
    Local $bJSON = (Int($aQueue[0][5]) = 1)
    Local $iRetryCount = Int($aQueue[0][6])
    Local $sTimestamp = $aQueue[0][7]

    ; НОВОЕ: Декодируем SQL и params из Base64
    Local $sSQL = BinaryToString(__JSON_Base64Decode($sSQLBase64))
    Local $sParams = BinaryToString(__JSON_Base64Decode($sParamsBase64))

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔄 [MySQL] Обрабатываю " & $sServerName & " очередь: " & $iQueueSize & " записей", 1)
        _Logger_Write("📋 [MySQL] Первая запись: ID=" & $iRecordID & ", UUID=" & $sUUID, 1)
        _Logger_Write("   📝 [MySQL] SQL: " & StringLeft($sSQL, 50) & "...", 1)
        _Logger_Write("   📅 [MySQL] Timestamp: " & $sTimestamp, 1)
        _Logger_Write("   🔄 [MySQL] Retry: " & $iRetryCount, 1)
    EndIf

    ; Проверяем доступность сервера через TCP пинг
    Local $bServerAvailable = False
    If $iServer = $MYSQL_SERVER_LOCAL Then
        $bServerAvailable = _MySQL_PingTCP_Local()
    Else
        $bServerAvailable = _MySQL_PingTCP_Remote()
    EndIf

    If Not $bServerAvailable Then
        _Utils_SQLite_Close($hDB)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("🚫 [MySQL] " & $sServerName & " сервер недоступен (TCP пинг неудачен), пропускаем обработку очереди", 1)
        EndIf
        Return
    EndIf

    ; Проверяем лимит попыток (защита от зацикливания)
    If $iRetryCount >= $g_iMaxRetryCount Then
        ; Превышен лимит - логируем в таблицу errors и СБРАСЫВАЕМ счетчик
        Local $sErrorMsg = "Max retry count exceeded - resetting counter"
        
        ; Кодируем SQL для безопасного хранения в errors
        Local $sSQLBase64Error = __JSON_Base64Encode($sSQL)
        Local $sInsertError = "INSERT INTO errors (uuid, server, sql_query, error_message, retry_count, created_at) " & _
                              "VALUES ('" & $sUUID & "', '" & $sServerType & "', '" & $sSQLBase64Error & "', '" & $sErrorMsg & "', " & $iRetryCount & ", '" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "')"
        _Utils_SQLite_Exec($hDB, $sInsertError)

        ; Сбрасываем счетчик попыток, обновляем last_attempt
        Local $sUpdateSQL = "UPDATE queue SET retry_count=0, last_attempt='" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "' WHERE id=" & $iRecordID
        _Utils_SQLite_Exec($hDB, $sUpdateSQL)

        ; Увеличиваем задержку для следующей попытки после сброса
        If $iServer = $MYSQL_SERVER_LOCAL Then
            $g_iLastLocalAttempt = $iCurrentTime + ($g_iQueueRetryInterval * 10)
        Else
            $g_iLastRemoteAttempt = $iCurrentTime + ($g_iQueueRetryInterval * 10)
        EndIf

        _Utils_SQLite_Close($hDB)

        If $g_bMySQL_DebugMode Then
            _Logger_Write("🔄 [MySQL] Превышен лимит попыток, сброшен счетчик для: " & StringLeft($sSQL, 50), 1)
            _Logger_Write("   📝 [MySQL] Запись остается в очереди для повторных попыток", 1)
            _Logger_Write("   ⏱️ [MySQL] Дополнительная задержка 5 секунд перед следующей попыткой", 1)
        EndIf
        Return
    EndIf

    ; Формируем данные для HTTP запроса
    Local $sHost = ($iServer = $MYSQL_SERVER_LOCAL) ? $g_sMySQL_LocalHost : $g_sMySQL_RemoteHost
    Local $sKey = ($iServer = $MYSQL_SERVER_LOCAL) ? $g_sMySQL_LocalKey : $g_sMySQL_RemoteKey
    Local $sURL = _MySQL_BuildURL($sHost)
    Local $sPostData = _MySQL_BuildPostData($sSQL, 0, $sKey, $bJSON)

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🔍 [MySQL] Формирую HTTP запрос", 1)
        _Logger_Write("   🌐 [MySQL] URL: " & $sURL, 1)
        _Logger_Write("   📝 [MySQL] POST данные: " & StringLeft($sPostData, 100) & "...", 1)
    EndIf

    ; Отправляем HTTP запрос (используем низкоуровневый _MySQL_HttpRequest)
    If $g_bMySQL_DebugMode Then
        _Logger_Write("🚀 [MySQL] Отправляю HTTP запрос из очереди...", 1)
    EndIf

    Local $sResponse = _MySQL_HttpRequest($sURL, 500, $sPostData)
    Local $iHTTPError = @error
    Local $iHTTPStatus = @extended

    If $g_bMySQL_DebugMode Then
        _Logger_Write("📥 [MySQL] Получен ответ", 1)
        _Logger_Write("   ❌ [MySQL] HTTP ошибка: " & $iHTTPError, 1)
        _Logger_Write("   📊 [MySQL] HTTP статус: " & $iHTTPStatus, 1)
        _Logger_Write("   📄 [MySQL] Ответ: " & StringLeft($sResponse, 100), 1)
    EndIf

    ; Обрабатываем результат
    If $iHTTPError <> 0 Then
        ; СЕТЕВАЯ ОШИБКА - увеличиваем счетчик попыток
        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] Сетевая ошибка " & $iHTTPError & " (HTTP " & $iHTTPStatus & "), увеличиваю счетчик попыток", 2)
        EndIf

        Local $sUpdateSQL = "UPDATE queue SET retry_count=" & ($iRetryCount + 1) & ", last_attempt='" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "' WHERE id=" & $iRecordID
        _Utils_SQLite_Exec($hDB, $sUpdateSQL)
        _Utils_SQLite_Close($hDB)

        If $g_bMySQL_DebugMode Then
            _Logger_Write("❌ [MySQL] Сетевая ошибка в очереди: попытка " & ($iRetryCount + 1) & " для " & StringLeft($sSQL, 50), 2)
        EndIf

    ElseIf StringInStr($sResponse, "ERROR:") = 1 Then
        ; ОШИБКА SQL - удаляем из очереди, записываем в лог ошибок (Poison Pill Protection)
        If $g_bMySQL_DebugMode Then
            _Logger_Write("🗑️ [MySQL] SQL ошибка в ответе, удаляю из очереди: " & StringTrimLeft($sResponse, 6), 2)
        EndIf

        ; Записываем в таблицу errors (SQL уже в Base64)
        Local $sErrorMsg = StringReplace(StringTrimLeft($sResponse, 6), "'", "''")
        Local $sInsertError = "INSERT INTO errors (uuid, server, sql_query, error_message, retry_count, created_at) " & _
                              "VALUES ('" & $sUUID & "', '" & $sServerType & "', '" & $sSQLBase64 & "', '" & $sErrorMsg & "', " & $iRetryCount & ", '" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "')"
        _Utils_SQLite_Exec($hDB, $sInsertError)

        ; Удаляем запись из очереди
        Local $sDeleteSQL = "DELETE FROM queue WHERE id=" & $iRecordID
        _Utils_SQLite_Exec($hDB, $sDeleteSQL)
        _Utils_SQLite_Close($hDB)

        If $g_bMySQL_DebugMode Then
            _Logger_Write("🗑️ [MySQL] SQL ошибка удалена из очереди: " & StringLeft($sSQL, 50), 2)
        EndIf

    Else
        ; УСПЕХ - удаляем из очереди И продолжаем агрессивную обработку
        If $g_bMySQL_DebugMode Then
            _Logger_Write("✅ [MySQL] Успешный ответ, удаляю из очереди и продолжаю обработку", 3)
        EndIf

        ; Удаляем запись из очереди
        Local $sDeleteSQL = "DELETE FROM queue WHERE id=" & $iRecordID
        _Utils_SQLite_Exec($hDB, $sDeleteSQL)

        ; Проверяем сколько записей осталось
        Local $iRemainingQueue = _Utils_SQLite_Count($hDB, "queue", "server='" & $sServerType & "' AND status='pending'")
        _Utils_SQLite_Close($hDB)

        ; Сбрасываем таймер для немедленной следующей попытки
        If $iServer = $MYSQL_SERVER_LOCAL Then
            $g_iLastLocalAttempt = 0
        Else
            $g_iLastRemoteAttempt = 0
        EndIf

        If $g_bMySQL_DebugMode Then
            _Logger_Write("✅ [MySQL] Отправлено из очереди: " & StringLeft($sSQL, 50) & " (осталось: " & $iRemainingQueue & ")", 3)
        EndIf

        ; АГРЕССИВНАЯ ОБРАБОТКА: Если есть еще записи - пробуем следующую немедленно
        If $iRemainingQueue > 0 Then
            If $g_bMySQL_DebugMode Then
                _Logger_Write("🚀 [MySQL] Связь восстановлена, обрабатываю следующую запись немедленно", 1)
            EndIf
            Sleep(100) ; Небольшая пауза чтобы не убить CPU
            _MySQL_ProcessSingleQueue($iServer) ; Рекурсивный вызов для следующей записи
        EndIf
    EndIf

    ; Проверяем опустела ли очередь (открываем базу заново для актуальных данных)
    Local $hDB2 = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
    If Not @error Then
        Local $iNewQueueSize = _Utils_SQLite_Count($hDB2, "queue", "server='" & $sServerType & "' AND status='pending'")
        _Utils_SQLite_Close($hDB2)

        If $g_bMySQL_DebugMode Then
            _Logger_Write("🔍 [MySQL] Проверяю размер очереди после обработки: " & $iNewQueueSize, 1)
        EndIf

        If $iNewQueueSize = 0 Then
            If $iServer = $MYSQL_SERVER_LOCAL Then
                $g_bLocalQueueActive = False
                If $g_bMySQL_DebugMode Then
                    _Logger_Write("📭 [MySQL] Локальная очередь опустела, отключаю флаг", 1)
                EndIf
            ElseIf $iServer = $MYSQL_SERVER_REMOTE Then
                $g_bRemoteQueueActive = False
                If $g_bMySQL_DebugMode Then
                    _Logger_Write("📭 [MySQL] Удаленная очередь опустела, отключаю флаг", 1)
                EndIf
            EndIf
        EndIf
    EndIf

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🏁 [MySQL] Завершение ProcessSingleQueue для " & $sServerName & " очереди", 1)
    EndIf
EndFunc

; ===============================================================================
; Функция: _MySQL_GetQueueStatus
; Описание: Получение статуса очередей
; Возврат: массив [local_count, remote_count]
; ===============================================================================
Func _MySQL_GetQueueStatus()
    ; Открываем базу данных
    Local $hDB = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
    If @error Then
        Local $aStatus[2] = [0, 0]
        Return $aStatus
    EndIf

    ; Подсчитываем записи в очередях
    Local $aStatus[2]
    $aStatus[0] = _Utils_SQLite_Count($hDB, "queue", "server='LOCAL' AND status='pending'")
    $aStatus[1] = _Utils_SQLite_Count($hDB, "queue", "server='REMOTE' AND status='pending'")

    ; Закрываем базу
    _Utils_SQLite_Close($hDB)

    Return $aStatus
EndFunc

; ===============================================================================
; Функция: _MySQL_ClearQueues
; Описание: Очистка всех очередей (для отладки)
; ===============================================================================
Func _MySQL_ClearQueues()
    ; Открываем базу данных
    Local $hDB = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
    If @error Then
        _Logger_Write("❌ [MySQL] Ошибка открытия базы для очистки очередей: " & _Utils_SQLite_GetLastError(), 2)
        Return False
    EndIf

    ; Удаляем все записи из обеих очередей
    _Utils_SQLite_Exec($hDB, "DELETE FROM queue WHERE server='LOCAL'")
    _Utils_SQLite_Exec($hDB, "DELETE FROM queue WHERE server='REMOTE'")

    ; Закрываем базу
    _Utils_SQLite_Close($hDB)

    ; Сбрасываем флаги
    $g_bLocalQueueActive = False
    $g_bRemoteQueueActive = False

    If $g_bMySQL_DebugMode Then
        _Logger_Write("🧹 [MySQL] Все очереди очищены (SQLite)", 1)
    EndIf

    Return True
EndFunc

; ===============================================================================
; Функция: _MySQL_ClearQueue
; Описание: Очистка очереди (для экстренных случаев)
; Параметры: $iServer - какую очередь очистить
; ===============================================================================
Func _MySQL_ClearQueue($iServer)
    ; Открываем базу данных
    Local $hDB = _Utils_SQLite_Open($g_sMySQLQueueDBPath)
    If @error Then
        _Logger_Write("❌ [MySQL] Ошибка открытия базы для очистки очереди: " & _Utils_SQLite_GetLastError(), 2)
        Return False
    EndIf

    ; Удаляем записи из указанной очереди
    If $iServer = $MYSQL_SERVER_LOCAL Or $iServer = 0 Then
        _Utils_SQLite_Exec($hDB, "DELETE FROM queue WHERE server='LOCAL'")
        $g_bLocalQueueActive = False
    EndIf

    If $iServer = $MYSQL_SERVER_REMOTE Or $iServer = 0 Then
        _Utils_SQLite_Exec($hDB, "DELETE FROM queue WHERE server='REMOTE'")
        $g_bRemoteQueueActive = False
    EndIf

    ; Закрываем базу
    _Utils_SQLite_Close($hDB)

    If $g_bMySQL_DebugMode Then
        Local $sServerName = ($iServer = $MYSQL_SERVER_LOCAL) ? "локальная" : ($iServer = $MYSQL_SERVER_REMOTE ? "удаленная" : "обе")
        _Logger_Write("🧹 [MySQL] Очередь очищена (SQLite): " & $sServerName, 1)
    EndIf

    Return True
EndFunc

