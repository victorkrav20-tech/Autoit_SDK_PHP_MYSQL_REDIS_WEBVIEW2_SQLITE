; ===============================================================================
; Приложение: NewApp1
; Описание: Минималистичное приложение с WebView2
; Версия: 1.0.0
; Дата: 26.02.2026
; ===============================================================================

; ===============================================================================
; СПИСОК ФУНКЦИЙ:
; - _ScadaGraphics_Main_OnClose() - Обработчик закрытия окна
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

; === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
Global $g_sScadaGraphics_Main_AppName = "ScadaGraphics"
Global $g_iScadaGraphics_Main_WindowID = 1
Global $g_iScadaGraphics_Main_WindowWidth = 1200
Global $g_iScadaGraphics_Main_WindowHeight = 700
Global $g_sScadaGraphics_Main_WindowTitle = "ScadaGraphics"

; === ИНИЦИАЛИЗАЦИЯ SDK ===
Local $bScadaGraphics_Main_SDKInit = _SDK_Init($g_sScadaGraphics_Main_AppName, True, 1, 3, True)
If Not $bScadaGraphics_Main_SDKInit Then
	_Logger_Write("Ошибка инициализации SDK", 2)
	Exit
EndIf

Local $bScadaGraphics_Main_WebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")
If Not $bScadaGraphics_Main_WebView2Init Then
	_Logger_Write("Ошибка инициализации WebView2", 2)
	Exit
EndIf

; === СОЗДАНИЕ GUI ===
Opt("GUIOnEventMode", 1)

_WebView2_Engine_Initialize($g_iScadaGraphics_Main_WindowID, "local", @ScriptDir & "\profile")
_WebView2_GUI_Create($g_iScadaGraphics_Main_WindowID, $g_sScadaGraphics_Main_WindowTitle, $g_iScadaGraphics_Main_WindowWidth, $g_iScadaGraphics_Main_WindowHeight)

GUISetOnEvent($GUI_EVENT_CLOSE, "_ScadaGraphics_Main_OnClose")

_WebView2_Events_WaitForReady($g_iScadaGraphics_Main_WindowID, 15000)
_WebView2_Nav_Load("index.html", 0, $g_iScadaGraphics_Main_WindowID)
_WebView2_GUI_Show($g_iScadaGraphics_Main_WindowID)

_Logger_Write("Приложение запущено", 3)

; === ОСНОВНОЙ ЦИКЛ ===
While 1
	Sleep(10)
WEnd

; ===============================================================================
; Функция: _ScadaGraphics_Main_OnClose
; Описание: Обработчик закрытия окна
; ===============================================================================
Func _ScadaGraphics_Main_OnClose()
	Local $hScadaGraphics_Main_Wnd = @GUI_WinHandle
	Local $hScadaGraphics_Main_Instance = _WebView2_GUI_GetInstanceByHandle($hScadaGraphics_Main_Wnd)

	If $hScadaGraphics_Main_Instance > 0 Then
		_WebView2_GUI_Hide($hScadaGraphics_Main_Instance)
		_WebView2_Core_DestroyInstance($hScadaGraphics_Main_Instance)
		GUIDelete($hScadaGraphics_Main_Wnd)
	EndIf


	_Logger_Write("Приложение завершено", 1)
	Exit
EndFunc
