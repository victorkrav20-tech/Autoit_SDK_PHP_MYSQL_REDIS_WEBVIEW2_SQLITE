; ===============================================================================
; Файл: 01_Start_Init_Utils.au3
; Описание: Вспомогательные функции для приложения 01_Start
; ===============================================================================

#include-once
#include <TrayConstants.au3>
#include "01_Start_Init.au3"
#include "01_Start_Main.au3"

; ===============================================================================
; АВТОКЛИКЕР (F2)
; ===============================================================================
Global $g_bAutoClicker_Enabled = False
Global $g_hAutoClicker_Timer = TimerInit()
Global $g_iAutoClicker_Interval = 10

; ===============================================================================
; ГОРЯЧИЕ КЛАВИШИ (асинхронная регистрация с повторными попытками)
; ===============================================================================
Global $g_iHotKey_Tries = 0
Global $g_bHotKey_Registered = False

Global $g_sTray_Mode ; Режим трэя: "destroy" или "hide" (значение задаётся в Main)

; ===============================================================================
; Функция: _01_Start_RegisterHotKeys_Async
; Описание: Асинхронная регистрация горячих клавиш с повторными попытками
; ===============================================================================
Func _01_Start_RegisterHotKeys_Async()
	$g_iHotKey_Tries += 1

	Local $bF2Success = HotKeySet("{F2}", "_01_Start_AutoClicker_Toggle")

	If $bF2Success Then
		If $g_bDebug_01_Start Then _Logger_Write("✅ [HOTKEY] F2 зарегистрирована на попытке " & $g_iHotKey_Tries, 3)
		$g_bHotKey_Registered = True
		AdlibUnRegister("_01_Start_RegisterHotKeys_Async")
		Return True
	EndIf

	If $g_iHotKey_Tries >= 10 Then
		If $g_bDebug_01_Start Then _Logger_Write("❌ [HOTKEY] Не удалось занять F2 за 10 попыток. Самоотключение.", 2)
		AdlibUnRegister("_01_Start_RegisterHotKeys_Async")
		Return False
	EndIf

	If Mod($g_iHotKey_Tries, 3) = 0 Then
		If $g_bDebug_01_Start Then _Logger_Write("⚠️ [HOTKEY] F2 занята... Попытка " & $g_iHotKey_Tries & "/10", 3)
	EndIf

	Return False
EndFunc

; ===============================================================================
; Функция: _01_Start_AutoClicker_Toggle
; Описание: Переключение автокликера по F2
; ===============================================================================
Func _01_Start_AutoClicker_Toggle()
	$g_bAutoClicker_Enabled = Not $g_bAutoClicker_Enabled

	If $g_bAutoClicker_Enabled Then
		$g_hAutoClicker_Timer = TimerInit()
		If $g_bDebug_01_Start Then _Logger_Write("🖱️ [AutoClicker] ВКЛЮЧЕН (интервал: " & $g_iAutoClicker_Interval & "мс)", 3)
	Else
		If $g_bDebug_01_Start Then _Logger_Write("🖱️ [AutoClicker] ВЫКЛЮЧЕН", 3)
	EndIf

	Local $sMessage = $g_bAutoClicker_Enabled ? "Автокликер включен" : "Автокликер выключен"
	Local $sType = $g_bAutoClicker_Enabled ? "success" : "info"
	_WebView2_Bridge_Notify($sType, $sMessage, 1)
EndFunc

; ===============================================================================
; Функция: _01_Start_AutoClicker_Process
; Описание: Обработка автокликера в основном цикле
; ===============================================================================
Func _01_Start_AutoClicker_Process()
	If Not $g_bAutoClicker_Enabled Then Return

	If TimerDiff($g_hAutoClicker_Timer) >= $g_iAutoClicker_Interval Then
		MouseClick("left")
		$g_hAutoClicker_Timer = TimerInit()
	EndIf
EndFunc

; ===============================================================================
; Функция: _01_Start_Tray_Toggle
; Описание: Переключение видимости главного окна по клику на трэй
; Режимы: "destroy" - создать/удалить, "hide" - показать/скрыть
; ===============================================================================
Func _01_Start_Tray_Toggle()
	Local $iInstanceID = $g_i01_Start_InstanceID

	Switch $g_sTray_Mode
		Case "destroy"
			; ═══════════════════════════════════════════════════
			; РЕЖИМ 1: CREATE/DESTROY
			; ═══════════════════════════════════════════════════
			If $g_b01_Start_WindowExists Then
				Local $iIndex = _WebView2_Core_GetInstance($iInstanceID)
				If $iIndex >= 0 Then
					If $g_bDebug_01_Start Then _Logger_Write("🎯 [Tray] Удаление окна Instance=" & $iInstanceID, 1)
					_01_Start_Window_Destroy()
				Else
					; Флаг True, но инстанс не существует — пересоздаём
					If $g_bDebug_01_Start Then _Logger_Write("🔄 [Tray] Флаг True, но инстанс не существует — создаю", 1)
					$g_b01_Start_WindowExists = False
					_01_Start_Window_Create()
				EndIf
			Else
				If $g_bDebug_01_Start Then _Logger_Write("🎯 [Tray] Создание окна Instance=" & $iInstanceID, 1)
				_01_Start_Window_Create()
			EndIf

		Case "hide"
			; ═══════════════════════════════════════════════════
			; РЕЖИМ 2: SHOW/HIDE
			; ═══════════════════════════════════════════════════
			If Not $g_b01_Start_WindowExists Then
				If $g_bDebug_01_Start Then _Logger_Write("🎯 [Tray] Создание окна Instance=" & $iInstanceID, 1)
				_01_Start_Window_Create()
			Else
				Local $hGUI = _WebView2_GUI_GetHandle($iInstanceID)
				If $hGUI = 0 Then
					; Handle не найден — пересоздаём
					If $g_bDebug_01_Start Then _Logger_Write("🔄 [Tray] Handle не найден — пересоздаю окно", 1)
					$g_b01_Start_WindowExists = False
					_01_Start_Window_Create()
				Else
					Local $iState = WinGetState($hGUI)
					If BitAND($iState, 2) Then
						If $g_bDebug_01_Start Then _Logger_Write("🙈 [Tray] Скрытие окна Instance=" & $iInstanceID, 1)
						_WebView2_GUI_Hide($iInstanceID)
					Else
						If $g_bDebug_01_Start Then _Logger_Write("👁️ [Tray] Показ окна Instance=" & $iInstanceID, 1)
						_WebView2_GUI_Show($iInstanceID)
						WinActivate($hGUI)
					EndIf
				EndIf
			EndIf
	EndSwitch
EndFunc

; ===============================================================================
; Функция: _01_Start_Tray_Init
; Описание: Инициализация трэя — иконка, подсказка, обработчик клика
; ===============================================================================
Func _01_Start_Tray_Init()
	; Загружаем режим трея из конфига
	$g_sTray_Mode = _Utils_Config_Get("tray.mode", "hide")

	; Иконка
	If FileExists(@ScriptDir & "\icon.ico") Then
		TraySetIcon(@ScriptDir & "\icon.ico")
	EndIf

	; Подсказка при наведении
	TraySetToolTip("01 Start" & @CRLF & "Клик - показать/скрыть")

	; Обработчик клика левой кнопкой
	TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "_01_Start_Tray_Toggle")

	; Показываем иконку
	TraySetState(1)

	If $g_bDebug_01_Start Then _Logger_Write("🎯 Трэй инициализирован (режим: " & $g_sTray_Mode & ")", 3)
EndFunc
