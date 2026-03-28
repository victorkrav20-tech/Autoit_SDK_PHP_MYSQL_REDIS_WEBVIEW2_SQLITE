; ===============================================================================
; WebView2_Engine_Navigation.au3 - Универсальная навигация для LOCAL и EXTERNAL
; Версия: 1.0.0
; Описание: Загрузка контента, навигация, ожидание событий
; ===============================================================================
; ЗАВИСИМОСТИ: Utils.au3, WebView2_Engine_Core.au3, WebView2_Engine_Events.au3
; НАЗНАЧЕНИЕ: Универсальная навигация для локальных HTML и внешних URL
; ИСТОЧНИК: Мигрировано из apps/Reference/Webview2/includes/WebView2_Engine.au3
;           и apps/Reference/Webview2/includes/WebView2_Engine_Client.au3
;
; СПИСОК ФУНКЦИЙ:
; _WebView2_Nav_Load()                - Универсальная загрузка (авто-определение типа)
; _WebView2_Nav_LoadLocal()           - Загрузка локального HTML файла
; _WebView2_Nav_LoadExternal()        - Загрузка внешнего URL
; _WebView2_Nav_LoadHTML()            - Загрузка HTML из строки
; _WebView2_Nav_Reload()              - Перезагрузка текущей страницы
; _WebView2_Nav_GoBack()              - Назад в истории
; _WebView2_Nav_GoForward()           - Вперёд в истории
; _WebView2_Nav_Stop()                - Остановка загрузки
; _WebView2_Nav_ConvertToFileURL()    - Конвертация пути в file:// URL
; _WebView2_Nav_IsLoading()           - Проверка загрузки
; _WebView2_Nav_GetCurrentURL()       - Получение текущего URL
; ===============================================================================

#include-once
#include "..\Utils\Utils.au3"
#include "WebView2_Engine_Core.au3"
#include "WebView2_Engine_Events.au3"

; ===============================================================================
; Универсальная загрузка контента (авто-определение типа)
; ===============================================================================
Func _WebView2_Nav_Load($sTarget, $bWait = False, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Экземпляр не найден" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Универсальная загрузка: " & $sTarget & " → ID = " & $hInstance, 1)

    ; Определяем тип загрузки
    Local $bResult = False

    If StringLeft($sTarget, 7) = "http://" Or StringLeft($sTarget, 8) = "https://" Then
        ; Внешний URL
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Определён тип: EXTERNAL URL" & " → ID = " & $hInstance, 1)
        $bResult = _WebView2_Nav_LoadExternal($sTarget, $bWait, $hInstance)
    ElseIf StringLeft($sTarget, 7) = "file://" Then
        ; Прямой file:// URL
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Определён тип: FILE URL" & " → ID = " & $hInstance, 1)
        Local $iIndex = _WebView2_Core_GetInstance($hInstance)
        If $iIndex >= 0 And IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then
            $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].Navigate($sTarget)
            $g_aWebView2_Instances[$iIndex][$WV2_LOADING] = True
            $g_aWebView2_Instances[$iIndex][$WV2_CURRENT_URL] = $sTarget
            $bResult = True
            If $bWait Then
                $bResult = _WebView2_Events_WaitForNavigation($hInstance, 10000)
            EndIf
        EndIf
    Else
        ; Локальный файл
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Определён тип: LOCAL FILE" & " → ID = " & $hInstance, 1)
        $bResult = _WebView2_Nav_LoadLocal($sTarget, $bWait, $hInstance)
    EndIf

    If $bResult Then
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Загрузка страницы успешна" & " → ID = " & $hInstance, 3)
    Else
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Ошибка загрузки страницы" & " → ID = " & $hInstance, 2)
    EndIf

    Return $bResult
EndFunc




; ===============================================================================
; Загрузка локального HTML файла
; ===============================================================================
Func _WebView2_Nav_LoadLocal($sFileName, $bWait = False, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Загрузка локального файла: " & $sFileName & " → ID = " & $hInstance, 1)

    ; Получаем путь к gui папке
    Local $sGuiPath = $g_aWebView2_Instances[$iIndex][$WV2_GUI_PATH]
    If $sGuiPath = "" Then
        $sGuiPath = @ScriptDir & "\gui"
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Используется путь по умолчанию: " & $sGuiPath & " → ID = " & $hInstance, 1)
    EndIf

    ; Формируем полный путь
    Local $sFullPath = $sGuiPath & "\" & $sFileName

    ; Проверяем существование файла
    If Not FileExists($sFullPath) Then
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Файл не найден: " & $sFullPath & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Конвертируем в file:// URL
    Local $sFileURL = _WebView2_Nav_ConvertToFileURL($sFullPath)
    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] File URL: " & $sFileURL & " → ID = " & $hInstance, 1)

    ; Загружаем
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].Navigate($sFileURL)
    $g_aWebView2_Instances[$iIndex][$WV2_LOADING] = True
    $g_aWebView2_Instances[$iIndex][$WV2_CURRENT_URL] = $sFileURL
    Local $bResult = True

    ; Ожидаем завершения если нужно
    If $bWait And $bResult Then
        $bResult = _WebView2_Events_WaitForNavigation($hInstance, 10000)
    EndIf

    Return $bResult
EndFunc




; ===============================================================================
; Загрузка внешнего URL
; ===============================================================================
Func _WebView2_Nav_LoadExternal($sURL, $bWait = False, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Загрузка внешнего URL: " & $sURL & " → ID = " & $hInstance, 1)

    ; Проверяем что URL начинается с http:// или https://
    If StringLeft($sURL, 7) <> "http://" And StringLeft($sURL, 8) <> "https://" Then
        If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Неверный формат URL (должен начинаться с http:// или https://)" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Загружаем
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].Navigate($sURL)
    $g_aWebView2_Instances[$iIndex][$WV2_LOADING] = True
    $g_aWebView2_Instances[$iIndex][$WV2_CURRENT_URL] = $sURL
    Local $bResult = True

    ; Ожидаем завершения если нужно
    If $bWait And $bResult Then
        $bResult = _WebView2_Events_WaitForNavigation($hInstance, 10000)
    EndIf

    Return $bResult
EndFunc


; ===============================================================================
; Загрузка HTML из строки
; ===============================================================================
Func _WebView2_Nav_LoadHTML($sHTML, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Загрузка HTML из строки" & " → ID = " & $hInstance, 1)

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].NavigateToString($sHTML)
    $g_aWebView2_Instances[$iIndex][$WV2_LOADING] = True

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] HTML загружен успешно" & " → ID = " & $hInstance, 3)
    Return True
EndFunc

; ===============================================================================
; Перезагрузка текущей страницы
; ===============================================================================
Func _WebView2_Nav_Reload($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Перезагрузка страницы" & " → ID = " & $hInstance, 1)
    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].Reload()
    Return True
EndFunc


; ===============================================================================
; Назад в истории
; ===============================================================================
Func _WebView2_Nav_GoBack($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Навигация назад" & " → ID = " & $hInstance, 1)
    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].GoBack()
    Return True
EndFunc


; ===============================================================================
; Вперёд в истории
; ===============================================================================
Func _WebView2_Nav_GoForward($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Навигация вперёд" & " → ID = " & $hInstance, 1)
    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].GoForward()
    Return True
EndFunc


; ===============================================================================
; Остановка загрузки
; ===============================================================================
Func _WebView2_Nav_Stop($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    If $g_bDebug_WebView2_Navigation Then _Logger_Write("[WebView2_Nav] Остановка загрузки" & " → ID = " & $hInstance, 1)
    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].Stop()
    $g_aWebView2_Instances[$iIndex][$WV2_LOADING] = False
    Return True
EndFunc
; ===============================================================================
; Конвертация пути в file:// URL
; ===============================================================================
Func _WebView2_Nav_ConvertToFileURL($sFilePath)
    ; Заменяем обратные слеши на прямые
    Local $sURL = StringReplace($sFilePath, "\", "/")

    ; Добавляем file:/// префикс
    $sURL = "file:///" & $sURL

    Return $sURL
EndFunc

; ===============================================================================
; Проверка загрузки
; ===============================================================================
Func _WebView2_Nav_IsLoading($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    Return $g_aWebView2_Instances[$iIndex][$WV2_LOADING]
EndFunc


; ===============================================================================
; Получение текущего URL
; ===============================================================================
Func _WebView2_Nav_GetCurrentURL($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return ""

    Return $g_aWebView2_Instances[$iIndex][$WV2_CURRENT_URL]
EndFunc

