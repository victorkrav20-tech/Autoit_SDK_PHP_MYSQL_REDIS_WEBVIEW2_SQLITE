#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ===============================================
; Test_DevTools.au3
; DevTools Protocol Error Tracking Test
; ===============================================

#include-once
#include "..\..\SDK_Init.au3"

Global $sAppName = "DevTools_Test"
Global $iWindowID = 1
Global Const $TEST_URL = "http://127.0.0.1/apps/new_app1/gui/index.html"

ConsoleWrite("=== DevTools Protocol Test START ===" & @CRLF)
ConsoleWrite("URL: " & $TEST_URL & @CRLF)
ConsoleWrite("Window ID: " & $iWindowID & @CRLF & @CRLF)

; [1] Initialize SDK
ConsoleWrite("[1] Initializing SDK..." & @CRLF)
Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
If Not $bSDKInit Then
    ConsoleWrite("ERROR: SDK initialization failed!" & @CRLF)
    Exit 1
EndIf
ConsoleWrite("[1] SDK initialized" & @CRLF & @CRLF)

; [2] Initialize WebView2
ConsoleWrite("[2] Initializing WebView2..." & @CRLF)
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\..\..\..\apps\new_app1\gui", "")
If Not $bWebView2Init Then
    ConsoleWrite("ERROR: WebView2 initialization failed!" & @CRLF)
    Exit 1
EndIf
ConsoleWrite("[2] WebView2 initialized" & @CRLF & @CRLF)

; [3] Initialize Engine
ConsoleWrite("[3] Initializing WebView2 Engine..." & @CRLF)
_WebView2_Engine_Initialize($iWindowID, "local", @ScriptDir & "\profile")
ConsoleWrite("[3] Engine initialized for Window ID=" & $iWindowID & @CRLF & @CRLF)

; [4] Create GUI
ConsoleWrite("[4] Creating GUI window..." & @CRLF)
_WebView2_GUI_Create($iWindowID, "DevTools Test", 1200, 800)
ConsoleWrite("[4] GUI created" & @CRLF & @CRLF)

; [5] Wait for Ready
ConsoleWrite("[5] Waiting for WebView2 ready..." & @CRLF)
_WebView2_Events_WaitForReady($iWindowID, 15000)
ConsoleWrite("[5] WebView2 is ready" & @CRLF & @CRLF)

; [6] Initialize Bridge (registers DevTools events)
ConsoleWrite("[6] Initializing Bridge..." & @CRLF)
_WebView2_Bridge_Initialize($iWindowID, @ScriptDir & "\..\..\..\apps\new_app1\gui")
ConsoleWrite("[6] Bridge initialized (DevTools events registered)" & @CRLF & @CRLF)

; [7] Navigate to test page
ConsoleWrite("[7] Loading index.html..." & @CRLF)
_WebView2_Nav_Load("index.html", 0, $iWindowID)
ConsoleWrite("[7] Navigation started" & @CRLF & @CRLF)

; [8] Show GUI
ConsoleWrite("[8] Showing GUI..." & @CRLF)
_WebView2_GUI_Show($iWindowID)
ConsoleWrite("[8] GUI shown" & @CRLF & @CRLF)

; [9] Wait for page load
ConsoleWrite("[9] Waiting for page load (3 sec)..." & @CRLF)
Sleep(3000)
ConsoleWrite("[9] Page load completed" & @CRLF & @CRLF)

; [10] Trigger JavaScript errors
ConsoleWrite("=== Triggering JavaScript errors ===" & @CRLF & @CRLF)

ConsoleWrite("[Test 1] Triggering console.log..." & @CRLF)
_WebView2_Core_ExecuteScript($iWindowID, "console.log('Test log message from AutoIt');")
Sleep(1000)

ConsoleWrite("[Test 2] Triggering console.error..." & @CRLF)
_WebView2_Core_ExecuteScript($iWindowID, "console.error('Test error message from AutoIt');")
Sleep(1000)

ConsoleWrite("[Test 3] Triggering throw Error..." & @CRLF)
_WebView2_Core_ExecuteScript($iWindowID, "throw new Error('Test exception from AutoIt');")
Sleep(1000)

ConsoleWrite("[Test 4] Triggering undefined variable..." & @CRLF)
_WebView2_Core_ExecuteScript($iWindowID, "undefinedVariable + 10;")
Sleep(1000)

ConsoleWrite(@CRLF & "=== JavaScript errors triggered ===" & @CRLF & @CRLF)

; [11] Wait for DevTools events
ConsoleWrite("=== Waiting for DevTools events (10 sec) ===" & @CRLF)
ConsoleWrite("Check console output above for:" & @CRLF)
ConsoleWrite("  - Bridge_OnConsoleMessage calls" & @CRLF)
ConsoleWrite("  - Bridge_OnJavaScriptException calls" & @CRLF & @CRLF)

Sleep(10000)

; [12] Cleanup
ConsoleWrite(@CRLF & "=== Cleanup ===" & @CRLF)
_WebView2_Core_Cleanup($iWindowID)

ConsoleWrite("=== DevTools Protocol Test END ===" & @CRLF)
Exit 0

; Note: Bridge event handlers (Bridge_OnConsoleMessage, Bridge_OnJavaScriptException)
; are defined in libs/WebView2/WebView2_Engine_Bridge.au3
; They should be called automatically when DevTools Protocol events fire from C# DLL
