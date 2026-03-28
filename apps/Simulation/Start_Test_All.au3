; ===============================================================================
; Start_Test_All.au3
; Тест инициализации SDK (Utils + MySQL + Redis)
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"



; Тестовая глобальная переменная для проверки autobatch
Global $g_sTestAutobatch = "Test Autobatch Integration"
Global $g_iTestCounter = 42
Global $g_bAutobatchEnabled = True
Global $g_sFinalTest = "POWERSHELL KILL + START - PERFECT!"
Global $g_sPsutilMinTest = "PSUTIL KILL + START /MIN - TESTING NOW!"
Global $g_sWorkingVersion = "Final working version test!"
Global $g_sHungarianNotation = "Testing Hungarian notation in filenames!"
Global $g_sAppsPrefix = "Testing apps_ prefix in filename!"



; ===============================================================================
; ГЛАВНАЯ ПРОГРАММА
; ===============================================================================



; ===============================================================================
; ШАГ 1: Инициализация SDK (Utils + MySQL + Redis)
; ===============================================================================

; Инициализация базового SDK (Utils + Logger)
Local $bSDKInit = _SDK_Init("Simulation", True, 1, 3, True)
If Not $bSDKInit Then
    _Logger_ConsoleWriteUTF("❌ ОШИБКА: Не удалось инициализировать SDK")
    Exit 1
EndIf

_Logger_Write("========================================", 1)
_Logger_Write("🚀 [Start_Test_All] Запуск теста SDK", 1)
_Logger_Write("========================================", 1)
_Logger_Write("", 1)

; Инициализация MySQL
_Logger_Write("📋 [Start_Test_All] Инициализация MySQL...", 1)
Local $bMySQLInit = _SDK_MySQL_Init()
If Not $bMySQLInit Then
    _Logger_Write("❌ [Start_Test_All] Ошибка инициализации MySQL", 2)
    Exit 1
EndIf

; Инициализация Redis
_Logger_Write("📋 [Start_Test_All] Инициализация Redis...", 1)
Local $bRedisInit = _SDK_Redis_Init("127.0.0.1", 6379)
If Not $bRedisInit Then
    _Logger_Write("⚠️ [Start_Test_All] Redis недоступен (проверьте что Redis запущен)", 2)
    _Logger_Write("⚠️ [Start_Test_All] Тесты Redis будут пропущены", 2)
EndIf

_Logger_Write("", 1)
_Logger_Write("✅ [Start_Test_All] Шаг 1: Инициализация SDK завершена", 3)
_Logger_Write("   📦 Utils: OK", 1)
_Logger_Write("   🗄️ MySQL: OK", 1)
_Logger_Write("   🔴 Redis: " & ($bRedisInit ? "OK" : "НЕДОСТУПЕН"), 1)

; ===============================================================================
; ШАГ 2: Тест Utils (логирование)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 [Start_Test_All] Шаг 2: Тест Utils (логирование)...", 1)

_Logger_Write("🧪 [Start_Test_All] Тест логирования INFO", 1)
_Logger_Write("🧪 [Start_Test_All] Тест логирования ERROR", 2)
_Logger_Write("🧪 [Start_Test_All] Тест логирования SUCCESS", 3)

_Logger_Write("✅ [Start_Test_All] Utils протестирован (проверьте logs/Start_Test_All/Start_Test_All.log)", 3)

; ===============================================================================
; ШАГ 3: Тест MySQL (создание таблицы + 2 инсерта)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 [Start_Test_All] Шаг 3: Тест MySQL...", 1)

; Создаем тестовую таблицу
_Logger_Write("🗄️ [Start_Test_All] Создание тестовой таблицы test_sdk...", 1)

Local $sCreateTable = "CREATE TABLE IF NOT EXISTS test_sdk (" & _
                      "id INT AUTO_INCREMENT PRIMARY KEY, " & _
                      "name VARCHAR(100), " & _
                      "value VARCHAR(255), " & _
                      "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" & _
                      ")"

Local $bCreate = _MySQL_Query($sCreateTable, 0, $MYSQL_SERVER_LOCAL, False)
If $bCreate Then
    _Logger_Write("✅ [Start_Test_All] Таблица test_sdk создана", 3)
Else
    _Logger_Write("❌ [Start_Test_All] Ошибка создания таблицы: " & _MySQL_GetLastError(), 2)
EndIf

; Первый INSERT
_Logger_Write("➕ [Start_Test_All] Вставка первой записи...", 1)

Local $bInsert1 = _MySQL_Insert("test_sdk", "name=Test1|value=Value1", $MYSQL_SERVER_LOCAL, False)
If $bInsert1 Then
    _Logger_Write("✅ [Start_Test_All] Первая запись вставлена", 3)
Else
    _Logger_Write("❌ [Start_Test_All] Ошибка вставки первой записи: " & _MySQL_GetLastError(), 2)
EndIf

; Второй INSERT
_Logger_Write("➕ [Start_Test_All] Вставка второй записи...", 1)

Local $bInsert2 = _MySQL_Insert("test_sdk", "name=Test2|value=Value2", $MYSQL_SERVER_LOCAL, False)
If $bInsert2 Then
    _Logger_Write("✅ [Start_Test_All] Вторая запись вставлена", 3)
Else
    _Logger_Write("❌ [Start_Test_All] Ошибка вставки второй записи: " & _MySQL_GetLastError(), 2)
EndIf

; Проверка данных
_Logger_Write("🔍 [Start_Test_All] Проверка вставленных данных...", 1)

Local $aResult = _MySQL_Select("test_sdk", "*", "", "id DESC", 2, $MYSQL_SERVER_LOCAL, False)
If IsArray($aResult) Then
    Local $iRows = UBound($aResult, 1)
    _Logger_Write("✅ [Start_Test_All] Найдено записей: " & $iRows, 3)

    ; Показываем последние 2 записи
    For $i = 0 To $iRows - 1
        _Logger_Write("   📝 [Start_Test_All] Запись " & ($i + 1) & ": ID=" & $aResult[$i][0] & ", Name=" & $aResult[$i][1] & ", Value=" & $aResult[$i][2], 1)
    Next
Else
    _Logger_Write("❌ [Start_Test_All] Ошибка чтения данных: " & _MySQL_GetLastError(), 2)
EndIf

; ===============================================================================
; ШАГ 4: Тест Redis (базовые операции)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 [Start_Test_All] Шаг 4: Тест Redis...", 1)

; Проверяем что Redis был инициализирован
If Not $bRedisInit Then
    _Logger_Write("⚠️ [Start_Test_All] Redis не инициализирован, тесты пропущены", 2)
Else
    ; Тест SET/GET
    _Logger_Write("📝 [Start_Test_All] Тест SET/GET...", 1)

    Local $bSet = _Redis_Set("test_sdk:key1", "TestValue1")
    If $bSet Then
        _Logger_Write("✅ [Start_Test_All] SET выполнен", 3)

        Local $sValue = _Redis_Get("test_sdk:key1")
        If $sValue = "TestValue1" Then
            _Logger_Write("✅ [Start_Test_All] GET выполнен, значение: " & $sValue, 3)
        Else
            _Logger_Write("❌ [Start_Test_All] GET вернул неверное значение: " & $sValue, 2)
        EndIf
    Else
        _Logger_Write("❌ [Start_Test_All] Ошибка SET", 2)
    EndIf

    ; Тест HSET/HGET
    _Logger_Write("📝 [Start_Test_All] Тест HSET/HGET...", 1)

    Local $bHSet1 = _Redis_HSet("test_sdk:user:1", "name", "John")
    Local $bHSet2 = _Redis_HSet("test_sdk:user:1", "age", "30")

    If $bHSet1 And $bHSet2 Then
        _Logger_Write("✅ [Start_Test_All] HSET выполнен", 3)

        Local $sName = _Redis_HGet("test_sdk:user:1", "name")
        Local $sAge = _Redis_HGet("test_sdk:user:1", "age")

        If $sName = "John" And $sAge = "30" Then
            _Logger_Write("✅ [Start_Test_All] HGET выполнен, name=" & $sName & ", age=" & $sAge, 3)
        Else
            _Logger_Write("❌ [Start_Test_All] HGET вернул неверные значения", 2)
        EndIf
    Else
        _Logger_Write("❌ [Start_Test_All] Ошибка HSET", 2)
    EndIf

    ; Тест HGETALL
    _Logger_Write("📝 [Start_Test_All] Тест HGETALL...", 1)

    Local $aUserData = _Redis_HGetAll("test_sdk:user:1")
    If IsArray($aUserData) Then
        _Logger_Write("✅ [Start_Test_All] HGETALL выполнен, получено полей: " & UBound($aUserData), 3)
        For $i = 0 To UBound($aUserData) - 1 Step 2
            If $i + 1 < UBound($aUserData) Then
                _Logger_Write("   📝 [Start_Test_All] " & $aUserData[$i] & " = " & $aUserData[$i + 1], 1)
            EndIf
        Next
    Else
        _Logger_Write("❌ [Start_Test_All] Ошибка HGETALL", 2)
    EndIf

    ; Отключение от Redis
    _Redis_Disconnect()
    _Logger_Write("🔌 [Start_Test_All] Redis отключен", 1)
EndIf

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 [Start_Test_All] Тест завершен успешно!", 3)
_Logger_Write("========================================", 1)
_Logger_Write("📁 [Start_Test_All] Проверьте лог: logs\Start_Test_All\Start_Test_All.log", 1)
_Logger_Write("🗄️ [Start_Test_All] Проверьте таблицу: test_sdk в локальной БД", 1)
_Logger_Write("🔴 [Start_Test_All] Проверьте Redis: ключи test_sdk:*", 1)

; Пауза перед закрытием
_Logger_Write("", 1)
_Logger_Write("⏸️ [Start_Test_All] Нажмите Enter для выхода...", 1)
ConsoleRead()
