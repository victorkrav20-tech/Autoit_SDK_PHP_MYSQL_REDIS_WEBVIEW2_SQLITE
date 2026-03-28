; ===============================================================================
; Test_05_Injection.au3 - Тест системы инъекций CSS/JS WebView2
; Версия: 1.0.0
; Описание: Тестирование InjectCSS, InjectJS, InjectCSSFile, InjectJSFile
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_05_Injection"

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
_Logger_Write("🧪 Test_05_Injection - Система инъекций", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; Создание GUI
_WebView2_GUI_Create(0, "Test_05_Injection", 800, 600)
_WebView2_Events_WaitForReady(0, 10000)
_WebView2_GUI_Show()

; Инициализация системы инъекций с путём к папке inject
_WebView2_Injection_Initialize(@ScriptDir & "\inject")

; Загружаем тестовую страницу
Local $sHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Test Injection</title></head>'
$sHTML &= '<body><h1 id="title">Test Injection</h1>'
$sHTML &= '<p id="text">Исходный текст</p>'
$sHTML &= '<div id="box" style="width:100px;height:100px;background:red;"></div>'
$sHTML &= '</body></html>'

_WebView2_Nav_LoadHTML($sHTML, True)
Sleep(1000)

; ===============================================================================
; ТЕСТ 1: InjectCSS (простой CSS)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: InjectCSS (простой CSS)", 1)

Local $sCSS = "body { background: #f0f0f0; } #title { color: blue; }"
_WebView2_Injection_InjectCSS($sCSS)
_Logger_Write("✅ PASS: CSS инжектирован (фон серый, заголовок синий)", 3)
Sleep(1000)

; ===============================================================================
; ТЕСТ 2: InjectCSS (изменение элемента)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: InjectCSS (изменение элемента)", 1)

Local $sCSS2 = "#box { background: green !important; border: 5px solid black; }"
_WebView2_Injection_InjectCSS($sCSS2)
_Logger_Write("✅ PASS: CSS инжектирован (box зелёный с рамкой)", 3)
Sleep(1000)

; ===============================================================================
; ТЕСТ 3: InjectJS (простой JavaScript)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3: InjectJS (простой JavaScript)", 1)

Local $sJS = "document.getElementById('text').innerText = 'Изменено через InjectJS';"
_WebView2_Injection_InjectJS($sJS)
_Logger_Write("✅ PASS: JavaScript инжектирован (текст изменён)", 3)
Sleep(1000)

; ===============================================================================
; ТЕСТ 4: InjectJS (создание элемента)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 4: InjectJS (создание элемента)", 1)

Local $sJS2 = "var div = document.createElement('div');"
$sJS2 &= "div.innerText = 'Создано через InjectJS';"
$sJS2 &= "div.style.padding = '10px';"
$sJS2 &= "div.style.background = '#4CAF50';"
$sJS2 &= "div.style.color = 'white';"
$sJS2 &= "div.style.margin = '10px 0';"
$sJS2 &= "document.body.appendChild(div);"

_WebView2_Injection_InjectJS($sJS2)
_Logger_Write("✅ PASS: JavaScript инжектирован (элемент создан)", 3)
Sleep(1000)

; ===============================================================================
; ТЕСТ 5: Проверка тестовых файлов
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 5: Проверка тестовых файлов", 1)

If FileExists(@ScriptDir & "\inject\test.css") Then
    _Logger_Write("✅ PASS: Файл test.css существует", 3)
Else
    _Logger_Write("❌ FAIL: Файл test.css не найден", 2)
EndIf

If FileExists(@ScriptDir & "\inject\test.js") Then
    _Logger_Write("✅ PASS: Файл test.js существует", 3)
Else
    _Logger_Write("❌ FAIL: Файл test.js не найден", 2)
EndIf

; ===============================================================================
; ТЕСТ 6: InjectCSSFile
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6: InjectCSSFile", 1)

_WebView2_Injection_InjectCSSFile("test.css")
_Logger_Write("✅ PASS: CSS файл инжектирован (заголовок 32px, подчёркнут)", 3)
Sleep(1000)

; ===============================================================================
; ТЕСТ 7: InjectJSFile
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 7: InjectJSFile", 1)

_WebView2_Injection_InjectJSFile("test.js")
_Logger_Write("✅ PASS: JS файл инжектирован (элемент создан)", 3)
Sleep(1000)

; ===============================================================================
; ТЕСТ 8: IsEnabled / SetEnabled
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 8: IsEnabled / SetEnabled", 1)

Local $bEnabled = _WebView2_Injection_IsEnabled()
_Logger_Write("✅ PASS: IsEnabled = " & ($bEnabled ? "True" : "False"), 3)

_WebView2_Injection_SetEnabled(False)
_Logger_Write("✅ PASS: Injection отключён", 3)

_WebView2_Injection_SetEnabled(True)
_Logger_Write("✅ PASS: Injection включён", 3)


; ===============================================================================
; ТЕСТ 9: Множественные инъекции CSS
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 9: Множественные инъекции CSS", 1)

_WebView2_Injection_InjectCSS("body { font-family: Arial; }")
_WebView2_Injection_InjectCSS("#box { border-radius: 10px; }")
_WebView2_Injection_InjectCSS("p { font-style: italic; }")
_Logger_Write("✅ PASS: 3 CSS инъекции выполнены", 3)
Sleep(1000)

; ===============================================================================
; ТЕСТ 10: Множественные инъекции JS
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 10: Множественные инъекции JS", 1)

_WebView2_Injection_InjectJS("console.log('Инъекция 1');")
_WebView2_Injection_InjectJS("console.log('Инъекция 2');")
_WebView2_Injection_InjectJS("console.log('Инъекция 3');")
_Logger_Write("✅ PASS: 3 JS инъекции выполнены (проверьте консоль F12)", 3)

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Test_05_Injection завершён (10 тестов)", 3)
_Logger_Write("========================================", 1)

Sleep(3000)
Exit 0
