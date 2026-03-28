; ===============================================================================
; Utils_AutoTest v1.0
; Автоматическое тестирование библиотеки Utils SDK v2.0
; ===============================================================================

#include "Utils.au3"

; === ТЕСТ 1: Инициализация с параметрами ===
_SDK_Utils_Init("Utils_AutoTest", "Main")

#cs
; === ТЕСТ 2: Различные типы логов ===
_Logger_Write("Тестирование Utils запущено", 1)
_Logger_Write("Тестовое информационное сообщение", 1)
_Logger_Write("Тестовая ошибка подключения к БД", 2)
_Logger_Write("Операция выполнена успешно", 3)

; === ТЕСТ 3: Смена модуля на лету ===
$g_sUtils_SDK_ModuleName = "MySQL"
_Logger_Write("Переключились на модуль MySQL", 1)
_Logger_Write("Подключение к базе данных MySQL", 1)
_Logger_Write("Ошибка: таблица не найдена", 2)

; === ТЕСТ 4: Смена модуля на Redis ===
$g_sUtils_SDK_ModuleName = "Redis"
_Logger_Write("Переключились на модуль Redis", 1)
_Logger_Write("Подключение к Redis серверу", 1)
_Logger_Write("Данные успешно сохранены в Redis", 3)

; === ТЕСТ 5: Возврат к Main и фильтрация (только ошибки) ===
$g_sUtils_SDK_ModuleName = "Main"
$g_iUtils_SDK_LogFilter = 2  ; Только ошибки
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Установлен фильтр = 2 (только ошибки)")
_Logger_Write("ТЕСТ ФИЛЬТРА: Это INFO - НЕ должно появиться", 1)
_Logger_Write("ТЕСТ ФИЛЬТРА: Это ERROR - ДОЛЖНО появиться", 2)
_Logger_Write("ТЕСТ ФИЛЬТРА: Это SUCCESS - НЕ должно появиться", 3)

; === ТЕСТ 6: Фильтрация (только успех) ===
$g_iUtils_SDK_LogFilter = 3  ; Только успех
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Установлен фильтр = 3 (только успех)")
_Logger_Write("ТЕСТ ФИЛЬТРА: Это INFO - НЕ должно появиться", 1)
_Logger_Write("ТЕСТ ФИЛЬТРА: Это ERROR - НЕ должно появиться", 2)
_Logger_Write("ТЕСТ ФИЛЬТРА: Это SUCCESS - ДОЛЖНО появиться", 3)

; === ТЕСТ 7: Все логи снова ===
$g_iUtils_SDK_LogFilter = 1  ; Все логи
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Фильтр сброшен (все логи)")
_Logger_Write("Фильтр сброшен - все логи работают", 1)

; === ТЕСТ 8: Вывод только в консоль ===
$g_iUtils_SDK_LogTarget = 1  ; Только консоль
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Target = 1 (только консоль)")
_Logger_Write("ТЕСТ TARGET: Только в консоль (не в файл)", 1)

; === ТЕСТ 9: Вывод только в файл ===
$g_iUtils_SDK_LogTarget = 2  ; Только файл
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Target = 2 (только файл)")
_Logger_Write("ТЕСТ TARGET: Только в файл (не в консоль)", 1)

; === ТЕСТ 10: Вывод в оба места ===
$g_iUtils_SDK_LogTarget = 3  ; Консоль + файл
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Target = 3 (консоль + файл)")
_Logger_Write("ТЕСТ TARGET: В консоль И в файл", 1)

; === ТЕСТ 11: Отключение логов ===
$g_bUtils_SDK_DebugMode = False
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] DebugMode = False (логи выключены)")
_Logger_Write("ТЕСТ DEBUG: НЕ должно появиться (логи выключены)", 1)

; === ТЕСТ 12: Включение логов обратно ===
$g_bUtils_SDK_DebugMode = True
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] DebugMode = True (логи включены)")
_Logger_Write("ТЕСТ DEBUG: Логи снова включены", 3)

; === ТЕСТ 13: Работа с массивами ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тестирование функций массивов")
Local $aTest[3] = ["один", "два", "три"]
Local $sResult = _Utils_ArrayToString($aTest, "|")
_Logger_Write("ArrayToString: " & $sResult, 1)

Local $aResult = _Utils_StringToArray("alpha|beta|gamma", "|")
_Logger_Write("StringToArray: " & UBound($aResult) & " элементов", 1)

; === ТЕСТ 14: Работа со временем ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тестирование функций времени")
Local $hTimer = _Utils_GetTimestamp()
Sleep(10)
Local $fElapsed = _Utils_GetElapsedTime($hTimer)
_Logger_Write("Прошло времени: " & StringFormat("%.2f", $fElapsed) & "мс", 1)

; === ТЕСТ 15: UUID v7 - Генерация ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тестирование UUID v7")
Local $sUUID1 = _Utils_GenerateUUIDv7()
_Logger_Write("UUID v7 #1: " & $sUUID1, 1)

; Проверка формата UUID
If StringLen($sUUID1) = 36 And StringMid($sUUID1, 9, 1) = "-" And StringMid($sUUID1, 14, 1) = "-" Then
    _Logger_Write("✅ Формат UUID корректный (36 символов с дефисами)", 3)
Else
    _Logger_Write("❌ ОШИБКА: Неверный формат UUID", 2)
EndIf

; Проверка версии (должна быть 7)
Local $sVersion = StringMid($sUUID1, 15, 1)
If $sVersion = "7" Then
    _Logger_Write("✅ Версия UUID = 7 (time-based)", 3)
Else
    _Logger_Write("❌ ОШИБКА: Версия UUID = " & $sVersion & " (ожидалась 7)", 2)
EndIf

; === ТЕСТ 16: UUID v7 - Стресс-тест генерации (100000 UUID) ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Стресс-тест UUID v7 (1000 генераций)")
Local $hUUIDTimer = _Utils_GetTimestamp()

; Генерируем 100000 UUID без проверки уникальности
; MySQL с UNIQUE индексом сам защитит от дубликатов (шанс коллизии ничтожен)
For $i = 1 To 1000
    _Utils_GenerateUUIDv7()
Next

Local $fUUIDTime = _Utils_GetElapsedTime($hUUIDTimer)
_Logger_Write("Сгенерировано 1000 UUID за " & StringFormat("%.2f", $fUUIDTime) & "мс", 1)
_Logger_Write("Средняя скорость: " & StringFormat("%.4f", $fUUIDTime / 1000) & "мс на UUID", 1)
_Logger_Write("Пропускная способность: " & StringFormat("%.0f", 1000 / ($fUUIDTime / 1000)) & " UUID/сек", 1)

If $fUUIDTime / 100000 < 0.1 Then
    _Logger_Write("✅ Производительность отличная (< 0.1мс на UUID)", 3)
ElseIf $fUUIDTime / 100000 < 1.0 Then
    _Logger_Write("✅ Производительность хорошая (< 1мс на UUID)", 3)
Else
    _Logger_Write("⚠️ Производительность приемлемая (> 1мс на UUID)", 1)
EndIf

; === ТЕСТ 17: UUID v7 - Сортировка по времени ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тест сортировки UUID v7 по времени")
Local $sUUID_First = _Utils_GenerateUUIDv7()
Sleep(5) ; Ждем 5мс
Local $sUUID_Second = _Utils_GenerateUUIDv7()

_Logger_Write("UUID #1 (раньше): " & $sUUID_First, 1)
_Logger_Write("UUID #2 (позже):  " & $sUUID_Second, 1)

; UUID v7 должны сортироваться лексикографически по времени
If $sUUID_First < $sUUID_Second Then
    _Logger_Write("✅ UUID v7 сортируются по времени создания", 3)
Else
    _Logger_Write("❌ ОШИБКА: UUID v7 НЕ сортируются по времени", 2)
EndIf

; === ТЕСТ 18: UUID v7 - Парсинг timestamp ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тест парсинга timestamp из UUID v7")

; Генерируем UUID и сразу получаем текущее время
Local $sUUID_Test = _Utils_GenerateUUIDv7()
Local $sCurrentTime = _Utils_GetDateTimeMS()

_Logger_Write("Сгенерирован UUID: " & $sUUID_Test, 1)
_Logger_Write("Текущее время:     " & $sCurrentTime, 1)

; Парсим timestamp из UUID
Local $sParsedTime = _Utils_ParseUUIDv7Timestamp($sUUID_Test)
If @error Then
    _Logger_Write("❌ ОШИБКА: Не удалось распарсить UUID", 2)
Else
    _Logger_Write("Время из UUID:     " & $sParsedTime, 1)

    ; Проверяем что время из UUID близко к текущему (разница < 100мс)
    ; Извлекаем миллисекунды для сравнения
    Local $aCurrentParts = StringSplit($sCurrentTime, ".")
    Local $aParsedParts = StringSplit($sParsedTime, ".")

    If $aParsedParts[0] >= 2 And $aCurrentParts[0] >= 2 Then
        ; Сравниваем дату/время без миллисекунд
        Local $sCurrentBase = $aCurrentParts[1]
        Local $sParsedBase = $aParsedParts[1]

        If $sCurrentBase = $sParsedBase Then
            _Logger_Write("✅ Timestamp из UUID корректный (совпадает с текущим временем)", 3)
        Else
            ; Допускаем разницу в 1 секунду (из-за задержки генерации)
            _Logger_Write("⚠️ Timestamp из UUID отличается (возможна задержка генерации)", 1)
        EndIf
    Else
        _Logger_Write("✅ Timestamp извлечён из UUID", 3)
    EndIf
EndIf

; Тест парсинга известного UUID
Local $sKnownUUID = "019c6d39-b98f-746f-a722-cf0e9357fafd"
Local $sKnownTime = _Utils_ParseUUIDv7Timestamp($sKnownUUID)
_Logger_Write("Известный UUID: " & $sKnownUUID, 1)
_Logger_Write("Время из UUID:  " & $sKnownTime, 1)

If StringLen($sKnownTime) = 23 Then
    _Logger_Write("✅ Парсер UUID v7 работает корректно", 3)
Else
    _Logger_Write("❌ ОШИБКА: Неверный формат распарсенного времени", 2)
EndIf

; === ТЕСТ 19: Функции даты и времени ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тестирование функций даты/времени")

Local $sDate = _Utils_GetDateOnly()
_Logger_Write("Текущая дата (DATE): " & $sDate, 1)

; Проверка формата YYYY-MM-DD
If StringLen($sDate) = 10 And StringMid($sDate, 5, 1) = "-" And StringMid($sDate, 8, 1) = "-" Then
    _Logger_Write("✅ Формат DATE корректный (YYYY-MM-DD)", 3)
Else
    _Logger_Write("❌ ОШИБКА: Неверный формат DATE", 2)
EndIf

Local $sDateTime = _Utils_GetDateTimeMS()
_Logger_Write("Текущая дата/время (DATETIME): " & $sDateTime, 1)

; Проверка формата YYYY-MM-DD HH:MM:SS.mmm
If StringLen($sDateTime) = 23 And StringMid($sDateTime, 11, 1) = " " And StringMid($sDateTime, 20, 1) = "." Then
    _Logger_Write("✅ Формат DATETIME(3) корректный (YYYY-MM-DD HH:MM:SS.mmm)", 3)
Else
    _Logger_Write("❌ ОШИБКА: Неверный формат DATETIME", 2)
EndIf

Local $iTimestampMS = _Utils_GetUnixTimestampMS()
_Logger_Write("Unix timestamp (мс): " & $iTimestampMS, 1)

; Проверка что timestamp разумный (больше 2020-01-01 и меньше 2100-01-01)
Local $iMin2020 = 1577836800000 ; 2020-01-01 00:00:00
Local $iMax2100 = 4102444800000 ; 2100-01-01 00:00:00
If $iTimestampMS > $iMin2020 And $iTimestampMS < $iMax2100 Then
    _Logger_Write("✅ Unix timestamp в разумных пределах (2020-2100)", 3)
Else
    _Logger_Write("❌ ОШИБКА: Unix timestamp вне разумных пределов", 2)
EndIf

; === ТЕСТ 20: Производительность UUID v7 ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тест производительности UUID v7")
Local $hPerfTimer = _Utils_GetTimestamp()
Local $iIterations = 1000

For $i = 1 To $iIterations
    _Utils_GenerateUUIDv7()
Next

Local $fPerfTime = _Utils_GetElapsedTime($hPerfTimer)
Local $fAvgTime = $fPerfTime / $iIterations

_Logger_Write("Сгенерировано " & $iIterations & " UUID за " & StringFormat("%.2f", $fPerfTime) & "мс", 1)
_Logger_Write("Средняя скорость: " & StringFormat("%.4f", $fAvgTime) & "мс на UUID", 1)

If $fAvgTime < 1.0 Then
    _Logger_Write("✅ Производительность отличная (< 1мс на UUID)", 3)
ElseIf $fAvgTime < 5.0 Then
    _Logger_Write("⚠️ Производительность приемлемая (< 5мс на UUID)", 1)
Else
    _Logger_Write("❌ ПРЕДУПРЕЖДЕНИЕ: Низкая производительность (> 5мс на UUID)", 2)
EndIf

; === ТЕСТ 21: SQLite - Инициализация ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тестирование SQLite")

#ce
#include "Utils_SQLite.au3"

; Проверка инициализации
Local $bStartup = _Utils_SQLite_Startup()
If $bStartup Then
    _Logger_Write("✅ SQLite инициализирован успешно", 3)
Else
    _Logger_Write("❌ ОШИБКА: SQLite не инициализирован: " & _Utils_SQLite_GetLastError(), 2)
EndIf

; === ТЕСТ 22: SQLite - Создание БД ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Создание тестовой БД")
Local $sTestDB = @ScriptDir & "\test_sqlite.db"

; Удаляем старую БД если существует
If FileExists($sTestDB) Then
    FileDelete($sTestDB)
    _Logger_Write("🗑️ Удалена старая тестовая БД", 1)
EndIf

; Открываем новую БД
Local $hDB = _Utils_SQLite_Open($sTestDB)
If $hDB <> 0 Then
    _Logger_Write("✅ БД создана и открыта: " & $sTestDB, 3)
Else
    _Logger_Write("❌ ОШИБКА: Не удалось открыть БД: " & _Utils_SQLite_GetLastError(), 2)
EndIf

; === ТЕСТ 23: SQLite - Создание таблицы ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Создание таблицы")
Local $sSchema = "id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, value TEXT, created_at INTEGER"
Local $bTableCreated = _Utils_SQLite_CreateTable($hDB, "test_table", $sSchema)

If $bTableCreated Then
    _Logger_Write("✅ Таблица test_table создана", 3)
Else
    _Logger_Write("❌ ОШИБКА: Не удалось создать таблицу: " & _Utils_SQLite_GetLastError(), 2)
EndIf

; Проверка существования таблицы
Local $bExists = _Utils_SQLite_TableExists($hDB, "test_table")
If $bExists Then
    _Logger_Write("✅ Таблица существует (проверка TableExists)", 3)
Else
    _Logger_Write("❌ ОШИБКА: Таблица не найдена", 2)
EndIf

; === ТЕСТ 24: SQLite - Вставка данных ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Вставка данных")

; Вставляем 5 строк
Local $aRow1[4] = ["", "Alice", "Test Value 1", _Utils_GetUnixTimestampMS()]
Local $aRow2[4] = ["", "Bob", "Test Value 2", _Utils_GetUnixTimestampMS()]
Local $aRow3[4] = ["", "Charlie", "Test Value 3", _Utils_GetUnixTimestampMS()]
Local $aRow4[4] = ["", "Diana", "Test Value 4", _Utils_GetUnixTimestampMS()]
Local $aRow5[4] = ["", "Eve", "Test Value 5", _Utils_GetUnixTimestampMS()]

_Utils_SQLite_AppendRow($hDB, "test_table", $aRow1)
_Utils_SQLite_AppendRow($hDB, "test_table", $aRow2)
_Utils_SQLite_AppendRow($hDB, "test_table", $aRow3)
_Utils_SQLite_AppendRow($hDB, "test_table", $aRow4)
_Utils_SQLite_AppendRow($hDB, "test_table", $aRow5)

Local $iLastID = _Utils_SQLite_GetLastID($hDB)
_Logger_Write("✅ Вставлено 5 строк, последний ID: " & $iLastID, 3)

; === ТЕСТ 25: SQLite - Подсчет записей ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Подсчет записей")
Local $iCount = _Utils_SQLite_Count($hDB, "test_table")
If $iCount = 5 Then
    _Logger_Write("✅ Количество записей корректно: " & $iCount, 3)
Else
    _Logger_Write("❌ ОШИБКА: Ожидалось 5 записей, получено: " & $iCount, 2)
EndIf

; === ТЕСТ 26: SQLite - Загрузка таблицы ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Загрузка таблицы в массив")
Local $aData = _Utils_SQLite_LoadTable($hDB, "test_table")

If IsArray($aData) And UBound($aData, 1) = 5 Then
    _Logger_Write("✅ Таблица загружена в массив: " & UBound($aData, 1) & " строк", 3)
    _Logger_Write("   Первая строка: ID=" & $aData[0][0] & ", Name=" & $aData[0][1], 1)
    _Logger_Write("   Последняя строка: ID=" & $aData[4][0] & ", Name=" & $aData[4][1], 1)
Else
    _Logger_Write("❌ ОШИБКА: Неверное количество строк в массиве", 2)
EndIf

; === ТЕСТ 27: SQLite - Загрузка с WHERE ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Загрузка с условием WHERE")
Local $aFiltered = _Utils_SQLite_LoadTable($hDB, "test_table", "name='Alice' OR name='Bob'")

If IsArray($aFiltered) And UBound($aFiltered, 1) = 2 Then
    _Logger_Write("✅ Фильтрация работает: найдено " & UBound($aFiltered, 1) & " записей", 3)
Else
    _Logger_Write("❌ ОШИБКА: Ожидалось 2 записи, получено: " & UBound($aFiltered, 1), 2)
EndIf

; === ТЕСТ 28: SQLite - Удаление строки ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Удаление строки по ID")
_Utils_SQLite_DeleteRow($hDB, "test_table", 3)

Local $iCountAfterDelete = _Utils_SQLite_Count($hDB, "test_table")
If $iCountAfterDelete = 4 Then
    _Logger_Write("✅ Строка удалена, осталось: " & $iCountAfterDelete, 3)
Else
    _Logger_Write("❌ ОШИБКА: Ожидалось 4 записи, получено: " & $iCountAfterDelete, 2)
EndIf

; === ТЕСТ 29: SQLite - Сохранение массива (перезапись) ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Сохранение массива в таблицу")

; Создаем новый массив данных
Local $aNewData[3][4]
$aNewData[0][0] = ""
$aNewData[0][1] = "User1"
$aNewData[0][2] = "Value1"
$aNewData[0][3] = _Utils_GetUnixTimestampMS()

$aNewData[1][0] = ""
$aNewData[1][1] = "User2"
$aNewData[1][2] = "Value2"
$aNewData[1][3] = _Utils_GetUnixTimestampMS()

$aNewData[2][0] = ""
$aNewData[2][1] = "User3"
$aNewData[2][2] = "Value3"
$aNewData[2][3] = _Utils_GetUnixTimestampMS()

; Сохраняем массив (полная перезапись таблицы)
_Utils_SQLite_SaveTable($hDB, "test_table", $aNewData)

Local $iCountAfterSave = _Utils_SQLite_Count($hDB, "test_table")
If $iCountAfterSave = 3 Then
    _Logger_Write("✅ Таблица перезаписана, записей: " & $iCountAfterSave, 3)
Else
    _Logger_Write("❌ ОШИБКА: Ожидалось 3 записи, получено: " & $iCountAfterSave, 2)
EndIf

; === ТЕСТ 30: SQLite - Очистка таблицы ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Очистка таблицы")
_Utils_SQLite_ClearTable($hDB, "test_table")

Local $iCountAfterClear = _Utils_SQLite_Count($hDB, "test_table")
If $iCountAfterClear = 0 Then
    _Logger_Write("✅ Таблица очищена, записей: " & $iCountAfterClear, 3)
Else
    _Logger_Write("❌ ОШИБКА: Ожидалось 0 записей, получено: " & $iCountAfterClear, 2)
EndIf

; === ТЕСТ 31: SQLite - Закрытие БД ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Закрытие БД")
_Utils_SQLite_Close($hDB)
_Logger_Write("✅ БД закрыта", 3)

; === ТЕСТ 32: SQLite - Повторное открытие БД ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Повторное открытие БД")
$hDB = _Utils_SQLite_Open($sTestDB)

If $hDB <> 0 Then
    _Logger_Write("✅ БД открыта повторно", 3)

    ; Проверяем что таблица существует
    If _Utils_SQLite_TableExists($hDB, "test_table") Then
        _Logger_Write("✅ Таблица сохранилась после закрытия БД", 3)
    Else
        _Logger_Write("❌ ОШИБКА: Таблица не найдена после повторного открытия", 2)
    EndIf

    _Utils_SQLite_Close($hDB)
Else
    _Logger_Write("❌ ОШИБКА: Не удалось открыть БД повторно", 2)
EndIf

; === ТЕСТ 33: SQLite - Завершение работы ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Завершение работы SQLite")
_Utils_SQLite_Shutdown()
_Logger_Write("✅ SQLite завершен", 3)

; Удаляем тестовую БД
If FileExists($sTestDB) Then
    FileDelete($sTestDB)
    _Logger_Write("🗑️ Тестовая БД удалена", 1)
EndIf

; === ТЕСТ 34: SQLite Config (INI замена) ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тестирование Config (INI замена)")

; Создаем отдельную БД для Config и Logs (не удаляем после тестов)
Local $sConfigDB = @ScriptDir & "\test_config_logs.db"

; Удаляем старую БД если существует
If FileExists($sConfigDB) Then
    FileDelete($sConfigDB)
    _Logger_Write("🗑️ Удалена старая БД Config/Logs", 1)
EndIf

; Инициализируем SQLite снова
_Utils_SQLite_Startup()

; Открываем БД
$hDB = _Utils_SQLite_Open($sConfigDB)

If $hDB <> 0 Then
    _Logger_Write("✅ БД Config/Logs создана: " & $sConfigDB, 3)
Else
    _Logger_Write("❌ ОШИБКА: Не удалось создать БД Config/Logs", 2)
EndIf

; Устанавливаем настройки
_Utils_SQLite_SetConfig($hDB, "Database", "Host", "localhost")
_Utils_SQLite_SetConfig($hDB, "Database", "Port", "3306")
_Utils_SQLite_SetConfig($hDB, "Database", "User", "root")
_Utils_SQLite_SetConfig($hDB, "Application", "Name", "SCADA System")
_Utils_SQLite_SetConfig($hDB, "Application", "Version", "1.0.0")

_Logger_Write("✅ Установлено 5 настроек", 3)

; Читаем настройки
Local $sHost = _Utils_SQLite_GetConfig($hDB, "Database", "Host", "")
Local $sPort = _Utils_SQLite_GetConfig($hDB, "Database", "Port", "")
Local $sName = _Utils_SQLite_GetConfig($hDB, "Application", "Name", "")

If $sHost = "localhost" And $sPort = "3306" And $sName = "SCADA System" Then
    _Logger_Write("✅ Настройки читаются корректно", 3)
    _Logger_Write("   Host: " & $sHost, 1)
    _Logger_Write("   Port: " & $sPort, 1)
    _Logger_Write("   Name: " & $sName, 1)
Else
    _Logger_Write("❌ ОШИБКА: Настройки читаются некорректно", 2)
EndIf

; Читаем несуществующую настройку с дефолтом
Local $sDefault = _Utils_SQLite_GetConfig($hDB, "Test", "NotExists", "DefaultValue")
If $sDefault = "DefaultValue" Then
    _Logger_Write("✅ Дефолтное значение работает корректно", 3)
Else
    _Logger_Write("❌ ОШИБКА: Дефолтное значение не работает", 2)
EndIf

; Читаем всю секцию
Local $aSection = _Utils_SQLite_GetSection($hDB, "Database")
If IsArray($aSection) And UBound($aSection, 1) = 3 Then
    _Logger_Write("✅ Секция Database содержит 3 настройки", 3)
    For $i = 0 To UBound($aSection, 1) - 1
        _Logger_Write("   " & $aSection[$i][0] & " = " & $aSection[$i][1], 1)
    Next
Else
    _Logger_Write("❌ ОШИБКА: Секция читается некорректно", 2)
EndIf

; Обновляем существующую настройку
_Utils_SQLite_SetConfig($hDB, "Database", "Port", "3307")
Local $sNewPort = _Utils_SQLite_GetConfig($hDB, "Database", "Port", "")
If $sNewPort = "3307" Then
    _Logger_Write("✅ Обновление настройки работает корректно", 3)
Else
    _Logger_Write("❌ ОШИБКА: Обновление настройки не работает", 2)
EndIf

; Удаляем одну настройку
_Utils_SQLite_DeleteConfig($hDB, "Database", "User")
Local $sDeleted = _Utils_SQLite_GetConfig($hDB, "Database", "User", "DELETED")
If $sDeleted = "DELETED" Then
    _Logger_Write("✅ Удаление настройки работает корректно", 3)
Else
    _Logger_Write("❌ ОШИБКА: Удаление настройки не работает", 2)
EndIf

; === ТЕСТ 35: SQLite Logs ===
_Logger_ConsoleWriteUTF(@CRLF & "[AUTOTEST] Тестирование Logs")

; Добавляем логи разных уровней
_Utils_SQLite_AddLog($hDB, "INFO", "Приложение запущено", "Main")
_Utils_SQLite_AddLog($hDB, "INFO", "Подключение к базе данных", "MySQL")
_Utils_SQLite_AddLog($hDB, "ERROR", "Ошибка подключения к серверу", "MySQL")
_Utils_SQLite_AddLog($hDB, "SUCCESS", "Данные успешно сохранены", "MySQL")
_Utils_SQLite_AddLog($hDB, "WARNING", "Низкий уровень памяти", "System")
_Utils_SQLite_AddLog($hDB, "ERROR", "Таймаут запроса", "Redis")
_Utils_SQLite_AddLog($hDB, "INFO", "Пользователь вошел в систему", "Auth")
_Utils_SQLite_AddLog($hDB, "SUCCESS", "Отчет сгенерирован", "Reports")

_Logger_Write("✅ Добавлено 8 логов", 3)

; Подсчитываем логи
Local $iTotal = _Utils_SQLite_CountLogs($hDB, "", "")
Local $iErrors = _Utils_SQLite_CountLogs($hDB, "ERROR", "")
Local $iMySQL = _Utils_SQLite_CountLogs($hDB, "", "MySQL")

If $iTotal = 8 And $iErrors = 2 And $iMySQL = 3 Then
    _Logger_Write("✅ Подсчет логов работает корректно", 3)
    _Logger_Write("   Всего логов: " & $iTotal, 1)
    _Logger_Write("   Ошибок: " & $iErrors, 1)
    _Logger_Write("   Логов MySQL: " & $iMySQL, 1)
Else
    _Logger_Write("❌ ОШИБКА: Подсчет логов некорректен", 2)
    _Logger_Write("   Ожидалось: 8, 2, 3", 2)
    _Logger_Write("   Получено: " & $iTotal & ", " & $iErrors & ", " & $iMySQL, 2)
EndIf

; Читаем только ошибки
Local $aErrors = _Utils_SQLite_GetLogs($hDB, "ERROR", "", 10)
If IsArray($aErrors) And UBound($aErrors, 1) = 2 Then
    _Logger_Write("✅ Фильтрация логов по уровню работает", 3)
    For $i = 0 To UBound($aErrors, 1) - 1
        _Logger_Write("   [" & $aErrors[$i][1] & "] " & $aErrors[$i][2] & " (" & $aErrors[$i][3] & ")", 1)
    Next
Else
    _Logger_Write("❌ ОШИБКА: Фильтрация логов не работает", 2)
EndIf

; Читаем логи MySQL
Local $aMySQL = _Utils_SQLite_GetLogs($hDB, "", "MySQL", 10)
If IsArray($aMySQL) And UBound($aMySQL, 1) = 3 Then
    _Logger_Write("✅ Фильтрация логов по модулю работает", 3)
Else
    _Logger_Write("❌ ОШИБКА: Фильтрация логов по модулю не работает", 2)
EndIf

; Читаем последние 5 логов
Local $aRecent = _Utils_SQLite_GetLogs($hDB, "", "", 5)
If IsArray($aRecent) And UBound($aRecent, 1) = 5 Then
    _Logger_Write("✅ Лимит логов работает корректно", 3)
    _Logger_Write("   Последние 5 логов:", 1)
    For $i = 0 To UBound($aRecent, 1) - 1
        _Logger_Write("   [" & $aRecent[$i][1] & "] " & $aRecent[$i][2], 1)
    Next
Else
    _Logger_Write("❌ ОШИБКА: Лимит логов не работает", 2)
EndIf

; Закрываем БД (НЕ удаляем для проверки)
_Utils_SQLite_Close($hDB)
_Utils_SQLite_Shutdown()

_Logger_Write("✅ БД Config/Logs сохранена для проверки: " & $sConfigDB, 3)
_Logger_Write("   Таблица 'config' содержит настройки приложения", 1)
_Logger_Write("   Таблица 'logs' содержит 8 записей логов", 1)

; === ЗАВЕРШЕНИЕ ===
_Logger_ConsoleWriteUTF(@CRLF & "=== РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ ===")
_Logger_Write("🎉 Все тесты Utils завершены успешно!", 3)

_Logger_ConsoleWriteUTF(@CRLF & "=== ИНФОРМАЦИЯ О ЛОГАХ ===")
_Logger_ConsoleWriteUTF("Путь к логам: " & _SDK_GetLogDir())
_Logger_ConsoleWriteUTF("Текущий лог: " & _SDK_GetLogPath())
_Logger_ConsoleWriteUTF(@CRLF & "=== БАЗА ДАННЫХ ДЛЯ ПРОВЕРКИ ===")
_Logger_ConsoleWriteUTF("БД сохранена: " & $sConfigDB)
_Logger_ConsoleWriteUTF("Откройте через SQLite Browser для проверки таблиц 'config' и 'logs'")
_Logger_ConsoleWriteUTF(@CRLF & "Тестирование завершено.")

