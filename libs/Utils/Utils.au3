; ===============================================================================
; Utils Library v2.1
; Утилиты для логирования, работы с UTF-8, общих функций и SQLite
; Поддержка модульной архитектуры SDK
; ===============================================================================
;
; ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ФУНКЦИЙ!
;
; СПИСОК ФУНКЦИЙ:
; ===============================================================================
; ИНИЦИАЛИЗАЦИЯ SDK:
; _SDK_Utils_Init($sAppName, $sModuleName, $bDebugMode, $iLogFilter, $iLogTarget, $bClearLog)
;   $sAppName - имя приложения (по умолчанию "DefaultApp")
;   $sModuleName - имя модуля (по умолчанию "Main")
;   $bDebugMode - режим отладки: True/False (по умолчанию True)
;   $iLogFilter - фильтр логов: 1=все, 2=только ошибки, 3=только успех (по умолчанию 1)
;   $iLogTarget - куда писать: 1=консоль, 2=файл, 3=оба (по умолчанию 3)
;   $bClearLog - очищать лог при запуске: True/False (по умолчанию True)
;
; _SDK_CreateLogDirs() - Создание папок для логов
; _SDK_GetLogPath() - Получение пути к текущему файлу лога
; _SDK_GetLogDir() - Получение папки логов приложения
;
; ФУНКЦИИ ЛОГИРОВАНИЯ V2:
; _Logger_Write($sText, $iLogType, $iTarget) - Универсальная функция логирования
;   $sText - текст для логирования (обязательный)
;   $iLogType - тип: 1=INFO, 2=ERROR, 3=SUCCESS (по умолчанию 1)
;   $iTarget - куда: 1=консоль, 2=файл, 3=оба (по умолчанию использует $g_iUtils_SDK_LogTarget)
;
; _Logger_WriteToFile($sText) - Запись в файл лога с временной меткой
; _Logger_ClearLog() - Очистка файла лога
; _Logger_ConsoleWriteUTF($sText) - Вывод в консоль с UTF-8 поддержкой
;
; ФУНКЦИИ РАБОТЫ С UTF-8:
; _Utils_StringToUTF8($sData) - Преобразование строки в UTF-8
; _Utils_UTF8ToString($vData) - Преобразование UTF-8 в строку
;
; ФУНКЦИИ РАБОТЫ С МАССИВАМИ:
; _Utils_ArrayToString($aArray, $sDelim) - Массив в строку с разделителем
; _Utils_StringToArray($sString, $sDelim) - Строка в массив по разделителю
;
; ФУНКЦИИ ВРЕМЕНИ:
; _Utils_GetTimestamp() - Получение временной метки
; _Utils_GetElapsedTime($hTimer) - Получение прошедшего времени
;
; ФУНКЦИИ UUID И ДАТЫ/ВРЕМЕНИ (для MySQL v2.0):
; _Utils_GenerateUUIDv7() - Генерация UUID v7 (time-based, сортируемый)
; _Utils_GetUnixTimestampMS() - Unix timestamp в миллисекундах
; _Utils_GetDateOnly() - Текущая дата в формате YYYY-MM-DD
; _Utils_GetDateTimeMS() - Дата и время с миллисекундами YYYY-MM-DD HH:MM:SS.mmm
; _Utils_ParseUUIDv7Timestamp($sUUID) - Извлечение timestamp из UUID v7
; ===============================================================================

#include-once
#include "Utils_SQLite.au3"
#include "Utils_Config.au3"
#include "Utils_Window.au3"

; === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ UTILS SDK ===


Global $g_sUtils_SDK_AppName = "DefaultApp"      ; Имя приложения (по умолчанию)
Global $g_sUtils_SDK_ModuleName = "Main"         ; Имя модуля (по умолчанию)
Global $g_bUtils_SDK_DebugMode = True            ; Режим отладки (True/False)
Global $g_iUtils_SDK_LogFilter = 1               ; Фильтр логов: 1=все, 2=только ошибки, 3=только успех+ошибки
Global $g_iUtils_SDK_LogTarget = 3               ; Куда писать: 1=консоль, 2=файл, 3=оба

; ===============================================================================
; Функция: _SDK_Utils_Init
; Описание: Инициализация SDK - настройка логирования и создание папок
; Параметры:
;   $sAppName - имя приложения (по умолчанию "DefaultApp")
;   $sModuleName - имя модуля (по умолчанию "Main")
;   $bDebugMode - режим отладки: True/False (по умолчанию True)
;   $iLogFilter - фильтр: 1=все, 2=только ошибки, 3=только успех (по умолчанию 1)
;   $iLogTarget - куда: 1=консоль, 2=файл, 3=оба (по умолчанию 3)
;   $bClearLog - очищать лог при запуске: True/False (по умолчанию True)
; Возврат: True при успехе
; Пример: _SDK_Utils_Init("TestApp", "Main")
; Пример: _SDK_Utils_Init() - использует дефолтные значения
; ===============================================================================
Func _SDK_Utils_Init($sAppName = "DefaultApp", $sModuleName = "Main", $bDebugMode = True, $iLogFilter = 1, $iLogTarget = 3, $bClearLog = True)
    $g_sUtils_SDK_AppName = $sAppName
    $g_sUtils_SDK_ModuleName = $sModuleName
    $g_bUtils_SDK_DebugMode = $bDebugMode
    $g_iUtils_SDK_LogFilter = $iLogFilter
    $g_iUtils_SDK_LogTarget = $iLogTarget

    ; Создание папок для логов
    _SDK_CreateLogDirs()

    ; Очистка лога если требуется
    If $bClearLog Then _Logger_ClearLog()

    ; Запись о запуске
    _Logger_Write("🚀 SDK инициализирован: " & $sAppName & " / " & $sModuleName, 3)

    Return True
EndFunc

; ===============================================================================
; Функция: _SDK_CreateLogDirs
; Описание: Создание папок для логов приложения
; Возврат: True при успехе
; ===============================================================================
Func _SDK_CreateLogDirs()
    Local $sLogDir = _SDK_GetLogDir()
    If Not FileExists($sLogDir) Then
        DirCreate($sLogDir)
    EndIf
    Return True
EndFunc

; ===============================================================================
; Функция: _SDK_GetLogPath
; Описание: Получение полного пути к файлу лога текущего модуля
; Возврат: Строка с путём (например: "D:\Project\logs\TestApp\TestApp_Main.log")
; Пример: Local $sPath = _SDK_GetLogPath()
; ===============================================================================
Func _SDK_GetLogPath()
    Local $sLogDir = _SDK_GetLogDir()
    ; ИСПРАВЛЕНО: Один файл лога на приложение (без _ModuleName)
    Local $sLogFile = $g_sUtils_SDK_AppName & ".log"
    Return $sLogDir & "\" & $sLogFile
EndFunc

; ===============================================================================
; Функция: _SDK_GetLogDir
; Описание: Получение папки логов приложения
; Возврат: Строка с путём (например: "D:\Project\logs\TestApp")
; Пример: Local $sDir = _SDK_GetLogDir()
; ===============================================================================
Func _SDK_GetLogDir()
    ; ИСПРАВЛЕНО: Правильное определение корня проекта
    Local $sProjectRoot = @ScriptDir

    ; Если мы в подпапке (libs, tests, apps), поднимаемся на уровень выше до корня
    If StringInStr($sProjectRoot, "\libs\") Then
        ; Из libs/Utils поднимаемся на 2 уровня: libs/Utils -> libs -> корень
        $sProjectRoot = StringRegExpReplace($sProjectRoot, "\\libs\\.*$", "")
    ElseIf StringInStr($sProjectRoot, "\tests") Then
        ; Из tests поднимаемся на 1 уровень: tests -> корень
        $sProjectRoot = StringRegExpReplace($sProjectRoot, "\\tests$", "")
    ElseIf StringInStr($sProjectRoot, "\apps\") Then
        ; Из apps/AppName поднимаемся на 2 уровня: apps/AppName -> apps -> корень
        $sProjectRoot = StringRegExpReplace($sProjectRoot, "\\apps\\.*$", "")
    EndIf

    Return $sProjectRoot & "\logs\" & $g_sUtils_SDK_AppName
EndFunc

; ===============================================================================
; Функция: _Logger_Write
; Описание: Универсальная функция логирования с фильтрацией и выбором вывода
; Параметры:
;   $sText - текст для логирования (обязательный)
;   $iLogType - тип: 1=INFO, 2=ERROR, 3=SUCCESS (по умолчанию 1)
;   $iTarget - куда: 1=консоль, 2=файл, 3=оба (по умолчанию использует $g_iUtils_SDK_LogTarget)
; Возврат: True если лог записан, False если отфильтрован
; Пример: _Logger_Write("Операция выполнена", 3)
; ===============================================================================
Func _Logger_Write($sText, $iLogType = 1, $iTarget = Default)
    ; Проверка режима отладки
    If Not $g_bUtils_SDK_DebugMode Then Return False

    ; Фильтрация по типу лога
    If $g_iUtils_SDK_LogFilter <> 1 Then
        ; Если фильтр = 3 (только SUCCESS), пропускаем SUCCESS и ERROR, но не INFO
        If $g_iUtils_SDK_LogFilter = 3 Then
            If $iLogType = 1 Then Return False ; Блокируем INFO
        ; Если фильтр = 2 (только ERROR), пропускаем только ERROR
        ElseIf $g_iUtils_SDK_LogFilter = 2 Then
            If $iLogType <> 2 Then Return False ; Блокируем всё кроме ERROR
        EndIf
    EndIf

    ; Использовать глобальный target если не указан
    If $iTarget = Default Then $iTarget = $g_iUtils_SDK_LogTarget

    ; Формирование префикса
    Local $sPrefix = ""
    Switch $iLogType
        Case 2
            $sPrefix = "❌ [ERROR] "
        Case 3
            $sPrefix = "✅ [SUCCESS] "
        Case Else
            $sPrefix = "ℹ️ [INFO] "
    EndSwitch

    ; Добавляем временную метку в начало
    Local $sDateTime = _Utils_GetDateTimeMS()
    Local $sTimestampConsole = "⏳ " & $sDateTime & " "
    Local $sTimestampFile = "[" & $sDateTime & "] "

    ; Вывод в консоль (с эмодзи)
    If BitAND($iTarget, 1) Then
        Local $sOutputConsole = $sTimestampConsole & $sPrefix & $sText
        _Logger_ConsoleWriteUTF($sOutputConsole)
    EndIf

    ; Вывод в файл (со скобками)
    If BitAND($iTarget, 2) Then
        Local $sOutputFile = $sTimestampFile & $sPrefix & $sText
        _Logger_WriteToFile($sOutputFile)
    EndIf

    Return True
EndFunc



; ===============================================================================
; Функция: _Logger_ConsoleWriteUTF
; Описание: Вывод текста в консоль с поддержкой UTF-8
; Параметры: $sText - текст для вывода
; ===============================================================================
Func _Logger_ConsoleWriteUTF($sText)
    ; Если текст не содержит временную метку, добавляем её
    Local $sOutput = $sText
    If Not StringInStr($sText, "⏳") Then
        $sOutput = "⏳ " & _Utils_GetDateTimeMS() & " " & $sText
    EndIf

    ConsoleWrite(BinaryToString(StringToBinary($sOutput, 4)) & @CRLF)
EndFunc



; ===============================================================================
; Функция: _Logger_WriteToFile
; Описание: Запись в файл лога с временной меткой
; Параметры: $sText - текст для записи
; ===============================================================================
Func _Logger_WriteToFile($sText)
    ; Если текст не содержит временную метку, добавляем её в квадратных скобках
    Local $sOutput = $sText
    If Not StringInStr($sText, "[20") Then  ; Проверяем наличие [2026-...
        $sOutput = "[" & _Utils_GetDateTimeMS() & "] " & $sText
    EndIf

    Local $sLogEntry = $sOutput & @CRLF
    Local $sLogPath = _SDK_GetLogPath()

    FileWrite($sLogPath, $sLogEntry)
EndFunc



; ===============================================================================
; Функция: _Logger_ClearLog
; Описание: Очистка файла лога текущего модуля
; ===============================================================================
Func _Logger_ClearLog()
    Local $sLogPath = _SDK_GetLogPath()
    If FileExists($sLogPath) Then
        FileDelete($sLogPath)
    EndIf
EndFunc

; ===============================================================================
; Функция: _Utils_StringToUTF8
; Описание: Преобразование строки в UTF-8 для отправки в Redis
; Параметры: $sData - исходная строка
; Возврат: Бинарные данные в UTF-8
; ===============================================================================
Func _Utils_StringToUTF8($sData)
    Return StringToBinary($sData, 4)
EndFunc

; ===============================================================================
; Функция: _Utils_UTF8ToString
; Описание: Преобразование UTF-8 данных в строку
; Параметры: $vData - бинарные данные
; Возврат: Строка
; ===============================================================================
Func _Utils_UTF8ToString($vData)
    Return BinaryToString($vData, 4)
EndFunc

; ===============================================================================
; Функция: _Utils_ArrayToString
; Описание: Преобразование одномерного массива в строку с разделителем
; Параметры: $aArray - массив, $sDelimiter - разделитель (по умолчанию "|")
; Возврат: Строка
; ===============================================================================
Func _Utils_ArrayToString($aArray, $sDelimiter = "|")
    Local $sResult = ""
    For $i = 0 To UBound($aArray) - 1
        $sResult &= $aArray[$i]
        If $i < UBound($aArray) - 1 Then $sResult &= $sDelimiter
    Next
    Return $sResult
EndFunc

; ===============================================================================
; Функция: _Utils_StringToArray
; Описание: Преобразование строки в одномерный массив по разделителю
; Параметры: $sString - строка, $sDelimiter - разделитель (по умолчанию "|")
; Возврат: Массив
; ===============================================================================
Func _Utils_StringToArray($sString, $sDelimiter = "|")
    Return StringSplit($sString, $sDelimiter, 1)
EndFunc

; ===============================================================================
; Функция: _Utils_GetTimestamp
; Описание: Получение текущей временной метки в миллисекундах
; Возврат: Время в мс
; ===============================================================================
Func _Utils_GetTimestamp()
    Return TimerInit()
EndFunc

; ===============================================================================
; Функция: _Utils_GetElapsedTime
; Описание: Получение прошедшего времени с момента старта
; Параметры: $hTimer - таймер от TimerInit()
; Возврат: Время в мс
; ===============================================================================
Func _Utils_GetElapsedTime($hTimer)
    Return TimerDiff($hTimer)
EndFunc

; ===============================================================================
; ФУНКЦИИ UUID И ДАТЫ/ВРЕМЕНИ (для MySQL v2.0 SCADA систем)
; ===============================================================================

; ===============================================================================
; Функция: _Utils_GenerateUUIDv7
; Описание: Генерация UUID v7 (time-based, RFC 9562)
;           UUID v7 содержит timestamp в первых 48 битах, что обеспечивает:
;           - Естественную сортировку по времени создания
;           - Оптимальную вставку в индексы MySQL (без фрагментации)
;           - Уникальность за счет случайной части (74 бита)
; Возврат: Строка UUID в формате xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx
; Пример: "018d5e8a-1234-7abc-9def-123456789abc"
; Примечание: Для SCADA систем идеален - сортируется по времени события
; ===============================================================================
Func _Utils_GenerateUUIDv7()
    ; Получаем Unix timestamp в миллисекундах (48 бит)
    Local $iTimestampMS = _Utils_GetUnixTimestampMS()

    ; Преобразуем timestamp в hex (12 символов = 48 бит)
    Local $sTimestampHex = Hex($iTimestampMS, 12)

    ; Генерируем случайные части
    Local $sChars = "0123456789abcdef"
    Local $sRandom1 = "" ; 4 символа (16 бит)
    Local $sRandom2 = "" ; 4 символа (16 бит) - с версией
    Local $sRandom3 = "" ; 4 символа (16 бит) - с вариантом
    Local $sRandom4 = "" ; 12 символов (48 бит)

    ; Генерируем случайные символы
    For $i = 1 To 4
        $sRandom1 &= StringMid($sChars, Random(1, 16, 1), 1)
    Next

    For $i = 1 To 4
        $sRandom2 &= StringMid($sChars, Random(1, 16, 1), 1)
    Next

    For $i = 1 To 4
        $sRandom3 &= StringMid($sChars, Random(1, 16, 1), 1)
    Next

    For $i = 1 To 12
        $sRandom4 &= StringMid($sChars, Random(1, 16, 1), 1)
    Next

    ; Устанавливаем версию 7 (биты 12-15 третьей группы = 0111)
    $sRandom2 = "7" & StringRight($sRandom2, 3)

    ; Устанавливаем вариант RFC4122 (биты 0-1 четвертой группы = 10)
    Local $sFirstChar = StringLeft($sRandom3, 1)
    Local $iFirstCharValue = Dec($sFirstChar)
    ; Устанавливаем биты 0-1 в 10 (значения 8, 9, a, b)
    $iFirstCharValue = BitAND($iFirstCharValue, 0x3) ; Оставляем младшие 2 бита
    $iFirstCharValue = BitOR($iFirstCharValue, 0x8)  ; Устанавливаем старшие биты в 10
    $sRandom3 = Hex($iFirstCharValue, 1) & StringRight($sRandom3, 3)

    ; Собираем UUID в формате: timestamp-rand1-ver-var-rand4
    ; Формат: xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx
    Local $sUUID = StringLeft($sTimestampHex, 8) & "-" & _
                   StringMid($sTimestampHex, 9, 4) & "-" & _
                   $sRandom2 & "-" & _
                   $sRandom3 & "-" & _
                   $sRandom4

    Return StringLower($sUUID)
EndFunc

; ===============================================================================
; Функция: _Utils_GetUnixTimestampMS
; Описание: Получение Unix timestamp в миллисекундах
;           Используется для UUID v7 и точных меток времени
; Возврат: Int64 - количество миллисекунд с 1970-01-01 00:00:00 UTC
; Пример: 1708185600000 (для 2024-02-17 12:00:00)
; ===============================================================================
Func _Utils_GetUnixTimestampMS($iTimezoneOffset = 2)
    ; Получаем текущее время в формате FileTime (100-наносекундные интервалы с 1601-01-01)
    Local $tSystemTime = DllStructCreate("ushort Year;ushort Month;ushort DayOfWeek;ushort Day;ushort Hour;ushort Minute;ushort Second;ushort Milliseconds")
    DllCall("kernel32.dll", "none", "GetSystemTime", "ptr", DllStructGetPtr($tSystemTime))

    Local $tFileTime = DllStructCreate("uint64")
    DllCall("kernel32.dll", "bool", "SystemTimeToFileTime", "ptr", DllStructGetPtr($tSystemTime), "ptr", DllStructGetPtr($tFileTime))

    ; FileTime в 100-наносекундных интервалах с 1601-01-01
    Local $iFileTime = DllStructGetData($tFileTime, 1)

    ; Конвертируем в Unix timestamp (секунды с 1970-01-01)
    ; Разница между 1601-01-01 и 1970-01-01 = 116444736000000000 (100-наносекундных интервалов)
    Local $iUnixEpochOffset = 116444736000000000
    Local $iUnixTime100ns = $iFileTime - $iUnixEpochOffset

    ; Конвертируем в миллисекунды (делим на 10000)
    Local $iUnixTimeMS = Int($iUnixTime100ns / 10000)

    ; Применяем смещение часового пояса (часы → миллисекунды)
    $iUnixTimeMS += ($iTimezoneOffset * 3600 * 1000)

    Return $iUnixTimeMS
EndFunc

; ===============================================================================
; Функция: _Utils_GetDateOnly
; Описание: Получение текущей даты в формате MySQL DATE
; Возврат: Строка в формате YYYY-MM-DD
; Пример: "2026-02-17"
; Использование: Для поля event_date в таблицах SCADA
; ===============================================================================
Func _Utils_GetDateOnly()
    Return @YEAR & "-" & @MON & "-" & @MDAY
EndFunc

; ===============================================================================
; Функция: _Utils_GetDateTimeMS
; Описание: Получение текущей даты и времени с миллисекундами
; Возврат: Строка в формате YYYY-MM-DD HH:MM:SS.mmm
; Пример: "2026-02-17 14:35:22.456"
; Использование: Для поля event_datetime в таблицах SCADA
; Примечание: Точность до миллисекунд критична для SCADA систем
; ===============================================================================
Func _Utils_GetDateTimeMS($iTimezoneOffset = 2)
    ; Получаем системное время с миллисекундами (UTC)
    Local $tSystemTime = DllStructCreate("ushort Year;ushort Month;ushort DayOfWeek;ushort Day;ushort Hour;ushort Minute;ushort Second;ushort Milliseconds")
    DllCall("kernel32.dll", "none", "GetSystemTime", "ptr", DllStructGetPtr($tSystemTime))

    Local $iYear = DllStructGetData($tSystemTime, "Year")
    Local $iMonth = DllStructGetData($tSystemTime, "Month")
    Local $iDay = DllStructGetData($tSystemTime, "Day")
    Local $iHour = DllStructGetData($tSystemTime, "Hour")
    Local $iMinute = DllStructGetData($tSystemTime, "Minute")
    Local $iSecond = DllStructGetData($tSystemTime, "Second")
    Local $iMilliseconds = DllStructGetData($tSystemTime, "Milliseconds")

    ; Применяем смещение часового пояса
    $iHour += $iTimezoneOffset

    ; Обработка переполнения часов
    If $iHour >= 24 Then
        $iHour -= 24
        $iDay += 1
        ; Упрощённая обработка переполнения дней (для большинства случаев достаточно)
    ElseIf $iHour < 0 Then
        $iHour += 24
        $iDay -= 1
    EndIf

    ; Форматируем в MySQL DATETIME(3) формат
    Return StringFormat("%04d-%02d-%02d %02d:%02d:%02d.%03d", $iYear, $iMonth, $iDay, $iHour, $iMinute, $iSecond, $iMilliseconds)
EndFunc

; ===============================================================================
; Функция: _Utils_ParseUUIDv7Timestamp
; Описание: Извлечение timestamp из UUID v7 и преобразование в дату/время
;           UUID v7 содержит Unix timestamp (мс) в первых 48 битах (12 hex символов)
; Параметры:
;   $sUUID - UUID v7 в формате xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx
; Возврат: Строка в формате YYYY-MM-DD HH:MM:SS.mmm или пустая строка при ошибке
; Пример: _Utils_ParseUUIDv7Timestamp("019c6d39-b98f-746f-a722-cf0e9357fafd")
;         Результат: "2026-02-17 20:10:25.423"
; Использование: Для отладки, логирования, восстановления времени события
; ===============================================================================
Func _Utils_ParseUUIDv7Timestamp($sUUID)
    ; Проверка формата UUID
    If StringLen($sUUID) <> 36 Then
        Return SetError(1, 0, "")
    EndIf

    ; Извлекаем первые 12 hex символов (48 бит timestamp)
    ; Формат UUID v7: xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx
    ;                 [  8  ] [4]
    Local $sTimestampHex = StringLeft($sUUID, 8) & StringMid($sUUID, 10, 4)

    ; Конвертируем hex в число (Unix timestamp в миллисекундах)
    Local $iTimestampMS = Dec($sTimestampHex)

    ; Конвертируем Unix timestamp (мс) в дату/время
    ; Unix timestamp в секундах
    Local $iTimestampSec = Int($iTimestampMS / 1000)
    Local $iMilliseconds = Mod($iTimestampMS, 1000)

    ; Используем FileTime для конвертации
    ; Unix epoch offset: разница между 1601-01-01 и 1970-01-01 в 100-наносекундных интервалах
    Local $iUnixEpochOffset = 116444736000000000
    Local $iFileTime = ($iTimestampSec * 10000000) + $iUnixEpochOffset

    ; Создаем структуру FileTime
    Local $tFileTime = DllStructCreate("uint64")
    DllStructSetData($tFileTime, 1, $iFileTime)

    ; Конвертируем FileTime в SystemTime
    Local $tSystemTime = DllStructCreate("ushort Year;ushort Month;ushort DayOfWeek;ushort Day;ushort Hour;ushort Minute;ushort Second;ushort Milliseconds")
    DllCall("kernel32.dll", "bool", "FileTimeToSystemTime", "ptr", DllStructGetPtr($tFileTime), "ptr", DllStructGetPtr($tSystemTime))

    Local $iYear = DllStructGetData($tSystemTime, "Year")
    Local $iMonth = DllStructGetData($tSystemTime, "Month")
    Local $iDay = DllStructGetData($tSystemTime, "Day")
    Local $iHour = DllStructGetData($tSystemTime, "Hour")
    Local $iMinute = DllStructGetData($tSystemTime, "Minute")
    Local $iSecond = DllStructGetData($tSystemTime, "Second")

    ; Форматируем в MySQL DATETIME(3) формат с миллисекундами из UUID
    Return StringFormat("%04d-%02d-%02d %02d:%02d:%02d.%03d", $iYear, $iMonth, $iDay, $iHour, $iMinute, $iSecond, $iMilliseconds)
EndFunc