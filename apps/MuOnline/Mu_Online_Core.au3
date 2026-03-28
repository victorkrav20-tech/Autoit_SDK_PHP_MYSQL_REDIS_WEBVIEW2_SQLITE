; ===============================================================================
; Файл: Mu_Online_Core.au3
; Описание: Основные функции для работы с игрой MU Online
; Версия: 1.0.0
; Дата: 11.03.2026
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

; ===============================================================================
; Функция: _Core_GetGameData
; Описание: Получение всех данных из игры (город, координаты, helper, level)
; Параметры: $hWnd - Handle окна игры
; Возврат: Map с ключами: city, coords, helper, level
; ===============================================================================
Func _Core_GetGameData($hWnd)
	Local $mData[]
	$mData["city"] = ""
	$mData["coords"] = ""
	$mData["helper"] = 0
	$mData["level"] = 0
	$mData["success"] = False
	
	_Logger_Write("_Core_GetGameData: Начало сбора данных из окна", 1)
	
	; TODO: Здесь будет логика получения данных через OCR
	; Пока заглушка
	
	_Logger_Write("_Core_GetGameData: Данные собраны", 3)
	Return $mData
EndFunc

; ===============================================================================
; Функция: _Core_IsGameReady
; Описание: Проверка готовности игры к работе
; Параметры: $hWnd - Handle окна игры
; Возврат: True если игра готова, False если нет
; ===============================================================================
Func _Core_IsGameReady($hWnd)
	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Core_IsGameReady: Неверный handle окна", 2)
		Return False
	EndIf
	
	; Проверка что окно существует и видимо
	If Not WinExists($hWnd) Then
		_Logger_Write("_Core_IsGameReady: Окно не существует", 2)
		Return False
	EndIf
	
	_Logger_Write("_Core_IsGameReady: Игра готова", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Core_WaitForGameResponse
; Описание: Ожидание ответа от игры после действия
; Параметры: 
;   $iTimeout - Таймаут ожидания в миллисекундах (по умолчанию 3000)
; Возврат: True если дождались, False если таймаут
; ===============================================================================
Func _Core_WaitForGameResponse($iTimeout = 3000)
	_Logger_Write("_Core_WaitForGameResponse: Ожидание " & $iTimeout & " мс", 1)
	Sleep($iTimeout)
	Return True
EndFunc

