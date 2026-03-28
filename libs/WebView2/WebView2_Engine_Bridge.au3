; ===============================================================================
; WebView2_Engine_Bridge.au3 - Стандартизированный Bridge для JS↔AutoIt связи
; Версия: 2.2.0 - DevTools Protocol Integration
; Описание: Упрощённый API для двусторонней связи с автоматической инъекцией engine.js
;           + DevTools Protocol для перехвата console и JavaScript исключений
; ===============================================================================
; Функции базовые:
;   _WebView2_Bridge_Initialize($hInstance, $sGuiPath)
;   _WebView2_Bridge_On($sType, $sCallback, $hInstance)
;   _WebView2_Bridge_Send($sType, $vData, $hInstance)
;   _WebView2_Bridge_OnConsole($sLevel, $sMessage, $hInstance)
;   _WebView2_Bridge_OnError($sMessage, $sFile, $iLine, $hInstance)
;   _WebView2_Bridge_OnReady($hInstance)
;
; Функции пушинга (AutoIt → JS):
;   _WebView2_Bridge_UpdateElement($sElementId, $vValue, $hInstance)
;   _WebView2_Bridge_UpdateData($sElementId, $vData, $hInstance) - НОВАЯ! Универсальная для массивов/JSON
;   _WebView2_Bridge_SetHTML($sElementId, $sHTML, $hInstance)
;   _WebView2_Bridge_SetClass($sElementId, $sClassName, $hInstance)
;   _WebView2_Bridge_ShowElement($sElementId, $hInstance)
;   _WebView2_Bridge_HideElement($sElementId, $hInstance)
;   _WebView2_Bridge_CallJS($sFunctionName, $aParams, $hInstance)
;   _WebView2_Bridge_Notify($sType, $sMessage, $hInstance)
;
; COM события DevTools Protocol (автоматические):
;   Bridge_OnConsoleMessage($sLevel, $sMessage, $sSource, $iLine, $iColumn)
;   Bridge_OnJavaScriptException($sMessage, $sSource, $iLine, $iColumn, $sStackTrace)
; ===============================================================================

#include-once
#include "..\..\libs\Utils\Utils.au3"
#include "..\..\libs\json\JSON.au3"
#include "WebView2_Engine_Core.au3"
#include "WebView2_Engine_Events.au3"

; Глобальные переменные Bridge
Global $g_bWebView2_Bridge_Initialized = False
Global $g_sWebView2_Bridge_EnginePath = ""

; ===============================================================================
; Функция: _WebView2_Bridge_Initialize
; Описание: Инициализация Bridge с автоматической инъекцией engine.js
; Параметры:
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
;   $sGuiPath - путь к папке gui (где лежит engine.js)
;   $bSkipEngineInject - пропустить инжект engine.js (по умолчанию False)
; Возврат: True при успехе, False при ошибке
; Примечание: Используйте $bSkipEngineInject = True если engine.js уже инжектирован
;             или если страница использует engine.js из другого источника
; ===============================================================================
Func _WebView2_Bridge_Initialize($hInstance = 0, $sGuiPath = "", $bSkipEngineInject = False, $bSkipDefaultHandlers = False)
    If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] Инициализация Bridge для инстанса" & " → ID = " & $hInstance & " (SkipEngine=" & $bSkipEngineInject & ", SkipHandlers=" & $bSkipDefaultHandlers & ")", 1)

    ; Проверяем путь к engine.js только если НЕ пропускаем инжект
    If Not $bSkipEngineInject Then
        If $sGuiPath = "" Then
            If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ❌ Не указан путь к gui папке" & " → ID = " & $hInstance, 2)
            Return False
        EndIf

        Local $sEnginePath = $sGuiPath & "\engine.js"
        If Not FileExists($sEnginePath) Then
            If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ❌ Файл engine.js не найден: " & $sEnginePath & " → ID = " & $hInstance, 2)
            Return False
        EndIf

        $g_sWebView2_Bridge_EnginePath = $sEnginePath
    Else
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ℹ️ Инжект engine.js пропущен (используется существующий)" & " → ID = " & $hInstance, 1)
    EndIf

    ; Регистрируем встроенные обработчики для стандартных событий (если не пропускаем)
    If Not $bSkipDefaultHandlers Then
        _WebView2_Events_RegisterMessageHandler("js_console", "_WebView2_Bridge_OnConsole", $hInstance)
        _WebView2_Events_RegisterMessageHandler("js_error", "_WebView2_Bridge_OnError", $hInstance)
        _WebView2_Events_RegisterMessageHandler("engine_ready", "_WebView2_Bridge_OnReady", $hInstance)
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ✅ Стандартные обработчики зарегистрированы (js_console, js_error, engine_ready)" & " → ID = " & $hInstance, 1)
    Else
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ℹ️ Стандартные обработчики пропущены (используются кастомные)" & " → ID = " & $hInstance, 1)
    EndIf

    $g_bWebView2_Bridge_Initialized = True
    If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ✅ Bridge инициализирован" & " → ID = " & $hInstance, 3)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_On
; Описание: Регистрация обработчика для типа сообщения (упрощённый синтаксис)
; Параметры:
;   $sType - тип сообщения (например "button_click", "sensor_data")
;   $sCallback - имя функции-обработчика
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_On("button_click", "_HandleButton")
; ===============================================================================
Func _WebView2_Bridge_On($sType, $sCallback, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован, вызовите _WebView2_Bridge_Initialize()" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    _WebView2_Events_RegisterMessageHandler($sType, $sCallback, $hInstance)
    If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ✅ Зарегистрирован обработчик: " & $sType & " → " & $sCallback & " → ID = " & $hInstance, 1)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_Send
; Описание: Отправка сообщения в JavaScript (упрощённый синтаксис)
; Параметры:
;   $sType - тип сообщения
;   $vData - данные (любой тип, будет преобразован в JSON)
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_Send("update_temp", 25.5)
; ===============================================================================
Func _WebView2_Bridge_Send($sType, $vData = "", $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    _WebView2_Events_SendToJS($sType, $vData, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_OnConsole (встроенный обработчик)
; Описание: Обработка console.log/warn/error/info из JavaScript
; Параметры:
;   $vJson - JSON объект с полями {level, message, timestamp}
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; ===============================================================================
Func _WebView2_Bridge_OnConsole($vJson, $hInstance = 0)
    ; Встроенный обработчик - ничего не логирует
    ; Логирование делается в кастомных обработчиках приложения (_NewApp1_OnConsole)
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_OnError (встроенный обработчик)
; Описание: Обработка ошибок JavaScript
; Параметры:
;   $vJson - JSON объект с полями {message, file, line, column, stack}
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; ===============================================================================
Func _WebView2_Bridge_OnError($vJson, $hInstance = 0)
    ; Встроенный обработчик - ничего не логирует
    ; Логирование делается в кастомных обработчиках приложения
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_OnReady (встроенный обработчик)
; Описание: Обработка события готовности engine.js
; Параметры:
;   $vJson - JSON объект (может быть пустым)
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; ===============================================================================
Func _WebView2_Bridge_OnReady($vJson, $hInstance = 0)
    If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ✅ Engine.js готов к работе" & " → ID = " & $hInstance, 3)
    
    ; Отправляем ID окна в JavaScript после полной загрузки engine.js
    _WebView2_Events_SendToJS("set_window_id", $hInstance, $hInstance)
    If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] 📤 Отправлен ID окна в JavaScript" & " → ID = " & $hInstance, 1)
EndFunc
; ===============================================================================
; ФУНКЦИИ ПУШИНГА (AutoIt → JavaScript)
; ===============================================================================

; ===============================================================================
; Функция: _WebView2_Bridge_UpdateElement
; Описание: Обновление текстового содержимого элемента на странице
; Параметры:
;   $sElementId - ID элемента (например "temp_value")
;   $vValue - новое значение (любой тип)
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_UpdateElement("temp_value", 25.5)
; ===============================================================================
Func _WebView2_Bridge_UpdateElement($sElementId, $vValue, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    Local $aData[2]
    $aData[0] = $sElementId
    $aData[1] = $vValue

    _WebView2_Events_SendToJS("update_element", $aData, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_UpdateData
; Описание: Универсальное обновление данных (строки, числа, массивы 1D/2D, JSON объекты)
; Параметры:
;   $sElementId - ID элемента
;   $vData - данные любого типа (string, number, array 1D/2D, Dictionary, Map)
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Примеры:
;   _WebView2_Bridge_UpdateData("temp", 25.5)
;   _WebView2_Bridge_UpdateData("chart", $aArray1D)
;   _WebView2_Bridge_UpdateData("table", $aArray2D)
;   _WebView2_Bridge_UpdateData("sensor", '{"temp":25.5,"status":"ok"}')
; ===============================================================================
Func _WebView2_Bridge_UpdateData($sElementId, $vData, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    Local $sJSON = ""

    ; Простые типы - отправляем как есть
    If IsString($vData) Or IsNumber($vData) Or IsBool($vData) Then
        $sJSON = $vData
    Else
        ; Сложные типы (массивы, объекты) - преобразуем в JSON
        $sJSON = _JSON_GenerateCompact($vData)
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] 📦 Преобразовано в JSON: " & StringLeft($sJSON, 100) & "..." & " → ID = " & $hInstance, 1)
    EndIf

    Local $aData[2]
    $aData[0] = $sElementId
    $aData[1] = $sJSON

    _WebView2_Events_SendToJS("update_data", $aData, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_SetHTML
; Описание: Установка HTML содержимого элемента
; Параметры:
;   $sElementId - ID элемента
;   $sHTML - HTML код
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_SetHTML("content", "<b>Hello</b>")
; ===============================================================================
Func _WebView2_Bridge_SetHTML($sElementId, $sHTML, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    Local $aData[2]
    $aData[0] = $sElementId
    $aData[1] = $sHTML

    _WebView2_Events_SendToJS("set_html", $aData, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_SetClass
; Описание: Установка CSS класса элемента
; Параметры:
;   $sElementId - ID элемента
;   $sClassName - имя CSS класса
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_SetClass("status", "active")
; ===============================================================================
Func _WebView2_Bridge_SetClass($sElementId, $sClassName, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    Local $aData[2]
    $aData[0] = $sElementId
    $aData[1] = $sClassName

    _WebView2_Events_SendToJS("set_class", $aData, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_ShowElement
; Описание: Показать элемент (display: block)
; Параметры:
;   $sElementId - ID элемента
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_ShowElement("warning")
; ===============================================================================
Func _WebView2_Bridge_ShowElement($sElementId, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    _WebView2_Events_SendToJS("show_element", $sElementId, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_HideElement
; Описание: Скрыть элемент (display: none)
; Параметры:
;   $sElementId - ID элемента
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_HideElement("warning")
; ===============================================================================
Func _WebView2_Bridge_HideElement($sElementId, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    _WebView2_Events_SendToJS("hide_element", $sElementId, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_CallJS
; Описание: Вызов JavaScript функции с параметрами
; Параметры:
;   $sFunctionName - имя JS функции
;   $aParams - массив параметров (опционально)
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_CallJS("updateChart", ["temp", 25.5])
; ===============================================================================
Func _WebView2_Bridge_CallJS($sFunctionName, $aParams = "", $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    Local $aData[2]
    $aData[0] = $sFunctionName
    $aData[1] = $aParams

    _WebView2_Events_SendToJS("call_function", $aData, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_Notify
; Описание: Отправка уведомления в JS (для toast/alert)
; Параметры:
;   $sType - тип уведомления (info/warning/error/success)
;   $sMessage - текст сообщения
;   $hInstance - ID инстанса WebView2 (по умолчанию 0)
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Bridge_Notify("success", "Данные сохранены")
; ===============================================================================
Func _WebView2_Bridge_Notify($sType, $sMessage, $hInstance = 0)
    If Not $g_bWebView2_Bridge_Initialized Then
        If $g_bDebug_WebView2_Bridge Then _Logger_Write("[Bridge] ⚠️ Bridge не инициализирован" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    Local $aData[2]
    $aData[0] = $sType
    $aData[1] = $sMessage

    _WebView2_Events_SendToJS("notify", $aData, $hInstance)

    Return True
EndFunc

; ===============================================================================
; Функция: Bridge_OnConsoleMessage
; ===============================================================================
; ===============================================================================
; Обработчик console сообщений от DevTools Protocol (COM событие)
; Вызывается автоматически из DLL при console.log/error/warn/info
; ===============================================================================
Func Bridge_OnConsoleMessage($sLevel, $sMessage, $sSource, $iLine, $iColumn)
	; Определяем Instance ID через @COM_EventObj
	Local $hInstance = 0
	If IsObj(@COM_EventObj) Then
		$hInstance = _WebView2_Bridge_GetInstanceFromObject(@COM_EventObj)
	EndIf
	
	ConsoleWrite("!!! DevTools Console Event Received (Instance: " & $hInstance & ") !!!" & @CRLF)
	ConsoleWrite("Level: " & $sLevel & @CRLF)
	ConsoleWrite("Message: " & $sMessage & @CRLF)
	ConsoleWrite("Source: " & $sSource & ":" & $iLine & ":" & $iColumn & @CRLF)
	
	; Определяем тип лога по уровню консоли
	Local $iLogType = 1 ; По умолчанию INFO
	Switch $sLevel
		Case "error"
			$iLogType = 2 ; ERROR
		Case "warn"
			$iLogType = 2 ; ERROR (предупреждения тоже как ошибки)
		Case "log", "info"
			$iLogType = 1 ; INFO
	EndSwitch
	
	; Логируем в AutoIt
	_Logger_Write("[DevTools Console " & StringUpper($sLevel) & "] " & $sMessage & " at " & $sSource & ":" & $iLine & ":" & $iColumn & " (Instance: " & $hInstance & ")", $iLogType)
	
	; Если есть зарегистрированные обработчики для типа "devtools_console"
	If $g_aWebView2_Bridge_Handlers <> '' Then
		For $i = 0 To UBound($g_aWebView2_Bridge_Handlers, 1) - 1
			If $g_aWebView2_Bridge_Handlers[$i][0] = "devtools_console" Then
				Local $sCallback = $g_aWebView2_Bridge_Handlers[$i][1]
				If $sCallback <> "" Then
					; Вызываем callback с параметрами
					Call($sCallback, $sLevel, $sMessage, $sSource, $iLine, $iColumn)
				EndIf
			EndIf
		Next
	EndIf
EndFunc
; ===============================================================================
; Обработчик JavaScript исключений от DevTools Protocol (COM событие)
; Вызывается автоматически из DLL при любой JS ошибке
; ===============================================================================
Func Bridge_OnJavaScriptException($sMessage, $sSource, $iLine, $iColumn, $sStackTrace)
	ConsoleWrite("!!! DevTools Exception Event Received !!!" & @CRLF)
	ConsoleWrite("Message: " & $sMessage & @CRLF)
	ConsoleWrite("Source: " & $sSource & ":" & $iLine & ":" & $iColumn & @CRLF)
	
	; Логируем детальную информацию об ошибке
	_Logger_Write("=== JAVASCRIPT EXCEPTION (DevTools) ===", 2)
	_Logger_Write("[Message] " & $sMessage, 2)
	_Logger_Write("[File] " & $sSource & ":" & $iLine & ":" & $iColumn, 2)
	
	; Если есть stack trace - логируем его
	If $sStackTrace <> "" And $sStackTrace <> "no stack" Then
		_Logger_Write("[Stack Trace]", 2)
		_Logger_Write($sStackTrace, 2)
	EndIf
	
	_Logger_Write("========================================", 2)
	
	; Если есть зарегистрированные обработчики для типа "devtools_exception"
	If $g_aWebView2_Bridge_Handlers <> '' Then
		For $i = 0 To UBound($g_aWebView2_Bridge_Handlers, 1) - 1
			If $g_aWebView2_Bridge_Handlers[$i][0] = "devtools_exception" Then
				Local $sCallback = $g_aWebView2_Bridge_Handlers[$i][1]
				If $sCallback <> "" Then
					; Вызываем callback с параметрами
					Call($sCallback, $sMessage, $sSource, $iLine, $iColumn, $sStackTrace)
				EndIf
			EndIf
		Next
	EndIf
EndFunc

