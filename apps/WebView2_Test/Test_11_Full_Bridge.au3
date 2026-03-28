; ===============================================================================
; Test_11_Full_Bridge.au3 - Тест полного Bridge функционала
; Версия: 1.0.0
; Описание: Тестирование WebView2_Engine_Bridge с автоматической инъекцией engine.js
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_11_Full_Bridge"

; ===============================================================================
; Инициализация SDK и WebView2
; ===============================================================================
_Logger_Write("========================================", 1)
_Logger_Write("🧪 Test_11_Full_Bridge - Полный тест Bridge", 1)
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
_WebView2_GUI_Create(0, "Test 11 - Full Bridge", 1200, 700)
_WebView2_Events_WaitForReady(0, 10000)

; Инициализация Bridge (автоматически инъектирует engine.js)
_Logger_Write("", 1)
_Logger_Write("🔧 Инициализация Bridge...", 1)
_WebView2_Bridge_Initialize(0, @ScriptDir & "\gui")

; Регистрация обработчиков для тестовых сообщений
_Logger_Write("", 1)
_Logger_Write("📝 Регистрация обработчиков...", 1)
_WebView2_Bridge_On("simple_test", "_HandleSimpleTest", 0)
_WebView2_Bridge_On("json_test", "_HandleJSONTest", 0)
_WebView2_Bridge_On("data_test", "_HandleDataTest", 0)

; Загрузка страницы
_Logger_Write("", 1)
_Logger_Write("🌐 Загрузка test11.html...", 1)
_WebView2_Nav_Load("test11.html", False, 0)
_WebView2_GUI_Show()

_Logger_Write("", 1)
_Logger_Write("✅ Приложение готово к тестированию!", 3)
_Logger_Write("", 1)
_Logger_Write("🎮 Нажимайте кнопки на странице для тестирования:", 1)
_Logger_Write("   - Console Tests: проверка перехвата console.log/warn/error/info", 1)
_Logger_Write("   - Error Tests: проверка перехвата JS ошибок", 1)
_Logger_Write("   - Message Tests: проверка отправки сообщений в AutoIt", 1)
_Logger_Write("", 1)

; ===============================================================================
; Основной цикл
; ===============================================================================
While 1
    Sleep(1)
WEnd

; ===============================================================================
; Обработчики сообщений от JavaScript
; ===============================================================================

Func _HandleSimpleTest($vJson)
    Local $sMessage = $vJson["payload"]
    _Logger_Write("", 1)
    _Logger_Write("📨 [Simple Test] Получено: " & $sMessage, 3)
    
    ; Отправляем ответ обратно в JS
    _WebView2_Bridge_Send("response", "Получено в AutoIt: " & $sMessage, 0)
EndFunc

Func _HandleJSONTest($vJson)
    Local $sAction = $vJson["payload"]["action"]
    Local $sButtonId = $vJson["payload"]["button_id"]
    Local $iTimestamp = $vJson["payload"]["timestamp"]
    
    _Logger_Write("", 1)
    _Logger_Write("📨 [JSON Test] Action: " & $sAction, 3)
    _Logger_Write("📨 [JSON Test] Button ID: " & $sButtonId, 1)
    _Logger_Write("📨 [JSON Test] Timestamp: " & $iTimestamp, 1)
EndFunc

Func _HandleDataTest($vJson)
    Local $sSensorId = $vJson["payload"]["sensor_id"]
    Local $fValue = $vJson["payload"]["value"]
    Local $sUnit = $vJson["payload"]["unit"]
    Local $sStatus = $vJson["payload"]["status"]
    
    _Logger_Write("", 1)
    _Logger_Write("📨 [Data Test] Sensor: " & $sSensorId, 3)
    _Logger_Write("📨 [Data Test] Value: " & $fValue & " " & $sUnit, 1)
    _Logger_Write("📨 [Data Test] Status: " & $sStatus, 1)
EndFunc
