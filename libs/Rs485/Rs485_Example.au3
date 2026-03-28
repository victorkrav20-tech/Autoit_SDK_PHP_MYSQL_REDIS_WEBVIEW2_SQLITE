; ===============================================================================
; Rs485_Example.au3 — Пример приложения RS-485 с GUI, конфигом JSON, Redis
; Версия: v1.0 | Дата: 28.03.2026
; Зависимости: SDK_Init.au3, Rs485.au3, CommMG64.au3
; -------------------------------------------------------------------------------
; СПИСОК ФУНКЦИЙ:
;   _App_Init()                    — инициализация SDK, конфига, Redis
;   _App_Config_Load()             — чтение JSON конфига
;   _App_Redis_Init()              — неблокирующий старт Redis
;   _App_Redis_Reconnect()         — автопереподключение Redis (из Loop)
;   _App_GUI_Create()              — создание окна и контролов
;   _App_GUI_UpdateStatus($sText)  — обновление строки статуса
;   _App_GUI_UpdateResult($sText)  — обновление поля результата
;   _App_OnClose()                 — обработчик закрытия окна
;   _App_OnTrayDblClick()          — двойной клик по трей-иконке
;   _App_OnBtnConnect()            — кнопка Подключить порт
;   _App_OnBtnDisconnect()         — кнопка Отключить
;   _App_OnBtnRead()               — кнопка Считать данные
;   _App_OnBtnRefresh()            — кнопка Обновить статус
;   _App_OnBtnHide()               — кнопка Скрыть в трей
;   _App_GetVarMap($iIdx)          — карта переменных для запроса
;   _App_Loop()                    — основной цикл (10мс)
;   _App_Exit()                    — корректное завершение
;   _App_Test_Run()                — тест-прогон всех функций (TestMode)
; ===============================================================================
#AutoIt3Wrapper_UseX64=y
#include-once
#include <GUIConstantsEx.au3>
#include <TrayConstants.au3>

; --- CommMG (x64 или x32 по флагу) ---
#include "Includes\CommMG64.au3"

; --- SDK ---
#include "..\..\libs\SDK_Init.au3"

; --- Ядро библиотеки Rs485 ---
#include "Rs485.au3"

; ===============================================================================
; Rs485_Example.au3 — Пример приложения RS-485 с GUI, конфигом JSON, Redis
; Копируется в папку проекта, настраивается через config_Rs485_Example.json
; ===============================================================================

; --- Режим теста: True = цикл на 5 сек и завершение, False = бесконечный ---
Global $g_bTestMode = False

; --- Имя приложения и конфиг ---
Global $g_sAppName        = "Rs485_Example"
Global $g_sConfigFile     = @ScriptDir & "\config_Rs485_Example.json"

; --- Настройки из конфига ---
Global $g_iCommPort       = 7
Global $g_iBaudRate       = 19200
Global $g_iCommMode       = 64
Global $g_iSlaveID        = 1
Global $g_iTimeoutMs      = 300

; --- Redis ---
Global $g_bRedisEnabled   = False
Global $g_sRedisHost      = "127.0.0.1"
Global $g_iRedisPort      = 6379
Global $g_sRedisHash      = "auto_zames_online"
Global $g_sRedisDevice    = "Rs485_Port1"
Global $g_iRedisReconnect = 5000
Global $g_bRedisConnected = False
Global $g_hRedisTimer     = 0

; --- GUI ---
Global $g_hGUI            = 0
Global $g_sWindowID       = "Rs485_Example_Main"
Global $g_bWindowVisible  = True

; --- Запросы из конфига ---
Global $g_aRequests       = ""   ; массив конфигов запросов
Global $g_aVarMaps        = ""   ; массив карт переменных

; --- GUI контролы (handle) ---
Global $g_hGUI_LblStatus  = 0
Global $g_hGUI_LblPort    = 0
Global $g_hGUI_LblRedis   = 0
Global $g_hGUI_EditResult = 0
Global $g_hGUI_BtnConnect = 0
Global $g_hGUI_BtnDisconn = 0
Global $g_hGUI_BtnRead    = 0
Global $g_hGUI_BtnRefresh = 0
Global $g_hGUI_BtnHide    = 0

; --- Запускаем ---
_App_Init()
_App_GUI_Create()
_App_Test_Run()   ; тест-функция (отключить перед продакшн)

; --- Основной цикл ---
If $g_bTestMode Then
    ; Тест-режим: работаем 5 секунд и выходим
    Local $hLoopTimer = TimerInit()
    While TimerDiff($hLoopTimer) < 5000
        _App_Loop()
        Sleep(10)
    WEnd
    _Logger_Write("[Main] Тест-режим завершён (5 сек)", 3)
Else
    While 1
        _App_Loop()
        Sleep(10)
    WEnd
EndIf

_App_Exit()

; ===============================================================================
; Функция: _App_Init
; Описание: Инициализация SDK, чтение JSON конфига, запуск Redis если включён
; Возврат: нет (Exit при ошибке SDK)
; ===============================================================================
Func _App_Init()
    ; SDK Init
    Local $bSDK = _SDK_Init($g_sAppName, True, 1, 3, True)
    If Not $bSDK Then
        MsgBox(16, "Ошибка", "Не удалось инициализировать SDK")
        Exit
    EndIf
    _Logger_Write("[Init] SDK инициализирован: " & $g_sAppName, 3)

    ; Читаем JSON конфиг
    _App_Config_Load()

    ; Redis (если включён в конфиге)
    If $g_bRedisEnabled Then
        _App_Redis_Init()
    Else
        _Logger_Write("[Init] Redis отключён в конфиге", 1)
    EndIf

    ; CommMG mode
    $g_iCommMode = (@AutoItX64 = 1) ? 64 : 32
    _Logger_Write("[Init] CommMG mode: x" & $g_iCommMode, 1)

    _Logger_Write("[Init] Инициализация завершена", 3)
EndFunc

; ===============================================================================
; Функция: _App_Config_Load
; Описание: Читает JSON конфиг из config_Rs485_Example.json, заполняет глобальные переменные
; Возврат: True = успех, False = ошибка
; ===============================================================================
Func _App_Config_Load()
    If Not FileExists($g_sConfigFile) Then
        _Logger_Write("[Config] Файл не найден: " & $g_sConfigFile, 2)
        Return False
    EndIf

    Local $hFile = FileOpen($g_sConfigFile, 0)
    If $hFile = -1 Then
        _Logger_Write("[Config] Не удалось открыть файл", 2)
        Return False
    EndIf
    Local $sJSON = FileRead($hFile)
    FileClose($hFile)

    If $sJSON = "" Then
        _Logger_Write("[Config] Файл пустой", 2)
        Return False
    EndIf

    Local $oConfig = _JSON_Parse($sJSON)
    If @error Then
        _Logger_Write("[Config] Ошибка парсинга JSON: " & @error, 2)
        Return False
    EndIf

    ; App секция
    Local $vPort = _JSON_Get($oConfig, 'app.comm_port')
    If Not @error And $vPort <> "" Then $g_iCommPort = Int($vPort)

    Local $vBaud = _JSON_Get($oConfig, 'app.baud_rate')
    If Not @error And $vBaud <> "" Then $g_iBaudRate = Int($vBaud)

    Local $vMode = _JSON_Get($oConfig, 'app.comm_mode')
    If Not @error And $vMode <> "" Then $g_iCommMode = Int($vMode)

    Local $vSlave = _JSON_Get($oConfig, 'app.slave_id')
    If Not @error And $vSlave <> "" Then $g_iSlaveID = Int($vSlave)

    Local $vTimeout = _JSON_Get($oConfig, 'app.timeout_ms')
    If Not @error And $vTimeout <> "" Then $g_iTimeoutMs = Int($vTimeout)

    ; Redis секция
    Local $vRedisEn = _JSON_Get($oConfig, 'redis.enabled')
    If Not @error Then $g_bRedisEnabled = ($vRedisEn = True Or $vRedisEn = "true" Or $vRedisEn = 1 Or $vRedisEn = "1")

    Local $vHost = _JSON_Get($oConfig, 'redis.host')
    If Not @error And $vHost <> "" Then $g_sRedisHost = $vHost

    Local $vRPort = _JSON_Get($oConfig, 'redis.port')
    If Not @error And $vRPort <> "" Then $g_iRedisPort = Int($vRPort)

    Local $vHash = _JSON_Get($oConfig, 'redis.hash_name')
    If Not @error And $vHash <> "" Then $g_sRedisHash = $vHash

    Local $vDev = _JSON_Get($oConfig, 'redis.device_name')
    If Not @error And $vDev <> "" Then $g_sRedisDevice = $vDev

    Local $vRecon = _JSON_Get($oConfig, 'redis.reconnect_interval_ms')
    If Not @error And $vRecon <> "" Then $g_iRedisReconnect = Int($vRecon)

    _Logger_Write("[Config] Загружен: COM" & $g_iCommPort & " " & $g_iBaudRate & " бод | Redis=" & $g_bRedisEnabled & " | Slave=" & $g_iSlaveID, 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _App_Redis_Init
; Описание: Неблокирующая инициализация Redis. При неудаче — запускает таймер переподключения
; Возврат: True = подключён, False = не подключён (будет автопереподключение)
; ===============================================================================
Func _App_Redis_Init()
    Local $bInit = _SDK_Redis_Init($g_sRedisHost, $g_iRedisPort)
    If Not $bInit Then
        _Logger_Write("[Redis] SDK Redis Init не удался", 2)
        $g_hRedisTimer = TimerInit()
        Return False
    EndIf

    Local $bConn = _Redis_Connect($g_sRedisHost, $g_iRedisPort)
    If $bConn Then
        $g_bRedisConnected = True
        _Logger_Write("[Redis] Подключён: " & $g_sRedisHost & ":" & $g_iRedisPort, 3)
    Else
        $g_bRedisConnected = False
        _Logger_Write("[Redis] Не подключён (автопереподключение через " & $g_iRedisReconnect & "мс)", 2)
    EndIf
    $g_hRedisTimer = TimerInit()
    Return $g_bRedisConnected
EndFunc

; ===============================================================================
; Функция: _App_Redis_Reconnect
; Описание: Проверяет таймер и пытается переподключиться к Redis. Вызывается из Loop
; ===============================================================================
Func _App_Redis_Reconnect()
    If Not $g_bRedisEnabled Then Return
    If $g_bRedisConnected Then Return
    If TimerDiff($g_hRedisTimer) < $g_iRedisReconnect Then Return

    _Logger_Write("[Redis] Попытка переподключения...", 1)
    Local $bConn = _Redis_Connect($g_sRedisHost, $g_iRedisPort)
    If $bConn Then
        $g_bRedisConnected = True
        _Logger_Write("[Redis] Переподключён успешно", 3)
    Else
        _Logger_Write("[Redis] Переподключение не удалось", 2)
    EndIf
    $g_hRedisTimer = TimerInit()
EndFunc

; ===============================================================================
; Функция: _App_GUI_Create
; Описание: Создаёт главное окно через Utils_Window, контролы, трей, привязывает события
; Возврат: True = успех, False = ошибка создания окна
; ===============================================================================
Func _App_GUI_Create()
    Opt("GUIOnEventMode", 1)

    ; Создаём окно через SDK Utils_Window
    _Utils_Window_Create($g_sWindowID, "RS-485 Monitor — " & $g_sAppName, 620, 420, -1, -1, "default", "_App_OnClose")
    $g_hGUI = _Utils_Window_GetHandle($g_sWindowID)

    If $g_hGUI = 0 Then
        _Logger_Write("[GUI] Ошибка создания окна", 2)
        Return False
    EndIf

    ; --- Статус бар (Label вверху) ---
    $g_hGUI_LblStatus = GUICtrlCreateLabel("Статус: инициализация...", 10, 10, 600, 20)
    GUICtrlSetColor($g_hGUI_LblStatus, 0x006600)

    ; --- Разделитель ---
    GUICtrlCreateLabel("", 10, 35, 600, 1)

    ; --- Инфо: порт и Redis ---
    $g_hGUI_LblPort  = GUICtrlCreateLabel("Порт: COM" & $g_iCommPort & "  " & $g_iBaudRate & " бод", 10, 45, 300, 18)
    $g_hGUI_LblRedis = GUICtrlCreateLabel("Redis: " & ($g_bRedisEnabled ? ($g_bRedisConnected ? "подключён" : "не подключён") : "отключён"), 320, 45, 290, 18)

    ; --- Последний JSON результат ---
    GUICtrlCreateLabel("Последний ответ:", 10, 75, 200, 18)
    $g_hGUI_EditResult = GUICtrlCreateEdit("", 10, 95, 600, 200, BitOR(0x0800, 0x0004, 0x0040))
    GUICtrlSetFont($g_hGUI_EditResult, 8, 400, 0, "Courier New")

    ; --- Кнопки ---
    $g_hGUI_BtnConnect = GUICtrlCreateButton("Подключить порт",  10,  310, 130, 28)
    $g_hGUI_BtnDisconn = GUICtrlCreateButton("Отключить",        150, 310, 100, 28)
    $g_hGUI_BtnRead    = GUICtrlCreateButton("Считать",          260, 310, 100, 28)
    $g_hGUI_BtnRefresh = GUICtrlCreateButton("Обновить статус",  370, 310, 130, 28)
    $g_hGUI_BtnHide    = GUICtrlCreateButton("Скрыть в трей",    510, 310, 100, 28)

    ; --- Привязка событий ---
    GUICtrlSetOnEvent($g_hGUI_BtnConnect, "_App_OnBtnConnect")
    GUICtrlSetOnEvent($g_hGUI_BtnDisconn, "_App_OnBtnDisconnect")
    GUICtrlSetOnEvent($g_hGUI_BtnRead,    "_App_OnBtnRead")
    GUICtrlSetOnEvent($g_hGUI_BtnRefresh, "_App_OnBtnRefresh")
    GUICtrlSetOnEvent($g_hGUI_BtnHide,    "_App_OnBtnHide")

    ; --- Трей ---
    TraySetIcon(@ScriptDir & "\icon.ico", 1)
    TraySetToolTip($g_sAppName)
    TraySetClick(16)  ; двойной клик
    TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "_App_OnTrayDblClick")
    TrayItemSetOnEvent(-1, "_App_OnTrayDblClick")

    _Utils_Window_Show($g_sWindowID)
    _App_GUI_UpdateStatus("Готов")
    _Logger_Write("[GUI] Окно создано", 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _App_GUI_UpdateStatus
; Описание: Обновляет строку статуса и лейбл Redis в GUI
; Параметры: $sText — текст статуса
; ===============================================================================
Func _App_GUI_UpdateStatus($sText)
    GUICtrlSetData($g_hGUI_LblStatus, "Статус: " & $sText)
    GUICtrlSetData($g_hGUI_LblRedis, "Redis: " & ($g_bRedisEnabled ? ($g_bRedisConnected ? "подключён ✓" : "не подключён") : "отключён"))
EndFunc

; ===============================================================================
; Функция: _App_GUI_UpdateResult
; Описание: Обновляет поле с JSON результатом последнего считывания
; Параметры: $sText — JSON строка или сообщение об ошибке
; ===============================================================================
Func _App_GUI_UpdateResult($sText)
    GUICtrlSetData($g_hGUI_EditResult, $sText)
EndFunc

; ===============================================================================
; Обработчики кнопок и событий
; ===============================================================================

; ===============================================================================
; Функция: _App_OnClose
; Описание: Обработчик закрытия окна — вызывает _App_Exit
; ===============================================================================
Func _App_OnClose()
    _Logger_Write("[GUI] Закрытие окна", 1)
    _App_Exit()
EndFunc

; ===============================================================================
; Функция: _App_OnTrayDblClick
; Описание: Двойной клик по трей-иконке — переключает видимость окна
; ===============================================================================
Func _App_OnTrayDblClick()
    If _Utils_Window_IsVisible($g_sWindowID) Then
        _Utils_Window_Hide($g_sWindowID)
        _Logger_Write("[Tray] Окно скрыто", 1)
    Else
        _Utils_Window_Show($g_sWindowID)
        _Logger_Write("[Tray] Окно показано", 1)
    EndIf
EndFunc

; ===============================================================================
; Функция: _App_OnBtnConnect
; Описание: Открывает COM порт через Rs485_Init с параметрами из конфига
; ===============================================================================
Func _App_OnBtnConnect()
    _Logger_Write("[Btn] Подключить порт COM" & $g_iCommPort, 1)
    Local $bOk = _Rs485_Init($g_iCommPort, $g_iBaudRate, $g_iCommMode)
    If $bOk Then
        _App_GUI_UpdateStatus("Порт COM" & $g_iCommPort & " открыт")
        _Logger_Write("[Port] Открыт COM" & $g_iCommPort, 3)
    Else
        _App_GUI_UpdateStatus("Ошибка открытия COM" & $g_iCommPort)
        _Logger_Write("[Port] Ошибка открытия COM" & $g_iCommPort, 2)
    EndIf
EndFunc

; ===============================================================================
; Функция: _App_OnBtnDisconnect
; Описание: Закрывает COM порт
; ===============================================================================
Func _App_OnBtnDisconnect()
    _Logger_Write("[Btn] Отключить порт", 1)
    _Rs485_Close()
    _App_GUI_UpdateStatus("Порт закрыт")
EndFunc

; ===============================================================================
; Функция: _App_OnBtnRead
; Описание: Считывает данные с устройства, парсит в JSON, пишет в Redis если включён
; ===============================================================================
Func _App_OnBtnRead()
    _Logger_Write("[Btn] Считать данные", 1)
    If Not _Rs485_IsOpen() Then
        _App_GUI_UpdateStatus("Порт не открыт — нажмите Подключить")
        _Logger_Write("[Read] Порт не открыт", 2)
        Return
    EndIf
    ; Читаем первый запрос из конфига
    Local $sReq = _Rs485_BuildRequest($g_iSlaveID, 3, 0, 10)
    Local $aResp = _Rs485_SendAndRead($sReq, 3 + 10 * 2 + 2, $g_iTimeoutMs)
    If $aResp = "" Then
        _App_GUI_UpdateStatus("Нет ответа от устройства")
        _App_GUI_UpdateResult("Нет ответа")
        Return
    EndIf
    ; Формируем JSON через ParseResponse (карта из конфига)
    Local $sJSON = _Rs485_ParseResponse($aResp, _App_GetVarMap(0))
    _App_GUI_UpdateResult($sJSON)
    _App_GUI_UpdateStatus("Считано успешно")
    _Logger_Write("[Read] JSON: " & $sJSON, 3)

    ; Пишем в Redis если подключён
    If $g_bRedisEnabled And $g_bRedisConnected Then
        _Redis_HSet($g_sRedisHash & ":" & $g_sRedisDevice, "data", $sJSON)
        _Logger_Write("[Redis] Записано в " & $g_sRedisHash & ":" & $g_sRedisDevice, 3)
    EndIf
EndFunc

; ===============================================================================
; Функция: _App_OnBtnRefresh
; Описание: Обновляет строку статуса — порт и Redis
; ===============================================================================
Func _App_OnBtnRefresh()
    _Logger_Write("[Btn] Обновить статус", 1)
    _App_GUI_UpdateStatus("Обновлено | Redis: " & ($g_bRedisConnected ? "OK" : "нет") & " | Порт: " & (_Rs485_IsOpen() ? "открыт" : "закрыт"))
EndFunc

Func _App_OnBtnHide()
    _Utils_Window_Hide($g_sWindowID)
    _Logger_Write("[Btn] Окно скрыто в трей", 1)
EndFunc

; ===============================================================================
; _App_GetVarMap — возвращает карту переменных для запроса по индексу
; Пока хардкод из конфига, потом будет динамически из JSON
; ===============================================================================
Func _App_GetVarMap($iRequestIndex)
    Local $aMap[7][6]
    $aMap[0][0]="temp_int16"
    $aMap[0][1]=0
    $aMap[0][2]="INT16"
    $aMap[0][3]="ABCD"
    $aMap[0][4]=0.1
    $aMap[0][5]="C"
    $aMap[1][0]="status"
    $aMap[1][1]=2
    $aMap[1][2]="UINT16"
    $aMap[1][3]="ABCD"
    $aMap[1][4]=1.0
    $aMap[1][5]=""
    $aMap[2][0]="counter"
    $aMap[2][1]=4
    $aMap[2][2]="UINT16"
    $aMap[2][3]="ABCD"
    $aMap[2][4]=1.0
    $aMap[2][5]=""
    $aMap[3][0]="pressure"
    $aMap[3][1]=6
    $aMap[3][2]="FLOAT32"
    $aMap[3][3]="ABCD"
    $aMap[3][4]=1.0
    $aMap[3][5]="bar"
    $aMap[4][0]="weight"
    $aMap[4][1]=10
    $aMap[4][2]="FLOAT32"
    $aMap[4][3]="CDAB"
    $aMap[4][4]=1.0
    $aMap[4][5]="kg"
    $aMap[5][0]="long_val"
    $aMap[5][1]=14
    $aMap[5][2]="INT32"
    $aMap[5][3]="ABCD"
    $aMap[5][4]=1.0
    $aMap[5][5]=""
    $aMap[6][0]="uint32_val"
    $aMap[6][1]=18
    $aMap[6][2]="UINT32"
    $aMap[6][3]="ABCD"
    $aMap[6][4]=1.0
    $aMap[6][5]=""
    Return $aMap
EndFunc

; ===============================================================================
; _App_Loop — основной цикл (вызывается каждые 10мс)
; ===============================================================================
Func _App_Loop()
    ; Проверка переподключения Redis
    _App_Redis_Reconnect()
EndFunc

; ===============================================================================
; _App_Exit — корректное завершение
; ===============================================================================
Func _App_Exit()
    _Logger_Write("[Exit] Завершение приложения", 1)
    If _Rs485_IsOpen() Then _Rs485_Close()
    If $g_bRedisConnected Then _Redis_Disconnect()
    If $g_hGUI <> 0 Then
        _Utils_Window_Destroy($g_sWindowID)
    EndIf
    Exit
EndFunc

; ===============================================================================
; _App_Test_Run — тест-функция: поочерёдно вызывает все функции кнопок
; Отключить перед продакшн (убрать вызов из основного кода)
; ===============================================================================
Func _App_Test_Run()
    _Logger_Write("[TEST] ══ Начало тест-прогона ══", 1)

    ; Тест 1: Обновить статус
    _Logger_Write("[TEST] 1. Обновить статус", 1)
    _App_OnBtnRefresh()
    Sleep(300)

    ; Тест 2: Скрыть окно
    _Logger_Write("[TEST] 2. Скрыть окно", 1)
    _App_OnBtnHide()
    Sleep(500)

    ; Тест 3: Показать окно через трей
    _Logger_Write("[TEST] 3. Показать окно (трей)", 1)
    _App_OnTrayDblClick()
    Sleep(500)

    ; Тест 4: Подключить порт
    _Logger_Write("[TEST] 4. Подключить порт COM" & $g_iCommPort, 1)
    _App_OnBtnConnect()
    Sleep(300)

    ; Тест 5: Считать данные (если порт открылся)
    If _Rs485_IsOpen() Then
        _Logger_Write("[TEST] 5. Считать данные", 1)
        _App_OnBtnRead()
        Sleep(500)
    Else
        _Logger_Write("[TEST] 5. Пропуск считывания — порт не открыт", 2)
    EndIf

    ; Тест 6: Обновить статус после считывания
    _Logger_Write("[TEST] 6. Обновить статус", 1)
    _App_OnBtnRefresh()
    Sleep(300)

    ; Тест 7: Отключить порт
    _Logger_Write("[TEST] 7. Отключить порт", 1)
    _App_OnBtnDisconnect()
    Sleep(300)

    ; Тест 8: Скрыть снова
    _Logger_Write("[TEST] 8. Скрыть окно снова", 1)
    _App_OnBtnHide()
    Sleep(500)

    ; Тест 9: Показать снова
    _Logger_Write("[TEST] 9. Показать окно снова", 1)
    _App_OnTrayDblClick()
    Sleep(300)

    _Logger_Write("[TEST] ══ Тест-прогон завершён ══", 3)
EndFunc
