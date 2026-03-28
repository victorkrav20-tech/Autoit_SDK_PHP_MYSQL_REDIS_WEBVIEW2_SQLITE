#pragma compile(AutoItExecuteAllowed, True)
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=img\note.ico ; Путь к иконке
#AutoIt3Wrapper_Outfile=ProcessManager.exe ; Имя выходного файла
#AutoIt3Wrapper_Compression=4           ; Уровень сжатия (0-4). 4 - макс.
#AutoIt3Wrapper_UseX64=n                ; y - 64 бит, n - 32 бит
; --- Данные версии ---
#AutoIt3Wrapper_Res_Description=Менеджер процессов и автозапуска ; Описание
#AutoIt3Wrapper_Res_Fileversion=1.0.0.5 ; Версия файла
#AutoIt3Wrapper_Res_Productversion=1.0  ; Версия продукта
#AutoIt3Wrapper_Res_LegalCopyright=© 2026
#AutoIt3Wrapper_Res_Language=1049        ; 1049 - Русский язык свойств
; --- Дополнительно ---
#AutoIt3Wrapper_Res_Field=Email|support@example.com
#AutoIt3Wrapper_Res_Field=Built with|AutoIt v3.3.16.1
; --- Настройки Au3Stripper для точного определения строк ошибок ---
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo /rsln
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;#RequireAdmin  ; 🔐 Требовать права администратора для управления процессами

; --- Подключение библиотек AutoIt ---
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <Date.au3>
#include <Constants.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>
#include <StaticConstants.au3>
#include <WinAPIShellEx.au3>
#include <GuiButton.au3>
#include <WinAPI.au3>
#include <WinAPIGdi.au3>
#include <WinAPISys.au3>
#include <GuiEdit.au3>
#include <File.au3>
#include <EditConstants.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>



#NoTrayIcon  ; 🔕 Отключаем стандартную иконку трея (создадим свою)
Opt("GUIOnEventMode", 1)     ; События для ОКОН
Opt("TrayOnEventMode", 1)    ; 🎯 События для ТРЕЯ (критически важно!)
Opt("TrayMenuMode", 1)       ; Убираем стандартное меню трея

Global $iHK_Tries = 10 ; Счетчик попыток для Adlib
;Global $oMyError = ObjEvent("AutoIt.Error", "_MyErrorHandler")

Global $oMyError = ObjEvent("AutoIt.Error", "_MyErrorHandler")
OnAutoItExitRegister("_OnExit")
; --- Подключение модулей ProcessManager ---
#include "ProcessManager_Config.au3"
#include "ProcessManager_Core.au3"
#include "ProcessManager_GUI.au3"
#include "ProcessManager_Actions.au3"
#include "ProcessManager_Settings.au3"
#include "ProcessManager_ProcessDialog.au3"
#include "ProcessManager_Logging.au3"
#include "ProcessManager_Utils.au3"


;Run(@AutoItExe & ' /AutoIt3ExecuteLine "ConsoleWriteError(MsgBox(64, ''Внимание..'', ''сообщение,'&@CRLF&' вторая часть и так далее таймаут=10'',10))"', '', '', 4)


; --- ЗАПУСК ---
InitializeLogging()
LoadSettingsFromINI()



CreateMainGUI()

; 🎯 ИНИЦИАЛИЗАЦИЯ СИСТЕМЫ ТРЕЯ
InitializeTrayIcon()

; Инициализируем реальные статусы процессов без логирования
InitializeProcessStatuses()

; Инициализируем таймеры для процессов при запуске
For $i = 1 To $aProcesses[0][0]
    $aProcesses[$i][11] = TimerInit() ; Инициализация таймера при загрузке
Next

AdlibRegister("RunStartupProcessesOnce", 1000) ; Проверяем таймауты для первого запуска каждые 1000мс

; Сбрасываем счетчик попыток регистрации горячих клавиш
$iHK_Tries = 0
AdlibRegister("_RegisterMyHotKeys_Async", 1000) ; Запускать каждую секунду
;HotKeySet("{F3}", "ShowArrayTable") ; Устанавливаем горячую клавишу F3 для отображения массива
;HotKeySet("{F4}", "TestLogCyclicity") ; Горячая клавиша для тестирования (F4)
;HotKeySet("{F5}", "debug_error") ; Горячая клавиша для тестирования ошибок (F5)
; --- В начале программы ---




; --- ОСНОВНОЙ ЦИКЛ ---
While 1
    ; Твоя логика модального окна
    If $active_on = 10 Then
        ; Здесь может быть код обработки, если окно активно
    EndIf

    $allProcs = ProcessList() ; Получаем список 1 раз
    MonitorProcesses($allProcs)    ; Передаем его в мониторинг
    UpdateWorkTime($allProcs)      ; Передаем его в обновление времени
    UpdateStatusBar()              ; 🎨 Обновляем строку состояния
    UpdateTrayTooltip()            ; 🎯 Обновляем подсказку трея

    ; 📊 Мониторинг изменений файла Watchdog.log для обновления GUI
    CheckWatchdogLogChanges()

    ; Ждем немного, чтобы не грузить CPU
    Sleep(500)
WEnd