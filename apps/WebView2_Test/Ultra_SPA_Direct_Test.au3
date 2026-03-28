; ===============================================================================
; Ultra_SPA_Direct_Test.au3 - SPA навигация с прямой работой с COM
; Версия: 1.0.0
; Описание: Прямая работа с COM без SDK для получения событий от JavaScript
; ===============================================================================

#AutoIt3Wrapper_UseX64=y
#include <GUIConstantsEx.au3>

OnAutoItExitRegister("_CleanExit")

Global $oManager, $oBridge, $oEvtManager, $oEvtBridge
Global $oMyError = ObjEvent("AutoIt.Error", "_ErrFunc")
Global $hGUI

; Переменные для теста
Global $g_bReady = False
Global $g_bNavCompleted = False
Global $g_sLastJSMessage = ""
Global $g_hNavTimer = 0
Global $aNavTimes[10]

ConsoleWrite("========================================" & @CRLF)
ConsoleWrite("ULTRA SPA NAVIGATION TEST (Direct COM)" & @CRLF)
ConsoleWrite("========================================" & @CRLF)
ConsoleWrite(@CRLF)

Main()

Func Main()
    ; Создание GUI
    ConsoleWrite("Creating GUI..." & @CRLF)
    $hGUI = GUICreate("Ultra SPA Navigation Test", 1200, 700)
    GUISetState(@SW_SHOW)
    
    ; Создание COM объекта
    ConsoleWrite("Creating COM object..." & @CRLF)
    $oManager = ObjCreate("NetWebView2.Manager")
    If Not IsObj($oManager) Then
        ConsoleWrite("ERROR: Cannot create COM object!" & @CRLF)
        Exit
    EndIf
    
    ; Регистрация событий Manager
    ConsoleWrite("Registering Manager events..." & @CRLF)
    $oEvtManager = ObjEvent($oManager, "WebView_", "IWebViewEvents")
    
    ; Получение Bridge и регистрация его событий
    ConsoleWrite("Getting Bridge..." & @CRLF)
    $oBridge = $oManager.GetBridge()
    $oEvtBridge = ObjEvent($oBridge, "Bridge_", "IBridgeEvents")
    
    ; Инициализация WebView2
    ConsoleWrite("Initializing WebView2..." & @CRLF)
    $oManager.Initialize(($hGUI), @ScriptDir & "\profile", 0, 0, 1200, 700)
    
    ; Ждём INIT_READY
    ConsoleWrite("Waiting for INIT_READY..." & @CRLF)
    Local $hTimeout = TimerInit()
    While Not $g_bReady And TimerDiff($hTimeout) < 10000
        Sleep(10)
    WEnd
    
    If Not $g_bReady Then
        ConsoleWrite("ERROR: WebView2 not ready!" & @CRLF)
        Exit
    EndIf
    
    ConsoleWrite("WebView2 ready!" & @CRLF & @CRLF)
    
    ; Загрузка SPA страницы
    ConsoleWrite("========================================" & @CRLF)
    ConsoleWrite("LOADING SPA PAGE" & @CRLF)
    ConsoleWrite("========================================" & @CRLF)
    
    $g_bNavCompleted = False
    Local $hLoadTimer = TimerInit()
    $oManager.Navigate("file:///" & StringReplace(@ScriptDir & "\gui\navi.html", "\", "/"))
    
    While Not $g_bNavCompleted And TimerDiff($hLoadTimer) < 3000
        Sleep(10)
    WEnd
    
    ConsoleWrite("Initial load: " & Round(TimerDiff($hLoadTimer), 2) & " ms" & @CRLF & @CRLF)
    Sleep(500)
    
    ; Тест навигации
    ConsoleWrite("========================================" & @CRLF)
    ConsoleWrite("NAVIGATION TEST" & @CRLF)
    ConsoleWrite("========================================" & @CRLF & @CRLF)
    
    Local $aPages[3] = [1, 2, 3]
    
    For $i = 0 To 9
        Local $iPage = $aPages[Mod($i, 3)]
        ConsoleWrite("Navigation " & ($i + 1) & ": Page " & $iPage & @CRLF)
        
        ; Сбрасываем флаг
        $g_sLastJSMessage = ""
        
        ; Запускаем таймер и навигацию
        $g_hNavTimer = TimerInit()
        $oManager.ExecuteScript("navigateToPage(" & $iPage & ");")
        
        ; Ждём события от JavaScript
        Local $hTimeout = TimerInit()
        While $g_sLastJSMessage = "" And TimerDiff($hTimeout) < 1000
            Sleep(1)
        WEnd
        
        Local $fTime = TimerDiff($g_hNavTimer)
        $aNavTimes[$i] = $fTime
        
        If $g_sLastJSMessage <> "" Then
            ConsoleWrite("  Time: " & Round($fTime, 2) & " ms (event: " & $g_sLastJSMessage & ")" & @CRLF)
        Else
            ConsoleWrite("  Time: " & Round($fTime, 2) & " ms (timeout)" & @CRLF)
        EndIf
        
        Sleep(50)
    Next
    
    ; Статистика
    ConsoleWrite(@CRLF)
    ConsoleWrite("========================================" & @CRLF)
    ConsoleWrite("STATISTICS" & @CRLF)
    ConsoleWrite("========================================" & @CRLF)
    
    Local $fTotal = 0, $fMin = 999999, $fMax = 0
    For $i = 0 To 9
        $fTotal += $aNavTimes[$i]
        If $aNavTimes[$i] < $fMin Then $fMin = $aNavTimes[$i]
        If $aNavTimes[$i] > $fMax Then $fMax = $aNavTimes[$i]
    Next
    Local $fAvg = $fTotal / 10
    
    ConsoleWrite("Average: " & Round($fAvg, 2) & " ms" & @CRLF)
    ConsoleWrite("Min: " & Round($fMin, 2) & " ms" & @CRLF)
    ConsoleWrite("Max: " & Round($fMax, 2) & " ms" & @CRLF)
    ConsoleWrite("Range: " & Round($fMax - $fMin, 2) & " ms" & @CRLF)
    
    ConsoleWrite(@CRLF)
    ConsoleWrite("========================================" & @CRLF)
    ConsoleWrite("TEST COMPLETED" & @CRLF)
    ConsoleWrite("========================================" & @CRLF)
    
    ; Основной цикл
    While 1
        If GUIGetMsg() = $GUI_EVENT_CLOSE Then ExitLoop
        Sleep(10)
    WEnd
    
    GUIDelete($hGUI)
EndFunc

Func _CleanExit()
    If IsObj($oManager) Then $oManager.Cleanup()
    $oManager = 0
    $oBridge = 0
    $oEvtManager = 0
    $oEvtBridge = 0
    $oMyError = 0
EndFunc

; ===============================================================================
; EVENT HANDLERS
; ===============================================================================
Func WebView_OnMessageReceived($sMessage)
    ConsoleWrite("[MANAGER] " & $sMessage & @CRLF)
    
    Local $aParts = StringSplit($sMessage, "|")
    Local $sCommand = StringStripWS($aParts[1], 3)
    
    Switch $sCommand
        Case "INIT_READY"
            $g_bReady = True
        Case "NAV_COMPLETED"
            $g_bNavCompleted = True
    EndSwitch
EndFunc

Func Bridge_OnMessageReceived($sMessage)
    ConsoleWrite("[BRIDGE] " & $sMessage & @CRLF)
    $g_sLastJSMessage = $sMessage
EndFunc

Func _ErrFunc($oError)
    ConsoleWrite("COM ERROR: " & $oError.description & @CRLF)
EndFunc
