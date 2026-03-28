; ===============================================================================
; WebView2_Engine_Core.au3 - Низкоуровневая работа с COM объектом WebView2
; Версия: 1.0.0
; Описание: Прямая работа с NetWebView2.Manager COM объектом
; ===============================================================================
; ЗАВИСИМОСТИ: Utils.au3
; НАЗНАЧЕНИЕ: Обёртка для всех COM методов WebView2
; ИСТОЧНИК: Мигрировано из apps/Reference/Webview2/includes/WebView2_Include.au3
;           и libs/WebView2/README.md (COM методы)
;
; СПИСОК ФУНКЦИЙ:
; _WebView2_Core_CreateManager()              - Создание COM объекта
; _WebView2_Core_InitializeWebView()          - Инициализация WebView2
; _WebView2_Core_RegisterEvents()             - Регистрация COM событий
; _WebView2_Core_ExecuteScript()              - Выполнение JavaScript
; _WebView2_Core_ExecuteScriptWithResult()    - Выполнение JS с результатом
; _WebView2_Core_InjectCss()                  - Инъекция CSS
; _WebView2_Core_ClearInjectedCss()           - Очистка CSS
; _WebView2_Core_GetSource()                  - Получение текущего URL
; _WebView2_Core_GetDocumentTitle()           - Получение заголовка
; _WebView2_Core_IsReady()                    - Проверка готовности
; _WebView2_Core_Cleanup()                    - Очистка ресурсов
; _WebView2_Core_ErrorHandler()               - Обработчик COM ошибок
; ===============================================================================

#include-once
#include "..\\Utils\\Utils.au3"

Global Const $WV2_ID = 0                               ; Уникальный ID экземпляра
Global Const $WV2_MODE = 1                             ; Режим: "local" или "external"
Global Const $WV2_PROFILE_PATH = 2                     ; Путь к профилю
Global Const $WV2_INJECT_PATH = 3                      ; Путь к inject
Global Const $WV2_GUI_PATH = 4                         ; Путь к gui
Global Const $WV2_DATA_PATH = 5                        ; Путь к data
Global Const $WV2_MANAGER = 6                          ; COM объект Manager
Global Const $WV2_EVENTS = 7                           ; COM объект Events
Global Const $WV2_GUI_HANDLE = 8                       ; Handle GUI окна
Global Const $WV2_INITIALIZED = 9                      ; Флаг инициализации
Global Const $WV2_READY = 10                           ; Флаг готовности (INIT_READY)
Global Const $WV2_LOADING = 11                         ; Флаг загрузки
Global Const $WV2_CURRENT_URL = 12                     ; Текущий URL
Global Const $WV2_CURRENT_TITLE = 13                   ; Текущий заголовок
Global Const $WV2_CALLBACK_MESSAGE = 14                ; Callback OnMessageReceived
Global Const $WV2_CALLBACK_READY = 15                  ; Callback OnWebViewReady
Global Const $WV2_CALLBACK_NAV_COMPLETED = 16          ; Callback OnNavigationCompleted
Global Const $WV2_CALLBACK_WINDOW_CLOSE = 17           ; Callback OnWindowClose
Global Const $WV2_LAST_MESSAGE = 18                    ; Последнее сообщение
Global Const $WV2_LAST_EVENT_TYPE = 19                 ; Тип последнего события
Global Const $WV2_LAST_EVENT_DATA = 20                 ; Данные последнего события
Global Const $WV2_BRIDGE = 21                          ; COM объект Bridge
Global Const $WV2_BRIDGE_EVENTS = 22                   ; COM объект Bridge Events
Global Const $WV2_STRUCT_SIZE = 23                     ; Размер структуры

; ===============================================================================
; Глобальные переменные Core модуля
; ===============================================================================
Global $g_aWebView2_Instances[0][$WV2_STRUCT_SIZE]     ; Двумерный массив экземпляров
Global $g_hWebView2_Default = 0                        ; Handle default экземпляра
Global $g_oCOMError_WebView2 = 0                       ; Глобальный COM Error Handler

; ===============================================================================
; Дебаг переменные для управления логами (True = включено, False = выключено)
; ===============================================================================
Global $g_bDebug_WebView2_Core = False                  ; Логи Core модуля
Global $g_bDebug_WebView2_Events = True                ; Логи Events модуля
Global $g_bDebug_WebView2_GUI = False                   ; Логи GUI модуля
Global $g_bDebug_WebView2_Injection = False             ; Логи Injection модуля
Global $g_bDebug_WebView2_Navigation = False            ; Логи Navigation модуля
Global $g_bDebug_WebView2_Engine = False                ; Логи Engine модуля
Global $g_bDebug_WebView2_Bridge = False                ; Логи Bridge модуля
Global $g_bDebug_WebView2_WebView2_DLL = False			; Логи WebView2_DLL модуля
Global $g_bDebug_WebView2_DevTools = True                ; Логи DevTools модуля
Global $g_aWebView2_Bridge_Mapping = ''                 ; Маппинг Bridge COM объектов на ID экземпляров

Func _WebView2_Core_CreateInstance($hInstance = 0, $sMode = "local", $sProfilePath = "")
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Создание экземпляра WebView2 (ID: " & $hInstance & ", режим: " & $sMode & ")" & " → ID = " & $hInstance, 1)

    ; Проверка режима
    If $sMode <> "local" And $sMode <> "external" Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Неверный режим: " & $sMode & " → ID = " & $hInstance, 2)
        Return -1
    EndIf

    ; Проверка что ID не занят (только если массив не пустой)
    If UBound($g_aWebView2_Instances, 1) > 0 Then
        For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
            If $g_aWebView2_Instances[$i][$WV2_ID] = $hInstance Then
                If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] ID " & $hInstance & " уже занят!" & " → ID = " & $hInstance, 2)
                Return -1
            EndIf
        Next
    EndIf

    ; Добавляем новую строку в двумерный массив
    Local $iSize = UBound($g_aWebView2_Instances, 1)
    ReDim $g_aWebView2_Instances[$iSize + 1][$WV2_STRUCT_SIZE]

    ; Заполняем структуру экземпляра
    $g_aWebView2_Instances[$iSize][$WV2_ID] = $hInstance
    $g_aWebView2_Instances[$iSize][$WV2_MODE] = $sMode
    $g_aWebView2_Instances[$iSize][$WV2_PROFILE_PATH] = $sProfilePath
    $g_aWebView2_Instances[$iSize][$WV2_INJECT_PATH] = ""
    $g_aWebView2_Instances[$iSize][$WV2_GUI_PATH] = ""
    $g_aWebView2_Instances[$iSize][$WV2_DATA_PATH] = ""
    $g_aWebView2_Instances[$iSize][$WV2_MANAGER] = 0
    $g_aWebView2_Instances[$iSize][$WV2_EVENTS] = 0
    $g_aWebView2_Instances[$iSize][$WV2_GUI_HANDLE] = 0
    $g_aWebView2_Instances[$iSize][$WV2_INITIALIZED] = False
    $g_aWebView2_Instances[$iSize][$WV2_READY] = False
    $g_aWebView2_Instances[$iSize][$WV2_LOADING] = False
    $g_aWebView2_Instances[$iSize][$WV2_CURRENT_URL] = ""
    $g_aWebView2_Instances[$iSize][$WV2_CURRENT_TITLE] = ""
    $g_aWebView2_Instances[$iSize][$WV2_CALLBACK_MESSAGE] = ""
    $g_aWebView2_Instances[$iSize][$WV2_CALLBACK_READY] = ""
    $g_aWebView2_Instances[$iSize][$WV2_CALLBACK_NAV_COMPLETED] = ""
    $g_aWebView2_Instances[$iSize][$WV2_CALLBACK_WINDOW_CLOSE] = ""
    $g_aWebView2_Instances[$iSize][$WV2_LAST_MESSAGE] = ""
    $g_aWebView2_Instances[$iSize][$WV2_LAST_EVENT_TYPE] = ""
    $g_aWebView2_Instances[$iSize][$WV2_LAST_EVENT_DATA] = ""
    $g_aWebView2_Instances[$iSize][$WV2_BRIDGE] = 0
    $g_aWebView2_Instances[$iSize][$WV2_BRIDGE_EVENTS] = 0

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр создан" & " → ID = " & $hInstance, 1)
    Return $hInstance
EndFunc


; ===============================================================================
; Получение индекса экземпляра по handle (внутренняя функция)
; ===============================================================================
Func _WebView2_Core_GetInstance($hInstance)
    ; Проверяем размер массива
    If UBound($g_aWebView2_Instances, 1) = 0 Then Return -1

    ; Если handle = 0 и default не установлен, ищем ID=0 в массиве
    If $hInstance = 0 And $g_hWebView2_Default = 0 Then
        For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
            If $g_aWebView2_Instances[$i][$WV2_ID] = 0 Then
                Return $i
            EndIf
        Next
        Return -1
    EndIf

    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    ; Если default тоже 0, возвращаем -1
    If $hInstance = 0 Then Return -1

    ; Ищем экземпляр в массиве, возвращаем индекс строки
    For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
        If $g_aWebView2_Instances[$i][$WV2_ID] = $hInstance Then
            Return $i
        EndIf
    Next

    Return -1
EndFunc

; ===============================================================================
; Создание COM объекта Manager для экземпляра
; ===============================================================================
Func _WebView2_Core_CreateManager($hInstance = 0)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр не найден" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Создание COM объекта Manager для " & " → ID = " & $hInstance, 1)

    ; Регистрируем глобальный COM Error Handler (один на все экземпляры)
    If Not IsObj($g_oCOMError_WebView2) Then
        $g_oCOMError_WebView2 = ObjEvent("AutoIt.Error", "_WebView2_Core_ErrorHandler")
        If Not IsObj($g_oCOMError_WebView2) Then
            If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ошибка регистрации COM Error Handler" & " → ID = " & $hInstance, 2)
            Return False
        EndIf
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] COM Error Handler зарегистрирован" & " → ID = " & $hInstance, 1)
    EndIf

    ; Создаём COM объект
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Попытка создания COM объекта NetWebView2Lib.Manager..." & " → ID = " & $hInstance, 1)

    ; Проверка регистрации в реестре
    Local $sRegKey = "HKEY_CLASSES_ROOT\NetWebView2Lib.Manager\CLSID"
    Local $sCLSID = RegRead($sRegKey, "")
    If $sCLSID <> "" Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] COM класс найден в реестре: " & $sCLSID & " → ID = " & $hInstance, 1)

        ; Проверяем зависимости DLL (абсолютный путь от корня проекта)
        ; Определяем корень проекта (поднимаемся от apps/NewApp1 к корню)
        Local $sProjectRoot = StringRegExpReplace(@ScriptDir, "\\apps\\[^\\]+$", "")
        Local $sDllDir = $sProjectRoot & "\libs\WebView2\bin"

        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Корень проекта: " & $sProjectRoot & " → ID = " & $hInstance, 1)
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Проверка зависимостей в: " & $sDllDir & " → ID = " & $hInstance, 1)

        Local $aRequiredDlls[4] = ["NetWebView2Lib.dll", "Microsoft.Web.WebView2.Core.dll", "Microsoft.Web.WebView2.WinForms.dll", "Newtonsoft.Json.dll"]
        For $sDll In $aRequiredDlls
            If FileExists($sDllDir & "\" & $sDll) Then
                If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Зависимость найдена: " & $sDll & " → ID = " & $hInstance, 1)
            Else
                If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] ОШИБКА: Зависимость НЕ найдена: " & $sDll & " → ID = " & $hInstance, 2)
            EndIf
        Next
    Else
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] ВНИМАНИЕ: COM класс НЕ найден в реестре HKCR\NetWebView2Lib.Manager\CLSID" & " → ID = " & $hInstance, 2)
    EndIf

    Local $oManager = ObjCreate("NetWebView2Lib.Manager")
    If Not IsObj($oManager) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ошибка создания COM объекта NetWebView2Lib.Manager" & " → ID = " & $hInstance, 2)
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] @error = " & @error & ", @extended = " & @extended & " → ID = " & $hInstance, 2)

        ; Проверяем .NET Framework
        Local $sDotNetVersion = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full", "Version")
        If $sDotNetVersion <> "" Then
            If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] .NET Framework версия: " & $sDotNetVersion & " → ID = " & $hInstance, 1)
        Else
            If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] КРИТИЧНО: .NET Framework 4.x НЕ найден!" & " → ID = " & $hInstance, 2)
        EndIf

        Return False
    EndIf

    ; Сохраняем в экземпляр
    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER] = $oManager

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] COM объект Manager создан успешно" & " → ID = " & $hInstance, 3)
    Return True
EndFunc


; ===============================================================================
; Инициализация WebView2 контрола
; ===============================================================================
Func _WebView2_Core_InitializeWebView($hInstance, $hGUI, $iX, $iY, $iWidth, $iHeight)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр не найден" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Инициализация WebView2 контрола для " & " → ID = " & $hInstance, 1)
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] GUI Handle: " & $hGUI & ", Размер: " & $iWidth & "x" & $iHeight & " → ID = " & $hInstance, 1)

    ; Проверяем что Manager создан
    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] COM объект Manager не создан" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Сохраняем handle GUI
    $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE] = $hGUI

    ; Получаем путь к профилю
    Local $sProfilePath = $g_aWebView2_Instances[$iIndex][$WV2_PROFILE_PATH]
    If $sProfilePath = "" Then
        $sProfilePath = @ScriptDir & "\WebView2_Profile_" & $g_aWebView2_Instances[$iIndex][$WV2_ID]
        $g_aWebView2_Instances[$iIndex][$WV2_PROFILE_PATH] = $sProfilePath
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Используется автоматический путь профиля: " & $sProfilePath  & " → ID = " & $hInstance, 1)
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Путь профиля: " & $sProfilePath  & " → ID = " & $hInstance, 1)

    ; Вызываем Initialize у COM объекта
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Вызов Manager.Initialize()..."  & " → ID = " & $hInstance, 1)
    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].Initialize($hGUI, $sProfilePath, $iX, $iY, $iWidth, $iHeight)

    If @error Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ошибка вызова Initialize: " & @error  & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    $g_aWebView2_Instances[$iIndex][$WV2_INITIALIZED] = True

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Manager.Initialize() выполнен успешно"  & " → ID = " & $hInstance, 3)
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] WebView2 инициализирован, ожидание INIT_READY события..."  & " → ID = " & $hInstance, 1)
    Return True
EndFunc



; ===============================================================================
; Регистрация COM событий
; ===============================================================================
Func _WebView2_Core_RegisterEvents($hInstance, $sEventPrefix = "WebView_")
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр не найден"  & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Регистрация COM событий для ID: " & " → ID = " & $hInstance, 1)
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Префикс событий: " & $sEventPrefix & " → ID = " & $hInstance, 1)

    ; Проверяем что Manager создан
    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] COM объект Manager не создан" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Manager объект: " & " → ID = " & $hInstance, 1)

    ; Регистрируем события
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Вызов ObjEvent с префиксом: " & $sEventPrefix & "OnMessageReceived"  & " → ID = " & $hInstance, 1)
    Local $oEvents = ObjEvent($g_aWebView2_Instances[$iIndex][$WV2_MANAGER], $sEventPrefix, "IWebViewEvents")
    If Not IsObj($oEvents) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ошибка регистрации событий"  & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Сохраняем в экземпляр
    $g_aWebView2_Instances[$iIndex][$WV2_EVENTS] = $oEvents

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] COM события зарегистрированы успешно"  & " → ID = " & $hInstance, 3)
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ожидаем вызов функции: " & $sEventPrefix & "OnMessageReceived"  & " → ID = " & $hInstance, 1)
    Return True
EndFunc
; ===============================================================================
; Выполнение JavaScript
; ===============================================================================
Func _WebView2_Core_ExecuteScript($hInstance, $sScript)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].ExecuteScript($sScript)
    Return True
EndFunc


; ===============================================================================
; Выполнение JavaScript с результатом
; ===============================================================================
Func _WebView2_Core_ExecuteScriptWithResult($hInstance, $sScript)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].ExecuteScriptWithResult($sScript)
    Return True
EndFunc


; ===============================================================================
; Инъекция CSS
; ===============================================================================
Func _WebView2_Core_InjectCss($hInstance, $sCss)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].InjectCss($sCss)
    Return True
EndFunc


; ===============================================================================
; Очистка инжектированных CSS
; ===============================================================================
Func _WebView2_Core_ClearInjectedCss($hInstance)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].ClearInjectedCss()
    Return True
EndFunc


; ===============================================================================
; Получение текущего URL
; ===============================================================================
Func _WebView2_Core_GetSource($hInstance)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return ""

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return ""

    Return $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].GetSource()
EndFunc


; ===============================================================================
; Получение заголовка страницы
; ===============================================================================
Func _WebView2_Core_GetDocumentTitle($hInstance)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return ""

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return ""

    Return $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].GetDocumentTitle()
EndFunc


; ===============================================================================
; Проверка готовности WebView2
; ===============================================================================
Func _WebView2_Core_IsReady($hInstance)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    Return $g_aWebView2_Instances[$iIndex][$WV2_READY]
EndFunc
; ===============================================================================
; Получение Bridge COM объекта
; ===============================================================================
Func _WebView2_Core_GetBridge($hInstance = 0)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр не найден" & " → ID = " & $hInstance, 2)
        Return 0
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Bridge объект уже существует" & " → ID = " & $hInstance, 1)
        Return $g_aWebView2_Instances[$iIndex][$WV2_BRIDGE]
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Получение Bridge COM объекта для"  & " → ID = " & $hInstance, 1)

    ; Получаем Bridge через Manager.GetBridge()
    Local $oBridge = $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].GetBridge()

    If Not IsObj($oBridge) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ошибка получения Bridge объекта" & " → ID = " & $hInstance, 2)
        Return 0
    EndIf

    ; Сохраняем в экземпляр
    $g_aWebView2_Instances[$iIndex][$WV2_BRIDGE] = $oBridge

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Bridge объект получен успешно" & " → ID = " & $hInstance, 3)
    Return $oBridge
EndFunc

; ===============================================================================
; Регистрация Bridge COM событий
; ===============================================================================
Func _WebView2_Core_RegisterBridgeEvents($hInstance, $sEventPrefix = "Bridge_")
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр не найден" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Регистрация Bridge событий для " & " → ID = " & $hInstance, 1)
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Префикс событий: " & $sEventPrefix & " → ID = " & $hInstance, 1)

    ; Получаем Bridge объект (если ещё не получен)
    Local $oBridge = _WebView2_Core_GetBridge($hInstance)
    If Not IsObj($oBridge) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Не удалось получить Bridge объект" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Bridge объект: " & ObjName($oBridge)  & " → ID = " & $hInstance, 1)

    ; НОВОЕ: Сохраняем маппинг Bridge → Instance для определения ID в Bridge_OnMessageReceived
    _WebView2_Bridge_SaveMapping($oBridge, $hInstance)

    ; Регистрируем события Bridge
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Вызов ObjEvent с префиксом: " & $sEventPrefix & "OnMessageReceived" & " → ID = " & $hInstance, 1)
    Local $oEvents = ObjEvent($oBridge, $sEventPrefix, "IBridgeEvents")
    If Not IsObj($oEvents) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ошибка регистрации Bridge событий" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Сохраняем в экземпляр
    $g_aWebView2_Instances[$iIndex][$WV2_BRIDGE_EVENTS] = $oEvents

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Bridge события зарегистрированы успешно" & " → ID = " & $hInstance, 3)
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ожидаем вызов функции: " & $sEventPrefix & "OnMessageReceived" & " → ID = " & $hInstance, 1)
    Return True
EndFunc

; ===============================================================================
; Очистка ресурсов экземпляра
; ===============================================================================

Func _WebView2_Core_Cleanup($hInstance)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Очистка ресурсов для " & " → ID = " & $hInstance, 1)

    ; Вызываем метод DLL Cleanup() для освобождения WebView2 ресурсов
    If IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then
        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Вызов Cleanup() для освобождения WebView2" & " → ID = " & $hInstance, 1)
        $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].Cleanup()
    EndIf

    ; Освобождаем COM объекты
    $g_aWebView2_Instances[$iIndex][$WV2_BRIDGE] = 0
    $g_aWebView2_Instances[$iIndex][$WV2_BRIDGE_EVENTS] = 0
    $g_aWebView2_Instances[$iIndex][$WV2_EVENTS] = 0
    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER] = 0

    ; Сбрасываем флаги
    $g_aWebView2_Instances[$iIndex][$WV2_INITIALIZED] = False
    $g_aWebView2_Instances[$iIndex][$WV2_READY] = False
    $g_aWebView2_Instances[$iIndex][$WV2_LOADING] = False

    ; Обнуляем handle окна
    $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE] = 0

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Ресурсы очищены успешно" & " → ID = " & $hInstance, 3)
    Return True
EndFunc


; ===============================================================================
; Удаление экземпляра из массива
; ===============================================================================
Func _WebView2_Core_DestroyInstance($hInstance)
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Удаление экземпляра " & " → ID = " & $hInstance, 1)

    ; Сначала очищаем ресурсы
    _WebView2_Core_Cleanup($hInstance)

    ; Удаляем из массива
    Local $iIndex = -1
    For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
        If $g_aWebView2_Instances[$i][$WV2_ID] = $hInstance Then
            $iIndex = $i
            ExitLoop
        EndIf
    Next

    If $iIndex >= 0 Then
        ; Удаляем элемент из массива
        Local $iSize = UBound($g_aWebView2_Instances, 1)
        For $i = $iIndex To $iSize - 2
            For $j = 0 To $WV2_STRUCT_SIZE - 1
                $g_aWebView2_Instances[$i][$j] = $g_aWebView2_Instances[$i + 1][$j]
            Next
        Next
        ReDim $g_aWebView2_Instances[$iSize - 1][$WV2_STRUCT_SIZE]

        ; Если это был default экземпляр, сбрасываем
        If $hInstance = $g_hWebView2_Default Then
            $g_hWebView2_Default = 0
        EndIf

        If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр удалён успешно" & " → ID = " & $hInstance, 3)
        Return True
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] Экземпляр не найден" & " → ID = " & $hInstance, 2)
    Return False
EndFunc


; ===============================================================================
; Установка User-Agent для WebView2
; ===============================================================================
Func _WebView2_Core_SetUserAgent($hInstance, $sUserAgent)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    If Not IsObj($g_aWebView2_Instances[$iIndex][$WV2_MANAGER]) Then Return False

    $g_aWebView2_Instances[$iIndex][$WV2_MANAGER].SetUserAgent($sUserAgent)

    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] User-Agent установлен: " & $sUserAgent & " → ID = " & $hInstance, 1)
    Return True
EndFunc

; ===============================================================================
; Обработчик COM ошибок
; ===============================================================================
Func _WebView2_Core_ErrorHandler()
    ; НЕ используем SetError() - это прервёт выполнение
    ; Просто логируем и возвращаемся

    ; Игнорируем ошибки с кодом 0 (не критичные)
    If @error = 0 Then Return

    Local $sError = "COM Error: " & @error
    If IsObj($g_oCOMError_WebView2) Then
        $sError &= " | Line: " & $g_oCOMError_WebView2.scriptline
    EndIf
    If $g_bDebug_WebView2_Core Then _Logger_Write("[WebView2_Core] " & $sError  & " → ID = null" , 2)
    Return
EndFunc



; ===============================================================================
; Функция: _WebView2_Bridge_SaveMapping
; ===============================================================================
; ===============================================================================
; Функция: _WebView2_Bridge_SaveMapping
; Описание: Сохраняет маппинг между COM объектом Bridge и ID экземпляра
; Параметры:
;   $oBridge - COM объект Bridge
;   $hInstance - ID экземпляра
; Возврат: True при успехе, False при ошибке
; ===============================================================================
Func _WebView2_Bridge_SaveMapping($oBridge, $hInstance)
    If Not IsObj($oBridge) Then Return False

    ; Получаем уникальный указатель на COM объект
    Local $sPointer = String(Ptr($oBridge))

    If $g_aWebView2_Bridge_Mapping = '' Then
        ; Создаём новый массив
        Local $aMap[1][2]
        $aMap[0][0] = $sPointer
        $aMap[0][1] = $hInstance
        $g_aWebView2_Bridge_Mapping = $aMap
    Else
        ; Проверяем, может уже есть (обновляем)
        For $i = 0 To UBound($g_aWebView2_Bridge_Mapping, 1) - 1
            If $g_aWebView2_Bridge_Mapping[$i][0] = $sPointer Then
                $g_aWebView2_Bridge_Mapping[$i][1] = $hInstance
                If $g_bDebug_WebView2_Core Then _Logger_Write("[Bridge Mapping] Обновлён маппинг: Pointer=" & $sPointer & " → ID = " & $hInstance, 1)
                Return True
            EndIf
        Next

        ; Добавляем новый (используем ReDim, так как это системный массив)
        Local $iSize = UBound($g_aWebView2_Bridge_Mapping, 1)
        ReDim $g_aWebView2_Bridge_Mapping[$iSize + 1][2]
        $g_aWebView2_Bridge_Mapping[$iSize][0] = $sPointer
        $g_aWebView2_Bridge_Mapping[$iSize][1] = $hInstance
    EndIf

    If $g_bDebug_WebView2_Core Then _Logger_Write("[Bridge Mapping] Сохранён маппинг: Pointer=" & $sPointer & " → ID = " & $hInstance, 1)
    Return True
EndFunc

; ===============================================================================
; Функция: _WebView2_Bridge_GetInstanceFromObject
; Описание: Получает ID экземпляра по COM объекту Bridge
; Параметры:
;   $oBridge - COM объект Bridge
; Возврат: ID экземпляра или 0 если не найден
; ===============================================================================
Func _WebView2_Bridge_GetInstanceFromObject($oBridge)
    If Not IsObj($oBridge) Then Return 0
    If $g_aWebView2_Bridge_Mapping = '' Then Return 0

    Local $sPointer = String(Ptr($oBridge))

    For $i = 0 To UBound($g_aWebView2_Bridge_Mapping, 1) - 1
        If $g_aWebView2_Bridge_Mapping[$i][0] = $sPointer Then
            If $g_bDebug_WebView2_Core Then _Logger_Write("[Bridge Mapping] Найден маппинг: Pointer=" & $sPointer & " → ID=" & $g_aWebView2_Bridge_Mapping[$i][1] & " → ID = null", 1)
            Return $g_aWebView2_Bridge_Mapping[$i][1]
        EndIf
    Next

    If $g_bDebug_WebView2_Core Then _Logger_Write("[Bridge Mapping] Маппинг не найден для Pointer=" & $sPointer & " → ID = null", 2)
    Return 0
EndFunc

