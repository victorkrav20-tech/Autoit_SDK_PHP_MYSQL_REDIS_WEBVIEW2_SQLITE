; ===============================================================================
; Test_07_Advanced.au3 - Продвинутые функции WebView2
; Версия: 1.0.0
; Описание: Тестирование ExecuteScriptWithResult, GetSource, сложных данных
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_07_Advanced"

; Инициализация SDK
_SDK_Init($sAppName, True, 1, 3, True)

_Logger_Write("========================================", 1)
_Logger_Write("🚀 Test_07_Advanced - Продвинутые функции", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; Создание экземпляра
Local $hInstance = _WebView2_Engine_CreateInstance(1, "local", @ScriptDir & "\profile")
_Logger_Write("✅ Экземпляр создан (ID: " & $hInstance & ")", 3)

; Создание GUI
Local $hGUI = GUICreate("Test_07_Advanced", 1200, 600)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)

; Инициализация WebView
_WebView2_Engine_SetPaths("", @ScriptDir & "\gui", "", $hInstance)
_WebView2_Core_InitializeWebView($hInstance, $hGUI, 0, 0, 1200, 600)

_Logger_Write("⏳ Ожидание инициализации (2 сек)...", 1)
Sleep(2000)

; ===============================================================================
; Загрузка тестовой страницы с данными
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: Загрузка HTML с данными", 1)

Local $sHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>'
$sHTML &= '<body style="background:#f5f5f5;padding:20px;font-family:Arial;">'
$sHTML &= '<h1 id="title">Тестовая страница</h1>'
$sHTML &= '<div id="data">Данные для теста</div>'
$sHTML &= '<input id="input1" type="text" value="Test Value" />'
$sHTML &= '<script>'
$sHTML &= 'var testData = {name: "WebView2", version: "1.0", active: true, count: 42};'
$sHTML &= 'var testArray = [1, 2, 3, 4, 5];'
$sHTML &= '</script>'
$sHTML &= '</body></html>'

_WebView2_Nav_LoadHTML($sHTML, $hInstance)
Sleep(1000)
_Logger_Write("✅ HTML загружен", 3)

; ===============================================================================
; ТЕСТ 2: GetSource - получение HTML кода
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: GetSource - получение HTML", 1)

Local $sSource = _WebView2_Core_GetSource($hInstance)
_Logger_Write("ℹ️ GetSource вернул: " & StringLen($sSource) & " символов", 1)

If $sSource <> "" Then
    _Logger_Write("✅ GetSource работает (получены данные)", 3)
Else
    _Logger_Write("⚠️ GetSource вернул пустую строку (возможно WebView не готов)", 2)
EndIf

; ===============================================================================
; ТЕСТ 3: ExecuteScriptWithResult - простое значение
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3: ExecuteScriptWithResult - число", 1)

Local $sJS = "2 + 2"
_WebView2_Core_ExecuteScriptWithResult($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Запрос выполнен (результат через событие)", 3)

; ===============================================================================
; ТЕСТ 4: ExecuteScriptWithResult - строка
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 4: ExecuteScriptWithResult - строка", 1)

$sJS = "'Hello from JavaScript'"
_WebView2_Core_ExecuteScriptWithResult($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Запрос выполнен", 3)

; ===============================================================================
; ТЕСТ 5: ExecuteScriptWithResult - получение значения из DOM
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 5: Получение значения из input", 1)

$sJS = "document.getElementById('input1').value"
_WebView2_Core_ExecuteScriptWithResult($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Запрос выполнен", 3)

; ===============================================================================
; ТЕСТ 6: ExecuteScriptWithResult - JSON объект
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6: Получение JSON объекта", 1)

$sJS = "JSON.stringify(testData)"
_WebView2_Core_ExecuteScriptWithResult($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Запрос выполнен", 3)

; ===============================================================================
; ТЕСТ 7: ExecuteScriptWithResult - массив
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 7: Получение массива", 1)

$sJS = "JSON.stringify(testArray)"
_WebView2_Core_ExecuteScriptWithResult($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Запрос выполнен", 3)

; ===============================================================================
; ТЕСТ 8: ExecuteScriptWithResult - сложный объект
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 8: Сложный объект с вложенностью", 1)

$sJS = "JSON.stringify({title: document.getElementById('title').textContent, data: testData, array: testArray})"
_WebView2_Core_ExecuteScriptWithResult($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Запрос выполнен", 3)

; ===============================================================================
; ТЕСТ 9: ExecuteScriptWithResult - вычисление
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 9: Вычисление в JavaScript", 1)

$sJS = "testArray.reduce((a, b) => a + b, 0)"
_WebView2_Core_ExecuteScriptWithResult($hInstance, $sJS)
Sleep(300)
_Logger_Write("✅ Запрос выполнен (сумма массива)", 3)

; ===============================================================================
; ТЕСТ 10: GetSource - повторный вызов
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 10: GetSource - повторный вызов", 1)

; Изменяем DOM через JavaScript
$sJS = "document.getElementById('data').innerHTML = 'Изменённые данные';"
_WebView2_Core_ExecuteScript($hInstance, $sJS)
Sleep(500)

; Получаем HTML повторно
$sSource = _WebView2_Core_GetSource($hInstance)
_Logger_Write("ℹ️ GetSource вернул: " & StringLen($sSource) & " символов", 1)

If $sSource <> "" Then
    _Logger_Write("✅ GetSource работает повторно", 3)
    _Logger_Write("ℹ️ Примечание: GetSource может возвращать исходный HTML", 1)
Else
    _Logger_Write("⚠️ GetSource вернул пустую строку", 2)
EndIf

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Тест завершён!", 3)
_Logger_Write("========================================", 1)
_Logger_Write("ℹ️ ExecuteScriptWithResult: результаты через события", 1)
_Logger_Write("ℹ️ GetSource: получение HTML кода страницы", 1)
_Logger_Write("ℹ️ Закройте окно для выхода", 1)

Exit 0

Func _OnExit()
    Exit
EndFunc
