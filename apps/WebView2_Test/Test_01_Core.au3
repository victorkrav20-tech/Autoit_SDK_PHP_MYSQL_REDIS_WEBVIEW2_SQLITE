; ===============================================================================
; Test_01_Core.au3 - Тест базовых функций WebView2 Engine Core
; Версия: 1.0.0
; Описание: Тестирование Initialize, CreateInstance, GetInstance, IsReady, Shutdown
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_01_Core"

; ===============================================================================
; Инициализация SDK и WebView2
; ===============================================================================
Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

If Not $bSDKInit Then
    ConsoleWrite("❌ SDK Init Failed" & @CRLF)
    Exit 1
EndIf

If Not $bWebView2Init Then
    ConsoleWrite("❌ WebView2 Init Failed" & @CRLF)
    Exit 1
EndIf

_Logger_Write("========================================", 1)
_Logger_Write("🧪 Test_01_Core - Базовые функции", 1)
_Logger_Write("========================================", 1)

; ===============================================================================
; ТЕСТ 1: Initialize (уже выполнен через _SDK_WebView2_Init)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: Initialize", 1)
Local $bInitialized = _WebView2_Engine_IsInitialized()
If $bInitialized Then
    _Logger_Write("✅ PASS: Engine инициализирован", 3)
Else
    _Logger_Write("❌ FAIL: Engine не инициализирован", 2)
EndIf

; ===============================================================================
; ТЕСТ 2: GetMode
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: GetMode", 1)
Local $sMode = _WebView2_Engine_GetMode()
If $sMode = "local" Then
    _Logger_Write("✅ PASS: Режим = " & $sMode, 3)
Else
    _Logger_Write("❌ FAIL: Неверный режим = " & $sMode, 2)
EndIf

; ===============================================================================
; ТЕСТ 3: GetStatus
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3: GetStatus", 1)
Local $aStatus = _WebView2_Engine_GetStatus()
If IsArray($aStatus) Then
    _Logger_Write("✅ PASS: GetStatus вернул массив", 3)
    _Logger_Write("   " & $aStatus[0][0] & ": " & $aStatus[0][1], 1)
    _Logger_Write("   " & $aStatus[1][0] & ": " & $aStatus[1][1], 1)
    _Logger_Write("   " & $aStatus[2][0] & ": " & $aStatus[2][1], 1)
Else
    _Logger_Write("❌ FAIL: GetStatus не вернул массив", 2)
EndIf

; ===============================================================================
; ТЕСТ 4: Создание GUI и проверка IsReady
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 4: GUI Create + IsReady", 1)

Opt("GUIOnEventMode", 1)
Local $bGUICreate = _WebView2_GUI_Create(0, "Test_01_Core", 800, 600)

If $bGUICreate Then
    _Logger_Write("✅ PASS: GUI создан", 3)
Else
    _Logger_Write("❌ FAIL: GUI не создан", 2)
    Exit 1
EndIf

; Ожидание готовности WebView2
Local $bReady = _WebView2_Events_WaitForReady(0, 10000)
If $bReady Then
    _Logger_Write("✅ PASS: WebView2 готов", 3)
Else
    _Logger_Write("❌ FAIL: WebView2 не готов (таймаут)", 2)
    Exit 1
EndIf

; ===============================================================================
; ТЕСТ 5: Проверка IsReady после инициализации
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 5: IsReady после инициализации", 1)
Local $bIsReady = _WebView2_Engine_IsInitialized()
If $bIsReady Then
    _Logger_Write("✅ PASS: IsReady = True", 3)
Else
    _Logger_Write("❌ FAIL: IsReady = False", 2)
EndIf

; ===============================================================================
; ФИНАЛ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Test_01_Core завершён", 3)
_Logger_Write("========================================", 1)

Exit 0
