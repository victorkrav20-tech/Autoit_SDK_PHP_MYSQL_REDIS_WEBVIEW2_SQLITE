; ===============================================================================
; Файл: 01_Start_Init_Response.au3
; Описание: Обработчики запросов от WebView2 (RequestHub)
; Функции:
;   _01_Start_OnResponse() - Главный обработчик запросов
;   _01_Start_Response_GetAppInfo() - Информация о приложении
; ===============================================================================

#include-once
#include "01_Start_Init.au3"

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ (объявлены в других файлах)
; ===============================================================================
Global $g_bDebug_01_Start
Global $g_i01_Start_Response_LogMode
Global $g_b01_Start_MySQL_Enabled
Global $g_b01_Start_Redis_Enabled
Global $g_s01_Start_AppName

; ===============================================================================
; ТЕСТОВЫЙ РЕЖИМ (для проверки стабильности связи)
; Для продакшена: $g_b01_Start_Response_TestMode = False
; ===============================================================================
Global $g_b01_Start_Response_TestMode = False
Global $g_i01_Start_Response_TestCounter = 0

; ===============================================================================
; Функция: _01_Start_OnResponse
; Описание: Главный обработчик запросов от WebView2 через RequestHub
; Параметры:
;   $vJson     - распарсенный JSON с запросом
;   $hInstance - ID инстанса WebView2
; Возврат: True при успехе
; ===============================================================================
Func _01_Start_OnResponse($vJson, $hInstance = 0)
	Static $iRequestCounter = 0
	$iRequestCounter += 1

	; Тест стабильности (50% потерь при включённом режиме)
	If $g_b01_Start_Response_TestMode Then
		$g_i01_Start_Response_TestCounter += 1
		If Mod($g_i01_Start_Response_TestCounter, 2) = 0 Then
			If $g_i01_Start_Response_LogMode >= 1 Then
				_Logger_Write("⚠️ [Response TEST] Игнорирую запрос #" & $g_i01_Start_Response_TestCounter & " (50% потерь)", 2)
			EndIf
			Return False
		EndIf
	EndIf

	; Валидация входных данных
	If Not IsMap($vJson) Then
		_Logger_Write("⚠️ [Response] Некорректный JSON", 2)
		Return False
	EndIf

	If Not MapExists($vJson, "payload") Then
		_Logger_Write("⚠️ [Response] Нет payload", 2)
		Return False
	EndIf

	Local $oPayload = $vJson["payload"]

	If Not IsMap($oPayload) Then
		_Logger_Write("⚠️ [Response] payload не Map", 2)
		Return False
	EndIf

	If Not MapExists($oPayload, "requestId") Or Not MapExists($oPayload, "requestType") Then
		_Logger_Write("⚠️ [Response] Нет requestId или requestType", 2)
		Return False
	EndIf

	Local $iRequestId = $oPayload["requestId"]
	Local $sType = $oPayload["requestType"]
	Local $oRequestPayload = MapExists($oPayload, "requestPayload") ? $oPayload["requestPayload"] : Null

	; Логирование по режиму
	Local $bShouldLog = False
	Switch $g_i01_Start_Response_LogMode
		Case 1
			$bShouldLog = True
		Case 2
			$bShouldLog = (Mod($iRequestCounter, 10) = 0)
		Case 3
			$bShouldLog = (Mod($iRequestCounter, 100) = 0)
		Case 4
			$bShouldLog = False
	EndSwitch

	If $bShouldLog Then _Logger_Write("📨 [Response] Запрос #" & $iRequestId & " | Тип: " & $sType, 1)

	; Обработка запросов
	Local $oResponse = Null
	Local $bSuccess = True
	Local $sError = ""

	Switch $sType
		Case "get_app_info"
			$oResponse = _01_Start_Response_GetAppInfo()

		Case "show_window"
			If IsMap($oRequestPayload) And MapExists($oRequestPayload, "windowId") Then
				Local $iWindowId = $oRequestPayload["windowId"]
				$bSuccess = _WebView2_GUI_Show($iWindowId)
				$oResponse = $bSuccess ? "OK" : "FAIL"
			Else
				$bSuccess = False
				$sError = "Не указан windowId"
			EndIf

		Case "hide_window"
			If IsMap($oRequestPayload) And MapExists($oRequestPayload, "windowId") Then
				Local $iWindowId = $oRequestPayload["windowId"]
				$bSuccess = _WebView2_GUI_Hide($iWindowId)
				$oResponse = $bSuccess ? "OK" : "FAIL"
			Else
				$bSuccess = False
				$sError = "Не указан windowId"
			EndIf

		Case "test_request"
			$oResponse = "Test OK"

		Case Else
			$bSuccess = False
			$sError = "Неизвестный тип запроса: " & $sType
			_Logger_Write("⚠️ [Response] " & $sError, 2)
	EndSwitch

	; Формируем и отправляем ответ
	Local $mResponse[]
	$mResponse["requestId"] = $iRequestId
	$mResponse["status"] = $bSuccess ? "success" : "error"
	$mResponse["success"] = $bSuccess
	$mResponse["payload"] = $oResponse
	If Not $bSuccess Then $mResponse["error"] = $sError

	Local $sResponseJSON = _JSON_Generate($mResponse)
	_WebView2_Bridge_Send("response", $sResponseJSON, $hInstance)

	If $bShouldLog Then _Logger_Write("📤 [Response] Ответ #" & $iRequestId & " | " & ($bSuccess ? "success" : "error"), 1)

	Return True
EndFunc

; ===============================================================================
; Функция: _01_Start_Response_GetAppInfo
; Описание: Информация о приложении
; Возврат: Map
; ===============================================================================
Func _01_Start_Response_GetAppInfo()
	Local $mInfo[]
	$mInfo["app_name"] = "01 Start"
	$mInfo["app_id"] = "01_start"
	$mInfo["version"] = "1.0.0"
	$mInfo["hostname"] = @ComputerName
	$mInfo["mysql_enabled"] = $g_b01_Start_MySQL_Enabled
	$mInfo["redis_enabled"] = $g_b01_Start_Redis_Enabled
	Return $mInfo
EndFunc
