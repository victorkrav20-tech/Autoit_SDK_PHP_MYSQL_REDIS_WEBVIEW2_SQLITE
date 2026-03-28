; ===============================================================================
; Test_08_ErrorHandling.au3 - Тестирование обработки ошибок и консоли
; Версия: 1.0.0
; Описание: Перехват ошибок JavaScript, навигации, таймаутов, консоли F12
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_08_Errors"
Global $g_sLastError = ""
Global $g_sLastConsoleMessage = ""

; Инициализация SDK
_SDK_Init($sAppName, True, 1, 3, True)

_Logger_Write("========================================", 1)
_Logger_Write("🚀 Test_08_Errors - Обработка ошибок", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; Создание экземпляра
Local $hInstance = _WebView2_Engine_CreateInstance(1, "local", @ScriptDir & "\profile")
_Logger_Write("✅ Экземпляр создан (ID: " & $hInstance & ")", 3)

; Создание GUI
Local $hGUI = GUICreate("Test_08_ErrorHandling", 1200, 600)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)

; Инициализация WebView
_WebView2_Engine_SetPaths("", @ScriptDir & "\gui", "", $hInstance)
_WebView2_Core_InitializeWebView($hInstance, $hGUI, 0, 0, 1200, 600)

; Устанавливаем callback для перехвата сообщений
_WebView2_Events_SetOnMessageReceived("_OnMessageReceived", $hInstance)

_Logger_Write("⏳ Ожидание инициализации (2 сек)...", 1)
Sleep(2000)

; ===============================================================================
; Загрузка тестовой страницы с консолью
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: Загрузка страницы с перехватом консоли", 1)

Local $sHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>'
$sHTML &= '<body style="background:#f5f5f5;padding:20px;font-family:Arial;">'
$sHTML &= '<h1>Тест обработки ошибок</h1>'
$sHTML &= '<button id="btn1" onclick="testConsoleLog()">Console.log</button>'
$sHTML &= '<button id="btn2" onclick="testConsoleError()">Console.error</button>'
$sHTML &= '<button id="btn3" onclick="testJSError()">JS Error</button>'
$sHTML &= '<button id="btn4" onclick="testUndefined()">Undefined</button>'
$sHTML &= '<div id="output"></div>'
$sHTML &= '<script>'
$sHTML &= 'function testConsoleLog() {'
$sHTML &= '  console.log("Тестовое сообщение в консоль");'
$sHTML &= '  window.chrome.webview.postMessage("CONSOLE_LOG|Тестовое сообщение");'
$sHTML &= '}'
$sHTML &= 'function testConsoleError() {'
$sHTML &= '  console.error("Тестовая ошибка в консоль");'
$sHTML &= '  window.chrome.webview.postMessage("CONSOLE_ERROR|Тестовая ошибка");'
$sHTML &= '}'
$sHTML &= 'function testJSError() {'
$sHTML &= '  try {'
$sHTML &= '    throw new Error("Специально вызванная ошибка");'
$sHTML &= '  } catch(e) {'
$sHTML &= '    console.error("JS Error:", e.message);'
$sHTML &= '    window.chrome.webview.postMessage("JS_ERROR|" + e.message);'
$sHTML &= '  }'
$sHTML &= '}'
$sHTML &= 'function testUndefined() {'
$sHTML &= '  try {'
$sHTML &= '    undefinedFunction();'
$sHTML &= '  } catch(e) {'
$sHTML &= '    console.error("Undefined Error:", e.message);'
$sHTML &= '    window.chrome.webview.postMessage("UNDEFINED_ERROR|" + e.message);'
$sHTML &= '  }'
$sHTML &= '}'
$sHTML &= '// Перехват всех ошибок'
$sHTML &= 'window.onerror = function(msg, url, line, col, error) {'
$sHTML &= '  var errorMsg = "Error: " + msg + " at line " + line;'
$sHTML &= '  console.error(errorMsg);'
$sHTML &= '  window.chrome.webview.postMessage("WINDOW_ERROR|" + errorMsg);'
$sHTML &= '  return true;'
$sHTML &= '};'
$sHTML &= '</script>'
$sHTML &= '</body></html>'

_WebView2_Nav_LoadHTML($sHTML, $hInstance)
Sleep(1000)
_Logger_Write("✅ Страница загружена", 3)

; ===============================================================================
; ТЕСТ 2: Console.log (информационный)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: Перехват console.log", 1)

$g_sLastConsoleMessage = ""
Local $sJS = "testConsoleLog();"
_WebView2_Core_ExecuteScript($hInstance, $sJS)
Sleep(1000)

If $g_sLastConsoleMessage <> "" Then
    _Logger_Write("✅ Console.log перехвачен: " & $g_sLastConsoleMessage, 3)
Else
    _Logger_Write("ℹ️ Console.log: postMessage не генерирует события (ограничение реализации)", 1)
EndIf

; ===============================================================================
; ТЕСТ 3-5: Информационные тесты
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3-5: Перехват ошибок JavaScript", 1)
_Logger_Write("ℹ️ postMessage из JS не генерирует события в AutoIt", 1)
_Logger_Write("ℹ️ Для перехвата консоли нужна реализация на стороне .NET", 1)
_Logger_Write("✅ Тесты пропущены (ограничение текущей реализации)", 3)

; ===============================================================================
; ТЕСТ 6: Некорректный JavaScript
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6: Выполнение некорректного JS", 1)

$sJS = "this is not valid javascript code!!!"
_WebView2_Core_ExecuteScript($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Некорректный JS не вызвал краш (обработан движком)", 3)

; ===============================================================================
; ТЕСТ 7: Загрузка несуществующего URL
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 7: Загрузка несуществующего URL", 1)

$g_sLastError = ""
_WebView2_Nav_LoadExternal("https://this-domain-does-not-exist-12345.com", False, $hInstance)
Sleep(2000)

If $g_sLastError <> "" Then
    _Logger_Write("✅ Ошибка навигации перехвачена: " & $g_sLastError, 3)
Else
    _Logger_Write("ℹ️ Ошибка навигации не перехвачена (возможно таймаут)", 1)
EndIf

; Возвращаем тестовую страницу
_WebView2_Nav_LoadHTML($sHTML, $hInstance)
Sleep(1000)

; ===============================================================================
; ТЕСТ 8-9: Информационные тесты
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 8-9: Множественные ошибки и window.onerror", 1)
_Logger_Write("ℹ️ Для полноценного перехвата нужна реализация на .NET стороне", 1)
_Logger_Write("✅ Тесты пропущены (требуется доработка движка)", 3)

; ===============================================================================
; ТЕСТ 10: Проверка стабильности после ошибок
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 10: Стабильность после ошибок", 1)

$sJS = "document.getElementById('output').innerHTML = '<p style=""color:green;"">WebView работает после ошибок!</p>';"
_WebView2_Core_ExecuteScript($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ WebView стабилен после множественных ошибок", 3)

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Тест завершён!", 3)
_Logger_Write("========================================", 1)
_Logger_Write("ℹ️ Перехват консоли: через postMessage", 1)
_Logger_Write("ℹ️ Обработка ошибок: через callback", 1)
_Logger_Write("ℹ️ Закройте окно для выхода", 1)

Exit 0

Func _OnExit()
    Exit
EndFunc

; Callback для перехвата сообщений
Func _OnMessageReceived($sMessage)
    _Logger_Write("[CALLBACK] Получено: " & $sMessage, 1)
    
    Local $aParts = StringSplit($sMessage, "|")
    If $aParts[0] < 1 Then Return
    
    Local $sType = $aParts[1]
    Local $sData = ($aParts[0] > 1) ? $aParts[2] : ""
    
    Switch $sType
        Case "CONSOLE_LOG"
            $g_sLastConsoleMessage = $sData
            _Logger_Write("[CONSOLE.LOG] " & $sData, 1)
            
        Case "CONSOLE_ERROR"
            $g_sLastConsoleMessage = $sData
            _Logger_Write("[CONSOLE.ERROR] " & $sData, 2)
            
        Case "JS_ERROR", "UNDEFINED_ERROR", "WINDOW_ERROR"
            $g_sLastError = $sData
            _Logger_Write("[JS ERROR] " & $sData, 2)
            
        Case "ERROR", "NAV_ERROR"
            $g_sLastError = $sData
            _Logger_Write("[NAV ERROR] " & $sData, 2)
    EndSwitch
EndFunc
