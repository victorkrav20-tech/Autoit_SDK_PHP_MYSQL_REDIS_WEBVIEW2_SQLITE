; ===============================================================================
; Файл: 01_Start_Init_Events.au3
; Описание: Обработчики событий приложения 01_Start
; Функции:
;   _01_Start_RegisterEvents() - Регистрация всех обработчиков событий
;   _01_Start_OnWindowClose() - Обработчик закрытия окна
;   _01_Start_OnMainWindowData() - Обработчик данных главного окна
; ===============================================================================

#include-once
#include <GUIConstantsEx.au3>
#include "01_Start_Init.au3"
#include "01_Start_Init_Response.au3"
#include "01_Start_Init_Utils.au3"

Global $g_bDebug_01_Start          ; Режим отладки (значение задаётся в Main)
Global $g_b01_Start_ExitOnNoWindows ; Завершать при 0 окнах (значение задаётся в Main)

; ===============================================================================
; Функция: _01_Start_RegisterEvents
; Описание: Регистрация всех обработчиков событий GUI
; Параметры: нет
; Возврат: True при успехе
; ===============================================================================
Func _01_Start_RegisterEvents()
	GUISetOnEvent($GUI_EVENT_CLOSE, "_01_Start_OnWindowClose")
	If $g_bDebug_01_Start Then _Logger_Write("✅ Обработчики событий зарегистрированы", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _01_Start_OnWindowClose
; Описание: Обработчик закрытия окна
; Параметры: нет
; Возврат: нет
; ===============================================================================
Func _01_Start_OnWindowClose()
	Local $hWnd = @GUI_WinHandle
	Local $hInstance = _WebView2_GUI_GetInstanceByHandle($hWnd)

	If $hInstance > 0 Then
		If $g_bDebug_01_Start Then _Logger_Write("🔄 Закрытие окна ID=" & $hInstance, 1)

		_WebView2_GUI_Hide($hInstance)

		; Считаем оставшиеся открытые окна
		Local $iOpenWindows = 0
		For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
			Local $hTestWnd = $g_aWebView2_Instances[$i][$WV2_GUI_HANDLE]
			If $hTestWnd <> 0 And $hTestWnd <> $hWnd And WinExists($hTestWnd) Then
				$iOpenWindows += 1
			EndIf
		Next

		_WebView2_Core_DestroyInstance($hInstance)
		GUIDelete($hWnd)
		If $g_bDebug_01_Start Then _Logger_Write("✅ Окно ID=" & $hInstance & " удалено, осталось: " & $iOpenWindows, 1)

		If $iOpenWindows = 0 Then
			If $g_b01_Start_ExitOnNoWindows Then
				_01_Start_Shutdown()
			Else
				If $g_bDebug_01_Start Then _Logger_Write("🔕 Все окна закрыты — приложение работает в фоне (трей активен)", 1)
			EndIf
		EndIf
	Else
		_01_Start_Shutdown()
	EndIf
EndFunc

; ===============================================================================
; Функция: _01_Start_Shutdown
; Описание: Завершение приложения — логирование и выход
; Параметры: нет
; Возврат: нет
; ===============================================================================
Func _01_Start_Shutdown()
	If $g_bDebug_01_Start Then _Logger_Write("👋 Завершение приложения", 1)

	If _01_Start_IsMySQLEnabled() Then
		_MySQL_InsertSCADA("app_logs", "app_id=01_start|app_name=01 Start|event_type=stop|message=Приложение остановлено|hostname=" & @ComputerName, $MYSQL_SERVER_LOCAL)
		_MySQL_InsertSCADA("app_logs", "app_id=01_start|app_name=01 Start|event_type=stop|message=Приложение остановлено|hostname=" & @ComputerName, $MYSQL_SERVER_REMOTE)
		If $g_bDebug_01_Start Then _Logger_Write("📝 Логирование остановки отправлено в MySQL", 3)
	EndIf

	If _01_Start_IsRedisEnabled() Then
		_Redis_Disconnect()
		If $g_bDebug_01_Start Then _Logger_Write("✅ Redis отключен", 3)
	EndIf

	_Core_Timer_Cleanup()
	Exit
EndFunc

; ===============================================================================
; Обработчики WebView2 окна
; ===============================================================================

Func _01_Start_OnMainWindowData($vJson, $hInstance = 0)
	If $g_bDebug_01_Start Then _Logger_Write("📨 [Main Window] Получены данные", 1)
	_01_Start_OnResponse($vJson, $hInstance)
	Return True
EndFunc

Func _01_Start_OnNavigate($sUrl)
	If $g_bDebug_01_Start Then _Logger_Write("🌐 Навигация: " & $sUrl, 1)
EndFunc

Func _01_Start_OnPageLoaded()
	If $g_bDebug_01_Start Then _Logger_Write("✅ Страница загружена", 3)
EndFunc

Func _01_Start_OnLoadError($sError)
	If $g_bDebug_01_Start Then _Logger_Write("❌ Ошибка загрузки: " & $sError, 2)
EndFunc

Func _01_Start_OnSaveHistory($sUrl, $sTitle)
	If $g_bDebug_01_Start Then _Logger_Write("💾 История: " & $sTitle & " (" & $sUrl & ")", 1)
EndFunc

Func _01_Start_OnAddBookmark($sUrl, $sTitle)
	If $g_bDebug_01_Start Then _Logger_Write("⭐ Закладка: " & $sTitle & " (" & $sUrl & ")", 1)
EndFunc
