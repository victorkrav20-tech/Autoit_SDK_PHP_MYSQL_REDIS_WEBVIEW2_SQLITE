; ===============================================================================
; Test_10_Bridge.au3 - Тест двусторонней связи JS→AutoIt через Bridge
; Версия: 2.0.0 (с замерами производительности)
; Описание: Тестирование 3 вариантов Bridge с замером времени отклика
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_10_Bridge"
Global $g_sSimpleMessage = ""
Global $g_sJSONType = ""
Global $g_sJSONAction = ""
Global $g_sPrefixData = ""
Global $g_iTestsPassed = 0
Global $g_hResponseTimer = 0  ; Таймер для замера отклика
Global $g_bResponseReceived = False

; ===============================================================================
; Инициализация SDK и WebView2
; ===============================================================================
Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

If Not $bSDKInit Or Not $bWebView2Init Then
    ConsoleWrite("❌ Init Failed" & @CRLF)
    Exit 1
EndIf

_Logger_Write("========================================", 1)
_Logger_Write("🧪 Test_10_Bridge - JS→AutoIt связь (Performance)", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; Создание GUI
_WebView2_GUI_Create(0, "Test_10_Bridge", 1200, 700)
_WebView2_Events_WaitForReady(0, 10000)
_WebView2_Nav_Load("Test_10_Bridge.html")
_WebView2_GUI_Show()

Sleep(1000)  ; Даём странице загрузиться

; ===============================================================================
; ТЕСТ 1: Простой callback (Вариант 1)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: Простой Bridge callback", 1)

; Устанавливаем простой callback
_WebView2_Events_SetOnJSMessage("_SimpleCallback")
_Logger_Write("✅ Callback установлен: _SimpleCallback", 1)

; Симулируем клик кнопки через JavaScript и замеряем время
$g_sSimpleMessage = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendSimple();")

; Ждём ответа (максимум 1 секунда)
Local $iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sSimpleMessage = "Привет из JavaScript!" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: Простой callback получил сообщение", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: Сообщение не получено", 2)
EndIf

Sleep(200)

; ===============================================================================
; ТЕСТ 2-5: JSON типизация (Вариант 2)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2-5: JSON типизированные обработчики", 1)

; Сбрасываем простой callback
$g_sWebView2_Bridge_SimpleCallback = ""

; Регистрируем обработчики для разных типов
_WebView2_Events_RegisterMessageHandler("CONTROL", "_HandleControl")
_WebView2_Events_RegisterMessageHandler("INFO", "_HandleInfo")
_WebView2_Events_RegisterMessageHandler("ALARM", "_HandleAlarm")
_WebView2_Events_RegisterMessageHandler("DATA", "_HandleData")
_Logger_Write("✅ Зарегистрированы 4 JSON обработчика", 1)

; ТЕСТ 2: CONTROL
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: JSON тип CONTROL", 1)
$g_sJSONType = ""
$g_sJSONAction = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendJSON('CONTROL', 'button_click', {id:'btn1'});")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sJSONType = "CONTROL" And $g_sJSONAction = "button_click" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: CONTROL обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: CONTROL не обработан", 2)
EndIf

Sleep(200)

; ТЕСТ 3: INFO
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3: JSON тип INFO", 1)
$g_sJSONType = ""
$g_sJSONAction = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendJSON('INFO', 'status_update', {status:'ok'});")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sJSONType = "INFO" And $g_sJSONAction = "status_update" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: INFO обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: INFO не обработан", 2)
EndIf

Sleep(200)

; ТЕСТ 4: ALARM
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 4: JSON тип ALARM", 1)
$g_sJSONType = ""
$g_sJSONAction = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendJSON('ALARM', 'high_temp', {temp:85});")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sJSONType = "ALARM" And $g_sJSONAction = "high_temp" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: ALARM обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: ALARM не обработан", 2)
EndIf

Sleep(200)

; ТЕСТ 5: DATA
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 5: JSON тип DATA", 1)
$g_sJSONType = ""
$g_sJSONAction = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendJSON('DATA', 'sensor_reading', {value:123.45});")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sJSONType = "DATA" And $g_sJSONAction = "sensor_reading" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: DATA обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: DATA не обработан", 2)
EndIf

Sleep(200)

; ===============================================================================
; ТЕСТ 6-9: Префиксы (Вариант 3)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6-9: Префиксные обработчики", 1)

; Очищаем JSON обработчики
$g_aWebView2_Bridge_Handlers = ''

; Регистрируем префиксные обработчики
_WebView2_Events_RegisterMessageHandler("CMD:", "_HandleCommand")
_WebView2_Events_RegisterMessageHandler("LOG:", "_HandleLog")
_WebView2_Events_RegisterMessageHandler("ERR:", "_HandleError")
_WebView2_Events_RegisterMessageHandler("DBG:", "_HandleDebug")
_Logger_Write("✅ Зарегистрированы 4 префиксных обработчика", 1)

; ТЕСТ 6: CMD:
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6: Префикс CMD:", 1)
$g_sPrefixData = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendPrefix('CMD:', 'start_motor:1');")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sPrefixData = "start_motor:1" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: CMD: обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: CMD: не обработан", 2)
EndIf

Sleep(200)

; ТЕСТ 7: LOG:
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 7: Префикс LOG:", 1)
$g_sPrefixData = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendPrefix('LOG:', 'system_started');")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sPrefixData = "system_started" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: LOG: обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: LOG: не обработан", 2)
EndIf

Sleep(200)

; ТЕСТ 8: ERR:
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 8: Префикс ERR:", 1)
$g_sPrefixData = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendPrefix('ERR:', 'connection_lost');")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sPrefixData = "connection_lost" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: ERR: обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: ERR: не обработан", 2)
EndIf

Sleep(200)

; ТЕСТ 9: DBG:
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 9: Префикс DBG:", 1)
$g_sPrefixData = ""
$g_bResponseReceived = False
$g_hResponseTimer = TimerInit()

_WebView2_Core_ExecuteScript(0, "sendPrefix('DBG:', 'variable_x=42');")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

If $g_sPrefixData = "variable_x=42" Then
    Local $fResponseTime = TimerDiff($g_hResponseTimer)
    _Logger_Write("✅ PASS: DBG: обработчик вызван", 3)
    _Logger_Write("⏱️ Время отклика: " & Round($fResponseTime, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: DBG: не обработан", 2)
EndIf

Sleep(200)

; ===============================================================================
; ТЕСТ 10: Смешанный режим (JSON + префиксы)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 10: Смешанный режим", 1)

; Очищаем обработчики
$g_aWebView2_Bridge_Handlers = ''

; Регистрируем оба типа
_WebView2_Events_RegisterMessageHandler("CONTROL", "_HandleControl")
_WebView2_Events_RegisterMessageHandler("CMD:", "_HandleCommand")
_Logger_Write("✅ Зарегистрированы JSON и префиксный обработчики", 1)

; Тестируем JSON
$g_sJSONType = ""
$g_bResponseReceived = False
Local $hTimer1 = TimerInit()

_WebView2_Core_ExecuteScript(0, "window.chrome.webview.postMessage(JSON.stringify({type:'CONTROL',action:'test'}));")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

Local $bJSONWorks = ($g_sJSONType = "CONTROL")
Local $fTime1 = TimerDiff($hTimer1)

; Тестируем префикс
$g_sPrefixData = ""
$g_bResponseReceived = False
Local $hTimer2 = TimerInit()

_WebView2_Core_ExecuteScript(0, "window.chrome.webview.postMessage('CMD:mixed_test');")

$iWaitTime = 0
While Not $g_bResponseReceived And $iWaitTime < 1000
    Sleep(10)
    $iWaitTime += 10
WEnd

Local $bPrefixWorks = ($g_sPrefixData = "mixed_test")
Local $fTime2 = TimerDiff($hTimer2)

If $bJSONWorks And $bPrefixWorks Then
    _Logger_Write("✅ PASS: Смешанный режим работает", 3)
    _Logger_Write("⏱️ JSON отклик: " & Round($fTime1, 2) & " мс, Префикс отклик: " & Round($fTime2, 2) & " мс", 1)
    $g_iTestsPassed += 1
Else
    _Logger_Write("❌ FAIL: Смешанный режим не работает (JSON:" & $bJSONWorks & ", Prefix:" & $bPrefixWorks & ")", 2)
EndIf

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Test_10_Bridge завершён (" & $g_iTestsPassed & "/10 тестов)", 3)
_Logger_Write("========================================", 1)

; ===============================================================================
; Регистрация всех обработчиков для ручного тестирования
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("🔧 Регистрация всех обработчиков для ручного тестирования...", 1)

; Очищаем старые обработчики
$g_sWebView2_Bridge_SimpleCallback = ""
$g_aWebView2_Bridge_Handlers = ''

; Регистрируем ВСЕ обработчики (JSON + префиксы + простой текст)
_WebView2_Events_RegisterMessageHandler("CONTROL", "_HandleControl")
_WebView2_Events_RegisterMessageHandler("INFO", "_HandleInfo")
_WebView2_Events_RegisterMessageHandler("ALARM", "_HandleAlarm")
_WebView2_Events_RegisterMessageHandler("DATA", "_HandleData")
_WebView2_Events_RegisterMessageHandler("CMD:", "_HandleCommand")
_WebView2_Events_RegisterMessageHandler("LOG:", "_HandleLog")
_WebView2_Events_RegisterMessageHandler("ERR:", "_HandleError")
_WebView2_Events_RegisterMessageHandler("DBG:", "_HandleDebug")
_WebView2_Events_RegisterMessageHandler("Привет", "_HandleSimpleText")  ; Для простого текста

_Logger_Write("✅ Все обработчики зарегистрированы (4 JSON + 4 префикса + 1 простой текст)", 1)
_Logger_Write("", 1)
_Logger_Write("🎮 Теперь можно нажимать кнопки на странице для ручного тестирования!", 1)
_Logger_Write("", 1)

; Основной цикл для ручного тестирования
While 1
    Sleep(1)
WEnd

; ===============================================================================
; Callback функции
; ===============================================================================

; Вариант 1: Простой callback
Func _SimpleCallback($sMessage)
    $g_sSimpleMessage = $sMessage
    $g_bResponseReceived = True
    _Logger_Write("🔔 [Simple] Получено: " & $sMessage, 1)
EndFunc

; Вариант 2: JSON обработчики
Func _HandleControl($vJson)
    $g_sJSONType = $vJson["type"]
    $g_sJSONAction = $vJson["action"]
    $g_bResponseReceived = True
    _Logger_Write("🔔 [JSON-CONTROL] Type: " & $g_sJSONType & ", Action: " & $g_sJSONAction, 1)
EndFunc

Func _HandleInfo($vJson)
    $g_sJSONType = $vJson["type"]
    $g_sJSONAction = $vJson["action"]
    $g_bResponseReceived = True
    _Logger_Write("🔔 [JSON-INFO] Type: " & $g_sJSONType & ", Action: " & $g_sJSONAction, 1)
EndFunc

Func _HandleAlarm($vJson)
    $g_sJSONType = $vJson["type"]
    $g_sJSONAction = $vJson["action"]
    $g_bResponseReceived = True
    _Logger_Write("🔔 [JSON-ALARM] Type: " & $g_sJSONType & ", Action: " & $g_sJSONAction, 1)
EndFunc

Func _HandleData($vJson)
    $g_sJSONType = $vJson["type"]
    $g_sJSONAction = $vJson["action"]
    $g_bResponseReceived = True
    _Logger_Write("🔔 [JSON-DATA] Type: " & $g_sJSONType & ", Action: " & $g_sJSONAction, 1)
EndFunc

; Вариант 3: Префиксные обработчики
Func _HandleCommand($sData)
    $g_sPrefixData = $sData
    $g_bResponseReceived = True
    _Logger_Write("🔔 [PREFIX-CMD] Data: " & $sData, 1)
EndFunc

Func _HandleLog($sData)
    $g_sPrefixData = $sData
    $g_bResponseReceived = True
    _Logger_Write("🔔 [PREFIX-LOG] Data: " & $sData, 1)
EndFunc

Func _HandleError($sData)
    $g_sPrefixData = $sData
    $g_bResponseReceived = True
    _Logger_Write("🔔 [PREFIX-ERR] Data: " & $sData, 1)
EndFunc

Func _HandleDebug($sData)
    $g_sPrefixData = $sData
    $g_bResponseReceived = True
    _Logger_Write("🔔 [PREFIX-DBG] Data: " & $sData, 1)
EndFunc

; Обработчик простого текста
Func _HandleSimpleText($sData)
    _Logger_Write("🔔 [SIMPLE-TEXT] Получено: Привет" & $sData, 3)
EndFunc
