#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "Utils.au3"
#include "Utils_Config.au3"

; ===============================================================================
; Utils_Window Library v1.0
; Универсальная система управления окнами для всех приложений SDK
; ===============================================================================

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
; ===============================================================================
Global $g_aUtils_Windows = ''

; Константы для WM_SYSCOMMAND
Global Const $SC_MINIMIZE = 0xF020
Global Const $SC_MAXIMIZE = 0xF030
Global Const $SC_RESTORE = 0xF120

; Индексы массива окон
Global Enum $UTILS_WIN_HANDLE = 0, $UTILS_WIN_ID, $UTILS_WIN_TITLE, $UTILS_WIN_CONFIG_KEY, $UTILS_WIN_MOVING, $UTILS_WIN_RESIZING, $UTILS_WIN_FROZEN, $UTILS_WIN_CALLBACK_CLOSE, $UTILS_WIN_CALLBACK_MINIMIZE, $UTILS_WIN_CALLBACK_MAXIMIZE, $UTILS_WIN_CALLBACK_RESIZE, $UTILS_WIN_CALLBACK_MOVE, $UTILS_WIN_CALLBACK_FREEZE, $UTILS_WIN_CALLBACK_UNFREEZE, $UTILS_WIN_STYLE, $UTILS_WIN_MAX

; ===============================================================================
; БАЗОВЫЕ ФУНКЦИИ
; ===============================================================================

Func _Utils_Window_Create($sWindowID, $sTitle, $iWidth, $iHeight, $iX = -1, $iY = -1, $sStyle = "default", $funcOnClose = "", $bRegisterHandlers = True)
	If $sWindowID = "" Or $sTitle = "" Then
		_Logger_Write("[Utils_Window] ОШИБКА: WindowID и Title обязательны", 2)
		Return SetError(1, 0, False)
	EndIf

	_Logger_Write("[Utils_Window] Создание окна: " & $sWindowID & " (" & $sTitle & ")", 1)

	Local $sConfigKey = "windows." & $sWindowID
	Local $bRememberPosition = _Utils_Config_Get($sConfigKey & ".remember_position", True)
	Local $bRememberSize = _Utils_Config_Get($sConfigKey & ".remember_size", True)

	_Logger_Write("[Utils_Window] Настройки: remember_position=" & $bRememberPosition & ", remember_size=" & $bRememberSize, 1)

	If $bRememberPosition Then
		Local $iConfigX = _Utils_Config_Get($sConfigKey & ".position.x", $iX)
		Local $iConfigY = _Utils_Config_Get($sConfigKey & ".position.y", $iY)
		If $iConfigX <> "" Then $iX = $iConfigX
		If $iConfigY <> "" Then $iY = $iConfigY
		_Logger_Write("[Utils_Window] Позиция из конфига: X=" & $iX & ", Y=" & $iY, 1)
	EndIf

	If $bRememberSize Then
		Local $iConfigWidth = _Utils_Config_Get($sConfigKey & ".size.width", $iWidth)
		Local $iConfigHeight = _Utils_Config_Get($sConfigKey & ".size.height", $iHeight)
		If $iConfigWidth <> "" Then $iWidth = $iConfigWidth
		If $iConfigHeight <> "" Then $iHeight = $iConfigHeight
		_Logger_Write("[Utils_Window] Размер из конфига: " & $iWidth & "x" & $iHeight, 1)
	EndIf

	Local $iGUIStyle = $WS_OVERLAPPEDWINDOW
	Switch $sStyle
		Case "no_close"
			$iGUIStyle = BitAND($WS_OVERLAPPEDWINDOW, BitNOT($WS_SYSMENU))
		Case "no_minimize"
			$iGUIStyle = BitAND($WS_OVERLAPPEDWINDOW, BitNOT($WS_MINIMIZEBOX))
		Case "no_maximize"
			$iGUIStyle = BitAND($WS_OVERLAPPEDWINDOW, BitNOT($WS_MAXIMIZEBOX))
		Case "no_titlebar"
			$iGUIStyle = $WS_POPUP
		Case "borderless"
			$iGUIStyle = $WS_POPUP
		Case "webview2"
			$iGUIStyle = BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
	EndSwitch

	Local $hGUI = GUICreate($sTitle, $iWidth, $iHeight, $iX, $iY, $iGUIStyle)
	If @error Or $hGUI = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Не удалось создать GUI", 2)
		Return SetError(2, 0, False)
	EndIf

	_Logger_Write("[Utils_Window] GUI создан: Handle=" & $hGUI, 3)

	If $g_aUtils_Windows = '' Then
		Local $aTemp[1][$UTILS_WIN_MAX]
		$g_aUtils_Windows = $aTemp
	Else
		Local $iOldSize = UBound($g_aUtils_Windows, 1)
		Local $aTemp[$iOldSize + 1][$UTILS_WIN_MAX]
		For $i = 0 To $iOldSize - 1
			For $j = 0 To $UTILS_WIN_MAX - 1
				$aTemp[$i][$j] = $g_aUtils_Windows[$i][$j]
			Next
		Next
		$g_aUtils_Windows = $aTemp
	EndIf

	Local $iIndex = UBound($g_aUtils_Windows, 1) - 1
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_HANDLE] = $hGUI
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_ID] = $sWindowID
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_TITLE] = $sTitle
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_CONFIG_KEY] = $sConfigKey
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_MOVING] = False
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_RESIZING] = False
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_FROZEN] = False
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_CLOSE] = $funcOnClose
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_STYLE] = $sStyle

	_Logger_Write("[Utils_Window] Окно зарегистрировано в массиве, индекс=" & $iIndex, 1)

	; Регистрация обработчиков только если $bRegisterHandlers = True
	If $bRegisterHandlers Then
		; OnEventMode событие для закрытия окна
		Local $sCloseHandler = ($funcOnClose <> "") ? $funcOnClose : "_Utils_Window_OnClose"
		GUISetOnEvent($GUI_EVENT_CLOSE, $sCloseHandler, $hGUI)
		_Logger_Write("[Utils_Window] Обработчик закрытия: " & $sCloseHandler, 1)

		; WM обработчики для изменения размера и перемещения
		GUIRegisterMsg($WM_SIZE, "_Utils_Window_WM_SIZE")
		GUIRegisterMsg($WM_MOVE, "_Utils_Window_WM_MOVE")
		GUIRegisterMsg($WM_ENTERSIZEMOVE, "_Utils_Window_WM_ENTERSIZEMOVE")
		GUIRegisterMsg($WM_EXITSIZEMOVE, "_Utils_Window_WM_EXITSIZEMOVE")
		GUIRegisterMsg($WM_SYSCOMMAND, "_Utils_Window_WM_SYSCOMMAND")

		_Logger_Write("[Utils_Window] Обработчики событий зарегистрированы", 1)
	Else
		_Logger_Write("[Utils_Window] Регистрация обработчиков отключена (для WebView2)", 1)
	EndIf

	_Logger_Write("[Utils_Window] Окно создано успешно: " & $sWindowID, 3)

	Return $hGUI
EndFunc

; ===============================================================================
; Функция: _Utils_Window_CreateForWebView2
; ===============================================================================
; ===============================================================================
; Функция: _Utils_Window_CreateForWebView2
; Описание: Создать окно для WebView2 с конфигом но без WM обработчиков
; Параметры:
;   $sWindowID - уникальный ID окна
;   $sTitle - заголовок окна
;   $iWidth - ширина окна
;   $iHeight - высота окна
;   $iX - позиция X (по умолчанию -1 = центр)
;   $iY - позиция Y (по умолчанию -1 = центр)
; Возврат: Handle окна или False при ошибке
; Примечание: Не регистрирует WM обработчики (WebView2 сделает это сам)
; ===============================================================================
Func _Utils_Window_CreateForWebView2($sWindowID, $sTitle, $iWidth, $iHeight, $iX = -1, $iY = -1)
	Return _Utils_Window_Create($sWindowID, $sTitle, $iWidth, $iHeight, $iX, $iY, "webview2", "", False)
EndFunc


Func _Utils_Window_GetHandle($sWindowID)
	If $g_aUtils_Windows = '' Then Return 0
	For $i = 0 To UBound($g_aUtils_Windows, 1) - 1
		If $g_aUtils_Windows[$i][$UTILS_WIN_ID] = $sWindowID Then
			Return $g_aUtils_Windows[$i][$UTILS_WIN_HANDLE]
		EndIf
	Next
	Return 0
EndFunc

Func _Utils_Window_GetInstanceByHandle($hWnd)
	If $g_aUtils_Windows = '' Then Return -1
	For $i = 0 To UBound($g_aUtils_Windows, 1) - 1
		If $g_aUtils_Windows[$i][$UTILS_WIN_HANDLE] = $hWnd Then Return $i
	Next
	Return -1
EndFunc

Func _Utils_Window_Destroy($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	GUIDelete($hWnd)
	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Window] Окно уничтожено: " & $sWindowID, 1)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Window_Show
; ===============================================================================
; ===============================================================================
; Функция: _Utils_Window_Show
; Описание: Показать окно
; Параметры:
;   $sWindowID - ID окна
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_Show($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	GUISetState(@SW_SHOW, $hWnd)
	_Logger_Write("[Utils_Window] Окно показано: " & $sWindowID, 1)
	Return True
EndFunc
; ===============================================================================
; Функция: _Utils_Window_Hide
; Описание: Скрыть окно
; Параметры:
;   $sWindowID - ID окна
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_Hide($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	GUISetState(@SW_HIDE, $hWnd)
	_Logger_Write("[Utils_Window] Окно скрыто: " & $sWindowID, 1)
	Return True
EndFunc
; ===============================================================================
; Функция: _Utils_Window_Minimize
; Описание: Свернуть окно
; Параметры:
;   $sWindowID - ID окна
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_Minimize($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	GUISetState(@SW_MINIMIZE, $hWnd)
	_Logger_Write("[Utils_Window] Окно свернуто: " & $sWindowID, 1)
	Return True
EndFunc
; ===============================================================================
; Функция: _Utils_Window_Maximize
; Описание: Развернуть окно на весь экран
; Параметры:
;   $sWindowID - ID окна
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_Maximize($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	GUISetState(@SW_MAXIMIZE, $hWnd)
	_Logger_Write("[Utils_Window] Окно развернуто: " & $sWindowID, 1)
	Return True
EndFunc
; ===============================================================================
; Функция: _Utils_Window_Restore
; Описание: Восстановить нормальный размер окна
; Параметры:
;   $sWindowID - ID окна
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_Restore($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	GUISetState(@SW_RESTORE, $hWnd)
	_Logger_Write("[Utils_Window] Окно восстановлено: " & $sWindowID, 1)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Window_OnClose
; ===============================================================================
; ===============================================================================
; Функция: _Utils_Window_OnClose
; Описание: Универсальный обработчик закрытия окна (работает с WebView2 и без)
; Параметры: нет (использует @GUI_WinHandle)
; Возврат: нет
; Примечание: Автоматически определяет наличие WebView2 и корректно закрывает
; ===============================================================================
Func _Utils_Window_OnClose()
	Local $hWnd = @GUI_WinHandle
	_Logger_Write("[Utils_Window] Закрытие окна: Handle=" & $hWnd, 1)

	Local $iIndex = _Utils_Window_GetInstanceByHandle($hWnd)
	If $iIndex = -1 Then
		_Logger_Write("[Utils_Window] Окно не найдено в массиве, завершение", 1)
		Exit
	EndIf

	Local $sWindowID = $g_aUtils_Windows[$iIndex][$UTILS_WIN_ID]
	_Logger_Write("[Utils_Window] Закрытие окна: " & $sWindowID, 1)

	If $g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_CLOSE] <> "" Then
		_Logger_Write("[Utils_Window] Вызов callback: " & $g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_CLOSE], 1)
		Call($g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_CLOSE])
	Else
		Local $iOpenWindows = 0
		If $g_aUtils_Windows <> '' Then
			For $i = 0 To UBound($g_aUtils_Windows, 1) - 1
				Local $hTestWnd = $g_aUtils_Windows[$i][$UTILS_WIN_HANDLE]
				If $hTestWnd <> 0 And $hTestWnd <> $hWnd And WinExists($hTestWnd) Then
					$iOpenWindows += 1
				EndIf
			Next
		EndIf

		_Logger_Write("[Utils_Window] Открытых окон: " & $iOpenWindows, 1)

		If $iOpenWindows = 0 Then
			_Logger_Write("[Utils_Window] Все окна закрыты, завершение приложения", 3)
			Exit
		EndIf
	EndIf
EndFunc

; ===============================================================================
; Функция: _Utils_Window_SetTitle
; ===============================================================================
; ===============================================================================
; Функция: _Utils_Window_SetTitle
; Описание: Изменить заголовок окна
; Параметры:
;   $sWindowID - ID окна
;   $sNewTitle - новый заголовок
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_SetTitle($sWindowID, $sNewTitle)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	WinSetTitle($hWnd, "", $sNewTitle)
	_Logger_Write("[Utils_Window] Заголовок изменён: " & $sWindowID & " -> " & $sNewTitle, 1)
	Return True
EndFunc
; ===============================================================================
; Функция: _Utils_Window_GetState
; Описание: Получить состояние окна
; Параметры:
;   $sWindowID - ID окна
; Возврат: "visible", "hidden", "minimized", "maximized" или False при ошибке
; ===============================================================================
Func _Utils_Window_GetState($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	Local $iState = WinGetState($hWnd)
	Local $sState = "unknown"

	If BitAND($iState, 16) Then
		$sState = "minimized"
	ElseIf BitAND($iState, 32) Then
		$sState = "maximized"
	ElseIf BitAND($iState, 2) Then
		$sState = "visible"
	Else
		$sState = "hidden"
	EndIf
	_Logger_Write("[Utils_Window] Состояние окна " & $sWindowID & ": " & $sState, 1)
	Return $sState
EndFunc
; ===============================================================================
; Функция: _Utils_Window_IsVisible
; Описание: Проверить видимость окна
; Параметры:
;   $sWindowID - ID окна
; Возврат: True если видимо, False если скрыто или ошибка
; ===============================================================================
Func _Utils_Window_IsVisible($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	Local $iState = WinGetState($hWnd)
	Local $bVisible = BitAND($iState, 2) <> 0
	_Logger_Write("[Utils_Window] Видимость окна " & $sWindowID & ": " & ($bVisible ? "Да" : "Нет"), 1)
	Return $bVisible
EndFunc
; ===============================================================================
; Функция: _Utils_Window_SetPosition
; Описание: Установить позицию окна
; Параметры:
;   $sWindowID - ID окна
;   $iX - координата X
;   $iY - координата Y
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_SetPosition($sWindowID, $iX, $iY)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	WinMove($hWnd, "", $iX, $iY)
	_Logger_Write("[Utils_Window] Позиция установлена: " & $sWindowID & " -> X=" & $iX & ", Y=" & $iY, 1)
	Return True
EndFunc
; ===============================================================================
; Функция: _Utils_Window_SetSize
; Описание: Установить размер окна
; Параметры:
;   $sWindowID - ID окна
;   $iWidth - ширина
;   $iHeight - высота
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _Utils_Window_SetSize($sWindowID, $iWidth, $iHeight)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	WinMove($hWnd, "", Default, Default, $iWidth, $iHeight)
	_Logger_Write("[Utils_Window] Размер установлен: " & $sWindowID & " -> " & $iWidth & "x" & $iHeight, 1)
	Return True
EndFunc
; ===============================================================================
; Функция: _Utils_Window_GetPosition
; Описание: Получить позицию окна
; Параметры:
;   $sWindowID - ID окна
; Возврат: массив [X, Y] или False при ошибке
; ===============================================================================
Func _Utils_Window_GetPosition($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	Local $aPos = WinGetPos($hWnd)
	If @error Then
		_Logger_Write("[Utils_Window] ОШИБКА: Не удалось получить позицию окна: " & $sWindowID, 2)
		Return SetError(2, 0, False)
	EndIf
	Local $aResult[2] = [$aPos[0], $aPos[1]]
	_Logger_Write("[Utils_Window] Позиция окна " & $sWindowID & ": X=" & $aResult[0] & ", Y=" & $aResult[1], 1)
	Return $aResult
EndFunc
; ===============================================================================
; Функция: _Utils_Window_GetSize
; Описание: Получить размер окна
; Параметры:
;   $sWindowID - ID окна
; Возврат: массив [Width, Height] или False при ошибке
; ===============================================================================
Func _Utils_Window_GetSize($sWindowID)
	Local $hWnd = _Utils_Window_GetHandle($sWindowID)
	If $hWnd = 0 Then
		_Logger_Write("[Utils_Window] ОШИБКА: Окно не найдено: " & $sWindowID, 2)
		Return SetError(1, 0, False)
	EndIf
	Local $aPos = WinGetPos($hWnd)
	If @error Then
		_Logger_Write("[Utils_Window] ОШИБКА: Не удалось получить размер окна: " & $sWindowID, 2)
		Return SetError(2, 0, False)
	EndIf
	Local $aResult[2] = [$aPos[2], $aPos[3]]
	_Logger_Write("[Utils_Window] Размер окна " & $sWindowID & ": " & $aResult[0] & "x" & $aResult[1], 1)
	Return $aResult
EndFunc




; ===============================================================================
; WM ОБРАБОТЧИКИ
; ===============================================================================

Func _Utils_Window_WM_SIZE($hWnd, $iMsg, $wParam, $lParam)
	Local $iIndex = _Utils_Window_GetInstanceByHandle($hWnd)
	If $iIndex = -1 Then Return $GUI_RUNDEFMSG

	Local $aClientSize = WinGetClientSize($hWnd)
	If @error Then Return $GUI_RUNDEFMSG

	Local $iWidth = $aClientSize[0]
	Local $iHeight = $aClientSize[1]


	If $iWidth > 0 And $iHeight > 0 Then
		$g_aUtils_Windows[$iIndex][$UTILS_WIN_RESIZING] = True
		If $g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_RESIZE] <> "" Then
			Call($g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_RESIZE], $g_aUtils_Windows[$iIndex][$UTILS_WIN_ID], $iWidth, $iHeight)
		EndIf
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc

Func _Utils_Window_WM_MOVE($hWnd, $iMsg, $wParam, $lParam)
	Local $iIndex = _Utils_Window_GetInstanceByHandle($hWnd)
	If $iIndex = -1 Then Return $GUI_RUNDEFMSG
	$g_aUtils_Windows[$iIndex][$UTILS_WIN_MOVING] = True
	Return $GUI_RUNDEFMSG
EndFunc

Func _Utils_Window_WM_ENTERSIZEMOVE($hWnd, $iMsg, $wParam, $lParam)
	Return $GUI_RUNDEFMSG
EndFunc

Func _Utils_Window_WM_EXITSIZEMOVE($hWnd, $iMsg, $wParam, $lParam)
	Local $iIndex = _Utils_Window_GetInstanceByHandle($hWnd)
	If $iIndex = -1 Then Return $GUI_RUNDEFMSG

	Local $aPos = WinGetPos($hWnd)
	If Not @error And IsArray($aPos) Then
		Local $sConfigKey = $g_aUtils_Windows[$iIndex][$UTILS_WIN_CONFIG_KEY]

		If $g_aUtils_Windows[$iIndex][$UTILS_WIN_MOVING] Then
			Local $bRememberPosition = _Utils_Config_Get($sConfigKey & ".remember_position", True)
			If $bRememberPosition Then
				_Utils_Config_Set($sConfigKey & ".position.x", $aPos[0])
				_Utils_Config_Set($sConfigKey & ".position.y", $aPos[1])
				If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Window] Позиция сохранена: " & $aPos[0] & ", " & $aPos[1], 3)
			EndIf
			$g_aUtils_Windows[$iIndex][$UTILS_WIN_MOVING] = False
		EndIf

		If $g_aUtils_Windows[$iIndex][$UTILS_WIN_RESIZING] Then
			Local $bRememberSize = _Utils_Config_Get($sConfigKey & ".remember_size", True)
			If $bRememberSize Then
				_Utils_Config_Set($sConfigKey & ".size.width", $aPos[2])
				_Utils_Config_Set($sConfigKey & ".size.height", $aPos[3])
				If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Window] Размер сохранён: " & $aPos[2] & "x" & $aPos[3], 3)
			EndIf
			$g_aUtils_Windows[$iIndex][$UTILS_WIN_RESIZING] = False
		EndIf
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc

Func _Utils_Window_WM_SYSCOMMAND($hWnd, $iMsg, $wParam, $lParam)
	Local $iIndex = _Utils_Window_GetInstanceByHandle($hWnd)
	If $iIndex = -1 Then Return $GUI_RUNDEFMSG

	Local $iCommand = BitAND($wParam, 0xFFF0)

	Switch $iCommand
		Case $SC_MINIMIZE
			If $g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_MINIMIZE] <> "" Then
				Call($g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_MINIMIZE], $g_aUtils_Windows[$iIndex][$UTILS_WIN_ID])
			EndIf
		Case $SC_MAXIMIZE, $SC_RESTORE
			If $g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_MAXIMIZE] <> "" Then
				Call($g_aUtils_Windows[$iIndex][$UTILS_WIN_CALLBACK_MAXIMIZE], $g_aUtils_Windows[$iIndex][$UTILS_WIN_ID])
			EndIf
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc
