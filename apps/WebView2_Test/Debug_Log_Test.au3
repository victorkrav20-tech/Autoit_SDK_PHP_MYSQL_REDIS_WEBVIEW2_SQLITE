; ===============================================================================
; Debug_Log_Test.au3 - Test DEBUG logs from DLL
; Version: 2.0.0
; Description: Direct COM event handler to receive ALL DLL messages
; ===============================================================================

#AutoIt3Wrapper_UseX64=y
#include <GUIConstantsEx.au3>

Global $oWeb, $oEvt, $oErr
Global $bReady = False
Global $hGUI

ConsoleWrite("========================================" & @CRLF)
ConsoleWrite("TEST DEBUG LOGS FROM DLL" & @CRLF)
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite(@CRLF)

; Create GUI
ConsoleWrite("Creating GUI..." & @CRLF)
$hGUI = GUICreate("Debug Log Test", 800, 600)
GUISetState(@SW_SHOW)

; Create COM object
ConsoleWrite("Creating COM object..." & @CRLF)
$oWeb = ObjCreate("NetWebView2.Manager")
If Not IsObj($oWeb) Then
	ConsoleWrite("ERROR: Cannot create COM object!" & @CRLF)
	Exit
EndIf

; Register COM error handler
$oErr = ObjEvent("AutoIt.Error", "_ErrHandler")

; Register events - THIS IS THE KEY!
ConsoleWrite("Registering COM events..." & @CRLF)
$oEvt = ObjEvent($oWeb, "Web_", "IWebViewEvents")

; Initialize WebView2
ConsoleWrite("Initializing WebView2..." & @CRLF)
ConsoleWrite("Profile: " & @ScriptDir & "\profile" & @CRLF)
ConsoleWrite(@CRLF)

$oWeb.Initialize(($hGUI), @ScriptDir & "\profile", 0, 0, 800, 600)

; Wait for INIT_READY
ConsoleWrite("Waiting for INIT_READY..." & @CRLF)
ConsoleWrite(@CRLF)

Local $hTimer = TimerInit()
While Not $bReady And TimerDiff($hTimer) < 10000
	If GUIGetMsg() = $GUI_EVENT_CLOSE Then Exit
	Sleep(10)
WEnd

If Not $bReady Then
	ConsoleWrite(@CRLF & "ERROR: WebView2 not ready after 10 seconds!" & @CRLF)
	Exit
EndIf

ConsoleWrite(@CRLF)
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite("NAVIGATION TEST" & @CRLF)
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite(@CRLF)

; Navigate to test page
Local $sTestFile = @ScriptDir & "\gui\test.html"
Local $sURL = "file:///" & StringReplace($sTestFile, "\", "/")
ConsoleWrite("Navigating to: " & $sURL & @CRLF)
ConsoleWrite(@CRLF)

$oWeb.Navigate($sURL)

; Wait for navigation
Sleep(2000)

ConsoleWrite(@CRLF)
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite("TEST COMPLETED" & @CRLF)
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite(@CRLF)
ConsoleWrite("Check logs above for DEBUG messages from DLL" & @CRLF)
ConsoleWrite("Should see DLL version marker and timing data" & @CRLF)
ConsoleWrite(@CRLF)

; Keep window open for 3 seconds
Sleep(3000)

Exit 0

; ===============================================================================
; COM Event Handler - receives ALL messages from DLL
; ===============================================================================
Func Web_OnMessageReceived($sMsg)
	ConsoleWrite("[DLL] " & $sMsg & @CRLF)
	
	If StringInStr($sMsg, "INIT_READY") Then
		$bReady = True
		ConsoleWrite(@CRLF & ">>> WebView2 READY <<<" & @CRLF & @CRLF)
	EndIf
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
