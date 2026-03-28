; ===============================================================================
; Ultra_Navigation_Test.au3 - Ультратест навигации с PRELOAD системой
; Версия: 3.0.0
; Описание: Предзагрузка HTML в память + сравнение с обычной навигацией
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Ultra_Nav_Test"
Global $g_bNavCompleted = False
Global $g_hNavTimer = 0

; Массив для хранения предзагруженных HTML страниц
Global $g_aPreloadedPages[2][2]  ; [index][0]=имя, [1]=HTML контент

; ===============================================================================
; ИНИЦИАЛИЗАЦИЯ
; ===============================================================================
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("🔥 УЛЬТРАТЕСТ НАВИГАЦИИ + PRELOAD")
_Logger_ConsoleWriteUTF("========================================")

Local $hTimer1 = TimerInit()
Local $bSDKInit = _SDK_Init($sAppName, True, 3, 3, True)
Local $fInitTime = TimerDiff($hTimer1)
_Logger_ConsoleWriteUTF("✅ SDK Init: " & Round($fInitTime, 2) & " мс")

Local $hTimer2 = TimerInit()
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")
Local $fWebView2InitTime = TimerDiff($hTimer2)
_Logger_ConsoleWriteUTF("✅ WebView2 Init: " & Round($fWebView2InitTime, 2) & " мс")

Opt("GUIOnEventMode", 1)

Local $hTimer3 = TimerInit()
_WebView2_GUI_Create(0, "Ultra Navigation Test - PRELOAD", 1200, 600)
Local $fGUICreate = TimerDiff($hTimer3)
_Logger_ConsoleWriteUTF("✅ GUI Create: " & Round($fGUICreate, 2) & " мс")

_WebView2_GUI_Show()
_WebView2_Events_SetOnNavigationCompleted("_OnNavCompleted")

Local $hTimer4 = TimerInit()
_WebView2_Events_WaitForReady(0, 10000)
Local $fWaitReady = TimerDiff($hTimer4)
_Logger_ConsoleWriteUTF("✅ WaitForReady: " & Round($fWaitReady, 2) & " мс")

; ===============================================================================
; PRELOAD: Загрузка HTML страниц в память
; ===============================================================================
_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("� PRELOAD: Загрузка страниц в память")
_Logger_ConsoleWriteUTF("========================================")

Local $aPageFiles[2] = ["index.html", "test.html"]
Local $hPreloadTimer = TimerInit()

For $i = 0 To 1
    Local $sFilePath = @ScriptDir & "\gui\" & $aPageFiles[$i]
    
    If FileExists($sFilePath) Then
        Local $hFile = FileOpen($sFilePath, 0)  ; Read mode
        If $hFile <> -1 Then
            Local $sHTML = FileRead($hFile)
            FileClose($hFile)
            
            $g_aPreloadedPages[$i][0] = $aPageFiles[$i]
            $g_aPreloadedPages[$i][1] = $sHTML
            
            Local $iSize = StringLen($sHTML)
            _Logger_ConsoleWriteUTF("✅ Загружено: " & $aPageFiles[$i] & " (" & $iSize & " символов)")
        Else
            _Logger_ConsoleWriteUTF("❌ Ошибка открытия: " & $aPageFiles[$i])
        EndIf
    Else
        _Logger_ConsoleWriteUTF("❌ Файл не найден: " & $sFilePath)
    EndIf
Next

Local $fPreloadTime = TimerDiff($hPreloadTimer)
_Logger_ConsoleWriteUTF("✅ Preload завершён: " & Round($fPreloadTime, 2) & " мс")

; ===============================================================================
; ТЕСТ 1: Обычная навигация (файлы с диска)
; ===============================================================================
_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("🔵 ТЕСТ 1: Обычная навигация (файлы)")
_Logger_ConsoleWriteUTF("========================================")

Local $aNavTimes_File[5]

For $i = 0 To 4
    Local $sPage = $aPageFiles[Mod($i, 2)]
    _Logger_ConsoleWriteUTF("📋 Навигация " & ($i + 1) & ": " & $sPage)
    
    $g_bNavCompleted = False
    $g_hNavTimer = TimerInit()
    _WebView2_Nav_Load($sPage)
    
    Local $hTimeout = TimerInit()
    While Not $g_bNavCompleted And TimerDiff($hTimeout) < 2000
        Sleep(10)
    WEnd
    
    $aNavTimes_File[$i] = TimerDiff($g_hNavTimer)
    _Logger_ConsoleWriteUTF("✅ Время: " & Round($aNavTimes_File[$i], 2) & " мс")
Next

; ===============================================================================
; ТЕСТ 2: PRELOAD навигация (HTML из памяти)
; ===============================================================================
_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("🟢 ТЕСТ 2: PRELOAD навигация (память)")
_Logger_ConsoleWriteUTF("========================================")

Local $aNavTimes_Preload[5]

For $i = 0 To 4
    Local $iPageIndex = Mod($i, 2)
    Local $sPageName = $g_aPreloadedPages[$iPageIndex][0]
    Local $sHTML = $g_aPreloadedPages[$iPageIndex][1]
    
    _Logger_ConsoleWriteUTF("📋 Навигация " & ($i + 1) & ": " & $sPageName & " (из памяти)")
    
    $g_bNavCompleted = False
    $g_hNavTimer = TimerInit()
    _WebView2_Nav_LoadHTML($sHTML)
    
    Local $hTimeout = TimerInit()
    While Not $g_bNavCompleted And TimerDiff($hTimeout) < 2000
        Sleep(10)
    WEnd
    
    $aNavTimes_Preload[$i] = TimerDiff($g_hNavTimer)
    _Logger_ConsoleWriteUTF("✅ Время: " & Round($aNavTimes_Preload[$i], 2) & " мс")
Next

; ===============================================================================
; СРАВНЕНИЕ РЕЗУЛЬТАТОВ
; ===============================================================================
_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("📊 СРАВНЕНИЕ РЕЗУЛЬТАТОВ")
_Logger_ConsoleWriteUTF("========================================")

Local $fAvg_File = 0, $fAvg_Preload = 0
For $i = 0 To 4
    $fAvg_File += $aNavTimes_File[$i]
    $fAvg_Preload += $aNavTimes_Preload[$i]
Next
$fAvg_File /= 5
$fAvg_Preload /= 5

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("🔵 Обычная навигация (файлы):")
_Logger_ConsoleWriteUTF("   Среднее: " & Round($fAvg_File, 2) & " мс")

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("🟢 PRELOAD навигация (память):")
_Logger_ConsoleWriteUTF("   Среднее: " & Round($fAvg_Preload, 2) & " мс")

Local $fDiff = $fAvg_File - $fAvg_Preload
Local $fPercent = ($fDiff / $fAvg_File) * 100

_Logger_ConsoleWriteUTF("")
If $fDiff > 0 Then
    _Logger_ConsoleWriteUTF("✅ PRELOAD быстрее на: " & Round($fDiff, 2) & " мс (" & Round($fPercent, 1) & "%)")
ElseIf $fDiff < 0 Then
    _Logger_ConsoleWriteUTF("⚠️ PRELOAD медленнее на: " & Round(Abs($fDiff), 2) & " мс (" & Round(Abs($fPercent), 1) & "%)")
Else
    _Logger_ConsoleWriteUTF("➖ Одинаковая скорость")
EndIf

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("📈 ДЕТАЛЬНАЯ СТАТИСТИКА")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("Обычная навигация:")
For $i = 0 To 4
    _Logger_ConsoleWriteUTF("  " & ($i+1) & ". " & Round($aNavTimes_File[$i], 2) & " мс")
Next

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("PRELOAD навигация:")
For $i = 0 To 4
    _Logger_ConsoleWriteUTF("  " & ($i+1) & ". " & Round($aNavTimes_Preload[$i], 2) & " мс")
Next

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("🎉 Тест завершён!")
_Logger_ConsoleWriteUTF("========================================")

Exit 0

Func _OnNavCompleted($sURL = "")
    $g_bNavCompleted = True
EndFunc
