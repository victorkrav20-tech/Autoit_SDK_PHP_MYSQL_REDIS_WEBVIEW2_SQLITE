; ===============================================================================
; WebView2_Engine_Events.au3 - Система событий и двусторонняя связь AutoIt ↔ JS
; Версия: 1.0.0
; Описание: Обработка событий WebView2, callbacks, отправка/получение сообщений
; ===============================================================================
; ЗАВИСИМОСТИ: Utils.au3, WebView2_Engine_Core.au3, json/JSON.au3
; НАЗНАЧЕНИЕ: Двусторонняя связь AutoIt ↔ JavaScript через события
; ИСТОЧНИК: Мигрировано из apps/Reference/Webview2/includes/WebView2_Engine.au3
;           и apps/Reference/Webview2/includes/WebView2_Engine_Client.au3
;
; СПИСОК ФУНКЦИЙ:
; _WebView2_Events_SetOnMessageReceived()     - Установка callback для сообщений от JS
; _WebView2_Events_SetOnWebViewReady()        - Установка callback готовности WebView2
; _WebView2_Events_SetOnNavigationCompleted() - Установка callback завершения навигации
; _WebView2_Events_SendToJS()                 - Отправка сообщения в JavaScript
; _WebView2_Events_Manager_OnMessageReceived() - Обработчик системных сообщений (COM)
; _WebView2_Events_ParseMessage()             - Парсинг входящего сообщения
; _WebView2_Events_DispatchEvent()            - Вызов пользовательских callbacks
; _WebView2_Events_WaitForReady()             - Ожидание готовности WebView2
; _WebView2_Events_WaitForNavigation()        - Ожидание завершения навигации
; _WebView2_Events_GetLastMessage()           - Получение последнего сообщения
; _WebView2_Events_SetDebugMode()             - Включение/выключение отладки
; _WebView2_Events_SetOnJSMessage()           - Простой callback для JS→AutoIt (Вариант 1)
; _WebView2_Events_RegisterMessageHandler()   - Типизированный обработчик (Вариант 2/3)
; Bridge_OnMessageReceived()                  - Глобальный обработчик Bridge событий
; ===============================================================================

#include-once
#include "..\Utils\Utils.au3"
#include "..\json\JSON.au3"
#include "WebView2_Engine_Core.au3"

; ===============================================================================
; Глобальные переменные Events модуля
; ===============================================================================
Global $g_bWebView2_Events_DebugMode = False   ; Режим отладки событий

; Bridge callbacks (для JS→AutoIt связи)
Global $g_sWebView2_Bridge_SimpleCallback = ""  ; Простой callback (получает всё)
Global $g_aWebView2_Bridge_Handlers = ''        ; Массив типизированных обработчиков [тип, callback, instanceId]

Func WebView_OnMessageReceived($sMessage)
    ; ФИЛЬТР: Пропускаем DevTools события - они обрабатываются в Bridge_OnMessageReceived
    If StringInStr($sMessage, '"type":"DEVTOOLS_CONSOLE"') Or StringInStr($sMessage, '"type":"DEVTOOLS_EXCEPTION"') Then
        Return ; Пропускаем, уже обработано в Bridge_OnMessageReceived
    EndIf

    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] 🔔 COM событие получено: " & $sMessage & " → ID = null", 1)
    ; Перенаправляем в основной обработчик с default экземпляром
    _WebView2_Events_Manager_OnMessageReceived($sMessage, 0)
EndFunc

; ===============================================================================
; Установка callback для сообщений от JavaScript
; ===============================================================================
Func _WebView2_Events_SetOnMessageReceived($sCallbackFunc, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_CALLBACK_MESSAGE] = $sCallbackFunc
    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Callback OnMessageReceived установлен: " & $sCallbackFunc & " → ID = " & $hInstance, 1)
    Return True
EndFunc


; ===============================================================================
; Установка callback готовности WebView2
; ===============================================================================
Func _WebView2_Events_SetOnWebViewReady($sCallbackFunc, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_CALLBACK_READY] = $sCallbackFunc
    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Callback OnWebViewReady установлен: " & $sCallbackFunc & " → ID = " & $hInstance, 1)
    Return True
EndFunc


; ===============================================================================
; Установка callback завершения навигации
; ===============================================================================
Func _WebView2_Events_SetOnNavigationCompleted($sCallbackFunc, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_CALLBACK_NAV_COMPLETED] = $sCallbackFunc
    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Callback OnNavigationCompleted установлен: " & $sCallbackFunc & " → ID = " & $hInstance, 1)
    Return True
EndFunc


; ===============================================================================
; Отправка сообщения в JavaScript
; ===============================================================================
Func _WebView2_Events_SendToJS($sEventType, $vData = "", $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    ; Формируем JSON сообщение
    Local $sMessage = '{"type":"' & $sEventType & '"'

    If $vData <> "" Then
        ; Проверяем тип данных и формируем правильный JSON
        If IsMap($vData) Then
            ; Map - НОВЫЙ ФОРМАТ с ключом "data" (для NewPreact1 и новых приложений)
            Local $sJsonData = _JSON_GenerateCompact($vData)
            $sMessage &= ',"data":' & $sJsonData
        ElseIf IsArray($vData) Then
            ; Массив - СТАРЫЙ ФОРМАТ с ключом "payload" (для обратной совместимости)
            Local $sJsonData = _JSON_GenerateCompact($vData)
            $sMessage &= ',"payload":' & $sJsonData
        ElseIf IsString($vData) Then
            ; Строка - проверяем, является ли она уже JSON объектом
            Local $sFirstChar = StringLeft(StringStripWS($vData, 1), 1)
            If $sFirstChar = "{" Or $sFirstChar = "[" Then
                ; JSON строка - СТАРЫЙ ФОРМАТ с ключом "payload" (для Inet_Reader)
                $sMessage &= ',"payload":' & $vData
            Else
                ; Обычная строка - используем "data"
                $sMessage &= ',"data":"' & $vData & '"'
            EndIf
        Else
            ; Число или другой тип - как есть в data
            $sMessage &= ',"data":' & String($vData)
        EndIf
    EndIf

    $sMessage &= '}'

    ; DEBUG: Логируем что отправляем
    ;_Logger_Write("[WebView2_Events] 📤 Отправляю в JS: " & StringLeft($sMessage, 150) & " → ID = " & $hInstance, 1)

    ; КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: вызываем handleAutoItMessage() напрямую вместо postMessage
    Local $sScript = 'if(window.handleAutoItMessage) handleAutoItMessage(' & $sMessage & ');'
    _WebView2_Core_ExecuteScript($hInstance, $sScript)

    Return True
EndFunc


; ===============================================================================
; Обработчик системных сообщений от WebView2 (COM событие)
; ===============================================================================
Func _WebView2_Events_Manager_OnMessageReceived($sMessage, $hInstance = 0)
	; Если handle = 0, используем default
	If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

	Local $iIndex = _WebView2_Core_GetInstance($hInstance)
	If $iIndex < 0 Then Return

	; Сохраняем последнее сообщение
	$g_aWebView2_Instances[$iIndex][$WV2_LAST_MESSAGE] = $sMessage
	
	; === DLL DEBUG СООБЩЕНИЯ ===
	If StringLeft($sMessage, 7) = "DEBUG: " Or StringLeft($sMessage, 18) = "DEBUG_RAW_CONSOLE:" Then
		If $g_bDebug_WebView2_WebView2_DLL Then _Logger_Write("[WebView2_DLL] " & $sMessage, 1)
		Return
	EndIf

	; === DEVTOOLS PROTOCOL ===
	If StringInStr($sMessage, '"type":"DEVTOOLS_CONSOLE"') Then
		; Логирование только если включен debug
		If $g_bDebug_WebView2_DevTools Then
			Local $sLevel = _JSON_ExtractValue($sMessage, "level")
			Local $sMsg = _JSON_ExtractValue($sMessage, "message")
			Local $sSource = _JSON_ExtractValue($sMessage, "source")
			Local $iLine = _JSON_ExtractValue($sMessage, "line")
			Local $iColumn = _JSON_ExtractValue($sMessage, "column")

			Local $iLogType = ($sLevel = "error" Or $sLevel = "warn") ? 2 : 1
			Local $sFormatted = "[JS " & $sLevel & "] " & $sMsg & " (" & $sSource & ":" & $iLine & ":" & $iColumn & ")"
			_Logger_Write($sFormatted & " [Instance: " & $hInstance & "]", $iLogType)
		EndIf
		; Передаём в Dispatch для кастомных обработчиков
		_WebView2_Events_DispatchEvent($sMessage, $hInstance)
		Return
	EndIf

	If StringInStr($sMessage, '"type":"DEVTOOLS_EXCEPTION"') Then
		; Логирование убрано - используется кастомный обработчик с полным stack trace
		; Передаём в Dispatch для кастомных обработчиков
		_WebView2_Events_DispatchEvent($sMessage, $hInstance)
		Return
	EndIf

	; === СУЩЕСТВУЮЩАЯ ЛОГИКА ===
	; Парсим сообщение
	Local $aParts = StringSplit($sMessage, "|")
	If $aParts[0] < 1 Then Return

	Local $sCommand = StringStripWS($aParts[1], 3)

	; Обрабатываем системные события
	Switch $sCommand
		Case "INIT_READY"
			If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] WebView2 готов" & " → ID = " & $hInstance, 3)
			$g_aWebView2_Instances[$iIndex][$WV2_READY] = True
			$g_aWebView2_Instances[$iIndex][$WV2_LAST_EVENT_TYPE] = "INIT_READY"

			; Вызываем callback
			If $g_aWebView2_Instances[$iIndex][$WV2_CALLBACK_READY] <> "" Then
				Call($g_aWebView2_Instances[$iIndex][$WV2_CALLBACK_READY])
			EndIf

		Case "NAV_STARTING"
			$g_aWebView2_Instances[$iIndex][$WV2_LOADING] = True
			$g_aWebView2_Instances[$iIndex][$WV2_LAST_EVENT_TYPE] = "NAV_STARTING"
			If $aParts[0] > 1 Then
				$g_aWebView2_Instances[$iIndex][$WV2_CURRENT_URL] = $aParts[2]
			EndIf

		Case "NAV_COMPLETED"
			If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Навигация завершена" & " → ID = " & $hInstance, 3)
			$g_aWebView2_Instances[$iIndex][$WV2_LOADING] = False
			$g_aWebView2_Instances[$iIndex][$WV2_LAST_EVENT_TYPE] = "NAV_COMPLETED"

			; Вызываем callback
			If $g_aWebView2_Instances[$iIndex][$WV2_CALLBACK_NAV_COMPLETED] <> "" Then
				Local $sURL = $g_aWebView2_Instances[$iIndex][$WV2_CURRENT_URL]
				Call($g_aWebView2_Instances[$iIndex][$WV2_CALLBACK_NAV_COMPLETED], $sURL)
			EndIf

		Case "TITLE_CHANGED"
			If $aParts[0] > 1 Then
				$g_aWebView2_Instances[$iIndex][$WV2_CURRENT_TITLE] = $aParts[2]
			EndIf

		Case "URL_CHANGED"
			If $aParts[0] > 1 Then
				$g_aWebView2_Instances[$iIndex][$WV2_CURRENT_URL] = $aParts[2]
			EndIf

		Case "ERROR", "NAV_ERROR"
			Local $sErr = ($aParts[0] > 1) ? $aParts[2] : "Unknown"
			If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Ошибка WebView2: " & $sErr & " → ID = " & $hInstance, 2)
			$g_aWebView2_Instances[$iIndex][$WV2_LAST_EVENT_TYPE] = "ERROR"
			$g_aWebView2_Instances[$iIndex][$WV2_LAST_EVENT_DATA] = $sErr

		Case Else
			; Пользовательское сообщение от JavaScript
			_WebView2_Events_DispatchEvent($sMessage, $hInstance)
	EndSwitch
EndFunc

; Простой JSON парсер для извлечения значений
Func _JSON_ExtractValue($sJson, $sKey)
	; Строковые значения
	Local $sPattern = '"' & $sKey & '"\s*:\s*"([^"]*)"'
	Local $aMatch = StringRegExp($sJson, $sPattern, 1)
	If @error = 0 And IsArray($aMatch) Then Return $aMatch[0]

	; Числовые значения
	$sPattern = '"' & $sKey & '"\s*:\s*(\d+)'
	$aMatch = StringRegExp($sJson, $sPattern, 1)
	If @error = 0 And IsArray($aMatch) Then Return $aMatch[0]

	Return ""
EndFunc


; ===============================================================================
; Парсинг входящего сообщения
; ===============================================================================
Func _WebView2_Events_ParseMessage($sMessage)
    ; Пытаемся распарсить как JSON
    Local $oJSON = _JSON_Parse($sMessage)
    If @error Then
        ; Если не JSON, возвращаем как есть
        Return $sMessage
    EndIf

    Return $oJSON
EndFunc

; ===============================================================================
; Вызов пользовательских callbacks
; ===============================================================================
Func _WebView2_Events_DispatchEvent($sMessage, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return

    ; Проверяем типизированные обработчики (Bridge handlers)
    If $g_aWebView2_Bridge_Handlers <> '' Then
        ; Пытаемся распарсить как JSON
        Local $vJson = _JSON_Parse($sMessage)

        If Not @error And IsMap($vJson) Then
            ; Это JSON сообщение, проверяем тип
            Local $sType = $vJson["type"]

            If $sType <> "" Then
                Local $bHandlerFound = False
                Local $iHandlersCount = UBound($g_aWebView2_Bridge_Handlers, 1)
                
                ; УМНАЯ РАСПАКОВКА: если есть ключ "data", передаём только его содержимое
                Local $vDataToPass = $vJson
                If MapExists($vJson, "data") Then
                    $vDataToPass = $vJson["data"]
                EndIf
                
                ; Ищем ВСЕ обработчики для этого типа И instanceId
                For $i = 0 To $iHandlersCount - 1
                    ; ФИЛЬТРАЦИЯ: проверяем тип И instanceId
                    If $g_aWebView2_Bridge_Handlers[$i][0] = $sType And $g_aWebView2_Bridge_Handlers[$i][2] = $hInstance Then
                        ; Нашли обработчик для ЭТОГО окна, вызываем его
                        Call($g_aWebView2_Bridge_Handlers[$i][1], $vDataToPass, $hInstance)
                        $bHandlerFound = True
                    EndIf
                Next

                If Not $bHandlerFound Then
                    ; Логируем только если debug включен
                    If $g_bDebug_WebView2_Events Then
                        _Logger_Write("[WebView2_Events] ⚠️ Обработчик НЕ НАЙДЕН для типа: " & $sType & " → ID = " & $hInstance, 2)
                    EndIf
                EndIf
                
                Return ; Обработчики вызваны, выходим
            EndIf
        Else
            ; Это не JSON, проверяем префиксные обработчики
            For $i = 0 To UBound($g_aWebView2_Bridge_Handlers, 1) - 1
                Local $sPrefix = $g_aWebView2_Bridge_Handlers[$i][0]
                ; ФИЛЬТРАЦИЯ: проверяем префикс И instanceId
                If StringLeft($sMessage, StringLen($sPrefix)) = $sPrefix And $g_aWebView2_Bridge_Handlers[$i][2] = $hInstance Then
                    ; Нашли префиксный обработчик для ЭТОГО окна
                    Local $sData = StringTrimLeft($sMessage, StringLen($sPrefix))
                    Call($g_aWebView2_Bridge_Handlers[$i][1], $sData, $hInstance)
                    Return ; Обработчик вызван, выходим
                EndIf
            Next
            ; Логируем только если debug включен
            If $g_bDebug_WebView2_Events Then
                _Logger_Write("[WebView2_Events] ⚠️ Префиксный обработчик НЕ НАЙДЕН → ID = " & $hInstance, 2)
            EndIf
        EndIf
    EndIf
    ; Не логируем если handlers не инициализированы - это нормально на старте
EndFunc


; ===============================================================================
; Ожидание готовности WebView2
; ===============================================================================
Func _WebView2_Events_WaitForReady($hInstance = 0, $iTimeout = 10000)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Ожидание готовности WebView2 (таймаут: " & $iTimeout & " мс)..." & " → ID = " & $hInstance, 1)

    Local $hTimer = TimerInit()
    Local $iLastLog = 0
    While TimerDiff($hTimer) < $iTimeout
        Local $iIndex = _WebView2_Core_GetInstance($hInstance)
        If $iIndex >= 0 Then
            ; Логируем каждую секунду
            If TimerDiff($hTimer) - $iLastLog > 1000 Then
                If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Ожидание... (прошло: " & Int(TimerDiff($hTimer)) & " мс, READY=" & $g_aWebView2_Instances[$iIndex][$WV2_READY] & ")" & " → ID = " & $hInstance, 1)
                $iLastLog = TimerDiff($hTimer)
            EndIf

            If $g_aWebView2_Instances[$iIndex][$WV2_READY] Then
                ;If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] WebView2 готов!" & " → ID = " & $hInstance, 3)
                Return True
            EndIf
        Else
            If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Экземпляр не найден в цикле ожидания" & " → ID = " & $hInstance, 2)
            Return False
        EndIf
        Sleep(1)
    WEnd

    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Таймаут ожидания готовности (READY флаг так и не установлен)" & " → ID = " & $hInstance, 2)
    Return False
EndFunc



; ===============================================================================
; Ожидание завершения навигации
; ===============================================================================
Func _WebView2_Events_WaitForNavigation($hInstance = 0, $iTimeout = 10000)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Ожидание завершения навигации..." & " → ID = " & $hInstance, 1)

    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeout
        Local $iIndex = _WebView2_Core_GetInstance($hInstance)
        If $iIndex >= 0 And Not $g_aWebView2_Instances[$iIndex][$WV2_LOADING] And $g_aWebView2_Instances[$iIndex][$WV2_READY] Then
            If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Навигация завершена" & " → ID = " & $hInstance, 3)
            Return True
        EndIf
        Sleep(1)
    WEnd

    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Таймаут ожидания навигации" & " → ID = " & $hInstance, 2)
    Return False
EndFunc




; ===============================================================================
; Получение последнего сообщения
; ===============================================================================
Func _WebView2_Events_GetLastMessage($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return ""

    Return $g_aWebView2_Instances[$iIndex][$WV2_LAST_MESSAGE]
EndFunc


; ===============================================================================
; Включение/выключение режима отладки
; ===============================================================================
Func _WebView2_Events_SetDebugMode($bEnable)
	$g_bWebView2_Events_DebugMode = $bEnable
	If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Режим отладки: " & ($bEnable ? "включён" : "выключен") & " → ID = null", 1)
	Return True
EndFunc

; ===============================================================================
; Установка простого callback для JS→AutoIt сообщений (Вариант 1)
; ===============================================================================
Func _WebView2_Events_SetOnJSMessage($sCallbackFunc, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    ; Получаем Bridge объект (если ещё не получен)
    Local $oBridge = _WebView2_Core_GetBridge($hInstance)
    If Not IsObj($oBridge) Then
        If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Не удалось получить Bridge объект" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Регистрируем Bridge события (если ещё не зарегистрированы)
    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_BRIDGE_EVENTS]) Then
        If Not _WebView2_Core_RegisterBridgeEvents($hInstance, "Bridge_") Then
            If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Не удалось зарегистрировать Bridge события" & " → ID = " & $hInstance, 2)
            Return False
        EndIf
    EndIf

    ; Сохраняем простой callback
    $g_sWebView2_Bridge_SimpleCallback = $sCallbackFunc
    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Простой Bridge callback установлен: " & $sCallbackFunc & " → ID = " & $hInstance, 1)
    Return True
EndFunc

; ===============================================================================
; Регистрация типизированного обработчика (Вариант 2 и 3: JSON/префиксы)
; ===============================================================================
Func _WebView2_Events_RegisterMessageHandler($sType, $sCallbackFunc, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    ; Получаем Bridge объект (если ещё не получен)
    Local $oBridge = _WebView2_Core_GetBridge($hInstance)
    If Not IsObj($oBridge) Then
        If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Не удалось получить Bridge объект" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Регистрируем Bridge события (если ещё не зарегистрированы)
    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_BRIDGE_EVENTS]) Then
        If Not _WebView2_Core_RegisterBridgeEvents($hInstance, "Bridge_") Then
            If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Не удалось зарегистрировать Bridge события" & " → ID = " & $hInstance, 2)
            Return False
        EndIf
    EndIf

    ; ПРОВЕРКА НА ДУБЛИКАТЫ: если обработчик уже зарегистрирован - перерегистрируем его
    If $g_aWebView2_Bridge_Handlers <> '' Then
        For $i = 0 To UBound($g_aWebView2_Bridge_Handlers, 1) - 1
            If $g_aWebView2_Bridge_Handlers[$i][0] = $sType And _
               $g_aWebView2_Bridge_Handlers[$i][2] = $hInstance Then
                ; Найден дубликат - обновляем callback на новый
                _Logger_Write("[WebView2_Events] 🔄 ПЕРЕРЕГИСТРАЦИЯ: " & $sType & " → " & $sCallbackFunc & " (Instance: " & $hInstance & ") [старый: " & $g_aWebView2_Bridge_Handlers[$i][1] & "]", 1)
                $g_aWebView2_Bridge_Handlers[$i][1] = $sCallbackFunc
                Return True
            EndIf
        Next
    EndIf

    ; Инициализируем массив обработчиков (если ещё не создан)
    If $g_aWebView2_Bridge_Handlers = '' Then
        Local $aHandlers[1][3]
        $aHandlers[0][0] = $sType
        $aHandlers[0][1] = $sCallbackFunc
        $aHandlers[0][2] = $hInstance
        $g_aWebView2_Bridge_Handlers = $aHandlers
    Else
        ; Добавляем новый обработчик
        Local $iSize = UBound($g_aWebView2_Bridge_Handlers, 1)
        ReDim $g_aWebView2_Bridge_Handlers[$iSize + 1][3]
        $g_aWebView2_Bridge_Handlers[$iSize][0] = $sType
        $g_aWebView2_Bridge_Handlers[$iSize][1] = $sCallbackFunc
        $g_aWebView2_Bridge_Handlers[$iSize][2] = $hInstance
    EndIf

    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] ✅ Типизированный обработчик зарегистрирован: " & $sType & " → " & $sCallbackFunc & " (Instance: " & $hInstance & ")" & " → ID = " & $hInstance, 1)

    ; ОТЛАДКА: выводим весь массив обработчиков (ОТКЛЮЧЕНО для уменьшения логов)
    ; _Logger_Write("[WebView2_Events] 📋 Всего обработчиков в массиве: " & UBound($g_aWebView2_Bridge_Handlers, 1), 1)
    ; For $i = 0 To UBound($g_aWebView2_Bridge_Handlers, 1) - 1
    ;     _Logger_Write("[WebView2_Events]    [" & $i & "] " & $g_aWebView2_Bridge_Handlers[$i][0] & " → " & $g_aWebView2_Bridge_Handlers[$i][1] & " (Instance: " & $g_aWebView2_Bridge_Handlers[$i][2] & ")", 1)
    ; Next

    Return True
EndFunc
; ===============================================================================
Func Bridge_OnMessageReceived($sMessage)
    ; Определяем Instance ID через @COM_EventObj
    Local $hInstance = 0

    If IsObj(@COM_EventObj) Then
        $hInstance = _WebView2_Bridge_GetInstanceFromObject(@COM_EventObj)
    EndIf

    ; Передаём в Manager для обработки DLL debug и DevTools
    _WebView2_Events_Manager_OnMessageReceived($sMessage, $hInstance)

    ; ИСПРАВЛЕНИЕ: Выходим после обработки, чтобы избежать двойного вызова обработчиков
    ; Вся логика обработки типизированных событий уже выполнена в _WebView2_Events_DispatchEvent
    Return

    ; Вариант 1: Простой callback (получает всё)
    If $g_sWebView2_Bridge_SimpleCallback <> "" Then
        If $g_bWebView2_Events_DebugMode Then
            If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Вызов простого callback: " & $g_sWebView2_Bridge_SimpleCallback & " → ID = " & $hInstance, 1)
        EndIf
        Call($g_sWebView2_Bridge_SimpleCallback, $sMessage, $hInstance)
        Return
    EndIf

    ; Вариант 2 и 3: Типизированные обработчики
    If $g_aWebView2_Bridge_Handlers <> '' Then
        ; Пробуем распарсить как JSON (Вариант 2)
        Local $vJson = _JSON_Parse($sMessage)
        If Not @error And IsMap($vJson) Then
            ; JSON формат: {"type":"CONTROL", "action":"click", "data":{...}}
            If MapExists($vJson, "type") Then
                Local $sType = $vJson["type"]

                Local $bHandlerFound = False
                ; Ищем ВСЕ обработчики для этого типа И instanceId
                For $i = 0 To UBound($g_aWebView2_Bridge_Handlers, 1) - 1
                    ; ФИЛЬТРАЦИЯ: проверяем тип И instanceId
                    If $g_aWebView2_Bridge_Handlers[$i][0] = $sType And $g_aWebView2_Bridge_Handlers[$i][2] = $hInstance Then
                        ; Нашли обработчик для ЭТОГО окна, вызываем его
                        _Logger_Write("[WebView2_Events] 🔔 ВЫЗОВ ОБРАБОТЧИКА: " & $g_aWebView2_Bridge_Handlers[$i][1] & " для типа " & $sType & " (Instance: " & $hInstance & ")", 1)
                        Call($g_aWebView2_Bridge_Handlers[$i][1], $vJson, $hInstance)
                        $bHandlerFound = True
                    EndIf
                Next

                If $bHandlerFound Then
                    Return ; Обработчики вызваны, выходим
                EndIf
            EndIf
        EndIf

        ; Вариант 3: Префиксы (CONTROL:button_click:btn1)
        For $i = 0 To UBound($g_aWebView2_Bridge_Handlers, 1) - 1
            Local $sPrefix = $g_aWebView2_Bridge_Handlers[$i][0]
            ; ФИЛЬТРАЦИЯ: проверяем префикс И instanceId
            If StringLeft($sMessage, StringLen($sPrefix)) = $sPrefix And $g_aWebView2_Bridge_Handlers[$i][2] = $hInstance Then
                If $g_bWebView2_Events_DebugMode Then
                    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Префикс найден: " & $sPrefix & " → ID = " & $hInstance, 1)
                    If $g_bDebug_WebView2_Events Then _Logger_Write("[WebView2_Events] Вызов префиксного обработчика: " & $g_aWebView2_Bridge_Handlers[$i][1] & " → ID = " & $hInstance, 1)
                EndIf
                ; Передаём сообщение без префикса и Instance ID
                Local $sData = StringTrimLeft($sMessage, StringLen($sPrefix))
                Call($g_aWebView2_Bridge_Handlers[$i][1], $sData, $hInstance)
                Return
            EndIf
        Next

    EndIf
EndFunc

