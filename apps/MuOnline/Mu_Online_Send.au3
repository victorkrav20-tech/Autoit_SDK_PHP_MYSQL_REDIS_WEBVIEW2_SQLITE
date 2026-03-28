; ===============================================================================
; Файл: Mu_Online_Send.au3
; Описание: Функции отправки команд в игру MU Online через ControlSend
; Версия: 1.0.0
; Дата: 11.03.2026
; ===============================================================================

#include-once

; ===============================================================================
; Функция: _Send_Reset
; Описание: Отправка команды /reset в игру (фоновый режим через PostMessage)
; Параметры: $hWnd - Handle окна игры
; Возврат: True если успешно, False если ошибка
; ===============================================================================
Func _Send_Reset($hWnd)
	_Logger_Write("_Send_Reset: Отправка команды /reset", 1)
	
	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Send_Reset: Неверный handle окна", 2)
		Return False
	EndIf
	
	If Not WinExists($hWnd) Then
		_Logger_Write("_Send_Reset: Окно не существует", 2)
		Return False
	EndIf
	
	; Константы WinAPI
	Local Const $WM_CHAR = 0x0102
	Local Const $WM_KEYDOWN = 0x0100
	Local Const $VK_RETURN = 0x0D
	
	; Шаг 1: Enter для открытия чата
	DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_KEYDOWN, "wparam", $VK_RETURN, "lparam", 0)
	Sleep(300)
	
	; Шаг 2: Отправка /reset посимвольно через WM_CHAR
	Local $sCommand = "/reset"
	For $i = 1 To StringLen($sCommand)
		Local $iChar = Asc(StringMid($sCommand, $i, 1))
		DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_CHAR, "wparam", $iChar, "lparam", 0)
		Sleep(50)
	Next
	Sleep(300)
	
	; Шаг 3: Enter для выполнения команды
	DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_KEYDOWN, "wparam", $VK_RETURN, "lparam", 0)
	Sleep(500)
	
	_Logger_Write("_Send_Reset: Команда отправлена", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Send_Add_Stats
; ===============================================================================
Func _Send_Add_Stats($hWnd, $addstr = 0, $addagi = 0, $addvit = 0, $addene = 0, $addcmd = 0)
	_Logger_Write("_Send_Add_Stats: Распределение статов str=" & $addstr & " agi=" & $addagi & " vit=" & $addvit & " ene=" & $addene & " cmd=" & $addcmd, 1)

	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Send_Add_Stats: Неверный handle окна", 2)
		Return False
	EndIf

	If Not WinExists($hWnd) Then
		_Logger_Write("_Send_Add_Stats: Окно не существует", 2)
		Return False
	EndIf

	; Константы WinAPI
	Local Const $WM_CHAR = 0x0102
	Local Const $WM_KEYDOWN = 0x0100
	Local Const $VK_RETURN = 0x0D

	; Список статов: команда => значение (порядок: STR, AGI, VIT, ENE, CMD)
	Local $aStats[5][2]
	$aStats[0][0] = "/addstr"
	$aStats[0][1] = $addstr
	$aStats[1][0] = "/addagi"
	$aStats[1][1] = $addagi
	$aStats[2][0] = "/addvit"
	$aStats[2][1] = $addvit
	$aStats[3][0] = "/addene"
	$aStats[3][1] = $addene
	$aStats[4][0] = "/addcmd"
	$aStats[4][1] = $addcmd

	Local $iSent = 0

	For $i = 0 To 4
		; Пропускаем если стат = 0
		If $aStats[$i][1] = 0 Then
			_Logger_Write("_Send_Add_Stats: Пропуск " & $aStats[$i][0] & " (значение 0)", 1)
			ContinueLoop
		EndIf

		Local $sCommand = $aStats[$i][0] & " " & $aStats[$i][1]
		_Logger_Write("_Send_Add_Stats: Отправка команды: " & $sCommand, 1)

		; Шаг 1: Enter для открытия чата
		DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_KEYDOWN, "wparam", $VK_RETURN, "lparam", 0)
		Sleep(300)

		; Шаг 2: Отправка команды посимвольно через WM_CHAR
		For $j = 1 To StringLen($sCommand)
			Local $iChar = Asc(StringMid($sCommand, $j, 1))
			DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_CHAR, "wparam", $iChar, "lparam", 0)
			Sleep(50)
		Next
		Sleep(300)

		; Шаг 3: Enter для выполнения команды
		DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_KEYDOWN, "wparam", $VK_RETURN, "lparam", 0)
		Sleep(500)

		$iSent += 1
		_Logger_Write("_Send_Add_Stats: Команда " & $sCommand & " отправлена", 3)
	Next

	_Logger_Write("_Send_Add_Stats: Отправлено команд: " & $iSent, 3)
	Return True
EndFunc


; ===============================================================================
; Функция: _Send_Command
; Описание: Отправка произвольной команды в игру (фоновый режим через PostMessage)
; Параметры: 
;   $hWnd - Handle окна игры
;   $sCommand - Команда для отправки (например "/reset", "/move")
; Возврат: True если успешно, False если ошибка
; ===============================================================================
Func _Send_Command($hWnd, $sCommand)
	_Logger_Write("_Send_Command: Отправка команды: " & $sCommand, 1)
	
	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Send_Command: Неверный handle окна", 2)
		Return False
	EndIf
	
	; Константы WinAPI
	Local Const $WM_CHAR = 0x0102
	Local Const $WM_KEYDOWN = 0x0100
	Local Const $VK_RETURN = 0x0D
	
	; Открытие чата
	DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_KEYDOWN, "wparam", $VK_RETURN, "lparam", 0)
	Sleep(200)
	
	; Отправка команды посимвольно
	For $i = 1 To StringLen($sCommand)
		Local $iChar = Asc(StringMid($sCommand, $i, 1))
		DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_CHAR, "wparam", $iChar, "lparam", 0)
		Sleep(50)
	Next
	Sleep(200)
	
	; Выполнение команды
	DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_KEYDOWN, "wparam", $VK_RETURN, "lparam", 0)
	Sleep(500)
	
	_Logger_Write("_Send_Command: Команда отправлена", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Send_KeyPress
; Описание: Отправка нажатия клавиши в игру
; Параметры: 
;   $hWnd - Handle окна игры
;   $sKey - Клавиша для отправки (например "{F1}", "{ESC}", "a")
; Возврат: True если успешно, False если ошибка
; ===============================================================================
Func _Send_KeyPress($hWnd, $sKey)
	_Logger_Write("_Send_KeyPress: Отправка клавиши: " & $sKey, 1)
	
	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Send_KeyPress: Неверный handle окна", 2)
		Return False
	EndIf
	
	; Отправка клавиши
	ControlSend($hWnd, "", "", $sKey)
	Sleep(100)
	
	_Logger_Write("_Send_KeyPress: Клавиша отправлена", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Send_Click
; Описание: Фоновый клик по координатам в окне (перемещение мыши + клик)
; Параметры:
;   $hWnd - Handle окна
;   $iX - X координата (относительно окна)
;   $iY - Y координата (относительно окна)
;   $bCtrl - Зажать Ctrl при клике (по умолчанию False)
; Возврат: True/False
; ===============================================================================
Func _Send_Click($hWnd, $iX, $iY, $bCtrl = False)
	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Send_Click: Неверный handle окна", 2)
		Return False
	EndIf
	
	If Not WinExists($hWnd) Then
		_Logger_Write("_Send_Click: Окно не существует", 2)
		Return False
	EndIf
	
	; Константы WinAPI
	Local Const $WM_MOUSEMOVE = 0x0200
	Local Const $WM_LBUTTONDOWN = 0x0201
	Local Const $WM_LBUTTONUP = 0x0202
	Local Const $MK_CONTROL = 0x0008
	
	; Формируем lparam для координат (Y-30: компенсация высоты titlebar окна)
	Local $lParam = BitOR($iX, BitShift($iY - 30, -16))
	Local $wParam = ($bCtrl ? $MK_CONTROL : 0)
	
	; Шаг 1: Фоновое перемещение мыши
	DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_MOUSEMOVE, "wparam", 0, "lparam", $lParam)
	Sleep(150)
	
	; Шаг 2: Клик (с Ctrl если нужно)
	DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_LBUTTONDOWN, "wparam", $wParam, "lparam", $lParam)
	Sleep(50)
	DllCall("user32.dll", "lresult", "PostMessage", "hwnd", $hWnd, "uint", $WM_LBUTTONUP, "wparam", $wParam, "lparam", $lParam)
	
	Return True
EndFunc

; ===============================================================================
; Функция: _Send_TeleportToCity
; Описание: Телепорт в город через карту (клик по кнопке + Ctrl+Click) - ФОНОВЫЙ
; Параметры:
;   $hWnd - Handle окна игры
;   $iY - Y координата города в списке (533, 551, 569...)
; Возврат: True/False
; ===============================================================================
Func _Send_TeleportToCity($hWnd, $iY)
	_Logger_Write("_Send_TeleportToCity: Телепорт на Y=" & $iY, 1)
	
	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Send_TeleportToCity: Неверный handle окна", 2)
		Return False
	EndIf
	
	If Not WinExists($hWnd) Then
		_Logger_Write("_Send_TeleportToCity: Окно не существует", 2)
		Return False
	EndIf
	
	Local $iX = 200
	
	; Шаг 1: Открываем карту кликом по кнопке (686, 870)
	_Logger_Write("_Send_TeleportToCity: Открытие карты (клик по кнопке 686,840)", 1)
	_Send_Click($hWnd, 686, 870)
	Sleep(1000)
	
	; Шаг 2: Ctrl+Click по городу
	_Logger_Write("_Send_TeleportToCity: Ctrl+Click на X=" & $iX & " Y=" & $iY, 1)
	_Send_Click($hWnd, $iX, $iY, True)
	Sleep(500)
	
	_Logger_Write("_Send_TeleportToCity: Телепорт завершён (карта закроется автоматически)", 3)
	Return True
EndFunc

