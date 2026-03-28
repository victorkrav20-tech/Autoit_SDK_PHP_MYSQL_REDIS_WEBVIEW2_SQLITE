; ===============================================================================
; WebView2_Engine_Injection.au3 - Система инъекций CSS/JS и preload
; Версия: 1.0.0
; Описание: Универсальная система инъекций для LOCAL и EXTERNAL режимов
; ===============================================================================
; ЗАВИСИМОСТИ: Utils.au3, JSON.au3, WebView2_Engine_Core.au3, WebView2_Engine_Events.au3
; НАЗНАЧЕНИЕ: Инъекции CSS/JS, preload скрипты, обработка rules.json
; ИСТОЧНИК: Мигрировано из apps/Reference/Webview2/inject/WebView2_Injector.au3
;           и apps/Reference/Webview2/includes/WebView2_Engine_Client.au3 (preload)
;
; СПИСОК ФУНКЦИЙ:
; _WebView2_Injection_Initialize()        - Инициализация системы инъекций
; _WebView2_Injection_LoadRules()         - Загрузка rules.json
; _WebView2_Injection_InjectCSS()         - Прямая инъекция CSS
; _WebView2_Injection_InjectCSSFile()     - Инъекция CSS из файла
; _WebView2_Injection_InjectJS()          - Прямая инъекция JavaScript
; _WebView2_Injection_InjectJSFile()      - Инъекция JavaScript из файла
; _WebView2_Injection_AddPreloadScript()  - Добавление preload скрипта
; _WebView2_Injection_ClearPreloadScripts() - Очистка preload скриптов
; _WebView2_Injection_PreparePreload()    - Подготовка preload для URL
; _WebView2_Injection_ProcessURL()        - Обработка URL и применение правил
; _WebView2_Injection_ApplyRule()         - Применение конкретного правила
; _WebView2_Injection_MatchURL()          - Проверка соответствия URL
; _WebView2_Injection_ConvertCSSToJS()    - Конвертация CSS в JS для preload
; _WebView2_Injection_EscapeForJS()       - Экранирование для JavaScript
; _WebView2_Injection_GetFileContent()    - Чтение содержимого файла
; ===============================================================================

#include-once
#include "..\Utils\Utils.au3"
#include "..\json\JSON.au3"
#include "WebView2_Engine_Core.au3"
#include "WebView2_Engine_Events.au3"

; ===============================================================================
; Глобальные переменные Injection модуля
; ===============================================================================
Global $g_sWebView2_Injection_Path = ""                ; Путь к папке inject
Global $g_aWebView2_Injection_Rules = ""               ; Массив правил из rules.json
Global $g_bWebView2_Injection_Initialized = False      ; Флаг инициализации
Global $g_bWebView2_Injection_Enabled = True           ; Флаг включения инъекций
Global $g_aWebView2_Injection_PreloadScripts[0]       ; Массив preload скриптов

; ===============================================================================
; Инициализация системы инъекций
; ===============================================================================
Func _WebView2_Injection_Initialize($sInjectPath, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Инициализация системы инъекций" & " → ID = " & $hInstance, 1)

    $g_sWebView2_Injection_Path = $sInjectPath
    $g_aWebView2_Instances[$iIndex][$WV2_INJECT_PATH] = $sInjectPath

    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Путь к inject: " & $sInjectPath & " → ID = " & $hInstance, 1)
    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Система инъекций инициализирована" & " → ID = " & $hInstance, 3)
    Return True
EndFunc


; ===============================================================================
; Загрузка правил из rules.json
; ===============================================================================
Func _WebView2_Injection_LoadRules()
    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Загрузка rules.json" & " → ID = null", 1)

    ; TODO: Реализация загрузки правил

    Return False
EndFunc


; ===============================================================================
; Прямая инъекция CSS кода
; ===============================================================================
Func _WebView2_Injection_InjectCSS($sCss, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not $g_bWebView2_Injection_Enabled Then Return False

    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Инъекция CSS из строки" & " → ID = " & $hInstance, 1)
    Return _WebView2_Core_InjectCss($hInstance, $sCss)
EndFunc


; ===============================================================================
; Инъекция CSS из файла
; ===============================================================================
Func _WebView2_Injection_InjectCSSFile($sFileName, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not $g_bWebView2_Injection_Enabled Then Return False

    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Инъекция CSS из файла: " & $sFileName & " → ID = " & $hInstance, 1)

    ; Формируем полный путь
    Local $sFullPath = $g_sWebView2_Injection_Path & "\" & $sFileName

    ; Проверяем существование файла
    If Not FileExists($sFullPath) Then
        If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] CSS файл не найден: " & $sFullPath & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Читаем содержимое
    Local $sCss = FileRead($sFullPath)
    If @error Then
        If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Ошибка чтения CSS файла" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Инжектируем
    Return _WebView2_Core_InjectCss($hInstance, $sCss)
EndFunc


; ===============================================================================
; Прямая инъекция JavaScript кода
; ===============================================================================
Func _WebView2_Injection_InjectJS($sScript, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not $g_bWebView2_Injection_Enabled Then Return False

    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Инъекция JS из строки" & " → ID = " & $hInstance, 1)
    Return _WebView2_Core_ExecuteScript($hInstance, $sScript)
EndFunc


; ===============================================================================
; Инъекция JavaScript из файла
; ===============================================================================
Func _WebView2_Injection_InjectJSFile($sFileName, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not $g_bWebView2_Injection_Enabled Then Return False

    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Инъекция JS из файла: " & $sFileName & " → ID = " & $hInstance, 1)

    ; Формируем полный путь
    Local $sFullPath = $g_sWebView2_Injection_Path & "\" & $sFileName

    ; Проверяем существование файла
    If Not FileExists($sFullPath) Then
        If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] JS файл не найден: " & $sFullPath & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Читаем содержимое
    Local $sScript = FileRead($sFullPath)
    If @error Then
        If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Ошибка чтения JS файла" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Инжектируем
    Return _WebView2_Core_ExecuteScript($hInstance, $sScript)
EndFunc


; ===============================================================================
; Добавление preload скрипта
; ===============================================================================
Func _WebView2_Injection_AddPreloadScript($sScript)
    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Добавление preload скрипта" & " → ID = null", 1)

    ; TODO: Реализация добавления preload скрипта

    Return False
EndFunc


; ===============================================================================
; Очистка всех preload скриптов
; ===============================================================================
Func _WebView2_Injection_ClearPreloadScripts()
    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Очистка preload скриптов" & " → ID = null", 1)

    ReDim $g_aWebView2_Injection_PreloadScripts[0]
    Return True
EndFunc


; ===============================================================================
; Подготовка preload скрипта для URL
; ===============================================================================
Func _WebView2_Injection_PreparePreload($sURL)
    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Подготовка preload для URL: " & $sURL & " → ID = null", 1)

    ; TODO: Реализация подготовки preload

    Return ""
EndFunc


; ===============================================================================
; Обработка URL и применение правил
; ===============================================================================
Func _WebView2_Injection_ProcessURL($sURL)
    If Not $g_bWebView2_Injection_Initialized Then Return False

    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Обработка URL: " & $sURL & " → ID = null", 1)

    ; TODO: Реализация обработки URL

    Return False
EndFunc


; ===============================================================================
; Применение конкретного правила
; ===============================================================================
Func _WebView2_Injection_ApplyRule($oRule)
    ; TODO: Реализация применения правила

    Return False
EndFunc

; ===============================================================================
; Проверка соответствия URL правилу
; ===============================================================================
Func _WebView2_Injection_MatchURL($sURL, $oRule)
    ; TODO: Реализация проверки соответствия

    Return False
EndFunc

; ===============================================================================
; Конвертация CSS в JavaScript для preload
; ===============================================================================
Func _WebView2_Injection_ConvertCSSToJS($sCSSContent)
    ; TODO: Реализация конвертации CSS в JS

    Return ""
EndFunc

; ===============================================================================
; Безопасное экранирование для JavaScript
; ===============================================================================
Func _WebView2_Injection_EscapeForJS($sString)
    Local $sEscaped = $sString
    $sEscaped = StringReplace($sEscaped, "\", "\\")
    $sEscaped = StringReplace($sEscaped, "'", "\'")
    $sEscaped = StringReplace($sEscaped, """", "\""")
    $sEscaped = StringReplace($sEscaped, @CRLF, "\n")
    $sEscaped = StringReplace($sEscaped, @LF, "\n")
    $sEscaped = StringReplace($sEscaped, @CR, "\r")
    $sEscaped = StringReplace($sEscaped, "`", "\`")

    Return "'" & $sEscaped & "'"
EndFunc

; ===============================================================================
; Чтение содержимого файла
; ===============================================================================
Func _WebView2_Injection_GetFileContent($sFilePath)
    If Not FileExists($sFilePath) Then
        If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Файл не найден: " & $sFilePath & " → ID = null", 2)
        Return ""
    EndIf

    Local $sContent = FileRead($sFilePath)
    Return $sContent
EndFunc


; ===============================================================================
; Проверка включена ли система инъекций
; ===============================================================================
Func _WebView2_Injection_IsEnabled()
    Return $g_bWebView2_Injection_Enabled
EndFunc

; ===============================================================================
; Включение/выключение системы инъекций
; ===============================================================================
Func _WebView2_Injection_SetEnabled($bEnable)
    $g_bWebView2_Injection_Enabled = $bEnable
    If $g_bDebug_WebView2_Injection Then _Logger_Write("[WebView2_Injection] Система инъекций: " & ($bEnable ? "включена" : "выключена") & " → ID = null", 1)
    Return True
EndFunc
