; ===============================================================================
; Utils SQLite v1.0
; Тонкая обертка над встроенным SQLite.au3 для SCADA систем
; Надежность, скорость, отказоустойчивость при перезагрузках
; ===============================================================================
;
; ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ФУНКЦИЙ!
;
; СПИСОК ФУНКЦИЙ:
; ===============================================================================
; ИНИЦИАЛИЗАЦИЯ:
; _Utils_SQLite_Startup() - Проверка DLL и инициализация SQLite
; _Utils_SQLite_Shutdown() - Завершение работы с SQLite
;
; БАЗОВЫЕ ФУНКЦИИ:
; _Utils_SQLite_Open($sDBPath) - Открыть/создать БД
; _Utils_SQLite_Close($hDB) - Закрыть БД
; _Utils_SQLite_Exec($hDB, $sSQL) - Выполнить SQL без результата
; _Utils_SQLite_Query($hDB, $sSQL) - SELECT запрос (возврат массив)
;
; РАБОТА С ТАБЛИЦАМИ:
; _Utils_SQLite_TableExists($hDB, $sTable) - Проверка существования таблицы
; _Utils_SQLite_CreateTable($hDB, $sTable, $sSchema) - Создание таблицы
; _Utils_SQLite_LoadTable($hDB, $sTable, $sWhere) - Загрузить таблицу в массив
; _Utils_SQLite_SaveTable($hDB, $sTable, $aData) - Сохранить массив (перезапись)
; _Utils_SQLite_AppendRow($hDB, $sTable, $aRow) - Добавить строку
; _Utils_SQLite_DeleteRow($hDB, $sTable, $iID) - Удалить строку по ID
; _Utils_SQLite_ClearTable($hDB, $sTable) - Очистить таблицу
;
; ВСПОМОГАТЕЛЬНЫЕ:
; _Utils_SQLite_Count($hDB, $sTable, $sWhere) - Количество строк
; _Utils_SQLite_GetLastID($hDB) - Последний вставленный ID
; _Utils_SQLite_GetLastError() - Последняя ошибка
;
; РАБОТА С НАСТРОЙКАМИ (INI ЗАМЕНА):
; _Utils_SQLite_SetConfig($hDB, $sSection, $sKey, $sValue) - Установить настройку
; _Utils_SQLite_GetConfig($hDB, $sSection, $sKey, $sDefault) - Получить настройку
; _Utils_SQLite_DeleteConfig($hDB, $sSection, $sKey) - Удалить настройку
; _Utils_SQLite_GetSection($hDB, $sSection) - Получить все настройки секции
;
; РАБОТА С ЛОГАМИ:
; _Utils_SQLite_AddLog($hDB, $sLevel, $sMessage, $sModule) - Добавить лог
; _Utils_SQLite_GetLogs($hDB, $sLevel, $sModule, $iLimit) - Получить логи
; _Utils_SQLite_ClearOldLogs($hDB, $iDaysOld) - Очистить старые логи
; _Utils_SQLite_CountLogs($hDB, $sLevel, $sModule) - Подсчет логов
; ===============================================================================

#include-once
#include "udf\SQLite_UDF.au3"
#include "Utils.au3"

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
; ===============================================================================

Global $g_bUtils_SQLite_Initialized = False
Global $g_sUtils_SQLite_LastError = ""
Global $g_bUtils_SQLite_DebugMode = True

; ===============================================================================
; ИНИЦИАЛИЗАЦИЯ И ПРОВЕРКИ
; ===============================================================================

; ===============================================================================
; Функция: _Utils_SQLite_Startup
; Описание: Инициализация SQLite с фиксированной DLL из папки udf
; Возврат: True при успехе, False при ошибке
; Примечание: Использует SQLite 3.28.0 из libs/Utils/udf/ (100% совместимость)
; ===============================================================================
Func _Utils_SQLite_Startup()
    If $g_bUtils_SQLite_Initialized Then
        Return True ; Уже инициализирован
    EndIf
    
    ; ИСПРАВЛЕНИЕ: Путь к DLL относительно файла Utils_SQLite.au3
    ; Используем @ScriptDir который указывает на папку запущенного скрипта
    ; Но нам нужен путь относительно ЭТОГО файла (Utils_SQLite.au3)
    ; Структура проекта: D:\OSPanel\domains\localhost\libs\Utils\Utils_SQLite.au3
    ; Нужно получить: D:\OSPanel\domains\localhost\libs\Utils\udf\sqlite3.dll
    
    ; Определяем корневую папку проекта через относительный путь от @ScriptDir
    ; Если приложение в apps/AppName/, то корень на 2 уровня выше
    Local $sProjectRoot = StringRegExpReplace(@ScriptDir, "\\[^\\]+$", "") ; Убираем папку приложения
    $sProjectRoot = StringRegExpReplace($sProjectRoot, "\\[^\\]+$", "") ; Убираем папку apps
    
    ; Путь к DLL: корень проекта + libs\Utils\udf\sqlite3.dll
    Local $sDLLPath = $sProjectRoot & "\libs\Utils\udf\sqlite3.dll"
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("🔍 [SQLite] Инициализация с фиксированной DLL", 1)
        _Logger_Write("   Путь: " & $sDLLPath, 1)
        _Logger_Write("   Архитектура: " & (@AutoItX64 ? "x64" : "x86"), 1)
    EndIf
    
    ; Проверяем наличие DLL
    If Not FileExists($sDLLPath) Then
        $g_sUtils_SQLite_LastError = "sqlite3.dll не найдена в папке udf. Путь: " & $sDLLPath
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("❌ [SQLite] DLL не найдена: " & $sDLLPath, 2)
        EndIf
        Return SetError(1, 0, False)
    EndIf
    
    ; Инициализируем SQLite с нашей DLL
    ; Параметры:
    ;   $sDLLPath - путь к DLL (библиотека сама добавит _x64 для x64)
    ;   False - не использовать UTF8 для сообщений об ошибках
    ;   1 - $iForceLocal = 1 (использовать только указанный путь, не искать в системе)
    Local $sResult = _SQLite_Startup($sDLLPath, False, 1)
    
    If @error Then
        $g_sUtils_SQLite_LastError = "Ошибка инициализации SQLite: " & @error & " (DLL: " & $sDLLPath & ")"
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("❌ [SQLite] Ошибка инициализации: " & @error, 2)
            _Logger_Write("   DLL путь: " & $sDLLPath, 2)
        EndIf
        Return SetError(2, 0, False)
    EndIf
    
    ; Проверяем версию SQLite
    Local $sVersion = _SQLite_LibVersion()
    
    $g_bUtils_SQLite_Initialized = True
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("✅ [SQLite] Инициализирован успешно", 3)
        _Logger_Write("   Версия: " & $sVersion, 1)
        _Logger_Write("   DLL: " & $sResult, 1)
    EndIf
    
    Return True
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_Shutdown
; Описание: Завершение работы с SQLite
; ===============================================================================
Func _Utils_SQLite_Shutdown()
    If Not $g_bUtils_SQLite_Initialized Then
        Return
    EndIf
    
    _SQLite_Shutdown()
    $g_bUtils_SQLite_Initialized = False
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("🔒 [SQLite] Завершение работы", 1)
    EndIf
EndFunc

; ===============================================================================
; БАЗОВЫЕ ФУНКЦИИ
; ===============================================================================

; ===============================================================================
; Функция: _Utils_SQLite_Open
; Описание: Открыть или создать базу данных SQLite
; Параметры:
;   $sDBPath - путь к файлу БД (будет создан если не существует)
; Возврат: Handle БД или 0 при ошибке
; ===============================================================================
Func _Utils_SQLite_Open($sDBPath)
    ; Проверяем инициализацию
    If Not $g_bUtils_SQLite_Initialized Then
        If Not _Utils_SQLite_Startup() Then
            Return SetError(1, 0, 0)
        EndIf
    EndIf
    
    ; Создаем папку если не существует
    Local $sDBDir = StringLeft($sDBPath, StringInStr($sDBPath, "\", 0, -1))
    If Not FileExists($sDBDir) Then
        DirCreate($sDBDir)
    EndIf
    
    ; Открываем БД
    Local $hDB = _SQLite_Open($sDBPath)
    If @error Then
        $g_sUtils_SQLite_LastError = "Ошибка открытия БД: " & $sDBPath
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("❌ [SQLite] Ошибка открытия: " & $sDBPath, 2)
        EndIf
        Return SetError(2, 0, 0)
    EndIf
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("📂 [SQLite] Открыта БД: " & $sDBPath, 1)
    EndIf
    
    Return $hDB
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_Close
; Описание: Закрыть базу данных
; Параметры:
;   $hDB - handle базы данных
; ===============================================================================
Func _Utils_SQLite_Close($hDB)
    If $hDB = 0 Then Return
    
    _SQLite_Close($hDB)
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("🔒 [SQLite] БД закрыта", 1)
    EndIf
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_Exec
; Описание: Выполнить SQL запрос без возврата результата (INSERT/UPDATE/DELETE/CREATE)
; Параметры:
;   $hDB - handle базы данных
;   $sSQL - SQL запрос
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_SQLite_Exec($hDB, $sSQL)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    Local $iResult = _SQLite_Exec($hDB, $sSQL)
    If @error Then
        $g_sUtils_SQLite_LastError = "Ошибка выполнения SQL: " & _SQLite_ErrMsg($hDB)
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("❌ [SQLite] Ошибка SQL: " & $g_sUtils_SQLite_LastError, 2)
        EndIf
        Return SetError(2, 0, False)
    EndIf
    
    Return True
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_Query
; Описание: Выполнить SELECT запрос и вернуть результат в виде массива
; Параметры:
;   $hDB - handle базы данных
;   $sSQL - SQL запрос (SELECT)
; Возврат: Двумерный массив данных или False при ошибке
; ===============================================================================
Func _Utils_SQLite_Query($hDB, $sSQL)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    Local $aResult, $iRows, $iCols
    Local $iResult = _SQLite_GetTable2d($hDB, $sSQL, $aResult, $iRows, $iCols)
    
    If @error Or $iResult <> $SQLITE_OK Then
        $g_sUtils_SQLite_LastError = "Ошибка SELECT: " & _SQLite_ErrMsg($hDB)
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("❌ [SQLite] Ошибка SELECT: " & $g_sUtils_SQLite_LastError, 2)
        EndIf
        Return SetError(2, 0, False)
    EndIf
    
    ; Если нет данных, возвращаем пустой массив
    If $iRows = 0 Then
        Local $aEmpty[0][0]
        Return $aEmpty
    EndIf
    
    Return $aResult
EndFunc

; ===============================================================================
; РАБОТА С ТАБЛИЦАМИ
; ===============================================================================

; ===============================================================================
; Функция: _Utils_SQLite_TableExists
; Описание: Проверка существования таблицы
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
; Возврат: True если таблица существует, False если нет
; ===============================================================================
Func _Utils_SQLite_TableExists($hDB, $sTable)
    If $hDB = 0 Then Return False
    
    Local $sSQL = "SELECT name FROM sqlite_master WHERE type='table' AND name='" & $sTable & "'"
    Local $aResult = _Utils_SQLite_Query($hDB, $sSQL)
    
    If @error Or Not IsArray($aResult) Then Return False
    
    Return (UBound($aResult, 1) > 0)
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_CreateTable
; Описание: Создание таблицы с заданной схемой
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
;   $sSchema - схема таблицы (например: "id INTEGER PRIMARY KEY, name TEXT")
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_SQLite_CreateTable($hDB, $sTable, $sSchema)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    ; Проверяем существование таблицы
    If _Utils_SQLite_TableExists($hDB, $sTable) Then
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("ℹ️ [SQLite] Таблица уже существует: " & $sTable, 1)
        EndIf
        Return True
    EndIf
    
    ; Создаем таблицу
    Local $sSQL = "CREATE TABLE IF NOT EXISTS " & $sTable & " (" & $sSchema & ")"
    Local $bResult = _Utils_SQLite_Exec($hDB, $sSQL)
    
    If $bResult Then
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("✅ [SQLite] Таблица создана: " & $sTable, 3)
        EndIf
    EndIf
    
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_LoadTable
; Описание: Загрузить всю таблицу или с условием WHERE в двумерный массив
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
;   $sWhere - условие WHERE (опционально, без слова WHERE)
; Возврат: Двумерный массив данных или False при ошибке
; ===============================================================================
Func _Utils_SQLite_LoadTable($hDB, $sTable, $sWhere = "")
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    ; Формируем SQL запрос
    Local $sSQL = "SELECT * FROM " & $sTable
    If $sWhere <> "" Then
        $sSQL &= " WHERE " & $sWhere
    EndIf
    
    ; Выполняем запрос
    Local $aResult = _Utils_SQLite_Query($hDB, $sSQL)
    
    If @error Then
        Return SetError(2, 0, False)
    EndIf
    
    ; _SQLite_GetTable2d возвращает массив с заголовками в [0]
    ; Нужно убрать первую строку (заголовки) и вернуть только данные
    If IsArray($aResult) And UBound($aResult, 1) > 1 Then
        Local $iRows = UBound($aResult, 1) - 1  ; Минус заголовок
        Local $iCols = UBound($aResult, 2)
        Local $aData[$iRows][$iCols]
        
        ; Копируем данные без заголовков
        For $i = 0 To $iRows - 1
            For $j = 0 To $iCols - 1
                $aData[$i][$j] = $aResult[$i + 1][$j]  ; +1 чтобы пропустить заголовок
            Next
        Next
        
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("📊 [SQLite] Загружено строк из " & $sTable & ": " & $iRows, 1)
        EndIf
        
        Return $aData
    Else
        ; Нет данных - возвращаем пустой массив
        Local $aEmpty[0][0]
        
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("📊 [SQLite] Загружено строк из " & $sTable & ": 0", 1)
        EndIf
        
        Return $aEmpty
    EndIf
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_SaveTable
; Описание: Сохранить двумерный массив в таблицу (полная перезапись)
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
;   $aData - двумерный массив данных
; Возврат: True при успехе, False при ошибке
; Примечание: Очищает таблицу и вставляет все данные из массива
; ===============================================================================
Func _Utils_SQLite_SaveTable($hDB, $sTable, $aData)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    If Not IsArray($aData) Then
        $g_sUtils_SQLite_LastError = "Данные должны быть массивом"
        Return SetError(2, 0, False)
    EndIf
    
    ; Начинаем транзакцию для атомарности
    _Utils_SQLite_Exec($hDB, "BEGIN TRANSACTION")
    
    ; Очищаем таблицу
    If Not _Utils_SQLite_ClearTable($hDB, $sTable) Then
        _Utils_SQLite_Exec($hDB, "ROLLBACK")
        Return SetError(3, 0, False)
    EndIf
    
    ; Если массив пустой, просто завершаем транзакцию
    If UBound($aData, 1) = 0 Then
        _Utils_SQLite_Exec($hDB, "COMMIT")
        If $g_bUtils_SQLite_DebugMode Then
            _Logger_Write("✅ [SQLite] Таблица очищена: " & $sTable, 1)
        EndIf
        Return True
    EndIf
    
    ; Вставляем все строки
    Local $iCols = UBound($aData, 2)
    Local $iRows = UBound($aData, 1)
    
    For $i = 0 To $iRows - 1
        ; Формируем VALUES с правильными типами
        Local $sValues = ""
        For $j = 0 To $iCols - 1
            If $j > 0 Then $sValues &= ", "
            
            ; Если значение пустая строка - используем NULL (для AUTOINCREMENT)
            If $aData[$i][$j] = "" Then
                $sValues &= "NULL"
            ; Если значение число - вставляем без кавычек
            ElseIf StringIsInt($aData[$i][$j]) Or StringIsFloat($aData[$i][$j]) Then
                $sValues &= $aData[$i][$j]
            ; Если строка - экранируем кавычки и оборачиваем в кавычки
            Else
                $sValues &= "'" & StringReplace($aData[$i][$j], "'", "''") & "'"
            EndIf
        Next
        
        ; Вставляем строку
        Local $sSQL = "INSERT INTO " & $sTable & " VALUES (" & $sValues & ")"
        If Not _Utils_SQLite_Exec($hDB, $sSQL) Then
            _Utils_SQLite_Exec($hDB, "ROLLBACK")
            Return SetError(4, 0, False)
        EndIf
    Next
    
    ; Завершаем транзакцию
    _Utils_SQLite_Exec($hDB, "COMMIT")
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("✅ [SQLite] Сохранено строк в " & $sTable & ": " & $iRows, 3)
    EndIf
    
    Return True
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_AppendRow
; Описание: Добавить строку в таблицу
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
;   $aRow - одномерный массив значений строки
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_SQLite_AppendRow($hDB, $sTable, $aRow)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    If Not IsArray($aRow) Then
        $g_sUtils_SQLite_LastError = "Строка должна быть массивом"
        Return SetError(2, 0, False)
    EndIf
    
    ; Формируем VALUES с правильными типами
    Local $sValues = ""
    For $i = 0 To UBound($aRow) - 1
        If $i > 0 Then $sValues &= ", "
        
        ; Если значение пустая строка - используем NULL (для AUTOINCREMENT)
        If $aRow[$i] = "" Then
            $sValues &= "NULL"
        ; Если значение число - вставляем без кавычек
        ElseIf StringIsInt($aRow[$i]) Or StringIsFloat($aRow[$i]) Then
            $sValues &= $aRow[$i]
        ; Если строка - экранируем кавычки и оборачиваем в кавычки
        Else
            $sValues &= "'" & StringReplace($aRow[$i], "'", "''") & "'"
        EndIf
    Next
    
    ; Вставляем строку
    Local $sSQL = "INSERT INTO " & $sTable & " VALUES (" & $sValues & ")"
    Local $bResult = _Utils_SQLite_Exec($hDB, $sSQL)
    
    If $bResult And $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("➕ [SQLite] Добавлена строка в " & $sTable, 1)
    EndIf
    
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_DeleteRow
; Описание: Удалить строку из таблицы по ID
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
;   $iID - ID строки для удаления
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_SQLite_DeleteRow($hDB, $sTable, $iID)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    Local $sSQL = "DELETE FROM " & $sTable & " WHERE id=" & $iID
    Local $bResult = _Utils_SQLite_Exec($hDB, $sSQL)
    
    If $bResult And $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("🗑️ [SQLite] Удалена строка ID=" & $iID & " из " & $sTable, 1)
    EndIf
    
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_ClearTable
; Описание: Очистить таблицу (удалить все строки)
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_SQLite_ClearTable($hDB, $sTable)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    Local $sSQL = "DELETE FROM " & $sTable
    Local $bResult = _Utils_SQLite_Exec($hDB, $sSQL)
    
    If $bResult And $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("🧹 [SQLite] Таблица очищена: " & $sTable, 1)
    EndIf
    
    Return $bResult
EndFunc

; ===============================================================================
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
; ===============================================================================

; ===============================================================================
; Функция: _Utils_SQLite_Count
; Описание: Подсчет количества строк в таблице
; Параметры:
;   $hDB - handle базы данных
;   $sTable - имя таблицы
;   $sWhere - условие WHERE (опционально, без слова WHERE)
; Возврат: Количество строк или -1 при ошибке
; ===============================================================================
Func _Utils_SQLite_Count($hDB, $sTable, $sWhere = "")
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, -1)
    EndIf
    
    ; Формируем SQL запрос
    Local $sSQL = "SELECT COUNT(*) FROM " & $sTable
    If $sWhere <> "" Then
        $sSQL &= " WHERE " & $sWhere
    EndIf
    
    ; Выполняем запрос
    Local $aResult = _Utils_SQLite_Query($hDB, $sSQL)
    
    If @error Or Not IsArray($aResult) Or UBound($aResult, 1) < 2 Then
        Return SetError(2, 0, -1)
    EndIf
    
    ; _SQLite_GetTable2d возвращает массив с заголовками в [0]
    ; Данные начинаются с [1]
    Return Int($aResult[1][0])
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_GetLastID
; Описание: Получить ID последней вставленной записи
; Параметры:
;   $hDB - handle базы данных
; Возврат: ID последней вставки или -1 при ошибке
; ===============================================================================
Func _Utils_SQLite_GetLastID($hDB)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, -1)
    EndIf
    
    Local $iLastID = _SQLite_LastInsertRowID($hDB)
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("🆔 [SQLite] LastInsertID: " & $iLastID, 1)
    EndIf
    
    Return $iLastID
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_GetLastError
; Описание: Получить описание последней ошибки
; Возврат: Строка с описанием ошибки
; ===============================================================================
Func _Utils_SQLite_GetLastError()
    Return $g_sUtils_SQLite_LastError
EndFunc


; ===============================================================================
; РАБОТА С НАСТРОЙКАМИ (INI ЗАМЕНА)
; ===============================================================================

; ===============================================================================
; Функция: _Utils_SQLite_SetConfig
; Описание: Установить значение настройки (замена IniWrite)
; Параметры:
;   $hDB - handle базы данных
;   $sSection - секция (аналог [Section] в INI)
;   $sKey - ключ настройки
;   $sValue - значение настройки
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_SQLite_SetConfig($hDB, "Database", "Host", "localhost")
; ===============================================================================
Func _Utils_SQLite_SetConfig($hDB, $sSection, $sKey, $sValue)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    ; Создаем таблицу config если не существует
    Local $sSchema = "section TEXT NOT NULL, key TEXT NOT NULL, value TEXT, UNIQUE(section, key)"
    If Not _Utils_SQLite_TableExists($hDB, "config") Then
        _Utils_SQLite_CreateTable($hDB, "config", $sSchema)
    EndIf
    
    ; Используем INSERT OR REPLACE для обновления существующих записей
    Local $sSQL = "INSERT OR REPLACE INTO config (section, key, value) VALUES ('" & _
                  StringReplace($sSection, "'", "''") & "', '" & _
                  StringReplace($sKey, "'", "''") & "', '" & _
                  StringReplace($sValue, "'", "''") & "')"
    
    Local $bResult = _Utils_SQLite_Exec($hDB, $sSQL)
    
    If $bResult And $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("⚙️ [SQLite] Config установлен: [" & $sSection & "] " & $sKey & " = " & $sValue, 1)
    EndIf
    
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_GetConfig
; Описание: Получить значение настройки (замена IniRead)
; Параметры:
;   $hDB - handle базы данных
;   $sSection - секция
;   $sKey - ключ настройки
;   $sDefault - значение по умолчанию (если не найдено)
; Возврат: Значение настройки или $sDefault
; Пример: Local $sHost = _Utils_SQLite_GetConfig($hDB, "Database", "Host", "localhost")
; ===============================================================================
Func _Utils_SQLite_GetConfig($hDB, $sSection, $sKey, $sDefault = "")
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, $sDefault)
    EndIf
    
    ; Проверяем существование таблицы
    If Not _Utils_SQLite_TableExists($hDB, "config") Then
        Return $sDefault
    EndIf
    
    ; Читаем значение
    Local $sSQL = "SELECT value FROM config WHERE section='" & _
                  StringReplace($sSection, "'", "''") & "' AND key='" & _
                  StringReplace($sKey, "'", "''") & "'"
    
    Local $aResult = _Utils_SQLite_Query($hDB, $sSQL)
    
    If @error Or Not IsArray($aResult) Or UBound($aResult, 1) < 2 Then
        Return $sDefault
    EndIf
    
    Return $aResult[1][0]
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_DeleteConfig
; Описание: Удалить настройку или всю секцию (замена IniDelete)
; Параметры:
;   $hDB - handle базы данных
;   $sSection - секция
;   $sKey - ключ настройки (если "", удаляется вся секция)
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_SQLite_DeleteConfig($hDB, "Database", "Host") - удалить ключ
;          _Utils_SQLite_DeleteConfig($hDB, "Database", "") - удалить секцию
; ===============================================================================
Func _Utils_SQLite_DeleteConfig($hDB, $sSection, $sKey = "")
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    ; Проверяем существование таблицы
    If Not _Utils_SQLite_TableExists($hDB, "config") Then
        Return True
    EndIf
    
    ; Формируем SQL
    Local $sSQL
    If $sKey = "" Then
        ; Удаляем всю секцию
        $sSQL = "DELETE FROM config WHERE section='" & StringReplace($sSection, "'", "''") & "'"
    Else
        ; Удаляем конкретный ключ
        $sSQL = "DELETE FROM config WHERE section='" & StringReplace($sSection, "'", "''") & _
                "' AND key='" & StringReplace($sKey, "'", "''") & "'"
    EndIf
    
    Local $bResult = _Utils_SQLite_Exec($hDB, $sSQL)
    
    If $bResult And $g_bUtils_SQLite_DebugMode Then
        If $sKey = "" Then
            _Logger_Write("🗑️ [SQLite] Config секция удалена: [" & $sSection & "]", 1)
        Else
            _Logger_Write("🗑️ [SQLite] Config удален: [" & $sSection & "] " & $sKey, 1)
        EndIf
    EndIf
    
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_GetSection
; Описание: Получить все настройки секции (замена IniReadSection)
; Параметры:
;   $hDB - handle базы данных
;   $sSection - секция
; Возврат: Двумерный массив [key, value] или False при ошибке
; Пример: Local $aSettings = _Utils_SQLite_GetSection($hDB, "Database")
; ===============================================================================
Func _Utils_SQLite_GetSection($hDB, $sSection)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    ; Проверяем существование таблицы
    If Not _Utils_SQLite_TableExists($hDB, "config") Then
        Local $aEmpty[0][2]
        Return $aEmpty
    EndIf
    
    ; Читаем все ключи секции
    Local $sSQL = "SELECT key, value FROM config WHERE section='" & _
                  StringReplace($sSection, "'", "''") & "' ORDER BY key"
    
    Local $aResult = _Utils_SQLite_Query($hDB, $sSQL)
    
    If @error Then
        Return SetError(2, 0, False)
    EndIf
    
    ; Убираем заголовки
    If IsArray($aResult) And UBound($aResult, 1) > 1 Then
        Local $iRows = UBound($aResult, 1) - 1
        Local $aData[$iRows][2]
        
        For $i = 0 To $iRows - 1
            $aData[$i][0] = $aResult[$i + 1][0]  ; key
            $aData[$i][1] = $aResult[$i + 1][1]  ; value
        Next
        
        Return $aData
    Else
        Local $aEmpty[0][2]
        Return $aEmpty
    EndIf
EndFunc

; ===============================================================================
; РАБОТА С ЛОГАМИ
; ===============================================================================

; ===============================================================================
; Функция: _Utils_SQLite_AddLog
; Описание: Добавить запись в лог
; Параметры:
;   $hDB - handle базы данных
;   $sLevel - уровень лога (INFO, ERROR, SUCCESS, WARNING)
;   $sMessage - текст сообщения
;   $sModule - имя модуля (опционально)
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_SQLite_AddLog($hDB, "ERROR", "Ошибка подключения", "MySQL")
; ===============================================================================
Func _Utils_SQLite_AddLog($hDB, $sLevel, $sMessage, $sModule = "")
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    ; Создаем таблицу logs если не существует
    Local $sSchema = "id INTEGER PRIMARY KEY AUTOINCREMENT, level TEXT NOT NULL, message TEXT NOT NULL, module TEXT, timestamp INTEGER NOT NULL"
    If Not _Utils_SQLite_TableExists($hDB, "logs") Then
        _Utils_SQLite_CreateTable($hDB, "logs", $sSchema)
        ; Создаем индексы для быстрого поиска
        _Utils_SQLite_Exec($hDB, "CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level)")
        _Utils_SQLite_Exec($hDB, "CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp)")
        _Utils_SQLite_Exec($hDB, "CREATE INDEX IF NOT EXISTS idx_logs_module ON logs(module)")
    EndIf
    
    ; Получаем текущий timestamp
    Local $iTimestamp = _Utils_GetUnixTimestampMS()
    
    ; Вставляем лог
    Local $aRow[5] = ["", $sLevel, $sMessage, $sModule, $iTimestamp]
    Local $bResult = _Utils_SQLite_AppendRow($hDB, "logs", $aRow)
    
    If $bResult And $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("📝 [SQLite] Лог добавлен: [" & $sLevel & "] " & $sMessage, 1)
    EndIf
    
    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_GetLogs
; Описание: Получить логи с фильтрацией
; Параметры:
;   $hDB - handle базы данных
;   $sLevel - фильтр по уровню (пусто = все)
;   $sModule - фильтр по модулю (пусто = все)
;   $iLimit - максимальное количество записей (0 = все)
; Возврат: Двумерный массив логов или False при ошибке
; Пример: Local $aLogs = _Utils_SQLite_GetLogs($hDB, "ERROR", "", 100)
; ===============================================================================
Func _Utils_SQLite_GetLogs($hDB, $sLevel = "", $sModule = "", $iLimit = 100)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, False)
    EndIf
    
    ; Проверяем существование таблицы
    If Not _Utils_SQLite_TableExists($hDB, "logs") Then
        Local $aEmpty[0][5]
        Return $aEmpty
    EndIf
    
    ; Формируем WHERE условие
    Local $sWhere = ""
    If $sLevel <> "" Then
        $sWhere = "level='" & StringReplace($sLevel, "'", "''") & "'"
    EndIf
    If $sModule <> "" Then
        If $sWhere <> "" Then $sWhere &= " AND "
        $sWhere &= "module='" & StringReplace($sModule, "'", "''") & "'"
    EndIf
    
    ; Формируем SQL
    Local $sSQL = "SELECT id, level, message, module, timestamp FROM logs"
    If $sWhere <> "" Then $sSQL &= " WHERE " & $sWhere
    $sSQL &= " ORDER BY timestamp DESC"
    If $iLimit > 0 Then $sSQL &= " LIMIT " & $iLimit
    
    ; Выполняем запрос
    Local $aResult = _Utils_SQLite_Query($hDB, $sSQL)
    
    If @error Then
        Return SetError(2, 0, False)
    EndIf
    
    ; Убираем заголовки
    If IsArray($aResult) And UBound($aResult, 1) > 1 Then
        Local $iRows = UBound($aResult, 1) - 1
        Local $aData[$iRows][5]
        
        For $i = 0 To $iRows - 1
            $aData[$i][0] = $aResult[$i + 1][0]  ; id
            $aData[$i][1] = $aResult[$i + 1][1]  ; level
            $aData[$i][2] = $aResult[$i + 1][2]  ; message
            $aData[$i][3] = $aResult[$i + 1][3]  ; module
            $aData[$i][4] = $aResult[$i + 1][4]  ; timestamp
        Next
        
        Return $aData
    Else
        Local $aEmpty[0][5]
        Return $aEmpty
    EndIf
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_ClearOldLogs
; Описание: Удалить логи старше указанного количества дней
; Параметры:
;   $hDB - handle базы данных
;   $iDaysOld - количество дней (логи старше будут удалены)
; Возврат: Количество удаленных записей или -1 при ошибке
; Пример: _Utils_SQLite_ClearOldLogs($hDB, 7) - удалить логи старше 7 дней
; ===============================================================================
Func _Utils_SQLite_ClearOldLogs($hDB, $iDaysOld = 7)
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, -1)
    EndIf
    
    ; Проверяем существование таблицы
    If Not _Utils_SQLite_TableExists($hDB, "logs") Then
        Return 0
    EndIf
    
    ; Вычисляем timestamp границы (текущее время - N дней)
    Local $iCurrentTime = _Utils_GetUnixTimestampMS()
    Local $iOldTime = $iCurrentTime - ($iDaysOld * 24 * 60 * 60 * 1000)
    
    ; Подсчитываем количество записей для удаления
    Local $iCountBefore = _Utils_SQLite_Count($hDB, "logs", "timestamp < " & $iOldTime)
    
    ; Удаляем старые логи
    Local $sSQL = "DELETE FROM logs WHERE timestamp < " & $iOldTime
    Local $bResult = _Utils_SQLite_Exec($hDB, $sSQL)
    
    If Not $bResult Then
        Return SetError(2, 0, -1)
    EndIf
    
    If $g_bUtils_SQLite_DebugMode Then
        _Logger_Write("🧹 [SQLite] Удалено старых логов: " & $iCountBefore & " (старше " & $iDaysOld & " дней)", 1)
    EndIf
    
    Return $iCountBefore
EndFunc

; ===============================================================================
; Функция: _Utils_SQLite_CountLogs
; Описание: Подсчет количества логов с фильтрацией
; Параметры:
;   $hDB - handle базы данных
;   $sLevel - фильтр по уровню (пусто = все)
;   $sModule - фильтр по модулю (пусто = все)
; Возврат: Количество логов или -1 при ошибке
; Пример: Local $iErrors = _Utils_SQLite_CountLogs($hDB, "ERROR", "MySQL")
; ===============================================================================
Func _Utils_SQLite_CountLogs($hDB, $sLevel = "", $sModule = "")
    If $hDB = 0 Then
        $g_sUtils_SQLite_LastError = "Неверный handle БД"
        Return SetError(1, 0, -1)
    EndIf
    
    ; Проверяем существование таблицы
    If Not _Utils_SQLite_TableExists($hDB, "logs") Then
        Return 0
    EndIf
    
    ; Формируем WHERE условие
    Local $sWhere = ""
    If $sLevel <> "" Then
        $sWhere = "level='" & StringReplace($sLevel, "'", "''") & "'"
    EndIf
    If $sModule <> "" Then
        If $sWhere <> "" Then $sWhere &= " AND "
        $sWhere &= "module='" & StringReplace($sModule, "'", "''") & "'"
    EndIf
    
    Return _Utils_SQLite_Count($hDB, "logs", $sWhere)
EndFunc