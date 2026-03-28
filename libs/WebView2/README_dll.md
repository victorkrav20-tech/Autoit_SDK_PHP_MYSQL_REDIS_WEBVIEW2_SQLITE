# 🌐 WebView2 для AutoIt - Полная документация для разработки

## 📋 О документе
**AI-Ready документация** для быстрой разработки приложений с WebView2 в AutoIt SDK.  
Всё необходимое для написания кода без чтения других файлов.

---

## 🚀 Быстрый старт

**ВАЖНО:** Примеры ниже используют событийную модель SDK (OnEventMode).  
Для работы WebView2 требуется WM обработчик или событийная система для обработки COM событий.

### Минимальный код (событийная модель)
```autoit
#AutoIt3Wrapper_UseX64=y
#include <GUIConstantsEx.au3>

Global $g_oManager, $g_oEvtManager, $g_hGUI

; Обработчик COM ошибок (ОБЯЗАТЕЛЬНО!)
Global $g_oCOMError = ObjEvent("AutoIt.Error", "_COM_ErrorHandler")

; Событийная модель
Opt("GUIOnEventMode", 1)

; Создаём GUI
$g_hGUI = GUICreate("WebView2 App", 800, 600)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)

; Создаём COM объект
$g_oManager = ObjCreate("NetWebView2.Manager")
$g_oEvtManager = ObjEvent($g_oManager, "WebView_", "IWebViewEvents")

; Инициализируем
$g_oManager.Initialize($g_hGUI, "", 10, 10, 780, 580)

; Основной цикл (событийная модель)
While 1
    Sleep(10)
WEnd

; Обработчик закрытия
Func _OnExit()
    $g_oManager.Cleanup()
    Sleep(100)
    $g_oManager = 0
    $g_oEvtManager = 0
    Exit
EndFunc

; Обработчик событий WebView
Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "INIT_READY") Then
        $g_oManager.Navigate("https://example.com")
    EndIf
EndFunc

; Обработчик COM ошибок (НЕ прерывает выполнение)
Func _COM_ErrorHandler()
    ; Логируем но продолжаем работу
    Return
EndFunc
```

---

## ⚠️ КРИТИЧЕСКИЕ ПРАВИЛА

### 1. ВСЕГДА используйте обработчик COM ошибок
```autoit
Global $g_oCOMError = ObjEvent("AutoIt.Error", "_COM_ErrorHandler")

Func _COM_ErrorHandler()
    ; НЕ используйте SetError() - это прервёт выполнение
    ; Просто логируйте и возвращайтесь
    Return
EndFunc
```

### 2. Навигация ТОЛЬКО после INIT_READY
```autoit
Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "INIT_READY") Then
        ; Теперь можно навигировать
        $g_oManager.Navigate("https://example.com")
    EndIf
EndFunc
```

### 3. Корректное завершение
```autoit
$g_oManager.Cleanup()
Sleep(100)  ; Минимальная задержка
$g_oManager = 0
$g_oEvtManager = 0
```

### 4. Используйте событийную модель или WM обработчики
WebView2 работает через COM события. Для их обработки используйте:
- **OnEventMode** (рекомендуется для SDK)
- **WM обработчики** (GUIRegisterMsg)
- **Основной цикл** с минимальной задержкой Sleep(10)

---

## 📚 Полный список методов COM объекта

### Инициализация
- `Initialize(hGUI, sUserDataFolder, iX, iY, iWidth, iHeight)` - Инициализация WebView2
- `IsReady()` → Boolean - Проверка готовности
- `Cleanup()` - Освобождение ресурсов

### Навигация
- `Navigate(sUrl)` - Переход по URL
- `NavigateToString(sHtml)` - Загрузка HTML из строки
- `GoBack()` - Назад в истории
- `GoForward()` - Вперёд в истории
- `Reload()` - Перезагрузка
- `Stop()` - Остановка загрузки
- `GetSource()` → String - Текущий URL
- `GetDocumentTitle()` → String - Заголовок страницы
- `GetCanGoBack()` → Boolean - Можно ли назад
- `GetCanGoForward()` → Boolean - Можно ли вперёд

### JavaScript
- `ExecuteScript(sScript)` - Выполнение JS без возврата
- `ExecuteScriptWithResult(sScript)` - Выполнение JS с возвратом через событие `SCRIPT_RESULT|`
- `AddInitializationScript(sScript)` - Регистрация скрипта для каждой страницы

### CSS и стилизация
- `InjectCss(sCssCode)` - Внедрение CSS
- `ClearInjectedCss()` - Удаление CSS

### Получение данных (через события)
- `GetHtmlSource()` - HTML код → событие `HTML_SOURCE|`
- `GetInnerText()` - Текст страницы → событие `INNER_TEXT|`
- `GetSelectedText()` - Выделенный текст → событие `SELECTED_TEXT|`
- `CapturePreview(sFilePath, sFormat)` - Скриншот → событие `CAPTURE_SUCCESS|`

### Cookies
- `GetCookies(sChannelId)` - Получение cookies → событие `COOKIES_B64|channelId|data`
- `AddCookie(sName, sValue, sDomain, sPath)` - Добавление cookie
- `DeleteCookie(sName, sDomain, sPath)` - Удаление cookie
- `DeleteAllCookies()` - Удаление всех cookies

### Настройки
- `SetZoom(fFactor)` - Масштаб (1.0 = 100%)
- `ResetZoom()` - Сброс масштаба
- `SetMuted(bMuted)` - Вкл/выкл звук
- `IsMuted()` → Boolean - Проверка звука
- `SetUserAgent(sUserAgent)` - User-Agent
- `Resize(iWidth, iHeight)` - Изменение размера

### Очистка данных
- `ClearBrowserData()` - Очистка всех данных → событие `DATA_CLEARED`
- `ClearCache()` - Очистка только кеша

### Утилиты
- `EncodeURI(sValue)` → String - Кодирование URL
- `DecodeURI(sValue)` → String - Декодирование URL
- `EncodeB64(sValue)` → String - Base64 кодирование
- `DecodeB64(sValue)` → String - Base64 декодирование

---

## 📡 События (IWebViewEvents)

### Обработчики
```autoit
Func WebView_OnMessageReceived($sMessage)
    ; Универсальное событие для всех сообщений
EndFunc

Func WebView_OnNavigationCompleted($bSuccess, $iWebErrorStatus)
    ; Навигация завершена
EndFunc

Func WebView_OnTitleChanged($sTitle)
    ; Заголовок изменился
EndFunc

Func WebView_OnUrlChanged($sUrl)
    ; URL изменился
EndFunc
```

### Типы сообщений OnMessageReceived
- `INIT_READY` - WebView2 готов
- `NAV_STARTING|url` - Начало навигации
- `NAV_COMPLETED` - Навигация завершена
- `TITLE_CHANGED|title` - Заголовок изменился
- `SCRIPT_RESULT|result` - Результат ExecuteScriptWithResult
- `SCRIPT_ERROR|error` - Ошибка ExecuteScriptWithResult
- `HTML_SOURCE|html` - HTML код (GetHtmlSource)
- `SELECTED_TEXT|text` - Выделенный текст (GetSelectedText)
- `CAPTURE_SUCCESS|path` - Скриншот создан
- `DATA_CLEARED` - Данные очищены
- `COOKIES_B64|channelId|data` - Cookies получены
- `ERROR|message` - Ошибка

---

## 💡 Паттерны разработки

### Паттерн 1: Ожидание результата ExecuteScriptWithResult
```autoit
Global $g_sScriptResult = ""

Func _SafeExecuteScriptWithResult($sScript)
    $g_sScriptResult = ""
    $g_oManager.ExecuteScriptWithResult($sScript)
    
    ; Ждём результата через события (3 сек)
    Local $hTimer = TimerInit()
    While $g_sScriptResult = "" And TimerDiff($hTimer) < 3000
        Sleep(10)
    WEnd
    
    If StringLeft($g_sScriptResult, 6) = "ERROR:" Then
        Return ""
    EndIf
    
    Return $g_sScriptResult
EndFunc

Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "SCRIPT_RESULT|") Then
        $g_sScriptResult = StringTrimLeft($sMessage, StringLen("SCRIPT_RESULT|"))
    EndIf
    
    If StringInStr($sMessage, "SCRIPT_ERROR|") Then
        $g_sScriptResult = "ERROR:" & StringTrimLeft($sMessage, StringLen("SCRIPT_ERROR|"))
    EndIf
EndFunc
```

### Паттерн 2: Ожидание async событий (GetHtmlSource, GetSelectedText, etc.)
```autoit
Global $g_sTestResult = ""

; Запрос данных
$g_sTestResult = ""
$g_oManager.GetHtmlSource()

; Ожидание события (5 сек)
Local $hTimer = TimerInit()
While $g_sTestResult = "" And TimerDiff($hTimer) < 5000
    Sleep(10)
WEnd

; Обработка результата
If StringInStr($g_sTestResult, "HTML_SOURCE|") Then
    Local $sHtml = StringTrimLeft($g_sTestResult, StringLen("HTML_SOURCE|"))
    ; Используем HTML
EndIf

; Обработчик
Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "HTML_SOURCE|") Or _
       StringInStr($sMessage, "SELECTED_TEXT|") Or _
       StringInStr($sMessage, "CAPTURE_SUCCESS|") Then
        $g_sTestResult = $sMessage
    EndIf
EndFunc
```

### Паттерн 3: Инициализация с ожиданием INIT_READY
```autoit
Func _InitWebView()
    $g_oManager = ObjCreate("NetWebView2.Manager")
    If Not IsObj($g_oManager) Then Return False
    
    $g_oEvtManager = ObjEvent($g_oManager, "WebView_", "IWebViewEvents")
    If Not IsObj($g_oEvtManager) Then
        $g_oManager = 0
        Return False
    EndIf
    
    $g_oManager.Initialize($g_hGUI, "", 10, 10, 780, 580)
    
    ; Ждём INIT_READY (10 сек)
    Local $hTimer = TimerInit()
    While Not $g_bInitReady And TimerDiff($hTimer) < 10000
        Sleep(10)
    WEnd
    
    If Not $g_bInitReady Then Return False
    
    ; Дополнительная задержка после INIT_READY
    Sleep(100)
    
    Return True
EndFunc

; Глобальный флаг
Global $g_bInitReady = False

Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "INIT_READY") Then
        $g_bInitReady = True
    EndIf
EndFunc
```

### Паттерн 4: Очистка WebView между тестами
```autoit
Func _CleanupWebView()
    ; Сначала Cleanup у COM объекта
    If IsObj($g_oManager) Then
        $g_oManager.Cleanup()
        Sleep(100)  ; Минимальная задержка
    EndIf
    
    ; Освобождаем COM объекты
    $g_oEvtManager = 0
    $g_oManager = 0
    
    ; Сбрасываем флаги
    $g_bInitReady = False
    $g_sScriptResult = ""
    $g_sTestResult = ""
EndFunc
```
    $g_sTestResult = ""
EndFunc
```

---

## 🔧 Структура автотеста (для понимания)

### Глобальные переменные
```autoit
Global $g_hGUI = 0                  ; Хэндл GUI
Global $g_oManager = 0              ; COM объект WebView2
Global $g_oEvtManager = 0           ; Обработчик событий
Global $g_oCOMError                 ; Обработчик COM ошибок
Global $g_sScriptResult = ""        ; Результат ExecuteScriptWithResult
Global $g_sTestResult = ""          ; Результат async методов
Global $g_bInitReady = False        ; Флаг INIT_READY
Global $g_iTestTimeout = 10000      ; Таймаут теста (10 сек)
```

### Основные функции
- `_InitWebView()` - Инициализация WebView2 с ожиданием INIT_READY
- `_CleanupWebView()` - Очистка WebView (GUI остаётся)
- `_SafeExecuteScriptWithResult($sScript)` - Обёртка для ExecuteScriptWithResult
- `_COM_ErrorHandler()` - Обработчик COM ошибок

### Порядок выполнения теста
1. Создать GUI (один раз для всех тестов)
2. Инициализировать WebView через `_InitWebView()`
3. Дождаться INIT_READY (100ms дополнительно)
4. Выполнить тест
5. Очистить WebView через `_CleanupWebView()`
6. Повторить 2-5 для следующего теста
7. Удалить GUI в конце всех тестов

---

## 📝 Примеры использования

### Пример 1: Простая навигация
```autoit
Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "INIT_READY") Then
        $g_oManager.Navigate("https://www.google.com")
    EndIf
    
    If StringInStr($sMessage, "NAV_COMPLETED") Then
        ; Страница загружена
        Local $sTitle = $g_oManager.GetDocumentTitle()
        MsgBox(0, "Заголовок", $sTitle)
    EndIf
EndFunc
```

### Пример 2: Выполнение JavaScript
```autoit
Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "NAV_COMPLETED") Then
        ; Изменяем текст через JavaScript
        $g_oManager.ExecuteScript("document.body.innerHTML = '<h1>Hello from AutoIt!</h1>'")
        
        ; Получаем результат
        Local $sResult = _SafeExecuteScriptWithResult("document.title")
        ConsoleWrite("Title: " & $sResult & @CRLF)
    EndIf
EndFunc
```

### Пример 3: Внедрение CSS
```autoit
Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "NAV_COMPLETED") Then
        ; Меняем фон страницы
        Local $sCss = "body { background: linear-gradient(to right, #667eea, #764ba2); color: white; }"
        $g_oManager.InjectCss($sCss)
    EndIf
EndFunc
```

### Пример 4: Получение HTML
```autoit
Global $g_sHtmlResult = ""

Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "NAV_COMPLETED") Then
        $g_oManager.GetHtmlSource()
    EndIf
    
    If StringInStr($sMessage, "HTML_SOURCE|") Then
        $g_sHtmlResult = StringTrimLeft($sMessage, StringLen("HTML_SOURCE|"))
        ConsoleWrite("HTML: " & $g_sHtmlResult & @CRLF)
    EndIf
EndFunc
```

---

## ⚙️ Технические детали

### Требования
- AutoIt 3.3.16.1+ (x64)
- .NET Framework 4.8
- WebView2 Runtime 109.0.1518.140
- Windows 7 x64 / Windows 10+ x64

### Файлы библиотеки
- `bin/NetWebView2Lib.dll` - основная DLL
- `bin/Microsoft.Web.WebView2.Core.dll` - WebView2 SDK
- `bin/Microsoft.Web.WebView2.WinForms.dll` - WinForms обёртка
- `bin/WebView2Loader.dll` - загрузчик Runtime

### Регистрация COM
```cmd
regasm /codebase NetWebView2Lib.dll
```
Или используй `bin/Register_web2.au3`

---

## 🐛 Отладка и решение проблем

### Проблема: COM ошибка 0x80020009
**Причина:** Обращение к CoreWebView2 из неправильного потока  
**Решение:** Всегда используй обработчик COM ошибок

### Проблема: События не приходят
**Причина:** Нет обработки событий в основном цикле  
**Решение:** Используй событийную модель (OnEventMode) или WM обработчики

### Проблема: Таймаут INIT_READY
**Причина:** WebView2 Runtime не установлен или неправильная версия  
**Решение:** Установи Runtime 109.0.1518.140

### Проблема: ExecuteScriptWithResult не возвращает результат
**Причина:** Не обрабатывается событие SCRIPT_RESULT|  
**Решение:** Используй паттерн `_SafeExecuteScriptWithResult()`

---

## 📖 Дополнительные файлы

- `WebView2_AutoTest.au3` - Полный набор автотестов (17 тестов)
- `README_RUS.md` - Подробная документация на русском
- `examples/` - Примеры использования

---

**Версия:** 1.4.2  
**Совместимость:** Windows 7 x64 / Windows 10+ x64  
**Лицензия:** MIT  
**Последнее обновление:** 2026-02-19
