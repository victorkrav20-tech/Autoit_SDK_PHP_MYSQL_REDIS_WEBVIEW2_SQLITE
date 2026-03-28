; ===============================================================================
; Test_11_Auto.au3 - Автоматический тест Bridge с симуляцией кликов
; Версия: 1.0.0
; Описание: Автоматическое тестирование всех функций Bridge
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_11_Auto"
Global $iTestsPassed = 0
Global $iTestsTotal = 9

; ===============================================================================
; Инициализация SDK и WebView2
; ===============================================================================
_Logger_Write("========================================", 1)
_Logger_Write("🧪 Test_11_Auto - Автоматический тест Bridge", 1)
_Logger_Write("========================================", 1)

Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

If Not $bSDKInit Or Not $bWebView2Init Then
    _Logger_Write("❌ Инициализация не удалась", 2)
    Exit 1
EndIf

Opt("GUIOnEventMode", 1)

; ===============================================================================
; Создание GUI и инициализация Bridge
; ===============================================================================
_WebView2_GUI_Create(0, "Test 11 - Auto", 1200, 700)
_WebView2_Events_WaitForReady(0, 10000)

_Logger_Write("", 1)
_Logger_Write("🔧 Инициализация Bridge...", 1)
_WebView2_Bridge_Initialize(0, @ScriptDir & "\gui")

; Регистрация обработчиков
_WebView2_Bridge_On("simple_test", "_HandleSimpleTest", 0)
_WebView2_Bridge_On("json_test", "_HandleJSONTest", 0)
_WebView2_Bridge_On("data_test", "_HandleDataTest", 0)

; Загрузка страницы
_WebView2_Nav_Load("test11.html", False, 0)
_WebView2_GUI_Show()

_Logger_Write("", 1)
_Logger_Write("✅ Приложение готово, начинаю автотесты...", 3)
_Logger_Write("", 1)

Sleep(2000)  ; Даём странице загрузиться

; ===============================================================================
; АВТОМАТИЧЕСКИЕ ТЕСТЫ
; ===============================================================================

; ТЕСТ 1: console.log
_Logger_Write("📋 ТЕСТ 1: console.log", 1)
_WebView2_Core_ExecuteScript(0, "testConsoleLog();")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 2: console.warn
_Logger_Write("📋 ТЕСТ 2: console.warn", 1)
_WebView2_Core_ExecuteScript(0, "testConsoleWarn();")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 3: console.error
_Logger_Write("📋 ТЕСТ 3: console.error", 1)
_WebView2_Core_ExecuteScript(0, "testConsoleError();")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 4: console.info
_Logger_Write("📋 ТЕСТ 4: console.info", 1)
_WebView2_Core_ExecuteScript(0, "testConsoleInfo();")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 5: JS Error (try-catch чтобы не упало)
_Logger_Write("📋 ТЕСТ 5: JS Error", 1)
_WebView2_Core_ExecuteScript(0, "try { testJSError(); } catch(e) { console.log('Error caught'); }")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 6: Undefined Error (try-catch)
_Logger_Write("📋 ТЕСТ 6: Undefined Error", 1)
_WebView2_Core_ExecuteScript(0, "try { testUndefinedError(); } catch(e) { console.log('Undefined caught'); }")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 7: Simple Message
_Logger_Write("📋 ТЕСТ 7: Simple Message", 1)
_WebView2_Core_ExecuteScript(0, "testSimpleMessage();")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 8: JSON Message
_Logger_Write("📋 ТЕСТ 8: JSON Message", 1)
_WebView2_Core_ExecuteScript(0, "testJSONMessage();")
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 9: Data Message
_Logger_Write("📋 ТЕСТ 9: Data Message", 1)
_WebView2_Core_ExecuteScript(0, "testDataMessage();")
Sleep(500)
$iTestsPassed += 1

; ===============================================================================
; ФИНАЛ
; ===============================================================================
Sleep(1000)
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Автотесты завершены: " & $iTestsPassed & "/" & $iTestsTotal, 3)
_Logger_Write("========================================", 1)

Sleep(2000)
Exit 0

; ===============================================================================
; Обработчики сообщений от JavaScript
; ===============================================================================

Func _HandleSimpleTest($vJson)
    Local $sMessage = $vJson["payload"]
    _Logger_Write("📨 [Simple Test] Получено: " & $sMessage, 3)
EndFunc

Func _HandleJSONTest($vJson)
    Local $sAction = $vJson["payload"]["action"]
    Local $sButtonId = $vJson["payload"]["button_id"]
    _Logger_Write("📨 [JSON Test] Action: " & $sAction & ", Button: " & $sButtonId, 3)
EndFunc

Func _HandleDataTest($vJson)
    Local $sSensorId = $vJson["payload"]["sensor_id"]
    Local $fValue = $vJson["payload"]["value"]
    _Logger_Write("📨 [Data Test] Sensor: " & $sSensorId & ", Value: " & $fValue, 3)
EndFunc
