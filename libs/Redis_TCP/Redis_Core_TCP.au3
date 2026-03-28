#include-once
#include "..\Utils\Utils.au3"


; ===============================================================================
; Redis Core TCP Library v1.1
; Библиотека для работы с Redis через TCP протокол (RESP)
; ===============================================================================
;
; ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ФУНКЦИЙ!
;
; СПИСОК ФУНКЦИЙ:
; ===============================================================================
; ОСНОВНЫЕ ФУНКЦИИ:
; _Redis_Connect($sHost, $iPort)           - Подключение к Redis серверу
; _Redis_ConnectNonBlocking($sHost, $iPort, $iTimeoutMs) - Неблокирующее подключение с таймаутом
; _Redis_Disconnect()                      - Отключение от Redis сервера
; _Redis_Set($sKey, $sValue)              - Установка значения ключа (SET)
; _Redis_Get($sKey)                       - Получение значения ключа (GET)
; _Redis_HSet($sKey, $sField, $sValue)    - Установка поля в хеше (HSET)
; _Redis_HGet($sKey, $sField)             - Получение поля из хеша (HGET)
; _Redis_HGetAll($sKey)                   - Получение всех полей хеша (HGETALL)
;
; БАЗОВЫЕ ФУНКЦИИ УПРАВЛЕНИЯ:
; _Redis_Del($sKeys)                      - Удаление ключей (DEL)
; _Redis_Exists($sKey)                    - Проверка существования ключа (EXISTS)
; _Redis_Expire($sKey, $iSeconds)         - Установка времени жизни (EXPIRE)
; _Redis_TTL($sKey)                       - Получение времени жизни (TTL)
;
; ФУНКЦИИ ПРОИЗВОДИТЕЛЬНОСТИ:
; _Redis_MSet($aKeyValuePairs)            - Массовая установка ключей (MSET)
; _Redis_MGet($aKeys)                     - Массовое получение ключей (MGET)
;
; ФУНКЦИИ ДЛЯ РАБОТЫ С МАССИВАМИ:
; _Redis_SetArray1D($sKey, $aArray)       - Сохранение 1D массива
; _Redis_GetArray1D($sKey)                - Получение 1D массива
; _Redis_SetArray2D($sKey, $aArray)       - Сохранение 2D массива
; _Redis_GetArray2D($sKey)                - Получение 2D массива
; _Redis_SetArray1D_Fast($sPrefix, $aArray) - Быстрое сохранение 1D через MSET
; _Redis_GetArray1D_Fast($sPrefix, $iSize)  - Быстрое получение 1D через MGET
; _Redis_SetArray2D_Fast($sPrefix, $aArray) - Быстрое сохранение 2D через MSET
; _Redis_GetArray2D_Fast($sPrefix)          - Быстрое получение 2D через MGET
;
; ФУНКЦИИ КОЛЬЦЕВОГО БУФЕРА (LIST):
; _Redis_ListPush($sKey, $sValue, $iMaxSize) - Добавление в кольцевой буфер (LPUSH + LTRIM)
; _Redis_ListGet($sKey, $iIndex)          - Получение элемента по индексу (LINDEX)
; _Redis_ListGetAll($sKey)                - Получение всех элементов (LRANGE)
; _Redis_ListSize($sKey)                  - Размер списка (LLEN)
; _Redis_ListClear($sKey)                 - Очистка списка (DEL)
;
; ФУНКЦИИ МОНИТОРИНГА:
; _Redis_Keys($sPattern)                  - Поиск ключей по шаблону (KEYS)
; _Redis_Info($sSection)                  - Информация о сервере (INFO)
; _Redis_Ping()                           - Проверка соединения (PING)
; _Redis_PingNonBlocking($iTimeoutMs)     - Неблокирующая проверка соединения
; _Redis_DBSize()                         - Количество ключей в БД (DBSIZE)
; _Redis_FlushDB()                        - Очистка текущей БД (FLUSHDB)
;
; ФУНКЦИИ СОХРАНЕНИЯ (PERSISTENCE):
; _Redis_Save()                           - Принудительное сохранение на диск (SAVE)
; _Redis_BgSave()                         - Фоновое сохранение на диск (BGSAVE)
; _Redis_LastSave()                       - Время последнего сохранения (LASTSAVE)
;
; ФУНКЦИИ СЧЕТЧИКОВ (COUNTERS):
; _Redis_Incr($sKey)                      - Увеличить значение на 1 (INCR)
; _Redis_IncrBy($sKey, $iValue)           - Увеличить на N (INCRBY)
; _Redis_Decr($sKey)                      - Уменьшить на 1 (DECR)
; _Redis_DecrBy($sKey, $iValue)           - Уменьшить на N (DECRBY)
;
; ВНУТРЕННИЕ ФУНКЦИИ:
; _Redis_SendCommand($aCommand)           - Отправка команды в RESP формате
; _Redis_ReceiveResponse()                - Получение и парсинг ответа (быстрая версия)
; _Redis_ReceiveResponseLarge()           - Надежное получение больших ответов с TCP фрагментацией
; _Redis_ParseRESP($sResponse)            - Оптимизированный парсинг RESP протокола
; _Redis_CheckConnection()                - Быстрая проверка соединения без лишних PING
; ===============================================================================

; Глобальные переменные Redis
Global $g_hRedis_Socket = -1
Global $g_sRedis_Host = "127.0.0.1"
Global $g_iRedis_Port = 6379
Global $g_bRedis_Connected = False

; Дебаг переменная для управления логами Redis
Global $g_bDebug_Redis_Core = False

; ===============================================================================
; Функция: _Redis_Connect
; Описание: Подключение к Redis серверу
; Параметры: $sHost - адрес сервера, $iPort - порт
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_Connect($sHost = "127.0.0.1", $iPort = 6379)
    ; Закрываем предыдущее соединение если есть
    If $g_hRedis_Socket <> -1 Then
        _Redis_Disconnect()
    EndIf

    If $g_bDebug_Redis_Core Then _Logger_Write("🔌 [Redis] Подключение к серверу: " & $sHost & ":" & $iPort, 1)

    ; Инициализируем TCP
    TCPStartup()

    ; Подключаемся к серверу
    $g_hRedis_Socket = TCPConnect($sHost, $iPort)

    If $g_hRedis_Socket = -1 Then
        $g_bRedis_Connected = False
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Ошибка подключения к " & $sHost & ":" & $iPort, 2)
        Return False
    EndIf

    ; Сохраняем параметры подключения
    $g_sRedis_Host = $sHost
    $g_iRedis_Port = $iPort
    $g_bRedis_Connected = True

    If $g_bDebug_Redis_Core Then _Logger_Write("✅ [Redis] Подключение успешно: " & $sHost & ":" & $iPort, 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _Redis_Disconnect
; Описание: Отключение от Redis сервера
; ===============================================================================
Func _Redis_Disconnect()
    If $g_hRedis_Socket <> -1 Then
        TCPCloseSocket($g_hRedis_Socket)
        $g_hRedis_Socket = -1
        If $g_bDebug_Redis_Core Then _Logger_Write("🔌 [Redis] Отключение от сервера", 1)
    EndIf

    $g_bRedis_Connected = False
    TCPShutdown()
EndFunc

; ===============================================================================
; Функция: _Redis_Set
; Описание: Установка значения ключа (команда SET)
; Параметры: $sKey - ключ, $sValue - значение
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_Set($sKey, $sValue)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[3] = ["SET", $sKey, $sValue]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return ($vResponse = "OK")
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_Get
; Описание: Получение значения ключа (команда GET)
; Параметры: $sKey - ключ
; Возврат: Значение ключа или False при ошибке
; ===============================================================================
Func _Redis_Get($sKey)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[2] = ["GET", $sKey]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return $vResponse
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_HSet
; Описание: Установка поля в хеше (команда HSET)
; Параметры: $sKey - ключ хеша, $sField - поле, $sValue - значение
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_HSet($sKey, $sField, $sValue)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[4] = ["HSET", $sKey, $sField, $sValue]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return ($vResponse = 1 Or $vResponse = 0) ; 1 = новое поле, 0 = обновлено
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_HGet
; Описание: Получение поля из хеша (команда HGET)
; Параметры: $sKey - ключ хеша, $sField - поле
; Возврат: Значение поля или False при ошибке
; ===============================================================================
Func _Redis_HGet($sKey, $sField)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[3] = ["HGET", $sKey, $sField]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return $vResponse
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_HGetAll
; Описание: Получение всех полей хеша (команда HGETALL)
; Параметры: $sKey - ключ хеша
; Возврат: Массив полей и значений или False при ошибке
; ===============================================================================
Func _Redis_HGetAll($sKey)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[2] = ["HGETALL", $sKey]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return $vResponse
    EndIf

    Return False
EndFunc

; ===============================================================================
; ВНУТРЕННИЕ ФУНКЦИИ ДЛЯ РАБОТЫ С RESP ПРОТОКОЛОМ
; ===============================================================================

; ===============================================================================
; Функция: _Redis_SendCommand
; Описание: Отправка команды в Redis в формате RESP
; Параметры: $aCommand - массив команды и параметров
; Возврат: True при успехе, False при ошибке
; ===============================================================================
#cs
Func _Redis_SendCommand($aCommand)
    If Not $g_bRedis_Connected Or $g_hRedis_Socket = -1 Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Нет подключения для отправки команды", 2)
        Return False
    EndIf

    ; Формируем RESP команду
    Local $sRESP = "*" & UBound($aCommand) & @CRLF

    For $i = 0 To UBound($aCommand) - 1
        ;Local $bData = StringToBinary($aCommand[$i], 4) ; UTF-8
        ;Local $iLength = BinaryLen($bData)
        Local $iLength = StringLen($aCommand[$i])
        $sRESP &= "$" & $iLength & @CRLF & $aCommand[$i] & @CRLF
    Next

    ; Отправляем команду
    Local $iBytesToSend = StringLen($sRESP)
    Local $iBytesSent = TCPSend($g_hRedis_Socket, $sRESP)

    Return ($iBytesSent = $iBytesToSend)
EndFunc
#ce
Func _Redis_SendCommand($aCommand)
    If Not $g_bRedis_Connected Or $g_hRedis_Socket = -1 Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Нет подключения для отправки команды", 2)
        Return False
    EndIf

    ; Формируем RESP команду
    Local $sRESP = "*" & UBound($aCommand) & @CRLF

    For $i = 0 To UBound($aCommand) - 1
        ; Считаем длину строки именно в UTF-8 байтах (для кириллицы)
        Local $iLength = BinaryLen(StringToBinary($aCommand[$i], 4))

        ; Формируем блок: $ДЛИНА\r\nЗНАЧЕНИЕ\r\n
        $sRESP &= "$" & $iLength & @CRLF & $aCommand[$i] & @CRLF
    Next

    ; Отправляем как UTF-8. Это ключевой момент.
    ; Флаг 4 в StringToBinary делает всю строку совместимой с Redis и ARDM
    Local $bFinalPacket = StringToBinary($sRESP, 4)
    Local $iBytesSent = TCPSend($g_hRedis_Socket, $bFinalPacket)

    Return ($iBytesSent > 0)
EndFunc

; ===============================================================================
; Функция: _Redis_ReceiveResponse
; Описание: Получение ответа от Redis и парсинг RESP (оригинальная быстрая версия)
; Возврат: Ответ от сервера или False при ошибке
; ===============================================================================
#cs
Func _Redis_ReceiveResponse()
    If Not $g_bRedis_Connected Or $g_hRedis_Socket = -1 Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Нет подключения для получения ответа", 2)
        Return False
    EndIf

    Local $sResponse = ""
    Local $iTimeout = 500 ; Возвращаем оригинальный таймаут
    Local $hTimer = TimerInit()

    ; Простая надежная логика чтения
    While TimerDiff($hTimer) < $iTimeout
        Local $sData = TCPRecv($g_hRedis_Socket, 1024)
        If $sData <> "" Then
            $sResponse &= $sData
            ; Проверка завершения ответа
            If StringInStr($sResponse, @CRLF) > 0 Then
                Local $sFirstChar = StringLeft($sResponse, 1)
                ; Для простых ответов
                If $sFirstChar = "+" Or $sFirstChar = "-" Or $sFirstChar = ":" Then
                    If StringRight($sResponse, 2) = @CRLF Then ExitLoop
                EndIf
                ; Для bulk strings
                If $sFirstChar = "$" Then
                    Local $aLines = StringSplit($sResponse, @CRLF, 1)
                    If $aLines[0] >= 2 Then
                        Local $iLength = Int(StringMid($aLines[1], 2))
                        If $iLength = -1 Or ($aLines[0] >= 2 And StringLen($aLines[2]) >= $iLength) Then
                            ExitLoop
                        EndIf
                    EndIf
                EndIf
                ; Для массивов - простая проверка
                If $sFirstChar = "*" Then
                    If StringLen($sResponse) > 10 And StringRight($sResponse, 2) = @CRLF Then
                        ExitLoop
                    EndIf
                EndIf
            EndIf
        EndIf
        Sleep(1) ; ВСЕГДА делаем Sleep(1) как в оригинале
    WEnd

    If $sResponse = "" Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Таймаут получения ответа", 2)
        Return False
    EndIf

    ; Парсим RESP ответ
    Return _Redis_ParseRESP($sResponse)
EndFunc
#ce
Func _Redis_ReceiveResponse()
    If Not $g_hRedis_Socket Then Return False

    Local $bBuffer = Binary("")
    Local $hTimer = TimerInit()
    Local $iTimeout = 1000 ; Увеличим до 1 сек для стабильности

    While TimerDiff($hTimer) < $iTimeout
        ; Читаем как Binary (флаг 1)
        Local $bChunk = TCPRecv($g_hRedis_Socket, 8192, 1)
        If @error Then Return False

        If BinaryLen($bChunk) > 0 Then
            $bBuffer &= $bChunk
            ; Если в конце буфера есть CRLF, пробуем парсить
            If BinaryLen($bBuffer) >= 2 Then
                Local $sEnd = BinaryToString(BinaryMid($bBuffer, BinaryLen($bBuffer) - 1), 4)
                If StringInStr($sEnd, @LF) Then ExitLoop
            EndIf
        EndIf
        Sleep(1)
    WEnd

    If BinaryLen($bBuffer) = 0 Then Return False

    ; Передаем бинарные данные в парсер
    Return _Redis_ParseRESP($bBuffer)
EndFunc

; ===============================================================================
; Функция: _Redis_ReceiveResponseLarge
; Описание: Надежное получение больших ответов с TCP фрагментацией (исправлена логика)
; Возврат: Ответ от сервера или False при ошибке
; ===============================================================================
#cs
Func _Redis_ReceiveResponseLarge()
    If Not $g_bRedis_Connected Or $g_hRedis_Socket = -1 Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Нет подключения для получения большого ответа", 2)
        Return False
    EndIf

    Local $sBuffer = ""
    Local $iTimeout = 5000 ; Больший таймаут для больших данных
    Local $hTimer = TimerInit()
    Local $iExpectedCount = -1
    Local $bHeaderParsed = False

    ; Читаем данные в цикле с умной проверкой завершенности
    While TimerDiff($hTimer) < $iTimeout
        ; Увеличенный буфер 64КБ для скорости
        Local $sChunk = TCPRecv($g_hRedis_Socket, 65536)
        If @error Then
            If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Ошибка чтения TCP данных", 2)
            Return SetError(1, 0, False)
        EndIf

        If $sChunk <> "" Then
            $sBuffer &= $sChunk

            ; Парсим заголовок массива для определения ожидаемого количества элементов
            If Not $bHeaderParsed And StringLeft($sBuffer, 1) = "*" Then
                Local $iCRLF = StringInStr($sBuffer, @CRLF)
                If $iCRLF > 0 Then
                    $iExpectedCount = Int(StringMid($sBuffer, 2, $iCRLF - 2))
                    $bHeaderParsed = True
                EndIf
            EndIf

            ; Если это не массив - используем простую проверку
            If Not $bHeaderParsed And StringRight($sBuffer, 2) = @CRLF Then
                ExitLoop
            EndIf

            ; Для массивов - проверяем количество CRLF
            If $bHeaderParsed And $iExpectedCount > 0 Then
                ; Подсчитываем CRLF: заголовок(1) + каждый элемент(2) = 1 + count*2
                Local $iCRLFCount = 0
                StringReplace($sBuffer, @CRLF, "")
                $iCRLFCount = @extended

                If $iCRLFCount >= ($iExpectedCount * 2 + 1) Then
                    ExitLoop
                EndIf
            EndIf
        Else
            ; ВАЖНО: Всегда ждем если нет данных, чтобы дать время TCP пакетам прийти
            Sleep(1)
        EndIf
    WEnd

    If $sBuffer = "" Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Таймаут получения больших данных", 2)
        Return SetError(2, 0, False)
    EndIf

    ; Парсим RESP ответ
    Return _Redis_ParseRESP($sBuffer)
EndFunc
#ce
Func _Redis_ReceiveResponseLarge()
    If Not $g_bRedis_Connected Or $g_hRedis_Socket = -1 Then Return False

    Local $bTotalBuffer = Binary("")
    Local $iTimeout = 5000
    Local $hTimer = TimerInit()
    Local $iExpectedCount = -1
    Local $bIsArray = False

    While TimerDiff($hTimer) < $iTimeout
        Local $bChunk = TCPRecv($g_hRedis_Socket, 262144, 1) ; Читаем сразу по 256КБ
        If @error Then ExitLoop

        If BinaryLen($bChunk) > 0 Then
            $bTotalBuffer &= $bChunk

            ; Если заголовок ещё не разобран — пытаемся понять, что мы качаем
            If $iExpectedCount = -1 Then
                Local $sStart = BinaryToString(BinaryMid($bTotalBuffer, 1, 64), 4)
                If StringLeft($sStart, 1) = "*" Then
                    $bIsArray = True
                    Local $iCRLF = StringInStr($sStart, @CRLF)
                    If $iCRLF > 0 Then
                        $iExpectedCount = Int(StringMid($sStart, 2, $iCRLF - 2))
                    EndIf
                ElseIf StringInStr($sStart, @CRLF) Then
                    ; Это не массив (например, OK или ошибка), выходим сразу
                    ExitLoop
                EndIf
            EndIf

            ; ГЛАВНАЯ ОПТИМИЗАЦИЯ:
            ; Если это массив, проверяем, заканчивается ли буфер на CRLF
            ; Для небольших массивов (Fast) это позволит выйти мгновенно.
            If $bIsArray And BinaryLen($bTotalBuffer) > 20 Then
                If BinaryToString(BinaryMid($bTotalBuffer, BinaryLen($bTotalBuffer) - 1, 2), 4) = @CRLF Then
                    ; Для супер-точности на больших данных можно оставить небольшую паузу "добора",
                    ; но для скорости 1000 ключей — выходим, если пакет кажется полным.
                    ExitLoop
                EndIf
            EndIf
        Else
            ; Если данных в сокете нет — микропауза, чтобы не грузить CPU
            If BinaryLen($bTotalBuffer) > 0 Then ExitLoop ; Данные закончились — уходим!
            Sleep(1)
        EndIf
    WEnd

    Return _Redis_ParseRESP($bTotalBuffer)
EndFunc
; ===============================================================================
; Функция: _Redis_IsLargeArrayComplete
; ===============================================================================
; Функция: _Redis_ParseRESP
; Описание: Оптимизированный парсинг RESP протокола (быстрый парсинг массивов)
; Параметры: $sResponse - сырой ответ от сервера
; Возврат: Обработанный ответ
; ===============================================================================
#cs
Func _Redis_ParseRESP($sResponse)
    Local $sFirstChar = StringLeft($sResponse, 1)

    Switch $sFirstChar
        Case "+"  ; Simple String
            Return StringMid($sResponse, 2, StringLen($sResponse) - 3)
        Case "-"  ; Error
            Return False
        Case ":"  ; Integer
            Return Int(StringMid($sResponse, 2, StringLen($sResponse) - 3))
        Case "$"  ; Bulk String
            Local $aLines = StringSplit($sResponse, @CRLF, 1)
            If $aLines[0] < 2 Then Return False

            Local $iLength = Int(StringMid($aLines[1], 2))
            If $iLength = -1 Then Return False ; NULL
            If $iLength = 0 Then Return ""  ; Empty string

            If $aLines[0] >= 2 Then
                Return $aLines[2]
            EndIf
            Return ""
        Case "*"  ; Array - ОПТИМИЗИРОВАННЫЙ парсинг без промежуточного массива
            Local $iFirstCRLF = StringInStr($sResponse, @CRLF)
            If $iFirstCRLF = 0 Then Return False

            Local $iArraySize = Int(StringMid($sResponse, 2, $iFirstCRLF - 2))
            If $iArraySize = 0 Then
                Local $aEmpty[0]
                Return $aEmpty
            EndIf
            If $iArraySize = -1 Then Return False

            Local $aResult[$iArraySize]
            Local $iPos = $iFirstCRLF + 2 ; Начинаем после заголовка

            ; Парсим элементы без StringSplit - навигация по строке
            For $i = 0 To $iArraySize - 1
                ; Ищем начало элемента ($)
                Local $iDollarPos = StringInStr($sResponse, "$", 0, 1, $iPos)
                If $iDollarPos = 0 Then ExitLoop

                ; Ищем CRLF после длины
                Local $iLengthCRLF = StringInStr($sResponse, @CRLF, 0, 1, $iDollarPos)
                If $iLengthCRLF = 0 Then ExitLoop

                ; Получаем длину элемента
                Local $iElementLength = Int(StringMid($sResponse, $iDollarPos + 1, $iLengthCRLF - $iDollarPos - 1))

                If $iElementLength = -1 Then
                    ; NULL элемент
                    $aResult[$i] = ""
                    $iPos = $iLengthCRLF + 2
                ElseIf $iElementLength = 0 Then
                    ; Пустой элемент
                    $aResult[$i] = ""
                    $iPos = $iLengthCRLF + 4 ; +2 для CRLF после длины, +2 для CRLF после пустых данных
                Else
                    ; Обычный элемент с данными
                    Local $iDataStart = $iLengthCRLF + 2
                    $aResult[$i] = StringMid($sResponse, $iDataStart, $iElementLength)
                    $iPos = $iDataStart + $iElementLength + 2 ; +2 для CRLF после данных
                EndIf
            Next

            Return $aResult
    EndSwitch

    Return False
EndFunc
#ce

Func _Redis_ParseRESP($bResponse)
    Local $sHeader = BinaryToString(BinaryMid($bResponse, 1, 1), 4)

    Switch $sHeader
        Case "+" ; Simple String
            Local $sFull = BinaryToString($bResponse, 4)
            Return StringStripWS(StringMid($sFull, 2), 3) ; Убираем CRLF

        Case "-" ; Error
            If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Ошибка сервера: " & BinaryToString($bResponse, 4), 2)
            Return False

        Case ":" ; Integer (ИСПРАВЛЕНО: теперь возвращает число, а не строку)
            Local $sFull = BinaryToString($bResponse, 4)
            Return Int(StringMid($sFull, 2))

        Case "$" ; Bulk String
            Local $sFullHeader = BinaryToString($bResponse, 4)
            Local $aLines = StringSplit($sFullHeader, @CRLF, 1)
            Local $iDataLen = Int(StringMid($aLines[1], 2))

            If $iDataLen = -1 Then Return False ; NULL
            If $iDataLen = 0 Then Return ""

            Local $iFirstCRLF = StringInStr($sFullHeader, @CRLF)
            Local $bData = BinaryMid($bResponse, $iFirstCRLF + 2, $iDataLen)
            Return BinaryToString($bData, 4)

   Case "*" ; Array - Исправленная логика смещений
            Local $sFullBuffer = BinaryToString($bResponse, 4)
            Local $iFirstCRLF = StringInStr($sFullBuffer, @CRLF)
            Local $iCount = Int(StringMid($sFullBuffer, 2, $iFirstCRLF - 2))

            If $iCount < 0 Then Return False
            If $iCount = 0 Then
                Local $aEmpty[0]
                Return $aEmpty
            EndIf

            Local $aResult[$iCount]
            ; Начинаем сразу после заголовка массива *<count>\r\n
            Local $iByteOffset = $iFirstCRLF + 2

            For $i = 0 To $iCount - 1
                ; Читаем небольшой кусок для парсинга заголовка элемента ($<len>\r\n)
                Local $bHeaderPart = BinaryMid($bResponse, $iByteOffset, 32)
                Local $sHeaderPart = BinaryToString($bHeaderPart, 4)
                Local $iNextCRLF = StringInStr($sHeaderPart, @CRLF)

                If $iNextCRLF = 0 Then ExitLoop ; Данные прерваны

                Local $iElemLen = Int(StringMid($sHeaderPart, 2, $iNextCRLF - 2))

                ; Сдвигаем указатель за пределы заголовка элемента ($12\r\n)
                $iByteOffset += $iNextCRLF + 1 ; +1 т.к. CRLF это 2 байта, а StringInStr дает позицию начала \r

                If $iElemLen > -1 Then
                    If $iElemLen > 0 Then
                        ; Забираем данные строго по байтам
                        $aResult[$i] = BinaryToString(BinaryMid($bResponse, $iByteOffset, $iElemLen), 4)
                        $iByteOffset += $iElemLen + 2 ; Пропускаем данные и завершающий CRLF
                    Else
                        $aResult[$i] = ""
                        $iByteOffset += 2 ; Только CRLF
                    EndIf
                Else
                    $aResult[$i] = "" ; NULL элемент
                    ; В RESP NULL это $-1\r\n, смещение уже сдвинуто на длину заголовка
                EndIf
            Next
            Return $aResult
    EndSwitch
    Return False
EndFunc
; ===============================================================================
; Функция: _Redis_CheckConnection
; Описание: Быстрая проверка соединения (без лишних PING запросов)
; Возврат: True если соединение активно
; ===============================================================================
Func _Redis_CheckConnection()
    Return _Redis_PingNonBlocking(5)

    If Not $g_bRedis_Connected Then
        ; Пытаемся переподключиться
        If $g_bDebug_Redis_Core Then _Logger_Write("🔄 [Redis] Попытка переподключения...", 1)
        Return _Redis_Connect($g_sRedis_Host, $g_iRedis_Port)
    EndIf

    ; Проверяем соединение командой PING (нужно для поддержания активности)
    Local $aCommand[1] = ["PING"]
    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        If $vResponse = "PONG" Then
            Return True
        EndIf
    EndIf

    ; Соединение потеряно, переподключаемся
    $g_bRedis_Connected = False
    If $g_bDebug_Redis_Core Then _Logger_Write("⚠️ [Redis] Соединение потеряно, переподключение...", 2)
    Return _Redis_Connect($g_sRedis_Host, $g_iRedis_Port)
EndFunc
; ===============================================================================
; БАЗОВЫЕ ФУНКЦИИ УПРАВЛЕНИЯ
; ===============================================================================

; ===============================================================================
; Функция: _Redis_Del
; Описание: Удаление одного или нескольких ключей (команда DEL)
; Параметры: $sKeys - ключ или массив ключей для удаления
; Возврат: Количество удаленных ключей или False при ошибке
; ===============================================================================
Func _Redis_Del($sKeys)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand ; Объявляем переменную

    If IsArray($sKeys) Then
        ; Массив ключей: создаём массив нужного размера СРАЗУ
        ; Используем Dim или Local с указанием размера вместо ReDim для пустой переменной
        Local $aCommand[UBound($sKeys) + 1]
        $aCommand[0] = "DEL"
        For $i = 0 To UBound($sKeys) - 1
            $aCommand[$i + 1] = $sKeys[$i]
        Next
    Else
        ; Один ключ: просто создаём массив из 2 элементов
        Dim $aCommand[2] = ["DEL", $sKeys]
    EndIf

    ; Проверяем, удалось ли нам сформировать массив перед отправкой
    If Not IsArray($aCommand) Then Return False

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        If $g_bDebug_Redis_Core Then _Logger_Write("🗑️ [Redis] DEL: Удалено ключей: " & $vResponse, 1)
        Return Int($vResponse)
    EndIf

    Return False
EndFunc
; ===============================================================================
; Функция: _Redis_Exists
; Описание: Проверка существования ключа (команда EXISTS)
; Параметры: $sKey - ключ для проверки
; Возврат: True если существует, False если нет или ошибка
; ===============================================================================
Func _Redis_Exists($sKey)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[2] = ["EXISTS", $sKey]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return (Int($vResponse) = 1)
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_Expire
; Описание: Установка времени жизни ключа в секундах (команда EXPIRE)
; Параметры: $sKey - ключ, $iSeconds - время жизни в секундах
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_Expire($sKey, $iSeconds)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[3] = ["EXPIRE", $sKey, String($iSeconds)]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return (Int($vResponse) = 1)
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_TTL
; Описание: Получение оставшегося времени жизни ключа (команда TTL)
; Параметры: $sKey - ключ
; Возврат: Время в секундах, -1 если без TTL, -2 если ключ не существует
; ===============================================================================
Func _Redis_TTL($sKey)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[2] = ["TTL", $sKey]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return Int($vResponse)
    EndIf

    Return False
EndFunc

; ===============================================================================
; ФУНКЦИИ ПРОИЗВОДИТЕЛЬНОСТИ
; ===============================================================================

; ===============================================================================
; Функция: _Redis_MSet
; Описание: Массовая установка ключей (команда MSET)
; Параметры: $aKeyValuePairs - массив пар [ключ1, значение1, ключ2, значение2, ...]
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_MSet($aKeyValuePairs)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    ; Проверяем что массив четный (пары ключ-значение)
    If Mod(UBound($aKeyValuePairs), 2) <> 0 Then
        Return False
    EndIf

    ; Формируем команду
    Local $aCommand[UBound($aKeyValuePairs) + 1]
    $aCommand[0] = "MSET"
    For $i = 0 To UBound($aKeyValuePairs) - 1
        $aCommand[$i + 1] = $aKeyValuePairs[$i]
    Next

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return ($vResponse = "OK")
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_MGet
; Описание: Массовое получение значений ключей (команда MGET)
; Параметры: $aKeys - массив ключей
; Возврат: Массив значений или False при ошибке
; ===============================================================================
#cs
Func _Redis_MGet($aKeys)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    ; Формируем команду
    Local $aCommand[UBound($aKeys) + 1]
    $aCommand[0] = "MGET"
    For $i = 0 To UBound($aKeys) - 1
        $aCommand[$i + 1] = $aKeys[$i]
    Next

    If _Redis_SendCommand($aCommand) Then
        ; Для больших массивов (>100 ключей) используем специальную функцию
        Local $vResponse
        If UBound($aKeys) > 100 Then
            $vResponse = _Redis_ReceiveResponseLarge()
        Else
            $vResponse = _Redis_ReceiveResponse()
        EndIf
        Return $vResponse
    EndIf

    Return False
EndFunc
#ce
Func _Redis_MGet($aKeys)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    ; Формируем команду MGET key1 key2 ...
    Local $iCount = UBound($aKeys)
    Local $aCommand[$iCount + 1]
    $aCommand[0] = "MGET"
    For $i = 0 To $iCount - 1
        $aCommand[$i + 1] = $aKeys[$i]
    Next

    If _Redis_SendCommand($aCommand) Then
        ; Если ключей много, используем буферизированный прием
        If $iCount > 100 Then
            Return _Redis_ReceiveResponseLarge()
        Else
            Return _Redis_ReceiveResponse()
        EndIf
    EndIf

    Return False
EndFunc
; ===============================================================================
; ФУНКЦИИ ДЛЯ РАБОТЫ С МАССИВАМИ
; ===============================================================================

; ===============================================================================
; Функция: _Redis_SetArray1D
; Описание: Сохранение одномерного массива в Redis через MSET
; Параметры: $sKey - базовый ключ, $aArray - одномерный массив
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_SetArray1D($sKey, $aArray, $sDelimiter = "|")
    If Not IsArray($aArray) Then
        Return False
    EndIf

    ; Используем один ключ со строкой (как было) для совместимости
    Local $sArrayString = _Utils_ArrayToString($aArray, $sDelimiter)
    Return _Redis_Set($sKey, $sArrayString)
EndFunc

; ===============================================================================
; Функция: _Redis_GetArray1D
; Описание: Получение одномерного массива из Redis
; Параметры: $sKey - ключ, $sDelimiter - разделитель
; Возврат: Массив или False при ошибке
; ===============================================================================
Func _Redis_GetArray1D($sKey, $sDelimiter = "|")
    Local $hGetTimer = _Utils_GetTimestamp()
    Local $sArrayString = _Redis_Get($sKey)
    Local $iGetTime = _Utils_GetElapsedTime($hGetTimer)

    If $sArrayString = False Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Ошибка получения массива 1D: " & $sKey, 2)
        Return False
    EndIf

    Local $hParseTimer = _Utils_GetTimestamp()
    Local $aResult = _Utils_StringToArray($sArrayString, $sDelimiter)
    ; Убираем первый элемент (счетчик от StringSplit)
    If IsArray($aResult) And $aResult[0] > 0 Then
        Local $aFinalResult[$aResult[0]]
        For $i = 0 To $aResult[0] - 1
            $aFinalResult[$i] = $aResult[$i + 1]
        Next
        Local $iParseTime = _Utils_GetElapsedTime($hParseTimer)
        If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG 1D: GET " & Int($iGetTime) & "мс, парсинг " & Int($iParseTime) & "мс", 1)
        Return $aFinalResult
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_SetArray2D
; Описание: Сохранение двумерного массива в Redis
; Параметры: $sKey - ключ, $aArray - двумерный массив, $sRowDelim - разделитель строк, $sColDelim - разделитель столбцов
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_SetArray2D($sKey, $aArray, $sRowDelim = "||", $sColDelim = "|")
    If Not IsArray($aArray) Then
        Return False
    EndIf

    Local $sArrayString = ""
    Local $iRows = UBound($aArray, 1)
    Local $iCols = UBound($aArray, 2)

    ; Добавляем размеры массива в начало
    $sArrayString = $iRows & "x" & $iCols & $sRowDelim

    For $i = 0 To $iRows - 1
        For $j = 0 To $iCols - 1
            $sArrayString &= $aArray[$i][$j]
            If $j < $iCols - 1 Then $sArrayString &= $sColDelim
        Next
        If $i < $iRows - 1 Then $sArrayString &= $sRowDelim
    Next

    Return _Redis_Set($sKey, $sArrayString)
EndFunc

; ===============================================================================
; Функция: _Redis_GetArray2D
; Описание: Получение двумерного массива из Redis
; Параметры: $sKey - ключ, $sRowDelim - разделитель строк, $sColDelim - разделитель столбцов
; Возврат: Двумерный массив или False при ошибке
; ===============================================================================
Func _Redis_GetArray2D($sKey, $sRowDelim = "||", $sColDelim = "|")
    Local $hGetTimer = _Utils_GetTimestamp()
    Local $sArrayString = _Redis_Get($sKey)
    Local $iGetTime = _Utils_GetElapsedTime($hGetTimer)

    If $sArrayString = False Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Ошибка получения массива 2D: " & $sKey, 2)
        Return False
    EndIf

    Local $hParseTimer = _Utils_GetTimestamp()
    Local $aRows = StringSplit($sArrayString, $sRowDelim, 1)
    If $aRows[0] < 2 Then
        Return False
    EndIf

    ; Парсим размеры из первой строки
    Local $aSizes = StringSplit($aRows[1], "x", 1)
    If $aSizes[0] <> 2 Then
        Return False
    EndIf

    Local $iRows = Int($aSizes[1])
    Local $iCols = Int($aSizes[2])
    Local $aResult[$iRows][$iCols]

    ; Заполняем массив
    For $i = 0 To $iRows - 1
        If ($i + 2) <= $aRows[0] Then
            Local $aCols = StringSplit($aRows[$i + 2], $sColDelim, 1)
            For $j = 0 To $iCols - 1
                If ($j + 1) <= $aCols[0] Then
                    $aResult[$i][$j] = $aCols[$j + 1]
                EndIf
            Next
        EndIf
    Next

    Local $iParseTime = _Utils_GetElapsedTime($hParseTimer)
    If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG 2D: GET " & Int($iGetTime) & "мс, парсинг " & Int($iParseTime) & "мс", 1)

    Return $aResult
EndFunc
; ===============================================================================
; ФУНКЦИИ МОНИТОРИНГА
; ===============================================================================

; ===============================================================================
; Функция: _Redis_Keys
; Описание: Поиск ключей по шаблону (команда KEYS)
; Параметры: $sPattern - шаблон поиска (* для всех ключей)
; Возврат: Массив ключей или False при ошибке
; ===============================================================================
Func _Redis_Keys($sPattern = "*")
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[2] = ["KEYS", $sPattern]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return $vResponse
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_Info
; Описание: Получение информации о сервере Redis (команда INFO)
; Параметры: $sSection - секция информации (server, memory, stats, etc.)
; Возврат: Строка с информацией или False при ошибке
; ===============================================================================
Func _Redis_Info($sSection = "")
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand
    If $sSection = "" Then
        Local $aCommand[1] = ["INFO"]
    Else
        Local $aCommand[2] = ["INFO", $sSection]
    EndIf

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return $vResponse
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_Ping
; Описание: Проверка соединения с сервером (команда PING)
; Возврат: True если сервер отвечает, False при ошибке
; ===============================================================================
Func _Redis_Ping()
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[1] = ["PING"]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return ($vResponse = "PONG")
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_DBSize
; Описание: Получение количества ключей в текущей БД (команда DBSIZE)
; Возврат: Количество ключей или False при ошибке
; ===============================================================================
Func _Redis_DBSize()
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[1] = ["DBSIZE"]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return Int($vResponse)
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_FlushDB
; Описание: Очистка текущей базы данных (команда FLUSHDB)
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_FlushDB()
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[1] = ["FLUSHDB"]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return ($vResponse = "OK")
    EndIf

    Return False
EndFunc
; ===============================================================================
; Функция: _Redis_SetArray1D_Fast
; Описание: Быстрое сохранение одномерного массива через MSET (каждый элемент = отдельный ключ)
; Параметры: $sKeyPrefix - префикс ключей, $aArray - одномерный массив
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_SetArray1D_Fast($sKeyPrefix, $aArray)
    If Not IsArray($aArray) Then
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] SetArray1D_Fast: Параметр не является массивом", 2)
        Return False
    EndIf

    ; Формируем массив для MSET: [ключ0, значение0, ключ1, значение1, ...]
    Local $aMSetData[UBound($aArray) * 2]
    For $i = 0 To UBound($aArray) - 1
        $aMSetData[$i * 2] = $sKeyPrefix & ":" & $i
        $aMSetData[$i * 2 + 1] = $aArray[$i]
    Next

    If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG SetArray1D_Fast: Сохраняем " & UBound($aArray) & " элементов, первый ключ: " & $aMSetData[0], 1)

    Local $bResult = _Redis_MSet($aMSetData)
    If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG SetArray1D_Fast: MSET результат: " & $bResult, 1)

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Redis_GetArray1D_Fast
; Описание: Быстрое получение одномерного массива через MGET
; Параметры: $sKeyPrefix - префикс ключей, $iSize - размер массива
; Возврат: Массив или False при ошибке
; ===============================================================================
Func _Redis_GetArray1D_Fast($sKeyPrefix, $iSize)
    ; Формируем массив ключей для MGET
    Local $aKeys[$iSize]
    For $i = 0 To $iSize - 1
        $aKeys[$i] = $sKeyPrefix & ":" & $i
    Next

    If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG GetArray1D_Fast: Запрашиваем " & $iSize & " ключей", 1)

    Local $hGetTimer = _Utils_GetTimestamp()
    Local $aResult = _Redis_MGet($aKeys)
    Local $iGetTime = _Utils_GetElapsedTime($hGetTimer)

    If IsArray($aResult) Then
        Local $iEmptyCount = 0
        For $i = 0 To UBound($aResult) - 1
            If $aResult[$i] = "" Then $iEmptyCount += 1
        Next
        If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG GetArray1D_Fast: Получено " & UBound($aResult) & " элементов, пустых: " & $iEmptyCount, 1)
    EndIf

    If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG 1D_Fast: MGET " & Int($iGetTime) & "мс, парсинг 0мс", 1)

    Return $aResult
EndFunc

; ===============================================================================
; Функция: _Redis_SetArray2D_Fast
; Описание: Быстрое сохранение двумерного массива через MSET
; Параметры: $sKeyPrefix - префикс ключей, $aArray - двумерный массив
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_SetArray2D_Fast($sKeyPrefix, $aArray)
    If Not IsArray($aArray) Then
        Return False
    EndIf

    Local $iRows = UBound($aArray, 1)
    Local $iCols = UBound($aArray, 2)

    ; Формируем массив для MSET
    Local $aMSetData[($iRows * $iCols + 1) * 2] ; +1 для метаданных

    ; Сохраняем метаданные (размеры)
    $aMSetData[0] = $sKeyPrefix & ":meta"
    $aMSetData[1] = $iRows & "x" & $iCols

    ; Сохраняем элементы массива
    Local $iIndex = 2
    For $i = 0 To $iRows - 1
        For $j = 0 To $iCols - 1
            $aMSetData[$iIndex] = $sKeyPrefix & ":" & $i & ":" & $j
            $aMSetData[$iIndex + 1] = $aArray[$i][$j]
            $iIndex += 2
        Next
    Next

    Return _Redis_MSet($aMSetData)
EndFunc

; ===============================================================================
; Функция: _Redis_GetArray2D_Fast
; Описание: Быстрое получение двумерного массива через MGET
; Параметры: $sKeyPrefix - префикс ключей
; Возврат: Двумерный массив или False при ошибке
; ===============================================================================
Func _Redis_GetArray2D_Fast($sKeyPrefix)
    ; Сначала получаем метаданные
    Local $sMeta = _Redis_Get($sKeyPrefix & ":meta")
    If $sMeta = False Then
        Return False
    EndIf

    ; Парсим размеры
    Local $aSizes = StringSplit($sMeta, "x", 1)
    If $aSizes[0] <> 2 Then
        Return False
    EndIf

    Local $iRows = Int($aSizes[1])
    Local $iCols = Int($aSizes[2])

    ; Формируем массив ключей для MGET
    Local $aKeys[$iRows * $iCols]
    Local $iIndex = 0
    For $i = 0 To $iRows - 1
        For $j = 0 To $iCols - 1
            $aKeys[$iIndex] = $sKeyPrefix & ":" & $i & ":" & $j
            $iIndex += 1
        Next
    Next

    Local $hGetTimer = _Utils_GetTimestamp()
    Local $aValues = _Redis_MGet($aKeys)
    Local $iGetTime = _Utils_GetElapsedTime($hGetTimer)

    If Not IsArray($aValues) Then
        Return False
    EndIf

    ; Восстанавливаем двумерный массив
    Local $hParseTimer = _Utils_GetTimestamp()
    Local $aResult[$iRows][$iCols]
    $iIndex = 0
    For $i = 0 To $iRows - 1
        For $j = 0 To $iCols - 1
            $aResult[$i][$j] = $aValues[$iIndex]
            $iIndex += 1
        Next
    Next
    Local $iParseTime = _Utils_GetElapsedTime($hParseTimer)

    If $g_bDebug_Redis_Core Then _Logger_Write("🔧 [Redis] DEBUG 2D_Fast: MGET " & Int($iGetTime) & "мс, парсинг " & Int($iParseTime) & "мс", 1)

    Return $aResult
EndFunc

; ===============================================================================
; ФУНКЦИИ КОЛЬЦЕВОГО БУФЕРА (LIST)
; ===============================================================================

; ===============================================================================
; Функция: _Redis_ListPush
; Описание: Добавление элемента в кольцевой буфер (LPUSH + LTRIM)
; Параметры: $sKey - ключ списка, $sValue - значение, $iMaxSize - максимальный размер буфера
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_ListPush($sKey, $sValue, $iMaxSize = 100)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    ; Добавляем элемент в начало списка (LPUSH)
    Local $aCommand[3] = ["LPUSH", $sKey, $sValue]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        If $vResponse <> False Then
            ; Обрезаем список до максимального размера (LTRIM)
            Local $aTrimCommand[4] = ["LTRIM", $sKey, "0", String($iMaxSize - 1)]
            If _Redis_SendCommand($aTrimCommand) Then
                Local $vTrimResponse = _Redis_ReceiveResponse()
                If $g_bDebug_Redis_Core Then _Logger_Write("📝 [Redis] ListPush: Добавлен элемент в список " & $sKey & ", размер: " & $vResponse, 1)
                Return ($vTrimResponse <> False)
            EndIf
        EndIf
    EndIf

    If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Ошибка добавления в список: " & $sKey, 2)
    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_ListGet
; Описание: Получение элемента по индексу (LINDEX)
; Параметры: $sKey - ключ списка, $iIndex - индекс (0 = первый элемент)
; Возврат: Значение элемента или False при ошибке
; ===============================================================================
Func _Redis_ListGet($sKey, $iIndex = 0)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[3] = ["LINDEX", $sKey, String($iIndex)]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return $vResponse
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_ListGetAll
; Описание: Получение всех элементов списка (LRANGE)
; Параметры: $sKey - ключ списка
; Возврат: Массив элементов или False при ошибке
; ===============================================================================
Func _Redis_ListGetAll($sKey)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[4] = ["LRANGE", $sKey, "0", "-1"]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        If IsArray($vResponse) Then
            Return $vResponse
        EndIf
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_FormatCommand
; Описание: Форматирует массив в строку протокола RESP без отправки в сокет
; ===============================================================================
Func _Redis_FormatCommand(ByRef $aCommand)
    Local $iCount = UBound($aCommand)
    Local $sRes = "*" & $iCount & @CRLF
    For $i = 0 To $iCount - 1
        Local $sVal = String($aCommand[$i])
        $sRes &= "$" & StringLen($sVal) & @CRLF & $sVal & @CRLF
    Next
    Return $sRes
EndFunc
; ===============================================================================
; Функция: _Redis_ListPush_Fast
; Описание: Оптимизированная версия. Отправляет LPUSH и LTRIM одним пакетом.
; ===============================================================================
; ===============================================================================
; Функция: _Redis_ListPush_Fast
; Описание: Максимально быстрая отправка LPUSH + LTRIM.
; Читаем только один ответ, чтобы не ловить таймауты сокета.
; ===============================================================================
Func _Redis_ListPush_Fast($sKey, $sValue, $iMaxSize = 100)
    If Not _Redis_CheckConnection() Then Return False

    ; Подготовка массивов команд (каноничный синтаксис AutoIt)
    Local $aPush[3] = ["LPUSH", $sKey, $sValue]
    Local $aTrim[4] = ["LTRIM", $sKey, "0", String($iMaxSize - 1)]

    ; Склеиваем команды в один поток RESP
    Local $sCmds = _Redis_FormatCommand($aPush) & _Redis_FormatCommand($aTrim)

    ; Отправляем одним пакетом
    If TCPSend($g_hRedis_Socket, StringToBinary($sCmds, 4)) = 0 Then Return False

    ; Читаем только первый ответ (результат LPUSH)
    ; Этого достаточно, чтобы подтвердить, что транзакция ушла в работу
    Local $vResp = _Redis_ReceiveResponse()

    Return ($vResp <> False)
EndFunc
; ===============================================================================
; Функция: _Redis_ListGetAll_Fast
; Описание: Быстрое получение списка (просто обертка для ясности)
; ===============================================================================
Func _Redis_ListGetAll_Fast($sKey)
    If Not _Redis_CheckConnection() Then Return False

    Local $aCommand[4] = ["LRANGE", $sKey, "0", "-1"]

    If _Redis_SendCommand($aCommand) Then
        ; Используем стандартный парсер.
        ; Он отработает мгновенно, так как весь RESP-массив прилетит в одном пакете.
        Return _Redis_ReceiveResponse()
    EndIf

    Return False
EndFunc
; ===============================================================================
; Функция: _Redis_ListSize
; Описание: Получение размера списка (LLEN)
; Параметры: $sKey - ключ списка
; Возврат: Количество элементов или -1 при ошибке
; ===============================================================================
Func _Redis_ListSize($sKey)
    If Not _Redis_CheckConnection() Then
        Return -1
    EndIf

    Local $aCommand[2] = ["LLEN", $sKey]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        If IsNumber($vResponse) Then
            Return $vResponse
        EndIf
    EndIf

    Return -1
EndFunc

; ===============================================================================
; Функция: _Redis_ListClear
; Описание: Очистка списка (DEL)
; Параметры: $sKey - ключ списка
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_ListClear($sKey)
    Return _Redis_Del($sKey) > 0
EndFunc
; ===============================================================================
; Функция: _Redis_ConnectNonBlocking
; Описание: Неблокирующее подключение к Redis с таймаутом
; Параметры: $sHost - хост, $iPort - порт, $iTimeoutMs - таймаут в мс
; Возврат: True при успехе, False при ошибке или таймауте
; ===============================================================================
Func _Redis_ConnectNonBlocking($sHost = "127.0.0.1", $iPort = 6379, $iTimeoutMs = 10)
    ; Отключаемся если уже подключены
    If $g_bRedis_Connected Then
        _Redis_Disconnect()
    EndIf

    If $g_bDebug_Redis_Core Then _Logger_Write("🔌 [Redis] Неблокирующее подключение к: " & $sHost & ":" & $iPort & " (таймаут: " & $iTimeoutMs & "мс)", 1)

    ; Инициализируем TCP
    TCPStartup()

    ; Засекаем время
    Local $hStartTime = TimerInit()

    ; Пытаемся подключиться
    $g_hRedis_Socket = TCPConnect($sHost, $iPort)

    ; Проверяем результат с таймаутом
    While $g_hRedis_Socket = -1 And TimerDiff($hStartTime) < $iTimeoutMs
        Sleep(1)
        $g_hRedis_Socket = TCPConnect($sHost, $iPort)
    WEnd

    If $g_hRedis_Socket <> -1 Then
        $g_sRedis_Host = $sHost
        $g_iRedis_Port = $iPort
        $g_bRedis_Connected = True
        If $g_bDebug_Redis_Core Then _Logger_Write("✅ [Redis] Неблокирующее подключение успешно", 3)
        Return True
    Else
        TCPShutdown()
        If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] Таймаут неблокирующего подключения", 2)
        Return False
    EndIf
EndFunc
; ===============================================================================
; Функция: _Redis_PingNonBlocking
; Описание: Неблокирующая проверка соединения с таймаутом
; Параметры: $iTimeoutMs - таймаут в мс
; Возврат: True если сервер отвечает, False при ошибке или таймауте
; ===============================================================================
Func _Redis_PingNonBlocking($iTimeoutMs = 10)
    If Not $g_bRedis_Connected Or $g_hRedis_Socket = -1 Then
        Return False
    EndIf

    Local $aCommand[1] = ["PING"]

    ; Отправляем команду
    If Not _Redis_SendCommand($aCommand) Then
        Return False
    EndIf

    ; Неблокирующее получение ответа с таймаутом
    Local $hStartTime = TimerInit()
    Local $sResponse = ""

    While TimerDiff($hStartTime) < $iTimeoutMs
        $sResponse = TCPRecv($g_hRedis_Socket, 1024)
        If $sResponse <> "" Then
            ; Проверяем что получили PONG
            If StringInStr($sResponse, "PONG") > 0 Then
                Return True
            Else
                Return False
            EndIf
        EndIf
        Sleep(1) ; Минимальная пауза
    WEnd

    ; Таймаут
    Return False
EndFunc

; ===============================================================================
; ФУНКЦИИ СОХРАНЕНИЯ (PERSISTENCE)
; ===============================================================================

; ===============================================================================
; Функция: _Redis_Save
; Описание: Синхронное сохранение данных на диск (блокирует сервер до завершения)
; Возврат: True при успехе, False при ошибке
; Пример: _Redis_Save()
; ===============================================================================
Func _Redis_Save()
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[1] = ["SAVE"]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Local $bResult = ($vResponse = "OK")
        If $bResult Then
            If $g_bDebug_Redis_Core Then _Logger_Write("💾 [Redis] SAVE: Данные принудительно сохранены на диск", 3)
        Else
            If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] SAVE: Ошибка сохранения", 2)
        EndIf
        Return $bResult
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_BgSave
; Описание: Асинхронное (фоновое) сохранение данных на диск
; Возврат: True при успехе (начало сохранения), False при ошибке
; Пример: _Redis_BgSave()
; ===============================================================================
Func _Redis_BgSave()
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[1] = ["BGSAVE"]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        ; Redis может вернуть "Background saving started" или "OK"
        Local $bResult = (StringInStr($vResponse, "Background saving started") > 0 Or $vResponse = "OK")
        If $bResult Then
            If $g_bDebug_Redis_Core Then _Logger_Write("💾 [Redis] BGSAVE: Запущено фоновое сохранение", 3)
        Else
            If $g_bDebug_Redis_Core Then _Logger_Write("❌ [Redis] BGSAVE: Ошибка запуска фонового сохранения", 2)
        EndIf
        Return $bResult
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_LastSave
; Описание: Получение времени последнего успешного сохранения (Unix timestamp)
; Возврат: Timestamp или False при ошибке
; Пример: Local $iLastSave = _Redis_LastSave()
; ===============================================================================
Func _Redis_LastSave()
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[1] = ["LASTSAVE"]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return Int($vResponse)
    EndIf

    Return False
EndFunc

; ===============================================================================
; ФУНКЦИИ СЧЕТЧИКОВ (COUNTERS)
; ===============================================================================

; ===============================================================================
; Функция: _Redis_Incr
; Описание: Атомарное увеличение значения ключа на 1
; Параметры: $sKey - ключ
; Возврат: Новое значение счетчика или False при ошибке
; Пример: Local $iCount = _Redis_Incr("counter:products")
; ===============================================================================
Func _Redis_Incr($sKey)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[2] = ["INCR", $sKey]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return Int($vResponse)
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_IncrBy
; Описание: Атомарное увеличение значения ключа на указанное число
; Параметры: $sKey - ключ, $iValue - число для прибавления
; Возврат: Новое значение счетчика или False при ошибке
; Пример: Local $iCount = _Redis_IncrBy("counter:products", 10)
; ===============================================================================
Func _Redis_IncrBy($sKey, $iValue)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[3] = ["INCRBY", $sKey, String($iValue)]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return Int($vResponse)
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_Decr
; Описание: Атомарное уменьшение значения ключа на 1
; Параметры: $sKey - ключ
; Возврат: Новое значение счетчика или False при ошибке
; Пример: Local $iCount = _Redis_Decr("counter:products")
; ===============================================================================
Func _Redis_Decr($sKey)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[2] = ["DECR", $sKey]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return Int($vResponse)
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_DecrBy
; Описание: Атомарное уменьшение значения ключа на указанное число
; Параметры: $sKey - ключ, $iValue - число для вычитания
; Возврат: Новое значение счетчика или False при ошибке
; Пример: Local $iCount = _Redis_DecrBy("counter:products", 5)
; ===============================================================================
Func _Redis_DecrBy($sKey, $iValue)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf

    Local $aCommand[3] = ["DECRBY", $sKey, String($iValue)]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return Int($vResponse)
    EndIf

    Return False
EndFunc
