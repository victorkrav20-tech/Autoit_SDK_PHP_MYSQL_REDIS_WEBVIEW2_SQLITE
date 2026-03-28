; ===============================================================================
; Файл: Mu_Online_Markers.au3
; Описание: Система проверки пикселей (маяков) для навигации и принятия решений
; Версия: 1.0.0
; Дата: 11.03.2026
; ===============================================================================
; ФУНКЦИИ:
; _Markers_Init() - Инициализация системы маяков
; _Markers_Load() - Загрузка маяков из JSON
; _Markers_Save() - Сохранение маяков в JSON
; _Markers_Add() - Добавление нового маяка
; _Markers_Update() - Обновление цвета маяка
; _Markers_Delete() - Удаление маяка
; _Markers_ScanAll() - Сканирование всех маяков
; _Markers_Check() - Проверка конкретного маяка
; _Markers_GetPixelColor() - Получение цвета пикселя из bitmap
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"
#include "..\..\libs\json\JSON.au3"
#include <GDIPlus.au3>

; === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
Global $g_sMarkers_FilePath = @ScriptDir & "\data\markers.json"
Global $g_aMarkers = '' ; Массив маяков из JSON

; ===============================================================================
; Функция: _Markers_Init
; Описание: Инициализация системы маяков
; Возврат: True/False
; ===============================================================================
Func _Markers_Init()
	_Logger_Write("_Markers_Init: Инициализация системы маяков", 1)
	
	; Проверяем существование папки data
	Local $sDataFolder = @ScriptDir & "\data"
	If Not FileExists($sDataFolder) Then
		DirCreate($sDataFolder)
		_Logger_Write("_Markers_Init: Создана папка data", 1)
	EndIf
	
	; Проверяем существование файла markers.json
	If Not FileExists($g_sMarkers_FilePath) Then
		_Logger_Write("_Markers_Init: Файл markers.json не найден, создаём пустой", 1)
		
		; Создаём пустую структуру
		Local $oMarkers = ObjCreate("Scripting.Dictionary")
		$oMarkers.Add("markers", _JSON_Parse("[]"))
		
		Local $sJSON = _JSON_Generate($oMarkers, True)
		FileWrite($g_sMarkers_FilePath, $sJSON)
	EndIf
	
	; Загружаем маяки
	Return _Markers_Load()
EndFunc

; ===============================================================================
; Функция: _Markers_Load
; Описание: Загрузка маяков из JSON файла
; Возврат: True/False
; ===============================================================================
Func _Markers_Load()
	_Logger_Write("_Markers_Load: Загрузка маяков из JSON", 1)
	
	If Not FileExists($g_sMarkers_FilePath) Then
		_Logger_Write("_Markers_Load: Файл не существует", 2)
		Return False
	EndIf
	
	Local $sJSON = FileRead($g_sMarkers_FilePath)
	If @error Then
		_Logger_Write("_Markers_Load: Ошибка чтения файла", 2)
		Return False
	EndIf
	
	$g_aMarkers = _JSON_Parse($sJSON)
	If @error Then
		_Logger_Write("_Markers_Load: Ошибка парсинга JSON", 2)
		Return False
	EndIf
	
	Local $iCount = UBound(_JSON_Get($g_aMarkers, "markers"))
	_Logger_Write("_Markers_Load: Загружено маяков: " & $iCount, 3)
	
	Return True
EndFunc

; ===============================================================================
; Функция: _Markers_Save
; Описание: Сохранение маяков в JSON файл
; Возврат: True/False
; ===============================================================================
Func _Markers_Save()
	_Logger_Write("_Markers_Save: Сохранение маяков в JSON", 1)
	
	Local $sJSON = _JSON_Generate($g_aMarkers, True)
	If @error Then
		_Logger_Write("_Markers_Save: Ошибка генерации JSON", 2)
		Return False
	EndIf
	
	Local $hFile = FileOpen($g_sMarkers_FilePath, 2)
	If $hFile = -1 Then
		_Logger_Write("_Markers_Save: Ошибка открытия файла", 2)
		Return False
	EndIf
	
	FileWrite($hFile, $sJSON)
	FileClose($hFile)
	
	_Logger_Write("_Markers_Save: Маяки сохранены", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Markers_Add
; Описание: Добавление нового маяка
; Параметры:
;   $sName - Имя маяка
;   $iX - X координата
;   $iY - Y координата
;   $sDescription - Описание (опционально)
; Возврат: True/False
; ===============================================================================
Func _Markers_Add($sName, $iX, $iY, $sDescription = "")
	_Logger_Write("_Markers_Add: Добавление маяка '" & $sName & "' [" & $iX & "," & $iY & "]", 1)
	
	; Создаём новый маяк
	Local $oMarker = ObjCreate("Scripting.Dictionary")
	$oMarker.Add("name", $sName)
	$oMarker.Add("x", $iX)
	$oMarker.Add("y", $iY)
	$oMarker.Add("color", "")
	$oMarker.Add("description", $sDescription)
	
	; Добавляем в массив
	Local $aMarkers = _JSON_Get($g_aMarkers, "markers")
	ReDim $aMarkers[UBound($aMarkers) + 1]
	$aMarkers[UBound($aMarkers) - 1] = $oMarker
	
	_JSON_addChangeDelete($g_aMarkers, "markers", $aMarkers)
	
	; Сохраняем
	_Markers_Save()
	
	_Logger_Write("_Markers_Add: Маяк добавлен", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Markers_Update
; Описание: Обновление цвета маяка из текущего скриншота
; Параметры:
;   $sName - Имя маяка
;   $hBitmap - Handle bitmap (если 0, то делается новый скриншот)
; Возврат: True/False
; ===============================================================================
Func _Markers_Update($sName, $hBitmap = 0)
	_Logger_Write("_Markers_Update: Обновление маяка '" & $sName & "'", 1)
	
	; Ищем маяк
	Local $aMarkers = _JSON_Get($g_aMarkers, "markers")
	Local $iIndex = -1
	
	For $i = 0 To UBound($aMarkers) - 1
		If $aMarkers[$i].Item("name") = $sName Then
			$iIndex = $i
			ExitLoop
		EndIf
	Next
	
	If $iIndex = -1 Then
		_Logger_Write("_Markers_Update: Маяк не найден", 2)
		Return False
	EndIf
	
	; Получаем координаты
	Local $iX = $aMarkers[$iIndex].Item("x")
	Local $iY = $aMarkers[$iIndex].Item("y")
	
	; Получаем цвет пикселя
	Local $sColor = _Markers_GetPixelColor($hBitmap, $iX, $iY)
	If $sColor = "" Then
		_Logger_Write("_Markers_Update: Ошибка получения цвета", 2)
		Return False
	EndIf
	
	; Обновляем цвет
	$aMarkers[$iIndex].Item("color") = $sColor
	_JSON_addChangeDelete($g_aMarkers, "markers", $aMarkers)
	
	; Сохраняем
	_Markers_Save()
	
	_Logger_Write("_Markers_Update: Цвет обновлён: " & $sColor, 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Markers_Delete
; Описание: Удаление маяка
; Параметры: $sName - Имя маяка
; Возврат: True/False
; ===============================================================================
Func _Markers_Delete($sName)
	_Logger_Write("_Markers_Delete: Удаление маяка '" & $sName & "'", 1)
	
	Local $aMarkers = _JSON_Get($g_aMarkers, "markers")
	Local $aNewMarkers[0]
	
	For $i = 0 To UBound($aMarkers) - 1
		If $aMarkers[$i].Item("name") <> $sName Then
			ReDim $aNewMarkers[UBound($aNewMarkers) + 1]
			$aNewMarkers[UBound($aNewMarkers) - 1] = $aMarkers[$i]
		EndIf
	Next
	
	_JSON_addChangeDelete($g_aMarkers, "markers", $aNewMarkers)
	_Markers_Save()
	
	_Logger_Write("_Markers_Delete: Маяк удалён", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Markers_ScanAll
; Описание: Сканирование всех маяков (делает скриншот и проверяет все точки)
; Параметры: $hWnd - Handle окна игры
; Возврат: Массив результатов [name, x, y, expected_color, current_color, match]
; ===============================================================================
Func _Markers_ScanAll($hWnd)
	_Logger_Write("_Markers_ScanAll: Сканирование всех маяков", 1)
	
	If Not IsHWnd($hWnd) Then
		_Logger_Write("_Markers_ScanAll: Неверный handle окна", 2)
		Return SetError(1, 0, '')
	EndIf
	
	; Делаем скриншот окна
	Local $aPos = WinGetPos($hWnd)
	If Not IsArray($aPos) Then
		_Logger_Write("_Markers_ScanAll: Ошибка получения позиции окна", 2)
		Return SetError(2, 0, '')
	EndIf
	
	; Захват окна через PrintWindow
	_GDIPlus_Startup()
	
	Local $hDC = _WinAPI_GetDC($hWnd)
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
	Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $aPos[2], $aPos[3])
	Local $hOld = _WinAPI_SelectObject($hMemDC, $hBitmap)
	
	DllCall("user32.dll", "bool", "PrintWindow", "hwnd", $hWnd, "handle", $hMemDC, "uint", 0)
	
	Local $hGDIBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
	
	; Освобождаем ресурсы GDI
	_WinAPI_SelectObject($hMemDC, $hOld)
	_WinAPI_DeleteObject($hBitmap)
	_WinAPI_DeleteDC($hMemDC)
	_WinAPI_ReleaseDC($hWnd, $hDC)
	
	; Сканируем все маяки
	Local $aMarkers = _JSON_Get($g_aMarkers, "markers")
	
	If Not IsArray($aMarkers) Or UBound($aMarkers) = 0 Then
		_Logger_Write("_Markers_ScanAll: Нет маяков для сканирования", 2)
		_GDIPlus_BitmapDispose($hGDIBitmap)
		_GDIPlus_Shutdown()
		Return SetError(3, 0, '')
	EndIf
	
	Local $aResults[UBound($aMarkers)][6]
	
	For $i = 0 To UBound($aMarkers) - 1
		; Получаем данные маяка через _JSON_Get
		Local $sName = _JSON_Get($aMarkers, "[" & $i & "].name")
		Local $iX = _JSON_Get($aMarkers, "[" & $i & "].x")
		Local $iY = _JSON_Get($aMarkers, "[" & $i & "].y")
		Local $sExpectedColor = _JSON_Get($aMarkers, "[" & $i & "].color")
		
		; Получаем текущий цвет
		Local $iColor = _GDIPlus_BitmapGetPixel($hGDIBitmap, $iX, $iY)
		Local $sCurrentColor = "0x" & Hex($iColor, 6)
		
		; Проверяем совпадение
		Local $bMatch = ($sExpectedColor = "" Or $sExpectedColor = $sCurrentColor)
		
		$aResults[$i][0] = $sName
		$aResults[$i][1] = $iX
		$aResults[$i][2] = $iY
		$aResults[$i][3] = $sExpectedColor
		$aResults[$i][4] = $sCurrentColor
		$aResults[$i][5] = $bMatch
		
		_Logger_Write("Маяк '" & $sName & "': ожидается=" & $sExpectedColor & ", текущий=" & $sCurrentColor & ", совпадение=" & $bMatch, 1)
	Next
	
	; Освобождаем GDI+ bitmap
	_GDIPlus_BitmapDispose($hGDIBitmap)
	_GDIPlus_Shutdown()
	
	_Logger_Write("_Markers_ScanAll: Сканирование завершено", 3)
	Return $aResults
EndFunc

; ===============================================================================
; Функция: _Markers_Check
; Описание: Проверка конкретного маяка
; Параметры:
;   $sName - Имя маяка
;   $hWnd - Handle окна игры
; Возврат: True если цвет совпадает, False если нет
; ===============================================================================
Func _Markers_Check($sName, $hWnd)
	_Logger_Write("_Markers_Check: Проверка маяка '" & $sName & "'", 1)
	
	; Ищем маяк
	Local $aMarkers = _JSON_Get($g_aMarkers, "markers")
	Local $iIndex = -1
	
	For $i = 0 To UBound($aMarkers) - 1
		If $aMarkers[$i].Item("name") = $sName Then
			$iIndex = $i
			ExitLoop
		EndIf
	Next
	
	If $iIndex = -1 Then
		_Logger_Write("_Markers_Check: Маяк не найден", 2)
		Return SetError(1, 0, False)
	EndIf
	
	; Получаем данные маяка
	Local $iX = $aMarkers[$iIndex].Item("x")
	Local $iY = $aMarkers[$iIndex].Item("y")
	Local $sExpectedColor = $aMarkers[$iIndex].Item("color")
	
	If $sExpectedColor = "" Then
		_Logger_Write("_Markers_Check: У маяка не задан цвет", 2)
		Return SetError(2, 0, False)
	EndIf
	
	; Делаем скриншот и получаем цвет
	Local $aPos = WinGetPos($hWnd)
	If Not IsArray($aPos) Then
		_Logger_Write("_Markers_Check: Ошибка получения позиции окна", 2)
		Return SetError(3, 0, False)
	EndIf
	
	_GDIPlus_Startup()
	
	Local $hDC = _WinAPI_GetDC($hWnd)
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
	Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $aPos[2], $aPos[3])
	Local $hOld = _WinAPI_SelectObject($hMemDC, $hBitmap)
	
	DllCall("user32.dll", "bool", "PrintWindow", "hwnd", $hWnd, "handle", $hMemDC, "uint", 0)
	
	Local $hGDIBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
	
	; Получаем цвет пикселя
	Local $iColor = _GDIPlus_BitmapGetPixel($hGDIBitmap, $iX, $iY)
	Local $sCurrentColor = "0x" & Hex($iColor, 6)
	
	; Освобождаем ресурсы
	_GDIPlus_BitmapDispose($hGDIBitmap)
	_WinAPI_SelectObject($hMemDC, $hOld)
	_WinAPI_DeleteObject($hBitmap)
	_WinAPI_DeleteDC($hMemDC)
	_WinAPI_ReleaseDC($hWnd, $hDC)
	_GDIPlus_Shutdown()
	
	; Сравниваем цвета
	Local $bMatch = ($sExpectedColor = $sCurrentColor)
	
	_Logger_Write("_Markers_Check: ожидается=" & $sExpectedColor & ", текущий=" & $sCurrentColor & ", совпадение=" & $bMatch, 1)
	
	Return $bMatch
EndFunc

; ===============================================================================
; Функция: _Markers_GetPixelColor
; Описание: Получение цвета пикселя из bitmap
; Параметры:
;   $hBitmap - Handle GDI+ bitmap (если 0, возвращает ошибку)
;   $iX - X координата
;   $iY - Y координата
; Возврат: Строка с цветом в формате "0xRRGGBB" или "" при ошибке
; ===============================================================================
Func _Markers_GetPixelColor($hBitmap, $iX, $iY)
	If $hBitmap = 0 Then
		_Logger_Write("_Markers_GetPixelColor: Неверный bitmap", 2)
		Return ""
	EndIf
	
	Local $iColor = _GDIPlus_BitmapGetPixel($hBitmap, $iX, $iY)
	If @error Then
		_Logger_Write("_Markers_GetPixelColor: Ошибка получения цвета пикселя", 2)
		Return ""
	EndIf
	
	Local $sColor = "0x" & Hex($iColor, 6)
	Return $sColor
EndFunc


; #FUNCTION# ====================================================================
; Name ..........: _Markers_CheckAll
; Description ...: Проверяет все маркеры и возвращает результаты в формате JSON
; Syntax ........: _Markers_CheckAll($hBitmap)
; Parameters ....: $hBitmap - GDI+ bitmap для проверки пикселей
; Return values .: JSON строка с результатами или False при ошибке
; ===============================================================================
Func _Markers_CheckAll($hBitmap)
	_Logger_Write("_Markers_CheckAll: Проверка всех маркеров", 1)
	
	If Not $hBitmap Then
		_Logger_Write("_Markers_CheckAll: Некорректный bitmap", 2)
		Return False
	EndIf
	
	; Загружаем маркеры если ещё не загружены
	If $g_aMarkers = "" Then
		If Not _Markers_Load() Then
			_Logger_Write("_Markers_CheckAll: Ошибка загрузки маркеров", 2)
			Return False
		EndIf
	EndIf
	
	; Получаем массив маркеров
	Local $aMarkersList = _JSON_Get($g_aMarkers, "[markers]")
	If @error Then
		_Logger_Write("_Markers_CheckAll: Ошибка получения списка маркеров", 2)
		Return False
	EndIf
	
	Local $iCount = UBound($aMarkersList)
	_Logger_Write("_Markers_CheckAll: Найдено маркеров: " & $iCount, 1)
	
	; Создаём результирующий массив
	Local $aResults[0]
	
	For $i = 0 To $iCount - 1
		Local $sName = _JSON_Get($g_aMarkers, "[markers][" & $i & "][name]")
		Local $iX = Number(_JSON_Get($g_aMarkers, "[markers][" & $i & "][x]"))
		Local $iY = Number(_JSON_Get($g_aMarkers, "[markers][" & $i & "][y]"))
		Local $sExpectedColor = _JSON_Get($g_aMarkers, "[markers][" & $i & "][color]")
		
		; Получаем цвет пикселя
		Local $iPixelColor = _GDIPlus_BitmapGetPixel($hBitmap, $iX, $iY)
		Local $sCurrentColor = "0x" & Hex($iPixelColor, 6)
		
		; Сравниваем цвета
		Local $bMatch = (StringUpper($sExpectedColor) = StringUpper($sCurrentColor))
		Local $iValue = ($bMatch ? 1 : 0)
		
		; Создаём объект результата
		Local $oResult = ObjCreate("Scripting.Dictionary")
		$oResult.Add("name", $sName)
		$oResult.Add("value", $iValue)
		$oResult.Add("x", $iX)
		$oResult.Add("y", $iY)
		$oResult.Add("expected_color", $sExpectedColor)
		$oResult.Add("current_color", $sCurrentColor)
		
		; Добавляем в массив
		ReDim $aResults[$i + 1]
		$aResults[$i] = $oResult
		
		_Logger_Write("_Markers_CheckAll: [" & $sName & "] = " & $iValue & " (ожидается: " & $sExpectedColor & ", текущий: " & $sCurrentColor & ")", 1)
	Next
	
	; Создаём итоговый объект
	Local $oFinal = ObjCreate("Scripting.Dictionary")
	$oFinal.Add("markers", $aResults)
	$oFinal.Add("count", $iCount)
	$oFinal.Add("timestamp", @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)
	
	; Генерируем JSON (второй параметр - отступ, не Boolean!)
	Local $sJSON = _JSON_Generate($oFinal)
	If @error Then
		_Logger_Write("_Markers_CheckAll: Ошибка генерации JSON", 2)
		Return False
	EndIf
	
	_Logger_Write("_Markers_CheckAll: Проверка завершена", 3)
	Return $sJSON
EndFunc
