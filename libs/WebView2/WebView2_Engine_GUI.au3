; ===============================================================================
; WebView2_Engine_GUI.au3 - Управление GUI окнами и WM обработчиками
; Версия: 1.0.0
; Описание: Создание и управление GUI окном с WebView2
; ===============================================================================
; ЗАВИСИМОСТИ: Utils.au3, WebView2_Engine_Core.au3
; НАЗНАЧЕНИЕ: Создание GUI окон, обработка WM событий, управление размером/позицией
; ИСТОЧНИК: Мигрировано из apps/Reference/Webview2/includes/WebView2_Engine.au3
;           и apps/Reference/Webview2/WindowConfig.au3
;
; СПИСОК ФУНКЦИЙ:
; _WebView2_GUI_Create()              - Создание GUI окна с WebView2
; _WebView2_GUI_Show()                - Показ окна
; _WebView2_GUI_Hide()                - Скрытие окна
; _WebView2_GUI_SetPosition()         - Установка позиции окна
; _WebView2_GUI_SetSize()             - Установка размера окна
; _WebView2_GUI_GetHandle()           - Получение handle окна
; _WebView2_GUI_GetInstanceByHandle() - Получение Instance ID по handle окна
; _WebView2_GUI_RegisterWMHandlers()  - Регистрация WM обработчиков
; _WebView2_GUI_WM_SIZE()             - Обработчик изменения размера
; _WebView2_GUI_WM_MOVE()             - Обработчик перемещения
; _WebView2_GUI_WM_ENTERSIZEMOVE()    - Обработчик начала изменения
; _WebView2_GUI_WM_EXITSIZEMOVE()     - Обработчик завершения изменения
; _WebView2_GUI_WM_SYSCOMMAND()       - Обработчик системных команд (минимизация/восстановление/развёртывание)
; _WebView2_GUI_SetVisible()          - Управление видимостью WebView2 (оптимизация производительности)
; _WebView2_GUI_OnClose()             - Обработчик закрытия окна (ручной)
; _WebView2_GUI_OnClose_Auto()        - Обработчик закрытия окна (автоматический)
; ===============================================================================

#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\Utils\Utils.au3"
#include "WebView2_Engine_Core.au3"

; ===============================================================================
; Глобальные переменные GUI модуля
; ===============================================================================
Global $g_bWebView2_GUI_WindowMoving = False       ; Флаг перемещения окна
Global $g_bWebView2_GUI_WindowResizing = False     ; Флаг изменения размера

; ===============================================================================
; Window Modes - Предустановленные режимы окон
; ===============================================================================
Global Const $WV2_MODE_NORMAL = 0           ; Обычное окно с рамкой и кнопками управления
Global Const $WV2_MODE_BORDERLESS = 1       ; Окно без рамки (popup стиль)
Global Const $WV2_MODE_TOOL = 2             ; Окно-инструмент (topmost, no taskbar)
Global Const $WV2_MODE_KIOSK = 3            ; Киоск режим (fullscreen popup, topmost)
Global Const $WV2_MODE_FRAMED_NOCONTROL = 4 ; Окно с рамкой, но без кнопок управления
Global Const $WV2_MODE_FRAMED_RESIZABLE = 5 ; Окно с рамкой, без кнопок, но с возможностью изменения размера

; ===============================================================================
; Создание GUI окна с WebView2
; ===============================================================================
Func _WebView2_GUI_Create($hInstance, $sTitle, $iWidth, $iHeight, $iX = -1, $iY = -1, $iMode = $WV2_MODE_NORMAL)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    ; Получаем индекс экземпляра
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Экземпляр не найден" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Создание GUI окна: " & $sTitle & " (" & $iWidth & "x" & $iHeight & ")" & " → ID = " & $hInstance, 1)

    ; Формируем ключ конфига для этого окна
    Local $sConfigKey = "windows.window_" & $hInstance

    ; Проверяем настройки из конфига
    Local $bRememberPosition = _Utils_Config_Get($sConfigKey & ".remember_position", True)
    Local $bRememberSize = _Utils_Config_Get($sConfigKey & ".remember_size", True)

    ; Читаем позицию из конфига если включено
    If $bRememberPosition Then
        Local $iConfigX = _Utils_Config_Get($sConfigKey & ".position.x", $iX)
        Local $iConfigY = _Utils_Config_Get($sConfigKey & ".position.y", $iY)
        If $iConfigX <> "" Then $iX = $iConfigX
        If $iConfigY <> "" Then $iY = $iConfigY
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] 📖 Позиция из конфига: X=" & $iX & ", Y=" & $iY & " → ID = " & $hInstance, 1)
    EndIf



    ; Читаем размер из конфига если включено
    If $bRememberSize Then
        Local $iConfigWidth = _Utils_Config_Get($sConfigKey & ".size.width", $iWidth)
        Local $iConfigHeight = _Utils_Config_Get($sConfigKey & ".size.height", $iHeight)
        If $iConfigWidth <> "" Then $iWidth = $iConfigWidth - 16
        If $iConfigHeight <> "" Then $iHeight = $iConfigHeight - 39
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] 📖 Размер из конфига: " & $iWidth & "x" & $iHeight & " → ID = " & $hInstance, 1)
    EndIf



    ; Включаем режим событий
    Opt("GUIOnEventMode", 1)

    ; Определяем стиль окна по режиму
    Local $iWindowStyle, $iWindowExStyle, $bNeedClassModify = False

    Switch $iMode
        Case $WV2_MODE_NORMAL
            ; Обычное окно с рамкой и кнопками управления
            $iWindowStyle = BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
            $iWindowExStyle = 0

        Case $WV2_MODE_BORDERLESS
            ; Окно без рамки (popup стиль)
            $iWindowStyle = BitOR($WS_POPUP, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
            $iWindowExStyle = 0

        Case $WV2_MODE_TOOL
            ; Окно-инструмент (topmost, no taskbar)
            $iWindowStyle = BitOR($WS_POPUP, $WS_BORDER, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
            $iWindowExStyle = BitOR($WS_EX_TOOLWINDOW, $WS_EX_TOPMOST)

        Case $WV2_MODE_KIOSK
            ; Киоск режим (fullscreen popup, topmost)
            $iWindowStyle = BitOR($WS_POPUP, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
            $iWindowExStyle = $WS_EX_TOPMOST

        Case $WV2_MODE_FRAMED_NOCONTROL
            ; Окно с рамкой, но без кнопок управления
            $iWindowStyle = BitAND($GUI_SS_DEFAULT_GUI, $WS_CAPTION, $WS_MAXIMIZEBOX, $WS_GROUP, $WS_POPUP, $WS_SYSMENU, $WS_EX_TOPMOST, BitNOT($WS_CAPTION))
            $iWindowStyle = BitOR($iWindowStyle, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
            $iWindowExStyle = 0
            $bNeedClassModify = True

        Case $WV2_MODE_FRAMED_RESIZABLE
            ; Окно с рамкой, без кнопок управления, но с возможностью изменения размера
            $iWindowStyle = BitAND($GUI_SS_DEFAULT_GUI, $WS_CAPTION, $WS_MAXIMIZEBOX, $WS_GROUP, $WS_POPUP, $WS_SYSMENU, $WS_EX_TOPMOST, BitNOT($WS_CAPTION))
            $iWindowStyle = BitOR($iWindowStyle, $WS_THICKFRAME, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
            $iWindowExStyle = 0
            $bNeedClassModify = True

        Case Else
            ; По умолчанию - обычное окно
            $iWindowStyle = BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN)
            $iWindowExStyle = 0
    EndSwitch

    ; Создаём GUI окно
    Local $hGUI = GUICreate($sTitle, $iWidth, $iHeight, $iX, $iY, $iWindowStyle, $iWindowExStyle)

    ; Для режима FRAMED_NOCONTROL убираем иконку и системное меню
    If $bNeedClassModify And $hGUI <> 0 Then
        _WinAPI_SetClassLongEx($hGUI, -26, BitAND(_WinAPI_GetClassLongEx($hGUI, -26), BitNOT(1), BitNOT(2)))
    EndIf

	;Local $aClientSize_1 = WinGetClientSize($hGUI)
	;Local $aClientSize_2 = WinGetPos($hGUI)
	;If @error Then Return $GUI_RUNDEFMSG
#cs
	Local $iWidth_1 = $aClientSize_1[0]
	Local $iHeight_1 = $aClientSize_1[1]
	Local $iWidth_2 = $aClientSize_2[2]
	Local $iHeight_2 = $aClientSize_2[3]
	Local $iRaznica_1 = $iWidth_2 - $iWidth_1
	Local $iRaznica_2 = $iHeight_2 - $iHeight_1
MsgBox(64,'Разница ширины',$iRaznica_1)
MsgBox(64,'Разница высоты',$iRaznica_2)
#ce

    If $hGUI = 0 Then
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Ошибка создания GUI окна" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Сохраняем handle в экземпляр
    $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE] = $hGUI

    ; Создаём COM Manager
    If Not _WebView2_Core_CreateManager($hInstance) Then
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Ошибка создания COM Manager" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; Регистрируем COM события
    If Not _WebView2_Core_RegisterEvents($hInstance, "WebView_") Then
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Ошибка регистрации COM событий" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    ; ОТКЛЮЧЕНО: Регистрация Bridge событий перенесена в _WebView2_Core_RegisterBridgeEvents
    ; Двойная регистрация вызывала дублирование событий
    ; Local $oBridge = _WebView2_Core_GetBridge($hInstance)
    ; If IsObj($oBridge) Then ObjEvent($oBridge, "Bridge_", "IBridgeEvents")

    ; Регистрируем WM обработчики
    _WebView2_GUI_RegisterWMHandlers($hInstance)

    ; Инициализируем WebView2 контрол
    If Not _WebView2_Core_InitializeWebView($hInstance, $hGUI, 0, 0, $iWidth, $iHeight) Then
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Ошибка инициализации WebView2" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] GUI окно создано успешно (handle: " & $hGUI & ")" & " → ID = " & $hInstance, 3)
    Return True
EndFunc




; ===============================================================================
; Показ окна
; ===============================================================================
Func _WebView2_GUI_Show($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    Local $hGUI = $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE]
    If $hGUI = 0 Then
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] GUI окно не создано" & " → ID = " & $hInstance, 2)
        Return False
    EndIf

    GUISetState(@SW_SHOW, $hGUI)
    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Окно показано" & " → ID = " & $hInstance, 1)
    Return True
EndFunc


; ===============================================================================
; Скрытие окна
; ===============================================================================
Func _WebView2_GUI_Hide($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    Local $hGUI = $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE]
    If $hGUI = 0 Then Return False

    GUISetState(@SW_HIDE, $hGUI)
    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Окно скрыто" & " → ID = " & $hInstance, 1)
    Return True
EndFunc


; ===============================================================================
; Установка позиции окна
; ===============================================================================
Func _WebView2_GUI_SetPosition($iX, $iY, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    Local $hGUI = $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE]
    If $hGUI = 0 Then Return False

    WinMove($hGUI, "", $iX, $iY)
    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Позиция установлена: " & $iX & "," & $iY & " → ID = " & $hInstance, 1)
    Return True
EndFunc



; ===============================================================================
; Установка размера окна
; ===============================================================================
Func _WebView2_GUI_SetSize($iWidth, $iHeight, $hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return False

    Local $hGUI = $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE]
    If $hGUI = 0 Then Return False

    WinMove($hGUI, "", Default, Default, $iWidth, $iHeight)
    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Размер установлен: " & $iWidth & "x" & $iHeight & " → ID = " & $hInstance, 1)
    Return True
EndFunc



; ===============================================================================
; Получение handle окна
; ===============================================================================
Func _WebView2_GUI_GetHandle($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex < 0 Then Return 0

    Return $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE]
EndFunc

; ===============================================================================
; Функция: _WebView2_GUI_GetInstanceByHandle
; ===============================================================================
; ===============================================================================
; Функция: _WebView2_GUI_GetInstanceByHandle
; Описание: Получение Instance ID по handle окна
; Параметры:
;   $hWnd - handle окна GUI
; Возврат: Instance ID или 0 если не найден
; ===============================================================================
; ===============================================================================
; Функция: _WebView2_GUI_GetInstanceByHandle
; Описание: Получение Instance ID по handle окна
; Параметры:
;   $hWnd - handle окна GUI
; Возврат: Instance ID или 0 если не найден
; ===============================================================================
Func _WebView2_GUI_GetInstanceByHandle($hWnd)
    If UBound($g_aWebView2_Instances, 1) = 0 Then Return -1

    For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
        If $g_aWebView2_Instances[$i][$WV2_GUI_HANDLE] = $hWnd Then
            Return $g_aWebView2_Instances[$i][$WV2_ID]
        EndIf
    Next

    Return -1
EndFunc



; ===============================================================================
; Регистрация WM обработчиков
; ===============================================================================
Func _WebView2_GUI_RegisterWMHandlers($hInstance = 0)
    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Регистрация WM обработчиков" & " → ID = " & $hInstance, 1)

    ; Регистрируем обработчики событий окна
    GUIRegisterMsg(0x0005, "_WebView2_GUI_WM_SIZE")         ; WM_SIZE
    GUIRegisterMsg(0x0003, "_WebView2_GUI_WM_MOVE")         ; WM_MOVE
    GUIRegisterMsg(0x0231, "_WebView2_GUI_WM_ENTERSIZEMOVE") ; WM_ENTERSIZEMOVE
    GUIRegisterMsg(0x0232, "_WebView2_GUI_WM_EXITSIZEMOVE")  ; WM_EXITSIZEMOVE
    GUIRegisterMsg(0x0112, "_WebView2_GUI_WM_SYSCOMMAND")    ; WM_SYSCOMMAND (минимизация/восстановление/развёртывание)

    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] WM обработчики зарегистрированы" & " → ID = " & $hInstance, 3)
    Return True
EndFunc


; ===============================================================================
; Обработчик изменения размера окна (WM_SIZE)
; ===============================================================================
Func _WebView2_GUI_WM_SIZE($hWnd, $iMsg, $wParam, $lParam)
    ; Защита от спама - статические переменные для последнего размера
    Local Static $iLastWidth = 0
    Local Static $iLastHeight = 0

    ; Проверяем размер массива
    If UBound($g_aWebView2_Instances, 1) = 0 Then
        Return "GUI_RUNDEFMSG"
    EndIf

    ; Ищем экземпляр по handle окна (ОДИН поиск вместо двух)
    For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
        If $g_aWebView2_Instances[$i][$WV2_GUI_HANDLE] = $hWnd Then
            Local $hInstance = $g_aWebView2_Instances[$i][$WV2_ID]

            ; Проверяем готовность
            If IsObj($g_aWebView2_Instances[$i][$WV2_MANAGER]) And $g_aWebView2_Instances[$i][$WV2_INITIALIZED] Then
                ; Получаем размеры клиентской области
                Local $aClientSize = WinGetClientSize($hWnd)
                If @error Then
                    Return "GUI_RUNDEFMSG"
                EndIf

                Local $iW = $aClientSize[0]
                Local $iH = $aClientSize[1]

                ; Проверяем что размеры изменились
                If ($iW <> $iLastWidth Or $iH <> $iLastHeight) And $iW > 0 And $iH > 0 Then
                    ; Изменяем размер WebView2
                    $g_aWebView2_Instances[$i][$WV2_MANAGER].MoveTo(0, 0)
                    $g_aWebView2_Instances[$i][$WV2_MANAGER].Resize($iW, $iH)

                    $iLastWidth = $iW
                    $iLastHeight = $iH
                    $g_bWebView2_GUI_WindowResizing = True

                    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Размер WebView2 изменён: " & $iW & "x" & $iH & " → ID = " & $hInstance, 3)
                EndIf
            EndIf
            ExitLoop
        EndIf
    Next

    Return "GUI_RUNDEFMSG"
EndFunc


; ===============================================================================
; Обработчик перемещения окна (WM_MOVE)
; ===============================================================================
Func _WebView2_GUI_WM_MOVE($hWnd, $iMsg, $wParam, $lParam)
    ; Устанавливаем флаг перемещения
    $g_bWebView2_GUI_WindowMoving = True
    Return "GUI_RUNDEFMSG"
EndFunc

; ===============================================================================
; Обработчик начала изменения размера/перемещения (WM_ENTERSIZEMOVE)
; ===============================================================================
Func _WebView2_GUI_WM_ENTERSIZEMOVE($hWnd, $iMsg, $wParam, $lParam)
    Local $hInstance = _WebView2_GUI_GetInstanceByHandle($hWnd)
    $g_bWebView2_GUI_WindowMoving = True
    $g_bWebView2_GUI_WindowResizing = True
    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Начало изменения окна → ID = " & $hInstance, 1)
    Return "GUI_RUNDEFMSG"
EndFunc


; ===============================================================================
; Обработчик завершения изменения размера/перемещения (WM_EXITSIZEMOVE)
; ===============================================================================
Func _WebView2_GUI_WM_EXITSIZEMOVE($hWnd, $iMsg, $wParam, $lParam)
    ; Проверяем размер массива
    If UBound($g_aWebView2_Instances, 1) = 0 Then
        Return "GUI_RUNDEFMSG"
    EndIf

    ; Ищем экземпляр по handle окна
    For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
        If $g_aWebView2_Instances[$i][$WV2_GUI_HANDLE] = $hWnd Then
            Local $hInstance = $g_aWebView2_Instances[$i][$WV2_ID]

            ; Получаем текущую позицию и размер окна
            Local $aPos = WinGetPos($hWnd)
            If Not @error And IsArray($aPos) Then
                ; Формируем ключ конфига для этого окна
                Local $sConfigKey = "windows.window_" & $hInstance

                ; Проверяем настройки из конфига
                Local $bRememberPosition = _Utils_Config_Get($sConfigKey & ".remember_position", True)
                Local $bRememberSize = _Utils_Config_Get($sConfigKey & ".remember_size", True)

                ; Сохраняем позицию если было перемещение
                If $g_bWebView2_GUI_WindowMoving And $bRememberPosition Then
                    _Utils_Config_Set($sConfigKey & ".position.x", $aPos[0])
                    _Utils_Config_Set($sConfigKey & ".position.y", $aPos[1])
                    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] 💾 Позиция сохранена: " & $aPos[0] & ", " & $aPos[1] & " → ID = " & $hInstance, 1)
                EndIf

                ; Сохраняем размер если было изменение
                If $g_bWebView2_GUI_WindowResizing And $bRememberSize Then
                    _Utils_Config_Set($sConfigKey & ".size.width", $aPos[2])
                    _Utils_Config_Set($sConfigKey & ".size.height", $aPos[3])
                    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] 💾 Размер сохранён: " & $aPos[2] & "x" & $aPos[3] & " → ID = " & $hInstance, 1)
                EndIf
            EndIf

            ExitLoop
        EndIf
    Next

    ; Сбрасываем флаги
    $g_bWebView2_GUI_WindowMoving = False
    $g_bWebView2_GUI_WindowResizing = False

    Return "GUI_RUNDEFMSG"
EndFunc

; ===============================================================================
; Функция: _WebView2_GUI_WM_SYSCOMMAND
; ===============================================================================
; ===============================================================================
; Функция: _WebView2_GUI_WM_SYSCOMMAND
; Описание: Обработчик системных команд окна (минимизация/восстановление/развёртывание)
; Параметры:
;   $hWnd - handle окна
;   $iMsg - сообщение
;   $wParam - параметр команды
;   $lParam - дополнительный параметр
; Возврат: "GUI_RUNDEFMSG"
; ===============================================================================
Func _WebView2_GUI_WM_SYSCOMMAND($hWnd, $iMsg, $wParam, $lParam)
    ; Константы системных команд
    Local Const $SC_RESTORE = 0xF120      ; Восстановление окна
    Local Const $SC_MINIMIZE = 0xF020     ; Минимизация окна
    Local Const $SC_MAXIMIZE = 0xF030     ; Развертывание на весь экран

    ; Проверяем размер массива
    If UBound($g_aWebView2_Instances, 1) = 0 Then
        Return "GUI_RUNDEFMSG"
    EndIf

    ; Ищем экземпляр по handle окна
    For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
        If $g_aWebView2_Instances[$i][$WV2_GUI_HANDLE] = $hWnd Then
            Local $hInstance = $g_aWebView2_Instances[$i][$WV2_ID]

            Switch $wParam
                Case $SC_RESTORE
                    ; Окно восстанавливается из минимизированного состояния
                    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] 🔄 Восстановление окна ID=" & $hInstance, 1)
                    ; Показываем WebView2 для возобновления рендеринга
                    _WebView2_GUI_SetVisible($hInstance, True)

                Case $SC_MINIMIZE
                    ; Окно минимизируется
                    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] 📉 Минимизация окна ID=" & $hInstance, 1)
                    ; Скрываем WebView2 для экономии CPU/GPU
                    _WebView2_GUI_SetVisible($hInstance, False)

                Case $SC_MAXIMIZE
                    ; Окно развертывается на весь экран
                    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] 🔳 Развертывание окна на весь экран ID=" & $hInstance, 1)
            EndSwitch

            ExitLoop
        EndIf
    Next

    Return "GUI_RUNDEFMSG"
EndFunc



; ===============================================================================
; Обработчик закрытия окна
; ===============================================================================

; ===============================================================================
; Функция: _WebView2_GUI_SetVisible
; ===============================================================================
; ===============================================================================
; Функция: _WebView2_GUI_SetVisible
; Описание: Управление видимостью WebView2 (оптимизация производительности)
; Параметры:
;   $hInstance - ID экземпляра (0 = default)
;   $bVisible - True = показать, False = скрыть
; Возврат: True при успехе, False при ошибке
; Примечание: При скрытии WebView2 останавливает рендеринг (экономия CPU/GPU)
; ===============================================================================
Func _WebView2_GUI_SetVisible($hInstance = 0, $bVisible = True)
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    If $iIndex = -1 Then Return False

    Local $oManager = $g_aWebView2_Instances[$iIndex][$WV2_MANAGER]
    If Not IsObj($oManager) Then Return False

    ; Вызываем COM метод SetVisible
    $oManager.SetVisible($bVisible)

    If $g_bDebug_WebView2_GUI Then
        Local $sState = ($bVisible ? "показан" : "скрыт")
        _Logger_Write("[WebView2_GUI] 👁️ WebView2 " & $sState & " → ID = " & $hInstance, 1)
    EndIf

    Return True
EndFunc

Func _WebView2_GUI_OnClose($hInstance = 0)
    ; Если handle = 0, используем default
    If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

    If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Закрытие окна для" & " → ID = " & $hInstance, 1)

    ; БЫСТРО скрываем окно для мгновенной реакции
    _WebView2_GUI_Hide($hInstance)

    ; Получаем GUI handle перед удалением инстанса
    Local $iIndex = _WebView2_Core_GetInstance($hInstance)
    Local $hGUI = 0
    If $iIndex >= 0 Then
        $hGUI = $g_aWebView2_Instances[$iIndex][$WV2_GUI_HANDLE]
    EndIf

    ; Полностью удаляем инстанс (включая вызовы Cleanup)
    _WebView2_Core_DestroyInstance($hInstance)

    ; Удаляем GUI окно
    If $hGUI <> 0 Then
        GUIDelete($hGUI)
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] GUI окно удалено" & " → ID = " & $hInstance, 3)
    EndIf

    ; Если это default экземпляр, завершаем приложение
    If $hInstance = $g_hWebView2_Default Then
        Exit
    EndIf
EndFunc

; ===============================================================================
; Функция: _WebView2_GUI_OnClose_Auto
; ===============================================================================
; ===============================================================================
; Функция: _WebView2_GUI_OnClose_Auto
; Описание: Автоматический обработчик закрытия окна (вызывается из OnEventMode)
; Параметры: Нет
; Возврат: Нет
; Примечание: Использует @GUI_WinHandle для определения закрытого окна
; ===============================================================================
Func _WebView2_GUI_OnClose_Auto()
    ; Получаем handle закрытого окна
    Local $hWnd = @GUI_WinHandle

    ; Получаем Instance ID по handle окна
    Local $hInstance = _WebView2_GUI_GetInstanceByHandle($hWnd)

    If $hInstance >= 0 Then
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Закрытие окна ID=" & $hInstance, 1)

        ; БЫСТРО скрываем окно для мгновенной реакции
        _WebView2_GUI_Hide($hInstance)
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Окно ID=" & $hInstance & " скрыто (быстро)", 1)

        ; Подсчитываем окна ДО удаления инстанса
        Local $iOpenWindows = 0
        For $i = 0 To UBound($g_aWebView2_Instances, 1) - 1
            Local $hTestWnd = $g_aWebView2_Instances[$i][$WV2_GUI_HANDLE]
            If $hTestWnd <> 0 And $hTestWnd <> $hWnd And WinExists($hTestWnd) Then
                $iOpenWindows += 1
            EndIf
        Next

        ; Полностью удаляем инстанс (медленно, но в фоне)
        _WebView2_Core_DestroyInstance($hInstance)

        ; Удаляем GUI окно
        GUIDelete($hWnd)
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Окно ID=" & $hInstance & " удалено, осталось окон: " & $iOpenWindows, 1)

        ; Если не осталось окон - завершаем приложение
        If $iOpenWindows = 0 Then
            If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Все окна закрыты, завершение приложения", 1)
            Exit
        EndIf
    Else
        ; Если не нашли инстанс, завершаем приложение
        If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Закрытие приложения", 1)
        Exit
    EndIf
EndFunc


; ===============================================================================
; Функция: _WebView2_GUI_SetProductionMode
; ===============================================================================
; ===============================================================================
; Функция: _WebView2_GUI_SetProductionMode
; Описание: Включает/отключает Production режим для SCADA приложений
; Параметры:
;   $hInstance - ID экземпляра WebView2 (0 = default)
;   $bEnabled - True = включить Production режим, False = Development режим
;   $bAllowDevTools - True = оставить F12/F5 для техподдержки (только если $bEnabled = True)
; Возврат: True при успехе, False при ошибке
; Примечание:
;   Production режим отключает:
;   - Контекстное меню (правая кнопка мыши)
;   - Строку состояния (URL внизу окна)
;   - DevTools и горячие клавиши (если $bAllowDevTools = False)
; ===============================================================================
Func _WebView2_GUI_SetProductionMode($hInstance = 0, $bEnabled = True, $bAllowDevTools = False)
	; Если handle = 0, используем default
	If $hInstance = 0 Then $hInstance = $g_hWebView2_Default

	Local $iIndex = _WebView2_Core_GetInstance($hInstance)
	If $iIndex < 0 Then Return False

	Local $oManager = $g_aWebView2_Instances[$iIndex][$WV2_MANAGER]
	If Not IsObj($oManager) Then Return False

	If $bEnabled Then
		; Production режим: отключаем UI элементы
		$oManager.AreDefaultContextMenusEnabled = False  ; Нет контекстного меню
		$oManager.IsStatusBarEnabled = False             ; Нет статус бара

		; DevTools и горячие клавиши - по параметру
		$oManager.AreDevToolsEnabled = $bAllowDevTools
		$oManager.AreBrowserAcceleratorKeysEnabled = $bAllowDevTools
		
		If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Production режим включен (DevTools: " & $bAllowDevTools & ")" & " → ID = " & $hInstance, 1)
	Else
		; Development режим: включаем всё
		$oManager.AreDefaultContextMenusEnabled = True
		$oManager.IsStatusBarEnabled = True
		$oManager.AreDevToolsEnabled = True
		$oManager.AreBrowserAcceleratorKeysEnabled = True
		
		If $g_bDebug_WebView2_GUI Then _Logger_Write("[WebView2_GUI] Development режим включен" & " → ID = " & $hInstance, 1)
	EndIf

	Return True
EndFunc

