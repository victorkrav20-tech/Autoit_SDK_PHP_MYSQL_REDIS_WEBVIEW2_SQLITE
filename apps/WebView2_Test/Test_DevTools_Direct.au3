; ===============================================================================
; Test_DevTools_Direct.au3 - Direct test for DevTools Protocol events
; Version: 1.0.0
; Description: Test Bridge COM events (OnConsoleMessage, OnJavaScriptException)
; ===============================================================================

#AutoIt3Wrapper_UseX64=y
#include <GUIConstantsEx.au3>

Global $oManager, $oBridge, $oManagerEvents, $oBridgeEvents, $oErr
Global $bReady = False
Global $hGUI

ConsoleWrite("========================================" & @CRLF)
ConsoleWrite("DEVTOOLS PROTOCOL TEST (DIRECT)" & @CRLF)
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite(@CRLF)

; Create GUI
ConsoleWrite("[1] Creating GUI..." & @CRLF)
$hGUI = GUICreate("DevTools Test", 1200, 800)
GUISetState(@SW_SHOW)
ConsoleWrite("[1] GUI created" & @CRLF & @CRLF)

; Create COM object (Manager)
ConsoleWrite("[2] Creating Manager COM object..." & @CRLF)
$oManager = ObjCreate("ScadaWebView2.Manager")
If Not IsObj($oManager) Then
	ConsoleWrite("ERROR: Cannot create Manager COM object!" & @CRLF)
	Exit 1
EndIf
ConsoleWrite("[2] Manager created" & @CRLF & @CRLF)

; Register COM error handler
$oErr = ObjEvent("AutoIt.Error", "_ErrHandler")

; Register Manager events
ConsoleWrite("[3] Registering Manager COM events..." & @CRLF)
$oManagerEvents = ObjEvent($oManager, "Manager_", "IWebViewEvents")
If Not IsObj($oManagerEvents) Then
	ConsoleWrite("ERROR: Cannot register Manager events!" & @CRLF)
	Exit 1
EndIf
ConsoleWrite("[3] Manager events registered" & @CRLF & @CRLF)

; Initialize WebView2
ConsoleWrite("[4] Initializing WebView2..." & @CRLF)
$oManager.Initialize($hGUI, @ScriptDir & "\profile", 0, 0, 1200, 800)
ConsoleWrite("[4] Initialize called" & @CRLF & @CRLF)

; Wait for INIT_READY
ConsoleWrite("[5] Waiting for INIT_READY..." & @CRLF)
Local $hTimer = TimerInit()
While Not $bReady And TimerDiff($hTimer) < 15000
	If GUIGetMsg() = $GUI_EVENT_CLOSE Then Exit
	Sleep(10)
WEnd

If Not $bReady Then
	ConsoleWrite(@CRLF & "ERROR: WebView2 not ready after 15 seconds!" & @CRLF)
	Exit 1
EndIf
ConsoleWrite("[5] WebView2 is READY" & @CRLF & @CRLF)

; Get Bridge object
ConsoleWrite("[6] Getting Bridge object..." & @CRLF)
$oBridge = $oManager.GetBridge()
If Not IsObj($oBridge) Then
	ConsoleWrite("ERROR: Cannot get Bridge object!" & @CRLF)
	Exit 1
EndIf
ConsoleWrite("[6] Bridge object obtained" & @CRLF & @CRLF)

; Register Bridge events (DevTools)
ConsoleWrite("[7] Registering Bridge COM events (DevTools)..." & @CRLF)
$oBridgeEvents = ObjEvent($oBridge, "Bridge_", "IBridgeEvents")
If Not IsObj($oBridgeEvents) Then
	ConsoleWrite("ERROR: Cannot register Bridge events!" & @CRLF)
	Exit 1
EndIf
ConsoleWrite("[7] Bridge events registered" & @CRLF & @CRLF)

; Test DevTools events
ConsoleWrite("[7.5] Testing DevTools events..." & @CRLF)
$oManager.TestDevToolsEvents()
ConsoleWrite("[7.5] Test completed" & @CRLF & @CRLF)

; Navigate to test page
ConsoleWrite("[8] Navigating to test page..." & @CRLF)
$oManager.Navigate("http://127.0.0.1/apps/new_app1/gui/index.html")
ConsoleWrite("[8] Navigation started" & @CRLF & @CRLF)

; Wait for page load
ConsoleWrite("[9] Waiting for page load (5 sec)..." & @CRLF)
Sleep(500)
ConsoleWrite("[9] Page load completed" & @CRLF & @CRLF)

; Trigger JavaScript errors
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite("TRIGGERING JAVASCRIPT ERRORS" & @CRLF)
ConsoleWrite("========================================" & @CRLF & @CRLF)

ConsoleWrite("[Test 1] console.log..." & @CRLF)
$oManager.ExecuteScript("console.log('Test log message from AutoIt');")
Sleep(100)

ConsoleWrite("[Test 2] console.error..." & @CRLF)
$oManager.ExecuteScript("console.error('Test error message from AutoIt');")
Sleep(100)

ConsoleWrite("[Test 3] throw Error..." & @CRLF)
$oManager.ExecuteScript("throw new Error('Test exception from AutoIt');")
Sleep(100)

ConsoleWrite("[Test 4] undefined variable..." & @CRLF)
$oManager.ExecuteScript("undefinedVariable + 10;")
Sleep(100)

ConsoleWrite(@CRLF & "========================================" & @CRLF)
ConsoleWrite("WAITING FOR DEVTOOLS EVENTS (10 sec)" & @CRLF)
ConsoleWrite("========================================" & @CRLF & @CRLF)
ConsoleWrite("Expected events:" & @CRLF)
ConsoleWrite("  - Bridge_OnConsoleMessage (for console.log/error)" & @CRLF)
ConsoleWrite("  - Bridge_OnJavaScriptException (for throw/undefined)" & @CRLF & @CRLF)

; Wait for DevTools events
;Sleep(10000)

ConsoleWrite(@CRLF & "========================================" & @CRLF)
ConsoleWrite("TEST COMPLETED" & @CRLF)
ConsoleWrite("========================================" & @CRLF & @CRLF)
ConsoleWrite("Check logs above for DevTools messages" & @CRLF)
ConsoleWrite(@CRLF)

; Cleanup
$oManager.Cleanup()
Exit 0

; ===============================================================================
; Manager COM Event Handlers
; ===============================================================================
Func Manager_OnMessageReceived($sMsg)
	ConsoleWrite("[Manager Event] " & $sMsg & @CRLF)
	
	If StringInStr($sMsg, "INIT_READY") Then
		$bReady = True
		ConsoleWrite(@CRLF & ">>> WebView2 READY <<<" & @CRLF & @CRLF)
	EndIf
EndFunc

; ===============================================================================
; Bridge COM Event Handlers (DevTools Protocol)
; ===============================================================================

; Message Handler - парсим DevTools JSON сообщения
Func Bridge_OnMessageReceived($sMessage)
	; Check for debug raw JSON
	If StringLeft($sMessage, 18) = "DEBUG_RAW_CONSOLE:" Then
		ConsoleWrite(@CRLF & "=== RAW JSON ===" & @CRLF)
		ConsoleWrite(StringTrimLeft($sMessage, 18) & @CRLF)
		ConsoleWrite("================" & @CRLF & @CRLF)
		Return
	EndIf
	
	; Check for DevTools JSON messages
	If StringInStr($sMessage, '"type":"DEVTOOLS_CONSOLE"') Then
		; Parse JSON: {"type":"DEVTOOLS_CONSOLE","level":"log","message":"...","source":"...","line":123,"column":45}
		Local $sLevel = _JsonExtract($sMessage, "level")
		Local $sMsg = _JsonExtract($sMessage, "message")
		Local $sSource = _JsonExtract($sMessage, "source")
		Local $iLine = Int(_JsonExtract($sMessage, "line"))
		Local $iColumn = Int(_JsonExtract($sMessage, "column"))
		
		ConsoleWrite(@CRLF & ">>> DEVTOOLS CONSOLE MESSAGE <<<" & @CRLF)
		ConsoleWrite("[Level] " & $sLevel & @CRLF)
		ConsoleWrite("[Message] " & $sMsg & @CRLF)
		ConsoleWrite("[Source] " & $sSource & ":" & $iLine & ":" & $iColumn & @CRLF)
		ConsoleWrite("========================================" & @CRLF & @CRLF)
		Return
	EndIf
	
	If StringInStr($sMessage, '"type":"DEVTOOLS_EXCEPTION"') Then
		; Parse JSON: {"type":"DEVTOOLS_EXCEPTION","message":"...","source":"...","line":123,"column":45,"stackTrace":"..."}
		Local $sMsg = _JsonExtract($sMessage, "message")
		Local $sSource = _JsonExtract($sMessage, "source")
		Local $iLine = Int(_JsonExtract($sMessage, "line"))
		Local $iColumn = Int(_JsonExtract($sMessage, "column"))
		Local $sStack = _JsonExtract($sMessage, "stackTrace")
		
		ConsoleWrite(@CRLF & ">>> DEVTOOLS JAVASCRIPT EXCEPTION <<<" & @CRLF)
		ConsoleWrite("=== JAVASCRIPT EXCEPTION (DevTools) ===" & @CRLF)
		ConsoleWrite("[Message] " & $sMsg & @CRLF)
		ConsoleWrite("[File] " & $sSource & ":" & $iLine & ":" & $iColumn & @CRLF)
		ConsoleWrite("[Stack Trace]" & @CRLF)
		ConsoleWrite($sStack & @CRLF)
		ConsoleWrite("========================================" & @CRLF & @CRLF)
		Return
	EndIf
	
	; Regular message
	ConsoleWrite("[Bridge Message] " & $sMessage & @CRLF)
EndFunc

; Simple JSON value extractor (for string and number values)
Func _JsonExtract($sJson, $sKey)
	Local $sPattern = '"' & $sKey & '"\s*:\s*"([^"]*)"'  ; For string values
	Local $aMatch = StringRegExp($sJson, $sPattern, 1)
	If @error = 0 And IsArray($aMatch) Then
		Return $aMatch[0]
	EndIf
	
	; Try number pattern
	$sPattern = '"' & $sKey & '"\s*:\s*(\d+)'
	$aMatch = StringRegExp($sJson, $sPattern, 1)
	If @error = 0 And IsArray($aMatch) Then
		Return $aMatch[0]
	EndIf
	
	Return ""
EndFunc

; ===============================================================================
; COM Error Handler
; ===============================================================================
Func _ErrHandler($oError)
	ConsoleWrite(@CRLF & "=== COM ERROR ===" & @CRLF)
	ConsoleWrite("Number: 0x" & Hex($oError.number) & @CRLF)
	ConsoleWrite("Description: " & $oError.description & @CRLF)
	ConsoleWrite("Source: " & $oError.source & @CRLF)
	ConsoleWrite("=== END COM ERROR ===" & @CRLF & @CRLF)
EndFunc
