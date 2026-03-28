#include-once
#include "..\Utils\Utils.au3"
#include "Redis_Core_TCP.au3"

; ===============================================================================
; Redis PubSub Library v1.1
; Библиотека для работы с Redis Pub/Sub через TCP протокол (RESP)
; ===============================================================================
; 
; ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ФУНКЦИЙ!
;
; СПИСОК ФУНКЦИЙ:
; ===============================================================================
; ОСНОВНЫЕ ФУНКЦИИ PUB/SUB:
; _Redis_PubSub_Connect($sHost, $iPort)    - Подключение отдельного Pub/Sub соединения
; _Redis_PubSub_Disconnect()              - Отключение Pub/Sub соединения
; _Redis_Publish($sChannel, $sMessage)    - Отправка сообщения в канал (PUBLISH)
; _Redis_Subscribe($sChannel)             - Подписка на канал (SUBSCRIBE)
; _Redis_Unsubscribe($sChannel)           - Отписка от канала (UNSUBSCRIBE)
;
; ФУНКЦИИ СЛУШАТЕЛЯ:
; _Redis_PubSub_StartListener()           - Запуск фонового слушателя
; _Redis_PubSub_StopListener()            - Остановка фонового слушателя
; _Redis_PubSub_CheckMessages()           - Неблокирующая проверка сообщений
; _Redis_PubSub_ProcessMessage($aMessage) - Обработка полученного сообщения
; _Redis_PubSub_IsConnected()             - Проверка состояния Pub/Sub соединения
;
; ФУНКЦИИ ТЕСТИРОВАНИЯ:
; _Redis_PubSub_TestArray($aArray)        - Тест отправки/получения массива
; _Redis_PubSub_GetStats()                - Получение статистики Pub/Sub
;
; ФУНКЦИИ ДВОЙНОЙ ОТПРАВКИ (_plus):
; _Redis_Publish_Plus($sChannel, $sMessage, $sTablePrefix) - Отправка в Pub/Sub и Redis таблицу
; _Redis_SetArray1D_Plus($sChannel, $aArray, $sTablePrefix) - Сохранение массива в Pub/Sub и таблицу
; _Redis_MSet_Plus($aChannels, $aKeyValuePairs, $sTablePrefix) - Множественная отправка
;
; ФУНКЦИИ ВОССТАНОВЛЕНИЯ ДАННЫХ:
; _Redis_GetAutoItDataKeys()                - Получение всех ключей из папки autoit_data
; _Redis_RestoreFromAutoItData($sPattern)   - Восстановление данных после перезагрузки
;
; ВНУТРЕННИЕ ФУНКЦИИ:
; _Redis_PubSub_SendCommand($aCommand)    - Отправка команды через Pub/Sub соединение
; _Redis_PubSub_ReceiveResponse()         - Получение ответа через Pub/Sub соединение
; _Redis_PubSub_ParseMessage($sResponse)  - Парсинг Pub/Sub сообщения
; ===============================================================================

#include-once

; Глобальные переменные для Pub/Sub
Global $g_hRedis_PubSub_Socket = -1
Global $g_sRedis_PubSub_Host = "127.0.0.1"
Global $g_iRedis_PubSub_Port = 6379
Global $g_bRedis_PubSub_Connected = False
Global $g_bRedis_PubSub_ListenerActive = False
Global $g_aRedis_PubSub_SubscribedChannels = ''
Global $g_iRedis_PubSub_MessageCount = 0
Global $g_iRedis_PubSub_PublishCount = 0

; Дебаг переменная для управления логами Redis PubSub
Global $g_bDebug_Redis_PubSub = False

; ===============================================================================
; Функция: _Redis_PubSub_Connect
; Описание: Подключение отдельного TCP соединения для Pub/Sub
; Параметры: $sHost - адрес сервера, $iPort - порт
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_PubSub_Connect($sHost = "127.0.0.1", $iPort = 6379)
    ; Закрываем предыдущее соединение если есть
    If $g_hRedis_PubSub_Socket <> -1 Then
        _Redis_PubSub_Disconnect()
    EndIf

    If $g_bDebug_Redis_PubSub Then _Logger_Write("🔌 [Redis] Pub/Sub: Подключение к серверу: " & $sHost & ":" & $iPort, 1)

    ; Инициализируем TCP (если еще не инициализирован)
    TCPStartup()

    ; Подключаемся к серверу
    $g_hRedis_PubSub_Socket = TCPConnect($sHost, $iPort)

    If $g_hRedis_PubSub_Socket = -1 Then
        $g_bRedis_PubSub_Connected = False
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Ошибка подключения к " & $sHost & ":" & $iPort, 2)
        Return False
    EndIf

    ; Сохраняем параметры подключения
    $g_sRedis_PubSub_Host = $sHost
    $g_iRedis_PubSub_Port = $iPort
    $g_bRedis_PubSub_Connected = True

    If $g_bDebug_Redis_PubSub Then _Logger_Write("✅ [Redis] Pub/Sub: Подключение успешно (" & $sHost & ":" & $iPort & ")", 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_Disconnect
; Описание: Отключение от Pub/Sub соединения
; ===============================================================================
Func _Redis_PubSub_Disconnect()
    ; Останавливаем слушателя
    _Redis_PubSub_StopListener()
    
    If $g_hRedis_PubSub_Socket <> -1 Then
        TCPCloseSocket($g_hRedis_PubSub_Socket)
        $g_hRedis_PubSub_Socket = -1
        If $g_bDebug_Redis_PubSub Then _Logger_Write("� [Redis] Pub/Sub: Отключение от сервера", 1)
    EndIf

    $g_bRedis_PubSub_Connected = False
    ; Очищаем список подписок (без ReDim)
    $g_aRedis_PubSub_SubscribedChannels = ''
EndFunc

; ===============================================================================
; Функция: _Redis_Publish
; Описание: Отправка сообщения в канал (команда PUBLISH)
; Параметры: $sChannel - канал, $sMessage - сообщение
; Возврат: Количество подписчиков получивших сообщение или False при ошибке
; ===============================================================================
Func _Redis_Publish($sChannel, $sMessage)
    ; Используем основное соединение для PUBLISH (не Pub/Sub соединение)
    ; Это позволяет публиковать сообщения не блокируя основные операции
    
    ; Проверяем основное соединение
    If Not _Redis_CheckConnection() Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Нет основного соединения для PUBLISH", 2)
        Return False
    EndIf

    Local $aCommand[3] = ["PUBLISH", $sChannel, $sMessage]

    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        $g_iRedis_PubSub_PublishCount += 1
        If $g_bDebug_Redis_PubSub Then _Logger_Write("📤 [Redis] Pub/Sub: Опубликовано в [" & $sChannel & "], получателей: " & $vResponse, 1)
        Return Int($vResponse)
    EndIf

    If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Ошибка публикации в канал [" & $sChannel & "]", 2)
    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_Subscribe
; Описание: Подписка на канал (команда SUBSCRIBE)
; Параметры: $sChannel - канал для подписки
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_Subscribe($sChannel)
    If Not $g_bRedis_PubSub_Connected Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Нет Pub/Sub соединения", 2)
        Return False
    EndIf

    Local $aCommand[2] = ["SUBSCRIBE", $sChannel]

    If _Redis_PubSub_SendCommand($aCommand) Then
        ; Получаем подтверждение подписки
        Local $vResponse = _Redis_PubSub_ReceiveResponse()
        If IsArray($vResponse) And UBound($vResponse) >= 3 And $vResponse[0] = "subscribe" Then
            ; Добавляем канал в список подписок (без ReDim)
            If $g_aRedis_PubSub_SubscribedChannels = '' Then
                Local $aTemp[1] = [$sChannel]
                $g_aRedis_PubSub_SubscribedChannels = $aTemp
            Else
                Local $iOldSize = UBound($g_aRedis_PubSub_SubscribedChannels)
                Local $aTemp[$iOldSize + 1]
                For $i = 0 To $iOldSize - 1
                    $aTemp[$i] = $g_aRedis_PubSub_SubscribedChannels[$i]
                Next
                $aTemp[$iOldSize] = $sChannel
                $g_aRedis_PubSub_SubscribedChannels = $aTemp
            EndIf
            
            Local $iSubCount = (UBound($vResponse) >= 3 ? Int($vResponse[2]) : 1)
            If $g_bDebug_Redis_PubSub Then _Logger_Write("📥 [Redis] Pub/Sub: Подписка на канал [" & $sChannel & "] активна, всего подписок: " & $iSubCount, 3)
            Return True
        EndIf
    EndIf

    If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Ошибка подписки на канал [" & $sChannel & "]", 2)
    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_Unsubscribe
; Описание: Отписка от канала (команда UNSUBSCRIBE)
; Параметры: $sChannel - канал для отписки
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_Unsubscribe($sChannel)
    If Not $g_bRedis_PubSub_Connected Then
        Return False
    EndIf

    Local $aCommand[2] = ["UNSUBSCRIBE", $sChannel]

    If _Redis_PubSub_SendCommand($aCommand) Then
        Local $vResponse = _Redis_PubSub_ReceiveResponse()
        If IsArray($vResponse) And UBound($vResponse) >= 3 And $vResponse[0] = "unsubscribe" Then
            ; Удаляем канал из списка подписок (без ReDim)
            If IsArray($g_aRedis_PubSub_SubscribedChannels) Then
                Local $iOldSize = UBound($g_aRedis_PubSub_SubscribedChannels)
                Local $aTemp[$iOldSize - 1]
                Local $iNewIndex = 0
                For $i = 0 To $iOldSize - 1
                    If $g_aRedis_PubSub_SubscribedChannels[$i] <> $sChannel Then
                        If $iNewIndex < UBound($aTemp) Then
                            $aTemp[$iNewIndex] = $g_aRedis_PubSub_SubscribedChannels[$i]
                            $iNewIndex += 1
                        EndIf
                    EndIf
                Next
                If UBound($aTemp) > 0 Then
                    $g_aRedis_PubSub_SubscribedChannels = $aTemp
                Else
                    $g_aRedis_PubSub_SubscribedChannels = ''
                EndIf
            EndIf
            
            Local $iSubCount = (UBound($vResponse) >= 3 ? Int($vResponse[2]) : 0)
            If $g_bDebug_Redis_PubSub Then _Logger_Write("📤 [Redis] Pub/Sub: Отписка от канала [" & $sChannel & "], осталось подписок: " & $iSubCount, 1)
            Return True
        EndIf
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_StartListener
; Описание: Запуск фонового слушателя сообщений
; ===============================================================================
Func _Redis_PubSub_StartListener()
    If $g_bRedis_PubSub_ListenerActive Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("⚠️ [Redis] Pub/Sub: Слушатель уже активен", 1)
        Return True
    EndIf

    If Not $g_bRedis_PubSub_Connected Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Нет Pub/Sub соединения для слушателя", 2)
        Return False
    EndIf

    ; Запускаем фоновую проверку каждые 10мс
    AdlibRegister("_Redis_PubSub_CheckMessages", 10)
    $g_bRedis_PubSub_ListenerActive = True
    
    If $g_bDebug_Redis_PubSub Then _Logger_Write("🎧 [Redis] Pub/Sub: Слушатель запущен (проверка каждые 10мс)", 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_StopListener
; Описание: Остановка фонового слушателя
; ===============================================================================
Func _Redis_PubSub_StopListener()
    If $g_bRedis_PubSub_ListenerActive Then
        AdlibUnRegister("_Redis_PubSub_CheckMessages")
        $g_bRedis_PubSub_ListenerActive = False
        If $g_bDebug_Redis_PubSub Then _Logger_Write("🔇 [Redis] Pub/Sub: Слушатель остановлен", 1)
    EndIf
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_CheckMessages
; Описание: Неблокирующая проверка входящих сообщений (исправленная версия)
; Возврат: Массив сообщения [тип, канал, данные] или False если нет сообщений
; ===============================================================================
Func _Redis_PubSub_CheckMessages()
    If Not $g_bRedis_PubSub_Connected Or $g_hRedis_PubSub_Socket = -1 Then
        Return False
    EndIf

    ; Простое неблокирующее чтение без сложной логики
    Local $sRawData = TCPRecv($g_hRedis_PubSub_Socket, 65536) ; Увеличенный буфер
    If $sRawData = "" Then
        Return False ; Нет данных
    EndIf

    ; Если данные неполные, пытаемся дочитать еще раз
    Local $iAttempts = 0
    While $iAttempts < 5 And StringRight($sRawData, 2) <> @CRLF
        Local $sAdditional = TCPRecv($g_hRedis_PubSub_Socket, 8192)
        If $sAdditional <> "" Then
            $sRawData &= $sAdditional
        Else
            Sleep(1) ; Короткая пауза
        EndIf
        $iAttempts += 1
    WEnd

    ; Парсим сообщение
    Local $aMessage = _Redis_PubSub_ParseMessage($sRawData)
    If IsArray($aMessage) Then
        ; Обновляем счетчик полученных сообщений
        If UBound($aMessage) >= 3 And $aMessage[0] = "message" Then
            $g_iRedis_PubSub_MessageCount += 1
        EndIf
        
        ; Если вызывается через AdlibRegister - обрабатываем автоматически
        If $g_bRedis_PubSub_ListenerActive Then
            _Redis_PubSub_ProcessMessage($aMessage)
        EndIf
        ; Возвращаем сообщение для ручной обработки
        Return $aMessage
    EndIf

    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_ProcessMessage
; Описание: Обработка полученного сообщения
; Параметры: $aMessage - массив [тип, канал, данные]
; ===============================================================================
Func _Redis_PubSub_ProcessMessage($aMessage)
    If Not IsArray($aMessage) Or UBound($aMessage) < 3 Then
        Return False
    EndIf

    Local $sType = $aMessage[0]
    Local $sChannel = $aMessage[1]
    Local $sData = $aMessage[2]

    Switch $sType
        Case "message"
            $g_iRedis_PubSub_MessageCount += 1
            If $g_bDebug_Redis_PubSub Then _Logger_Write("📨 [Redis] Pub/Sub: Сообщение в [" & $sChannel & "]: " & StringLeft($sData, 50) & (StringLen($sData) > 50 ? "..." : ""), 1)
            
            ; Здесь можно добавить callback функции для разных каналов
            ; Пока просто логируем
            
        Case "subscribe"
            If $g_bDebug_Redis_PubSub Then _Logger_Write("✅ [Redis] Pub/Sub: Подтверждение подписки на [" & $sChannel & "]", 3)
            
        Case "unsubscribe"
            If $g_bDebug_Redis_PubSub Then _Logger_Write("📤 [Redis] Pub/Sub: Подтверждение отписки от [" & $sChannel & "]", 1)
    EndSwitch

    Return True
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_IsConnected
; Описание: Проверка состояния Pub/Sub соединения
; Возврат: True если подключен, False если нет
; ===============================================================================
Func _Redis_PubSub_IsConnected()
    Return $g_bRedis_PubSub_Connected
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_TestArray
; Описание: Тест отправки и получения массива через Pub/Sub
; Параметры: $aArray - массив для тестирования
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_PubSub_TestArray($aArray)
    If Not IsArray($aArray) Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: TestArray - параметр не является массивом", 2)
        Return False
    EndIf

    Local $hStartTimer = _Utils_GetTimestamp()
    
    ; Сериализуем массив в строку
    Local $sArrayData = _Utils_ArrayToString($aArray, "|")
    
    ; Отправляем через Pub/Sub
    Local $sChannel = "test_array_channel"
    Local $iSubscribers = _Redis_Publish($sChannel, $sArrayData)
    
    Local $iSendTime = _Utils_GetElapsedTime($hStartTimer)
    
    If $g_bDebug_Redis_PubSub Then _Logger_Write("🧪 [Redis] Pub/Sub Test: Массив " & UBound($aArray) & " элементов отправлен за " & Int($iSendTime) & "мс, получателей: " & $iSubscribers, 1)
    
    Return ($iSubscribers >= 0)
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_GetStats
; Описание: Получение статистики Pub/Sub
; Возврат: Массив со статистикой
; ===============================================================================
Func _Redis_PubSub_GetStats()
    Local $aStats[6]
    $aStats[0] = "PubSub_Stats"
    $aStats[1] = "Connected: " & ($g_bRedis_PubSub_Connected ? "Yes" : "No")
    $aStats[2] = "Listener: " & ($g_bRedis_PubSub_ListenerActive ? "Active" : "Inactive")
    $aStats[3] = "Subscriptions: " & (IsArray($g_aRedis_PubSub_SubscribedChannels) ? UBound($g_aRedis_PubSub_SubscribedChannels) : 0)
    $aStats[4] = "Messages_Received: " & $g_iRedis_PubSub_MessageCount
    $aStats[5] = "Messages_Published: " & $g_iRedis_PubSub_PublishCount
    
    Return $aStats
EndFunc

; ===============================================================================
; ВНУТРЕННИЕ ФУНКЦИИ ДЛЯ PUB/SUB
; ===============================================================================

; ===============================================================================
; Функция: _Redis_PubSub_SendCommand
; Описание: Отправка команды через Pub/Sub соединение в формате RESP
; Параметры: $aCommand - массив команды и параметров
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Redis_PubSub_SendCommand($aCommand)
    If Not $g_bRedis_PubSub_Connected Or $g_hRedis_PubSub_Socket = -1 Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Нет подключения для отправки команды", 2)
        Return False
    EndIf

    ; Формируем RESP команду (аналогично основной библиотеке)
    Local $sRESP = "*" & UBound($aCommand) & @CRLF

    For $i = 0 To UBound($aCommand) - 1
        Local $iLength = StringLen($aCommand[$i])
        $sRESP &= "$" & $iLength & @CRLF & $aCommand[$i] & @CRLF
    Next

    ; Отправляем команду
    Local $iBytesToSend = StringLen($sRESP)
    Local $iBytesSent = TCPSend($g_hRedis_PubSub_Socket, $sRESP)

    Return ($iBytesSent = $iBytesToSend)
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_ReceiveResponse
; Описание: Получение ответа через Pub/Sub соединение
; Возврат: Ответ от сервера или False при ошибке
; ===============================================================================
Func _Redis_PubSub_ReceiveResponse()
    If Not $g_bRedis_PubSub_Connected Or $g_hRedis_PubSub_Socket = -1 Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Нет подключения для получения ответа", 2)
        Return False
    EndIf

    Local $sResponse = ""
    Local $iTimeout = 1000 ; Больший таймаут для Pub/Sub
    Local $hTimer = TimerInit()

    ; Читаем ответ
    While TimerDiff($hTimer) < $iTimeout
        Local $sData = TCPRecv($g_hRedis_PubSub_Socket, 1024)
        If $sData <> "" Then
            $sResponse &= $sData
            ; Проверяем завершение ответа
            If StringInStr($sResponse, @CRLF) > 0 And StringRight($sResponse, 2) = @CRLF Then
                ExitLoop
            EndIf
        EndIf
        Sleep(1)
    WEnd

    If $sResponse = "" Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub: Таймаут получения ответа", 2)
        Return False
    EndIf

    ; Парсим RESP ответ
    Return _Redis_PubSub_ParseMessage($sResponse)
EndFunc

; ===============================================================================
; Функция: _Redis_PubSub_ParseMessage
; Описание: Парсинг Pub/Sub сообщения в формате RESP
; Параметры: $sResponse - сырой ответ от сервера
; Возврат: Массив [тип, канал, данные] или False при ошибке
; ===============================================================================
Func _Redis_PubSub_ParseMessage($sResponse)
    Local $sFirstChar = StringLeft($sResponse, 1)

    ; Pub/Sub сообщения всегда приходят как массивы
    If $sFirstChar <> "*" Then
        Return False
    EndIf

    ; Парсим массив
    Local $iFirstCRLF = StringInStr($sResponse, @CRLF)
    If $iFirstCRLF = 0 Then Return False
    
    Local $iArraySize = Int(StringMid($sResponse, 2, $iFirstCRLF - 2))
    If $iArraySize < 3 Then Return False ; Pub/Sub сообщения имеют минимум 3 элемента

    Local $aResult[$iArraySize]
    Local $iPos = $iFirstCRLF + 2 ; Начинаем после заголовка
    
    ; Парсим элементы массива
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
            $iPos = $iLengthCRLF + 4
        Else
            ; Обычный элемент с данными
            Local $iDataStart = $iLengthCRLF + 2
            $aResult[$i] = StringMid($sResponse, $iDataStart, $iElementLength)
            $iPos = $iDataStart + $iElementLength + 2
        EndIf
    Next

    Return $aResult
EndFunc

; ===============================================================================
; ФУНКЦИИ ДВОЙНОЙ ОТПРАВКИ (_plus)
; ===============================================================================

; ===============================================================================
; Функция: _Redis_Publish_Plus
; Описание: Отправка сообщения в Pub/Sub канал И сохранение в Redis таблицу
; Параметры: $sChannel - канал, $sMessage - сообщение, $sTablePrefix - префикс таблицы
; Возврат: True при успехе обеих операций
; ===============================================================================
Func _Redis_Publish_Plus($sChannel, $sMessage, $sTablePrefix = "autoit_data:")
    ; Отправляем в Pub/Sub
    Local $iPubSubResult = _Redis_Publish($sChannel, $sMessage)
    
    ; Сохраняем в Redis таблицу в папке autoit_data
    Local $sTableKey = $sTablePrefix & $sChannel & "_data"
    Local $bTableResult = _Redis_Set($sTableKey, $sMessage)
    
    ; Логируем результат
    If $iPubSubResult >= 0 And $bTableResult Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("📤 [Redis] Pub/Sub+: Отправлено в [" & $sChannel & "] и таблицу [" & $sTableKey & "], получателей: " & $iPubSubResult, 3)
        Return True
    Else
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub+: Ошибка отправки в [" & $sChannel & "] или таблицу [" & $sTableKey & "]", 2)
        Return False
    EndIf
EndFunc

; ===============================================================================
; Функция: _Redis_SetArray1D_Plus
; Описание: Сохранение 1D массива в Pub/Sub канал И Redis таблицу
; Параметры: $sChannel - канал, $aArray - массив, $sTablePrefix - префикс таблицы
; Возврат: True при успехе обеих операций
; ===============================================================================
Func _Redis_SetArray1D_Plus($sChannel, $aArray, $sTablePrefix = "autoit_data:")
    If Not IsArray($aArray) Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub+: Параметр не является массивом", 2)
        Return False
    EndIf
    
    ; Сериализуем массив
    Local $sArrayData = _Utils_ArrayToString($aArray, "|")
    
    ; Используем функцию двойной отправки
    Return _Redis_Publish_Plus($sChannel, $sArrayData, $sTablePrefix)
EndFunc

; ===============================================================================
; Функция: _Redis_MSet_Plus
; Описание: Множественная отправка в несколько каналов И таблиц
; Параметры: $aChannels - массив каналов, $aKeyValuePairs - пары ключ-значение, $sTablePrefix - префикс
; Возврат: Количество успешных операций
; ===============================================================================
Func _Redis_MSet_Plus($aChannels, $aKeyValuePairs, $sTablePrefix = "autoit_data:")
    If Not IsArray($aChannels) Or Not IsArray($aKeyValuePairs) Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("❌ [Redis] Pub/Sub+: Неверные параметры массивов", 2)
        Return 0
    EndIf
    
    Local $iSuccessCount = 0
    Local $iChannelCount = UBound($aChannels)
    Local $iPairCount = UBound($aKeyValuePairs)
    
    ; Отправляем в каждый канал
    For $i = 0 To $iChannelCount - 1
        ; Формируем данные для отправки (используем пары ключ-значение)
        Local $sData = ""
        For $j = 0 To $iPairCount - 1 Step 2
            If $j + 1 < $iPairCount Then
                $sData &= $aKeyValuePairs[$j] & "=" & $aKeyValuePairs[$j + 1]
                If $j + 2 < $iPairCount Then $sData &= "|"
            EndIf
        Next
        
        ; Отправляем через функцию _plus
        If _Redis_Publish_Plus($aChannels[$i], $sData, $sTablePrefix) Then
            $iSuccessCount += 1
        EndIf
    Next
    
    If $g_bDebug_Redis_PubSub Then _Logger_Write("📤 [Redis] Pub/Sub+: Множественная отправка завершена, успешно: " & $iSuccessCount & "/" & $iChannelCount, 1)
    Return $iSuccessCount
EndFunc
; ===============================================================================
; Функция: _Redis_GetAutoItDataKeys
; Описание: Получение всех ключей из папки autoit_data для восстановления
; Возврат: Массив ключей или False при ошибке
; ===============================================================================
Func _Redis_GetAutoItDataKeys()
    ; Ищем все ключи с префиксом autoit_data:
    Local $aKeys = _Redis_Keys("autoit_data:*")
    
    If IsArray($aKeys) And UBound($aKeys) > 0 Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("📊 [Redis] Найдено " & UBound($aKeys) & " ключей в папке autoit_data", 1)
        Return $aKeys
    EndIf
    
    If $g_bDebug_Redis_PubSub Then _Logger_Write("📊 [Redis] Папка autoit_data пуста или не найдена", 1)
    Return False
EndFunc

; ===============================================================================
; Функция: _Redis_RestoreFromAutoItData
; Описание: Восстановление данных из папки autoit_data после перезагрузки
; Параметры: $sChannelPattern - шаблон каналов для восстановления (например "test_*")
; Возврат: Количество восстановленных каналов
; ===============================================================================
Func _Redis_RestoreFromAutoItData($sChannelPattern = "*")
    Local $aKeys = _Redis_GetAutoItDataKeys()
    Local $iRestoredCount = 0
    
    If IsArray($aKeys) Then
        If $g_bDebug_Redis_PubSub Then _Logger_Write("🔄 [Redis] Восстановление данных из папки autoit_data...", 1)
        
        For $i = 0 To UBound($aKeys) - 1
            Local $sKey = $aKeys[$i]
            
            ; Извлекаем имя канала из ключа (autoit_data:channel_name_data -> channel_name)
            Local $sChannelName = StringReplace($sKey, "autoit_data:", "")
            $sChannelName = StringReplace($sChannelName, "_data", "")
            
            ; Проверяем соответствие шаблону
            If $sChannelPattern = "*" Or StringInStr($sChannelName, StringReplace($sChannelPattern, "*", "")) > 0 Then
                Local $sData = _Redis_Get($sKey)
                If $sData <> False Then
                    If $g_bDebug_Redis_PubSub Then _Logger_Write("📥 [Redis] Восстановлен канал [" & $sChannelName & "]: " & StringLen($sData) & " байт", 1)
                    $iRestoredCount += 1
                EndIf
            EndIf
        Next
        
        If $g_bDebug_Redis_PubSub Then _Logger_Write("✅ [Redis] Восстановление завершено: " & $iRestoredCount & " каналов", 3)
    EndIf
    
    Return $iRestoredCount
EndFunc