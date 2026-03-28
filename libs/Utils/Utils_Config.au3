#include-once
#include "Utils.au3"
#include "..\json\JSON.au3"

; ===============================================================================
; Utils_Config Library v1.0
; Универсальная система управления конфигурацией для всех приложений SDK
; ===============================================================================
;
; СПИСОК ФУНКЦИЙ:
; ===============================================================================
; ИНИЦИАЛИЗАЦИЯ:
; _Utils_Config_Init($sAppName) - Инициализация системы конфигурации
;
; СОЗДАНИЕ И ЗАГРУЗКА:
; _Utils_Config_CreateDefault($sAppName) - Создание дефолтного конфига
; _Utils_Config_Load() - Загрузка конфига из файла
; _Utils_Config_Save() - Сохранение конфига в файл
;
; РАБОТА С ДАННЫМИ:
; _Utils_Config_Get($sPath, $vDefault) - Получение значения по пути
; _Utils_Config_Set($sPath, $vValue) - Установка значения по пути
;
; ВАЛИДАЦИЯ И BACKUP:
; _Utils_Config_Validate() - Проверка структуры конфига
; _Utils_Config_Backup() - Создание резервной копии
; _Utils_Config_Restore($iBackupIndex) - Восстановление из backup
;
; ИМПОРТ/ЭКСПОРТ:
; _Utils_Config_Export($sFilePath) - Экспорт конфига в другой файл
; _Utils_Config_Import($sFilePath) - Импорт конфига из файла
; ===============================================================================

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
; ===============================================================================
Global $g_bUtils_DebugMode = True  ; Debug режим (общий для Utils_Config и Utils_Window)
Global $g_oUtils_AppConfig = ''     ; Объект конфигурации (Map или Scripting.Dictionary)
Global $g_sUtils_ConfigPath = ""    ; Путь к файлу конфига
Global $g_sUtils_AppName = ""       ; Имя приложения

; ===============================================================================
; Функция: _Utils_Config_Init
; Описание: Инициализация системы конфигурации
; Параметры:
;   $sAppName - имя приложения (обязательный)
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Init("MyApp")
; ===============================================================================

Func _Utils_Config_Init($sAppName)
	If $sAppName = "" Then
		_Logger_Write("[Utils_Config] ОШИБКА: Имя приложения не указано", 2)
		Return SetError(1, 0, False)
	EndIf

	$g_sUtils_AppName = $sAppName
	$g_sUtils_ConfigPath = @ScriptDir & "\config\app_config.json"

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Инициализация для приложения: " & $sAppName, 1)

	Local $sBackupDir = @ScriptDir & "\config\backup"
	If FileExists($sBackupDir) Then
		Local $aBackups = _FileListToArray($sBackupDir, "app_config_*.json", 1)
		If IsArray($aBackups) And $aBackups[0] > 10 Then
			_ArraySort($aBackups, 1, 1)
			
			For $i = 11 To $aBackups[0]
				FileDelete($sBackupDir & "\" & $aBackups[$i])
			Next
			
			If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Автоочистка backup: удалено " & ($aBackups[0] - 10) & " файлов", 1)
		EndIf
	EndIf

	If Not FileExists($g_sUtils_ConfigPath) Then
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг не найден, создаю дефолтный", 1)
		If Not _Utils_Config_CreateDefault($sAppName) Then
			_Logger_Write("[Utils_Config] ОШИБКА: Не удалось создать дефолтный конфиг", 2)
			Return SetError(2, 0, False)
		EndIf
	EndIf

	If Not _Utils_Config_Load() Then
		_Logger_Write("[Utils_Config] КРИТИЧЕСКАЯ ОШИБКА: Конфиг повреждён, пытаюсь восстановить из backup", 2)
		
		If Not FileExists($sBackupDir) Then DirCreate($sBackupDir)
		
		Local $sTimestamp = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
		Local $sCorruptedBackup = $sBackupDir & "\corrupted_config_" & $sTimestamp & ".json"
		FileCopy($g_sUtils_ConfigPath, $sCorruptedBackup, 1)
		
		FileDelete($g_sUtils_ConfigPath)
		
		Local $aBackups = _FileListToArray($sBackupDir, "app_config_*.json", 1)
		Local $bRestored = False
		
		If IsArray($aBackups) And $aBackups[0] > 0 Then
			_ArraySort($aBackups, 1, 1)
			
			For $i = 1 To $aBackups[0]
				Local $sBackupFile = $sBackupDir & "\" & $aBackups[$i]
				If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Проверяю backup: " & $aBackups[$i], 1)
				
				FileCopy($sBackupFile, $g_sUtils_ConfigPath, 1)
				
				If _Utils_Config_Load() Then
					_Logger_Write("[Utils_Config] ✅ Конфиг восстановлен из backup: " & $aBackups[$i], 3)
					$bRestored = True
					ExitLoop
				Else
					If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Backup битый, пробую следующий", 1)
					FileDelete($g_sUtils_ConfigPath)
				EndIf
			Next
		EndIf
		
		If Not $bRestored Then
			_Logger_Write("[Utils_Config] Валидные backup не найдены, создаю дефолтный конфиг", 1)
			
			If Not _Utils_Config_CreateDefault($sAppName) Then
				_Logger_Write("[Utils_Config] КРИТИЧЕСКАЯ ОШИБКА: Не удалось пересоздать конфиг", 2)
				Return SetError(3, 0, False)
			EndIf
			
			If Not _Utils_Config_Load() Then
				_Logger_Write("[Utils_Config] КРИТИЧЕСКАЯ ОШИБКА: Не удалось загрузить новый конфиг", 2)
				Return SetError(4, 0, False)
			EndIf
			
			Run(@ComSpec & ' /c start "" /min cmd /c "echo Конфигурация была повреждена и сброшена к дефолтным значениям. & echo Backup сохранён: ' & $sCorruptedBackup & ' & pause"', "", @SW_HIDE)
			
			_Logger_Write("[Utils_Config] Конфиг сброшен к дефолтным значениям, backup: " & $sCorruptedBackup, 1)
		EndIf
	EndIf

	If Not _Utils_Config_Validate() Then
		_Logger_Write("[Utils_Config] ПРЕДУПРЕЖДЕНИЕ: Валидация конфига провалилась", 2)
	EndIf

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Инициализация завершена успешно", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_CreateDefault
; Описание: Создание дефолтного конфига
; Параметры:
;   $sAppName - имя приложения (обязательный)
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_CreateDefault("MyApp")
; ===============================================================================
Func _Utils_Config_CreateDefault($sAppName)
	; Создание папки config
	Local $sConfigDir = @ScriptDir & "\config"
	If Not FileExists($sConfigDir) Then
		If Not DirCreate($sConfigDir) Then
			_Logger_Write("[Utils_Config] ОШИБКА: Не удалось создать папку config", 2)
			Return SetError(1, 0, False)
		EndIf
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Папка config создана", 1)
	EndIf

	; Создание дефолтной структуры конфига через Scripting.Dictionary
	Local $oConfig = ObjCreate("Scripting.Dictionary")
	
	; Секция app
	Local $oApp = ObjCreate("Scripting.Dictionary")
	$oApp.Item("name") = $sAppName
	$oApp.Item("version") = "1.0.0"
	$oApp.Item("autostart") = False
	$oConfig.Item("app") = $oApp

	; Секция windows
	Local $oWindows = ObjCreate("Scripting.Dictionary")
	
	; Дефолтное окно window_1
	Local $oWindow1 = ObjCreate("Scripting.Dictionary")
	$oWindow1.Item("title") = "Main Window"
	$oWindow1.Item("show_on_startup") = True
	$oWindow1.Item("remember_position") = True
	$oWindow1.Item("remember_size") = True
	$oWindow1.Item("minimize_to_tray") = False
	$oWindow1.Item("freeze_on_hide") = False
	$oWindow1.Item("hide_mode") = "minimize"
	$oWindow1.Item("style") = "default"
	
	; Позиция
	Local $oPosition = ObjCreate("Scripting.Dictionary")
	$oPosition.Item("x") = 100
	$oPosition.Item("y") = 100
	$oWindow1.Item("position") = $oPosition
	
	; Размер
	Local $oSize = ObjCreate("Scripting.Dictionary")
	$oSize.Item("width") = 1200
	$oSize.Item("height") = 800
	$oWindow1.Item("size") = $oSize
	
	$oWindow1.Item("state") = "normal"
	$oWindows.Item("window_1") = $oWindow1
	$oConfig.Item("windows") = $oWindows

	; Секция hotkeys
	Local $oHotkeys = ObjCreate("Scripting.Dictionary")
	$oHotkeys.Item("toggle_window") = "F2"
	$oHotkeys.Item("exit_app") = "Ctrl+Alt+Q"
	$oConfig.Item("hotkeys") = $oHotkeys

	; Секция tray
	Local $oTray = ObjCreate("Scripting.Dictionary")
	$oTray.Item("enabled") = False
	$oTray.Item("tooltip") = $sAppName
	$oTray.Item("show_notifications") = True
	$oConfig.Item("tray") = $oTray

	; Сохранение в файл через _JSON_Generate
	Local $sJSON = _JSON_Generate($oConfig)
	Local $hFile = FileOpen($g_sUtils_ConfigPath, 2)
	If $hFile = -1 Then
		_Logger_Write("[Utils_Config] ОШИБКА: Не удалось открыть файл для записи", 2)
		Return SetError(2, 0, False)
	EndIf

	FileWrite($hFile, $sJSON)
	FileClose($hFile)

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Дефолтный конфиг создан: " & $g_sUtils_ConfigPath, 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Load
; Описание: Загрузка конфига из файла
; Параметры: Нет
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Load()
; ===============================================================================
Func _Utils_Config_Load()
	If Not FileExists($g_sUtils_ConfigPath) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Файл конфига не найден: " & $g_sUtils_ConfigPath, 2)
		Return SetError(1, 0, False)
	EndIf

	Local $sJSON = FileRead($g_sUtils_ConfigPath)
	If @error Then
		_Logger_Write("[Utils_Config] ОШИБКА: Не удалось прочитать файл конфига", 2)
		Return SetError(2, 0, False)
	EndIf

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] JSON прочитан, размер: " & StringLen($sJSON) & " символов", 1)

	$g_oUtils_AppConfig = _JSON_Parse($sJSON)
	
	; Проверяем что парсинг успешен (Map или Object)
	If @error Or ($g_oUtils_AppConfig = '' And Not IsMap($g_oUtils_AppConfig) And Not IsObj($g_oUtils_AppConfig)) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Не удалось распарсить JSON", 2)
		Return SetError(3, 0, False)
	EndIf

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг загружен успешно (тип: " & VarGetType($g_oUtils_AppConfig) & ")", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Save
; Описание: Сохранение конфига в файл
; Параметры: Нет
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Save()
; ===============================================================================
Func _Utils_Config_Save()
	If Not IsMap($g_oUtils_AppConfig) And Not IsObj($g_oUtils_AppConfig) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Конфиг не инициализирован", 2)
		Return SetError(1, 0, False)
	EndIf

	; Создание backup перед сохранением
	If FileExists($g_sUtils_ConfigPath) Then
		_Utils_Config_Backup()
	EndIf

	Local $sJSON = _JSON_Generate($g_oUtils_AppConfig)
	Local $hFile = FileOpen($g_sUtils_ConfigPath, 2)
	If $hFile = -1 Then
		_Logger_Write("[Utils_Config] ОШИБКА: Не удалось открыть файл для записи", 2)
		Return SetError(2, 0, False)
	EndIf

	FileWrite($hFile, $sJSON)
	FileClose($hFile)

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг сохранён", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Get
; Описание: Получение значения по пути
; Параметры:
;   $sPath - путь к значению (например, "windows.window_1.position.x")
;   $vDefault - значение по умолчанию (опционально)
; Возврат: Значение или $vDefault при ошибке
; Пример: _Utils_Config_Get("windows.window_1.position.x", 100)
; ===============================================================================
Func _Utils_Config_Get($sPath, $vDefault = "")
	If Not IsMap($g_oUtils_AppConfig) And Not IsObj($g_oUtils_AppConfig) Then
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] ПРЕДУПРЕЖДЕНИЕ: Конфиг не инициализирован", 2)
		Return $vDefault
	EndIf

	; Используем _JSON_Get для навигации по пути
	Local $vResult = _JSON_Get($g_oUtils_AppConfig, $sPath)
	If @error Then
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Ключ не найден: " & $sPath, 1)
		Return $vDefault
	EndIf

	Return $vResult
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Set
; Описание: Установка значения по пути
; Параметры:
;   $sPath - путь к значению (например, "windows.window_1.position.x")
;   $vValue - новое значение
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Set("windows.window_1.position.x", 200)
; ===============================================================================
Func _Utils_Config_Set($sPath, $vValue)
	If Not IsMap($g_oUtils_AppConfig) And Not IsObj($g_oUtils_AppConfig) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Конфиг не инициализирован", 2)
		Return SetError(1, 0, False)
	EndIf

	; Используем _JSON_addChangeDelete для установки значения
	_JSON_addChangeDelete($g_oUtils_AppConfig, $sPath, $vValue)
	If @error Then
		_Logger_Write("[Utils_Config] ОШИБКА: Не удалось установить значение: " & $sPath, 2)
		Return SetError(2, 0, False)
	EndIf

	; Автосохранение
	_Utils_Config_Save()

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Значение установлено: " & $sPath & " = " & $vValue, 1)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Validate
; Описание: Проверка структуры конфига
; Параметры: Нет
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Validate()
; ===============================================================================
Func _Utils_Config_Validate()
	If Not IsMap($g_oUtils_AppConfig) And Not IsObj($g_oUtils_AppConfig) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Конфиг не инициализирован", 2)
		Return SetError(1, 0, False)
	EndIf

	Local $bModified = False

	; Проверка секции app (работает и для Map и для Dictionary)
	Local $vApp = _JSON_Get($g_oUtils_AppConfig, "app")
	If @error Or $vApp = '' Then
		Local $oApp = ObjCreate("Scripting.Dictionary")
		$oApp.Item("name") = $g_sUtils_AppName
		$oApp.Item("version") = "1.0.0"
		$oApp.Item("autostart") = False
		_JSON_addChangeDelete($g_oUtils_AppConfig, "app", $oApp)
		$bModified = True
	EndIf

	; Проверка секции windows
	Local $vWindows = _JSON_Get($g_oUtils_AppConfig, "windows")
	If @error Or $vWindows = '' Then
		Local $oWindows = ObjCreate("Scripting.Dictionary")
		_JSON_addChangeDelete($g_oUtils_AppConfig, "windows", $oWindows)
		$bModified = True
	EndIf

	; Проверка секции hotkeys
	Local $vHotkeys = _JSON_Get($g_oUtils_AppConfig, "hotkeys")
	If @error Or $vHotkeys = '' Then
		Local $oHotkeys = ObjCreate("Scripting.Dictionary")
		_JSON_addChangeDelete($g_oUtils_AppConfig, "hotkeys", $oHotkeys)
		$bModified = True
	EndIf

	; Проверка секции tray
	Local $vTray = _JSON_Get($g_oUtils_AppConfig, "tray")
	If @error Or $vTray = '' Then
		Local $oTray = ObjCreate("Scripting.Dictionary")
		$oTray.Item("enabled") = False
		$oTray.Item("tooltip") = $g_sUtils_AppName
		$oTray.Item("show_notifications") = True
		_JSON_addChangeDelete($g_oUtils_AppConfig, "tray", $oTray)
		$bModified = True
	EndIf

	If $bModified Then
		_Utils_Config_Save()
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг валидирован и обновлён", 3)
	Else
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг валиден", 3)
	EndIf

	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Backup
; Описание: Создание резервной копии конфига
; Параметры: Нет
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Backup()
; ===============================================================================
Func _Utils_Config_Backup()
	If Not FileExists($g_sUtils_ConfigPath) Then
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Нечего бэкапить, файл не существует", 1)
		Return True
	EndIf

	Local $sBackupDir = @ScriptDir & "\config\backup"
	If Not FileExists($sBackupDir) Then
		DirCreate($sBackupDir)
	EndIf

	Local $sTimestamp = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC
	Local $sBackupPath = $sBackupDir & "\app_config_" & $sTimestamp & ".json"
	
	If FileExists($sBackupPath) Then
		If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Backup с таким timestamp уже существует, пропускаю", 1)
		Return True
	EndIf

	FileCopy($g_sUtils_ConfigPath, $sBackupPath, 1)

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Backup создан: " & $sBackupPath, 1)

	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Restore
; Описание: Восстановление конфига из backup
; Параметры:
;   $iBackupIndex - индекс backup (0 = последний, 1 = предпоследний и т.д.)
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Restore(0) - восстановить последний backup
; ===============================================================================
Func _Utils_Config_Restore($iBackupIndex = 0)
	Local $sBackupDir = @ScriptDir & "\config\backup"
	If Not FileExists($sBackupDir) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Папка backup не найдена", 2)
		Return SetError(1, 0, False)
	EndIf

	Local $aBackups = _FileListToArray($sBackupDir, "app_config_*.json", 1)
	If Not IsArray($aBackups) Or $aBackups[0] = 0 Then
		_Logger_Write("[Utils_Config] ОШИБКА: Backup файлы не найдены", 2)
		Return SetError(2, 0, False)
	EndIf

	If $iBackupIndex >= $aBackups[0] Then
		_Logger_Write("[Utils_Config] ОШИБКА: Неверный индекс backup", 2)
		Return SetError(3, 0, False)
	EndIf

	_ArraySort($aBackups, 1) ; Сортировка по убыванию
	Local $sBackupFile = $sBackupDir & "\" & $aBackups[$iBackupIndex + 1]

	FileCopy($sBackupFile, $g_sUtils_ConfigPath, 1)
	_Utils_Config_Load()

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг восстановлен из: " & $sBackupFile, 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Export
; Описание: Экспорт конфига в другой файл
; Параметры:
;   $sFilePath - путь к файлу для экспорта
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Export("D:\my_config.json")
; ===============================================================================
Func _Utils_Config_Export($sFilePath)
	If Not IsMap($g_oUtils_AppConfig) And Not IsObj($g_oUtils_AppConfig) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Конфиг не инициализирован", 2)
		Return SetError(1, 0, False)
	EndIf

	Local $sJSON = _JSON_Generate($g_oUtils_AppConfig)
	Local $hFile = FileOpen($sFilePath, 2)
	If $hFile = -1 Then
		_Logger_Write("[Utils_Config] ОШИБКА: Не удалось открыть файл для экспорта", 2)
		Return SetError(2, 0, False)
	EndIf

	FileWrite($hFile, $sJSON)
	FileClose($hFile)

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг экспортирован в: " & $sFilePath, 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Utils_Config_Import
; Описание: Импорт конфига из файла
; Параметры:
;   $sFilePath - путь к файлу для импорта
; Возврат: True при успехе, False при ошибке
; Пример: _Utils_Config_Import("D:\my_config.json")
; ===============================================================================
Func _Utils_Config_Import($sFilePath)
	If Not FileExists($sFilePath) Then
		_Logger_Write("[Utils_Config] ОШИБКА: Файл для импорта не найден: " & $sFilePath, 2)
		Return SetError(1, 0, False)
	EndIf

	; Создание backup текущего конфига
	If FileExists($g_sUtils_ConfigPath) Then
		_Utils_Config_Backup()
	EndIf

	FileCopy($sFilePath, $g_sUtils_ConfigPath, 1)
	_Utils_Config_Load()

	If $g_bUtils_DebugMode Then _Logger_Write("[Utils_Config] Конфиг импортирован из: " & $sFilePath, 3)
	Return True
EndFunc
