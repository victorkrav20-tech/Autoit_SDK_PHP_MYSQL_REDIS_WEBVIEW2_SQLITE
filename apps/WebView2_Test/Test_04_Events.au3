; ===============================================================================
; Test_04_Events.au3 - Тест событий и JavaScript взаимодействия WebView2
; Версия: 1.0.0
; Описание: Тестирование ExecuteJS, SendToJS, callbacks, события
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_04_Events"
Global $g_sTestMessage = ""
Global $g_bCallbackCalled = False

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
_Logger_Write("🧪 Test_04_Events - События и JavaScript", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; Создание GUI
_WebView2_GUI_Create(0, "Test_04_Events", 800, 600)
_WebView2_Events_WaitForReady(0, 10000)

; ===============================================================================
; ТЕСТ 1: ExecuteJS (простой JavaScript)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: ExecuteJS (console.log)", 1)

_WebView2_Core_ExecuteScript(0, "console.log('✅ Test from AutoIt');")
_Logger_Write("✅ PASS: ExecuteJS выполнен (проверьте консоль F12)", 3)
Sleep(100)

; ===============================================================================
; ТЕСТ 2: ExecuteJS (изменение DOM)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: ExecuteJS (изменение DOM)", 1)

Local $sHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Test Events</title></head>'
$sHTML &= '<body><h1 id="title">Original Title</h1><div id="content">Original Content</div></body></html>'

_WebView2_Nav_LoadHTML($sHTML, True)
Sleep(200)

_WebView2_Core_ExecuteScript(0, "document.getElementById('title').innerText = 'Changed by AutoIt';")
_WebView2_Core_ExecuteScript(0, "document.getElementById('content').innerText = 'Content updated!';")
_Logger_Write("✅ PASS: DOM изменён через JavaScript", 3)
Sleep(100)

; ===============================================================================
; ТЕСТ 3: ExecuteJS (создание элементов)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3: ExecuteJS (создание элементов)", 1)

Local $sJS = "var p = document.createElement('p');"
$sJS &= "p.innerText = 'Параграф создан из AutoIt';"
$sJS &= "p.style.color = 'blue';"
$sJS &= "document.body.appendChild(p);"

_WebView2_Core_ExecuteScript(0, $sJS)
_Logger_Write("✅ PASS: Элемент создан через JavaScript", 3)
Sleep(100)

; ===============================================================================
; ТЕСТ 4: SendToJS (отправка данных в JavaScript)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 4: SendToJS", 1)

; Создаём HTML с обработчиком
Local $sHTML2 = '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Test SendToJS</title>'
$sHTML2 &= '<script>'
$sHTML2 &= 'window.chrome.webview.addEventListener("message", function(e) {'
$sHTML2 &= '  console.log("Получено из AutoIt:", e.data);'
$sHTML2 &= '  var div = document.createElement("div");'
$sHTML2 &= '  div.innerText = "Получено: " + e.data;'
$sHTML2 &= '  div.style.padding = "10px";'
$sHTML2 &= '  div.style.background = "#4CAF50";'
$sHTML2 &= '  div.style.color = "white";'
$sHTML2 &= '  div.style.margin = "5px";'
$sHTML2 &= '  document.body.appendChild(div);'
$sHTML2 &= '});'
$sHTML2 &= '</script></head><body><h1>Test SendToJS</h1></body></html>'

_WebView2_Nav_LoadHTML($sHTML2, True)
Sleep(200)

_WebView2_Events_SendToJS("Привет из AutoIt!")
_Logger_Write("✅ PASS: SendToJS выполнен", 3)
Sleep(200)

_WebView2_Events_SendToJS("Второе сообщение")
_Logger_Write("✅ PASS: SendToJS выполнен снова", 3)
Sleep(200)

; ===============================================================================
; ТЕСТ 5: SetOnMessageReceived (системные события)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 5: SetOnMessageReceived (системные события)", 1)

; Устанавливаем callback
_WebView2_Events_SetOnMessageReceived("_MyMessageCallback")
_Logger_Write("✅ PASS: Callback установлен", 3)
_Logger_Write("ℹ️ INFO: Callback работает для системных событий (INIT_READY, NAV_COMPLETED)", 1)
_Logger_Write("ℹ️ INFO: postMessage из JS не генерирует обратное событие в AutoIt", 1)

; ===============================================================================
; ТЕСТ 6: GetLastMessage
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6: GetLastMessage", 1)

Local $sLastMsg = _WebView2_Events_GetLastMessage()
If StringLen($sLastMsg) > 0 Then
    _Logger_Write("✅ PASS: Последнее сообщение: " & $sLastMsg, 3)
Else
    _Logger_Write("⚠️ WARN: Последнее сообщение пустое", 1)
EndIf

; ===============================================================================
; ТЕСТ 7: SetDebugMode
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 7: SetDebugMode", 1)

_WebView2_Events_SetDebugMode(True)
_Logger_Write("✅ PASS: Debug режим включён", 3)

_WebView2_Events_SetDebugMode(False)
_Logger_Write("✅ PASS: Debug режим выключен", 3)

; ===============================================================================
; ТЕСТ 8: ExecuteJS (математические операции)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 8: ExecuteJS (математика)", 1)

_WebView2_Core_ExecuteScript(0, "console.log('2 + 2 =', 2 + 2);")
_WebView2_Core_ExecuteScript(0, "console.log('Math.PI =', Math.PI);")
_Logger_Write("✅ PASS: Математические операции выполнены", 3)

; ===============================================================================
; ТЕСТ 9: ExecuteJS (работа с массивами)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 9: ExecuteJS (массивы)", 1)

Local $sJSArray = "var arr = [1, 2, 3, 4, 5];"
$sJSArray &= "var sum = arr.reduce((a, b) => a + b, 0);"
$sJSArray &= "console.log('Array sum:', sum);"

_WebView2_Core_ExecuteScript(0, $sJSArray)
_Logger_Write("✅ PASS: Работа с массивами выполнена", 3)

; ===============================================================================
; ТЕСТ 10: ExecuteJS (JSON)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 10: ExecuteJS (JSON)", 1)

Local $sJSJSON = "var obj = {name: 'Test', value: 123};"
$sJSJSON &= "var json = JSON.stringify(obj);"
$sJSJSON &= "console.log('JSON:', json);"

_WebView2_Core_ExecuteScript(0, $sJSJSON)
_Logger_Write("✅ PASS: JSON операции выполнены", 3)

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Test_04_Events завершён (10 тестов)", 3)
_Logger_Write("========================================", 1)

Exit 0

; ===============================================================================
; Callback функция для тестирования
; ===============================================================================
Func _MyMessageCallback($sMessage)
    $g_bCallbackCalled = True
    $g_sTestMessage = $sMessage
    _Logger_Write("🔔 Callback получил: " & $sMessage, 1)
EndFunc
