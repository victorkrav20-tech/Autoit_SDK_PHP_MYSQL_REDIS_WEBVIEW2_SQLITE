; ===============================================================================
; WebView2_Engine.au3 - Главный модуль движка WebView2
; Версия: 1.0.0
; Описание: Высокоуровневый API для работы с WebView2 (LOCAL и EXTERNAL режимы)
; ===============================================================================
; ЗАВИСИМОСТИ: Utils.au3, WebView2_Engine_Core.au3, WebView2_Engine_GUI.au3,
;              WebView2_Engine_Navigation.au3, WebView2_Engine_Events.au3,
;              WebView2_Engine_Injection.au3
; НАЗНАЧЕНИЕ: Универсальный движок для локальных и внешних приложений
;
; СПИСОК ФУНКЦИЙ:
; _WebView2_Engine_Initialize()         - Инициализация движка (default экземпляр)
; _WebView2_Engine_Shutdown()           - Завершение работы движка (все экземпляры)
; _WebView2_Engine_CreateInstance()     - Создание нового экземпляра
; _WebView2_Engine_DestroyInstance()    - Удаление экземпляра
; _WebView2_Engine_QuickStart()         - Быстрый старт (всё в одном)
; _WebView2_Engine_SetMode()            - Установка режима работы
; _WebView2_Engine_GetMode()            - Получение текущего режима
; _WebView2_Engine_IsInitialized()      - Проверка инициализации движка
; _WebView2_Engine_GetStatus()          - Получение детального статуса
; _WebView2_Engine_SetPaths()           - Установка путей (inject, gui, data)
; ===============================================================================

#include-once
#Include <WinAPIEx.au3>
#include "..\Utils\Utils.au3"
#include "WebView2_Engine_Core.au3"
#include "WebView2_Engine_GUI.au3"
#include "WebView2_Engine_Navigation.au3"
#include "WebView2_Engine_Events.au3"
#include "WebView2_Engine_Injection.au3"
#include "WebView2_Engine_Bridge.au3"

; ===============================================================================
; Глобальные переменные движка
; ===============================================================================
Global $g_sWebView2_Engine_Mode = "local"              ; Режим: "local" или "external"
Global $g_bWebView2_Engine_Initialized = False         ; Флаг инициализации
Global $g_sWebView2_Engine_Version = "1.0.0"           ; Версия движка

; ===============================================================================
; Инициализация движка WebView2 (default экземпляр)
; ===============================================================================
Func _WebView2_Engine_Initialize($hInstance = 0, $sMode = "local", $sProfilePath = "")
	If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Инициализация движка (ID: " & $hInstance & ", режим: " & $sMode & ")" & " → ID = " & $hInstance, 1)

	; Проверяем что default экземпляр ещё не создан
	If $g_hWebView2_Default <> 0 Then
	   ; If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Default экземпляр уже создан" & " → ID = " & $hInstance, 2)
	   ; Return False
	EndIf

	; Создаём default экземпляр (БЕЗ COM объекта - он создастся в GUI_Create)
	$g_hWebView2_Default = _WebView2_Core_CreateInstance($hInstance, $sMode, $sProfilePath)

	If $g_hWebView2_Default < 0 Then
		If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Ошибка создания default экземпляра" & " → ID = " & $hInstance, 2)
		Return False
	EndIf

	$g_bWebView2_Engine_Initialized = True
	If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Движок инициализирован успешно (ID: " & $g_hWebView2_Default & ")" & " → ID = " & $hInstance, 3)
	If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] COM объект будет создан при вызове GUI_Create" & " → ID = " & $hInstance, 1)
	Return True
EndFunc

; ===============================================================================
; Создание нового экземпляра (для множественных WebView)
; ===============================================================================
Func _WebView2_Engine_CreateInstance($hInstance = 0, $sMode = "local", $sProfilePath = "")
    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Создание нового экземпляра (ID: " & $hInstance & ", режим: " & $sMode & ")" & " → ID = " & $hInstance, 1)

    ; Создаём экземпляр
    Local $hResult = _WebView2_Core_CreateInstance($hInstance, $sMode, $sProfilePath)

    If $hResult < 0 Then
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Ошибка создания экземпляра" & " → ID = " & $hInstance, 2)
        Return 0
    EndIf

    ; Создаём COM объект
    If Not _WebView2_Core_CreateManager($hResult) Then
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Ошибка создания COM объекта" & " → ID = " & $hInstance, 2)
        _WebView2_Core_DestroyInstance($hResult)
        Return 0
    EndIf

    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Экземпляр создан успешно (ID: " & $hResult & ")" & " → ID = " & $hInstance, 3)
    Return $hResult
EndFunc

; ===============================================================================
; Удаление экземпляра
; ===============================================================================
Func _WebView2_Engine_DestroyInstance($hInstance)
    If $g_bDebug_WebView2_Engine Then _Logger_Write("WebView2_Engine", "Удаление экземпляра ID: " & $hInstance & " → ID = " & $hInstance, 1)
    Return _WebView2_Core_DestroyInstance($hInstance)
EndFunc

; ===============================================================================
; Завершение работы движка
; ===============================================================================
Func _WebView2_Engine_Shutdown()
    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Завершение работы движка" & " → ID = null", 1)

    ; Очищаем все экземпляры
    Local $iCount = UBound($g_aWebView2_Instances)
    For $i = $iCount - 1 To 0 Step -1
        Local $hID = $g_aWebView2_Instances[$i][$WV2_ID]
        _WebView2_Core_DestroyInstance($hID)
    Next

    ; Сбрасываем default
    $g_hWebView2_Default = 0
    $g_bWebView2_Engine_Initialized = False

    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Движок завершён, все экземпляры удалены" & " → ID = null", 3)
    Return True
EndFunc

; ===============================================================================
; Быстрый старт (всё в одном)
; ===============================================================================
Func _WebView2_Engine_QuickStart($sTitle, $iWidth, $iHeight, $sMode = "local", $sProfilePath = "")
    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Быстрый старт: " & $sTitle & " (" & $iWidth & "x" & $iHeight & ")" & " → ID = null", 1)

    ; Инициализируем движок
    If Not _WebView2_Engine_Initialize($sMode, $sProfilePath) Then
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Ошибка инициализации движка" & " → ID = null", 2)
        Return False
    EndIf

    ; Создаём GUI окно (используем GUI модуль, когда он будет реализован)
    ; TODO: Вызов _WebView2_GUI_Create($g_hWebView2_Default, $sTitle, $iWidth, $iHeight)

    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Быстрый старт выполнен (GUI модуль ещё не реализован)" & " → ID = null", 1)
    Return $g_hWebView2_Default
EndFunc


; ===============================================================================
; Установка режима работы
; ===============================================================================
Func _WebView2_Engine_SetMode($sMode)
    If $sMode <> "local" And $sMode <> "external" Then
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Неверный режим: " & $sMode & " → ID = null", 2)
        Return False
    EndIf

    $g_sWebView2_Engine_Mode = $sMode
    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Режим установлен: " & $sMode & " → ID = null", 1)
    Return True
EndFunc


; ===============================================================================
; Получение текущего режима
; ===============================================================================
Func _WebView2_Engine_GetMode()
    Return $g_sWebView2_Engine_Mode
EndFunc
; ===============================================================================
; Проверка готовности движка
; ===============================================================================
Func _WebView2_Engine_IsInitialized()
    Return $g_bWebView2_Engine_Initialized
EndFunc

; ===============================================================================
; Получение детального статуса
; ===============================================================================
Func _WebView2_Engine_GetStatus($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    ; Получаем экземпляр
    Local $aInstance = _WebView2_Core_GetInstance($hInstance)

    ; Формируем статус
    Local $aStatus[10][2]
    $aStatus[0][0] = "Engine Initialized"
    $aStatus[0][1] = $g_bWebView2_Engine_Initialized
    $aStatus[1][0] = "Engine Mode"
    $aStatus[1][1] = $g_sWebView2_Engine_Mode
    $aStatus[2][0] = "Engine Version"
    $aStatus[2][1] = $g_sWebView2_Engine_Version
    $aStatus[3][0] = "Default Instance"
    $aStatus[3][1] = $g_hWebView2_Default
    $aStatus[4][0] = "Total Instances"
    $aStatus[4][1] = UBound($g_aWebView2_Instances)

    If IsArray($aInstance) Then
        $aStatus[5][0] = "Instance ID"
        $aStatus[5][1] = $aInstance[$WV2_ID]
        $aStatus[6][0] = "Instance Mode"
        $aStatus[6][1] = $aInstance[$WV2_MODE]
        $aStatus[7][0] = "Initialized"
        $aStatus[7][1] = $aInstance[$WV2_INITIALIZED]
        $aStatus[8][0] = "Ready"
        $aStatus[8][1] = $aInstance[$WV2_READY]
        $aStatus[9][0] = "Current URL"
        $aStatus[9][1] = $aInstance[$WV2_CURRENT_URL]
    Else
        $aStatus[5][0] = "Instance"
        $aStatus[5][1] = "Not Found"
        $aStatus[6][0] = ""
        $aStatus[6][1] = ""
        $aStatus[7][0] = ""
        $aStatus[7][1] = ""
        $aStatus[8][0] = ""
        $aStatus[8][1] = ""
        $aStatus[9][0] = ""
        $aStatus[9][1] = ""
    EndIf

    Return $aStatus
EndFunc
; ===============================================================================
; Установка путей для экземпляра
; ===============================================================================
Func _WebView2_Engine_SetPaths($sInjectPath = "", $sGuiPath = "", $sDataPath = "", $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    ; Получаем индекс экземпляра
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Экземпляр не найден" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Установка путей" & " → ID = " & $hInstance, 1)

    If $sInjectPath <> "" Then
        $g_aWebView2_Instances[$iIndex][$WV2_INJECT_PATH] = $sInjectPath
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Inject: " & $sInjectPath & " → ID = " & $hInstance, 1)
    EndIf

    If $sGuiPath <> "" Then
        $g_aWebView2_Instances[$iIndex][$WV2_GUI_PATH] = $sGuiPath
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] GUI: " & $sGuiPath & " → ID = " & $hInstance, 1)
    EndIf

    If $sDataPath <> "" Then
        $g_aWebView2_Instances[$iIndex][$WV2_DATA_PATH] = $sDataPath
        If $g_bDebug_WebView2_Engine Then _Logger_Write("[WebView2_Engine] Data: " & $sDataPath & " → ID = " & $hInstance, 1)
    EndIf

    Return True
EndFunc
