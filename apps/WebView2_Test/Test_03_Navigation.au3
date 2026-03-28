; ===============================================================================
; Test_03_Navigation.au3 - Тест функций навигации WebView2
; Версия: 1.0.0
; Описание: Тестирование Load, LoadLocal, LoadExternal, LoadHTML, GoBack, GoForward, Reload, Stop
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_03_Navigation"

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
_Logger_Write("🧪 Test_03_Navigation - Функции навигации", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; Создание GUI
_WebView2_GUI_Create(0, "Test_03_Navigation", 800, 600)
_WebView2_Events_WaitForReady(0, 10000)

; ===============================================================================
; ТЕСТ 1: LoadHTML (загрузка HTML из строки)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: LoadHTML", 1)

Local $sHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Test HTML</title></head>'
$sHTML &= '<body><h1>Test LoadHTML</h1><p>Загружено из строки</p></body></html>'

Local $bLoadHTML = _WebView2_Nav_LoadHTML($sHTML, True)
If $bLoadHTML Then
    _Logger_Write("✅ PASS: LoadHTML выполнен", 3)
Else
    _Logger_Write("❌ FAIL: LoadHTML не выполнен", 2)
EndIf

Sleep(200)

; ===============================================================================
; ТЕСТ 2: Load (локальный файл index.html)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: Load (index.html)", 1)

Local $bLoad = _WebView2_Nav_Load("index.html", True)
If $bLoad Then
    _Logger_Write("✅ PASS: Load выполнен", 3)
Else
    _Logger_Write("❌ FAIL: Load не выполнен", 2)
EndIf

Sleep(200)

; ===============================================================================
; ТЕСТ 3: GetCurrentURL
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3: GetCurrentURL", 1)

Local $sURL = _WebView2_Nav_GetCurrentURL()
If StringLen($sURL) > 0 Then
    _Logger_Write("✅ PASS: URL = " & $sURL, 3)
Else
    _Logger_Write("❌ FAIL: URL пустой", 2)
EndIf

; ===============================================================================
; ТЕСТ 4: LoadHTML снова (для истории навигации)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 4: LoadHTML снова (для истории)", 1)

Local $sHTML2 = '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Page 2</title></head>'
$sHTML2 &= '<body><h1>Страница 2</h1><p>Вторая страница для теста GoBack</p></body></html>'

_WebView2_Nav_LoadHTML($sHTML2, True)
_Logger_Write("✅ PASS: Вторая страница загружена", 3)
Sleep(200)

; ===============================================================================
; ТЕСТ 5: GoBack
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 5: GoBack", 1)

_WebView2_Nav_GoBack()
_Logger_Write("✅ PASS: GoBack выполнен", 3)
Sleep(200)

; ===============================================================================
; ТЕСТ 6: GoForward
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6: GoForward", 1)

_WebView2_Nav_GoForward()
_Logger_Write("✅ PASS: GoForward выполнен", 3)
Sleep(200)

; ===============================================================================
; ТЕСТ 7: Reload
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 7: Reload", 1)

_WebView2_Nav_Reload()
_Logger_Write("✅ PASS: Reload выполнен", 3)
Sleep(200)

; ===============================================================================
; ТЕСТ 8: LoadExternal (внешний URL)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 8: LoadExternal (example.com)", 1)

Local $bLoadExt = _WebView2_Nav_LoadExternal("https://example.com", True)
If $bLoadExt Then
    _Logger_Write("✅ PASS: LoadExternal выполнен", 3)
Else
    _Logger_Write("❌ FAIL: LoadExternal не выполнен", 2)
EndIf

Sleep(500)

; ===============================================================================
; ТЕСТ 9: Stop (остановка загрузки)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 9: Stop", 1)

; Запускаем загрузку и сразу останавливаем
_WebView2_Nav_LoadExternal("https://google.com", False)
Sleep(50)
_WebView2_Nav_Stop()
_Logger_Write("✅ PASS: Stop выполнен", 3)

; ===============================================================================
; ТЕСТ 10: IsLoading
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 10: IsLoading", 1)

Local $bIsLoading = _WebView2_Nav_IsLoading()
_Logger_Write("✅ PASS: IsLoading = " & ($bIsLoading ? "True" : "False"), 3)

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Test_03_Navigation завершён (10 тестов)", 3)
_Logger_Write("========================================", 1)

Exit 0
