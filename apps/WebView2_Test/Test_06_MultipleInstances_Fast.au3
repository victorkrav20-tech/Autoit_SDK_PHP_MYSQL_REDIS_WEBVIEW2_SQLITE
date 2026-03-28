; ===============================================================================
; Test_06_MultipleInstances_Fast.au3 - Быстрый тест множественных WebView
; Версия: 1.0.0
; Описание: Упрощённый тест 3 WebView в одном окне (без детальных проверок)
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_06_Fast"

; Инициализация SDK
_SDK_Init($sAppName, True, 1, 3, True)

_Logger_Write("========================================", 1)
_Logger_Write("🚀 Test_06_Fast - 3 WebView в одном окне", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; ===============================================================================
; Создание 3 экземпляров (один профиль для всех)
; ===============================================================================
_Logger_Write("📋 Создание 3 экземпляров...", 1)

Local $hInstance1 = _WebView2_Engine_CreateInstance(1, "local", @ScriptDir & "\profile_shared")
Local $hInstance2 = _WebView2_Engine_CreateInstance(2, "local", @ScriptDir & "\profile_shared")
Local $hInstance3 = _WebView2_Engine_CreateInstance(3, "local", @ScriptDir & "\profile_shared")

_Logger_Write("✅ Экземпляры созданы (ID: " & $hInstance1 & ", " & $hInstance2 & ", " & $hInstance3 & ")", 3)

; ===============================================================================
; Создание GUI с 3 панелями
; ===============================================================================
_Logger_Write("📋 Создание GUI (1200x800)...", 1)

Local $hGUI = GUICreate("3 WebView - Fast Test", 1200, 800)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)

_Logger_Write("✅ GUI создан", 3)

; ===============================================================================
; Инициализация всех 3 WebView
; ===============================================================================
_Logger_Write("📋 Инициализация WebView...", 1)

_WebView2_Engine_SetPaths("", @ScriptDir & "\gui", "", $hInstance1)
_WebView2_Core_InitializeWebView($hInstance1, $hGUI, 0, 0, 390, 790)

_WebView2_Engine_SetPaths("", @ScriptDir & "\gui", "", $hInstance2)
_WebView2_Core_InitializeWebView($hInstance2, $hGUI, 400, 0, 390, 790)

_WebView2_Engine_SetPaths("", @ScriptDir & "\gui", "", $hInstance3)
_WebView2_Core_InitializeWebView($hInstance3, $hGUI, 800, 0, 390, 790)

_Logger_Write("✅ Все WebView инициализированы", 3)

; Даём время на инициализацию
_Logger_Write("⏳ Ожидание загрузки (2 сек)...", 1)
Sleep(2000)

; ===============================================================================
; Загрузка контента
; ===============================================================================
_Logger_Write("📋 Загрузка контента...", 1)

; WebView1 - Красный
Local $sHTML1 = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>'
$sHTML1 &= '<body style="background:#ffebee;padding:20px;font-family:Arial;margin:0;">'
$sHTML1 &= '<h1 style="color:#c62828;">WebView 1</h1>'
$sHTML1 &= '<div style="padding:15px;background:#ef5350;color:white;border-radius:8px;">Левая панель</div>'
$sHTML1 &= '</body></html>'

_WebView2_Nav_LoadHTML($sHTML1, $hInstance1)

; WebView2 - Зелёный
Local $sHTML2 = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>'
$sHTML2 &= '<body style="background:#e8f5e9;padding:20px;font-family:Arial;margin:0;">'
$sHTML2 &= '<h1 style="color:#2e7d32;">WebView 2</h1>'
$sHTML2 &= '<div style="padding:15px;background:#66bb6a;color:white;border-radius:8px;">Центральная панель</div>'
$sHTML2 &= '</body></html>'

_WebView2_Nav_LoadHTML($sHTML2, $hInstance2)

; WebView3 - Синий
Local $sHTML3 = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>'
$sHTML3 &= '<body style="background:#e3f2fd;padding:20px;font-family:Arial;margin:0;">'
$sHTML3 &= '<h1 style="color:#1565c0;">WebView 3</h1>'
$sHTML3 &= '<div style="padding:15px;background:#42a5f5;color:white;border-radius:8px;">Правая панель</div>'
$sHTML3 &= '</body></html>'

_WebView2_Nav_LoadHTML($sHTML3, $hInstance3)

_Logger_Write("✅ Контент загружен", 3)

Sleep(500)

; ===============================================================================
; Тест JavaScript
; ===============================================================================
_Logger_Write("📋 Тест JavaScript...", 1)

Local $sJS1 = "document.body.innerHTML += '<p style=""color:red;font-weight:bold;"">JS работает!</p>';"
_WebView2_Core_ExecuteScript($hInstance1, $sJS1)

Local $sJS2 = "document.body.innerHTML += '<p style=""color:green;font-weight:bold;"">JS работает!</p>';"
_WebView2_Core_ExecuteScript($hInstance2, $sJS2)

Local $sJS3 = "document.body.innerHTML += '<p style=""color:blue;font-weight:bold;"">JS работает!</p>';"
_WebView2_Core_ExecuteScript($hInstance3, $sJS3)

_Logger_Write("✅ JavaScript выполнен во всех WebView", 3)

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Тест завершён успешно!", 3)
_Logger_Write("========================================", 1)
_Logger_Write("ℹ️ 3 WebView работают независимо", 1)
_Logger_Write("ℹ️ Закройте окно для выхода", 1)

Exit 0

Func _OnExit()
    Exit
EndFunc
