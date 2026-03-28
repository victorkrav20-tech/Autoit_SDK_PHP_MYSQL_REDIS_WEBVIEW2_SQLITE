; ===============================================================================
; Файл: WebView2_Tray.au3
; Описание: Простая система трэя для WebView2 (показ/скрытие GUI окна)
; Версия: 2.1.0
; Дата: 06.03.2026
; ===============================================================================
; Функции:
;   _WebView2_Tray_Init($sAppName, $sIconPath, $hGUI, $funcOnShow, $funcOnHide) - Инициализация трэя
;   _WebView2_Tray_Toggle() - Переключить видимость окна
;   _WebView2_Tray_Show() - Показать окно
;   _WebView2_Tray_Hide() - Скрыть окно
;   _WebView2_Tray_UpdateTooltip($sText) - Обновить подсказку
; ===============================================================================

#include-once
#include <TrayConstants.au3>
#include "..\Utils\Utils.au3"
#include "WebView2_Engine_GUI.au3"

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
; ===============================================================================
Global $g_bWebView2_Tray_Initialized = False
Global $g_sWebView2_Tray_AppName = ""
Global $g_hWebView2_Tray_GUI = 0  ; Handle GUI окна
Global $g_funcWebView2_Tray_OnShow = ""  ; Callback при показе окна
Global $g_funcWebView2_Tray_OnHide = ""  ; Callback при скрытии окна
Global $g_bDebug_WebView2_Tray = False

; ===============================================================================
; Функция: _WebView2_Tray_Init
; Описание: Инициализация системы трэя
; Параметры:
;   $sAppName - имя приложения для подсказки
;   $sIconPath - путь к иконке трэя
;   $hGUI - handle GUI окна для показа/скрытия
;   $funcOnShow - (опционально) callback функция при показе окна
;   $funcOnHide - (опционально) callback функция при скрытии окна
; Возврат: True при успехе, False при ошибке
; Пример: _WebView2_Tray_Init("Inet Reader", @ScriptDir & "\icon.ico", $hGUI, "_MyShowFunc", "_MyHideFunc")
; ===============================================================================
Func _WebView2_Tray_Init($sAppName, $sIconPath, $hGUI, $funcOnShow = "", $funcOnHide = "")
	If $g_bWebView2_Tray_Initialized Then
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] Трэй уже инициализирован", 2)
		Return False
	EndIf
	
	; Сохраняем параметры
	$g_sWebView2_Tray_AppName = $sAppName
	$g_hWebView2_Tray_GUI = $hGUI
	$g_funcWebView2_Tray_OnShow = $funcOnShow
	$g_funcWebView2_Tray_OnHide = $funcOnHide
	
	; Логируем переданные callback функции
	_Logger_Write("[WebView2_Tray] 📋 Инициализация трэя:", 1)
	_Logger_Write("[WebView2_Tray]    OnShow callback: " & ($funcOnShow <> "" ? $funcOnShow : "(не задан)"), 1)
	_Logger_Write("[WebView2_Tray]    OnHide callback: " & ($funcOnHide <> "" ? $funcOnHide : "(не задан)"), 1)
	
	; Проверяем существование функций
	If $funcOnShow <> "" Then
		Local $sFuncCheck = FuncName($funcOnShow)
		_Logger_Write("[WebView2_Tray]    FuncName(OnShow) = '" & $sFuncCheck & "'", 1)
	EndIf
	If $funcOnHide <> "" Then
		Local $sFuncCheck = FuncName($funcOnHide)
		_Logger_Write("[WebView2_Tray]    FuncName(OnHide) = '" & $sFuncCheck & "'", 1)
	EndIf
	
	; Устанавливаем иконку трэя
	If FileExists($sIconPath) Then
		TraySetIcon($sIconPath)
	Else
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] ⚠️ Иконка не найдена: " & $sIconPath, 2)
	EndIf
	
	; Устанавливаем начальную подсказку
	_WebView2_Tray_UpdateTooltip()
	
	; Устанавливаем действие при клике на иконку трея (левая кнопка)
	TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "_WebView2_Tray_Toggle")
	
	; Показываем иконку трэя
	TraySetState(1) ; 1 = показать иконку
	
	$g_bWebView2_Tray_Initialized = True
	
	If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] ✅ Иконка трэя инициализирована", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Tray_Toggle
; Описание: Переключить видимость окна (показать/скрыть)
; Параметры: нет
; Возврат: True при успехе
; ===============================================================================
Func _WebView2_Tray_Toggle()
	If Not $g_bWebView2_Tray_Initialized Then
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] Трэй не инициализирован", 2)
		Return False
	EndIf
	
	; Проверяем состояние окна (видимо ли оно)
	Local $iState = WinGetState($g_hWebView2_Tray_GUI)
	
	; Если окно видимо (бит 2 = SW_SHOW)
	If BitAND($iState, 2) Then
		Return _WebView2_Tray_Hide()
	Else
		Return _WebView2_Tray_Show()
	EndIf
EndFunc

; ===============================================================================
; Функция: _WebView2_Tray_Show
; Описание: Показать окно
; Параметры: нет
; Возврат: True при успехе
; ===============================================================================
Func _WebView2_Tray_Show()
	If Not $g_bWebView2_Tray_Initialized Then
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] Трэй не инициализирован", 2)
		Return False
	EndIf
	
	; Проверяем режим работы: с callback или встроенный
	If $g_funcWebView2_Tray_OnShow <> "" And FuncName($g_funcWebView2_Tray_OnShow) <> "" Then
		; Режим с callback функцией
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] 🔄 Вызов callback: " & $g_funcWebView2_Tray_OnShow, 1)
		Call($g_funcWebView2_Tray_OnShow)
	Else
		; Встроенный режим - показываем GUI
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] 🔄 Встроенный режим: GUISetState(@SW_SHOW)", 1)
		GUISetState(@SW_RESTORE, $g_hWebView2_Tray_GUI)
		GUISetState(@SW_SHOW, $g_hWebView2_Tray_GUI)
		WinActivate($g_hWebView2_Tray_GUI)
	EndIf
	
	If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] 👁️ Окно показано", 1)
	Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Tray_Hide
; Описание: Скрыть окно
; Параметры: нет
; Возврат: True при успехе
; ===============================================================================
Func _WebView2_Tray_Hide()
	If Not $g_bWebView2_Tray_Initialized Then
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] Трэй не инициализирован", 2)
		Return False
	EndIf
	
	; Проверяем режим работы: с callback или встроенный
	If $g_funcWebView2_Tray_OnHide <> "" And FuncName($g_funcWebView2_Tray_OnHide) <> "" Then
		; Режим с callback функцией
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] 🔄 Вызов callback: " & $g_funcWebView2_Tray_OnHide, 1)
		Call($g_funcWebView2_Tray_OnHide)
	Else
		; Встроенный режим - скрываем GUI
		If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] 🔄 Встроенный режим: GUISetState(@SW_HIDE)", 1)
		GUISetState(@SW_HIDE, $g_hWebView2_Tray_GUI)
	EndIf
	
	If $g_bDebug_WebView2_Tray Then _Logger_Write("[WebView2_Tray] 🙈 Окно скрыто", 1)
	Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Tray_UpdateTooltip
; Описание: Обновить подсказку трэя
; Параметры:
;   $sText - текст подсказки (опционально, если пусто - автоматически)
; Возврат: True при успехе
; ===============================================================================
Func _WebView2_Tray_UpdateTooltip($sText = "")
	If Not $g_bWebView2_Tray_Initialized Then Return False
	
	; Если текст не указан - формируем автоматически
	If $sText = "" Then
		$sText = $g_sWebView2_Tray_AppName & @CRLF & "Клик - показать/скрыть"
	EndIf
	
	TraySetToolTip($sText)
	Return True
EndFunc
