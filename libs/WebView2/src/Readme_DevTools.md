# 🔧 DevTools Protocol Integration - Console & Exception Tracking

**Версия:** 1.0  
**Дата:** 25.02.2026  
**Статус:** ✅ Реализовано и протестировано

---

## 📋 Описание

Интеграция Chrome DevTools Protocol (CDP) в WebView2 для перехвата всех JavaScript ошибок и console сообщений на уровне браузера, минуя ограничения CORS.

---

## 🎯 Проблема которую решает

### До внедрения:
- ❌ JavaScript ошибки показывали `unknown:0:0` из-за CORS политики
- ❌ Реальные runtime ошибки не перехватывались
- ❌ Требовались обёртки (try-catch, setTimeout wrapper) в JS коде
- ❌ Сторонние библиотеки не отдавали детали ошибок

### После внедрения:
- ✅ Все ошибки перехватываются с точным файлом и строкой
- ✅ Полный stack trace для каждой ошибки
- ✅ Обход CORS (перехват на уровне браузера)
- ✅ Работает для любого JS кода (включая сторонние библиотеки)
- ✅ Перехват всех console.log/error/warn/info вызовов

---

## 🏗️ Архитектура

```
JavaScript Error/Console
        ↓
Chrome DevTools Protocol (CDP)
        ↓
WebView2 CoreWebView2
        ↓
C# Event Handlers
        ↓
WebViewBridge COM Events
        ↓
AutoIt Event Handlers
```

---

## 📦 Изменения в DLL

### 1. WebViewBridge.cs

#### Новые COM события в IBridgeEvents:

```csharp
[DispId(2)]
void OnConsoleMessage(string level, string message, string source, int line, int column);

[DispId(3)]
void OnJavaScriptException(string message, string source, int line, int column, string stackTrace);
```

#### Новые методы в WebViewBridge:

```csharp
public void RaiseConsoleMessage(string level, string message, string source, int line, int column)
public void RaiseJavaScriptException(string message, string source, int line, int column, string stackTrace)
```

---

### 2. WebViewManager.cs

#### В методе RegisterEvents() добавлено:

```csharp
// Enable DevTools Protocol
_webView.CoreWebView2.CallDevToolsProtocolMethodAsync("Runtime.enable", "{}");
_webView.CoreWebView2.CallDevToolsProtocolMethodAsync("Console.enable", "{}");

// Subscribe to events
_webView.CoreWebView2.GetDevToolsProtocolEventReceiver("Runtime.exceptionThrown")
    .DevToolsProtocolEventReceived += OnRuntimeExceptionThrown;

_webView.CoreWebView2.GetDevToolsProtocolEventReceiver("Runtime.consoleAPICalled")
    .DevToolsProtocolEventReceived += OnConsoleAPICalled;
```

#### Новые обработчики событий:

**OnRuntimeExceptionThrown:**
- Перехватывает все JavaScript исключения
- Парсит JSON от DevTools Protocol
- Извлекает: message, url, line, column, stackTrace
- Отправляет в AutoIt через `_bridge.RaiseJavaScriptException()`

**OnConsoleAPICalled:**
- Перехватывает все console.* вызовы (log, error, warn, info)
- Парсит JSON от DevTools Protocol
- Извлекает: type, message, url, line, column
- Отправляет в AutoIt через `_bridge.RaiseConsoleMessage()`

#### Вспомогательные методы:

```csharp
private string ExtractJsonValue(string json, string key)
private int FindMatchingBrace(string json, int startIndex)
private int FindMatchingBracket(string json, int startIndex)
```

Простой JSON парсер для производительности (без зависимостей).

---

## 📊 Формат данных от DevTools Protocol

### Runtime.exceptionThrown

```json
{
  "exceptionDetails": {
    "text": "Uncaught ReferenceError: undefinedVariable is not defined",
    "url": "file:///D:/path/to/app.js",
    "lineNumber": 149,
    "columnNumber": 24,
    "stackTrace": {
      "callFrames": [
        {
          "functionName": "",
          "url": "file:///D:/path/to/app.js",
          "lineNumber": 149,
          "columnNumber": 24
        }
      ]
    }
  }
}
```

### Runtime.consoleAPICalled

```json
{
  "type": "error",
  "args": [
    {
      "type": "string",
      "value": "Error message"
    }
  ],
  "stackTrace": {
    "callFrames": [
      {
        "url": "file:///D:/path/to/app.js",
        "lineNumber": 150,
        "columnNumber": 12
      }
    ]
  }
}
```

---

## 🔌 Интеграция в AutoIt

### Шаг 1: Регистрация COM событий

В файле `WebView2_Engine_Events.au3` нужно добавить обработчики для новых COM событий:

```autoit
; В функции инициализации WebView2
$oWebView = ObjCreate("ScadaWebView2.Manager")

; Регистрация новых событий
ObjEvent($oWebView, "OnConsoleMessage_", "_WebView2_DevTools_")
ObjEvent($oWebView, "OnJavaScriptException_", "_WebView2_DevTools_")
```

### Шаг 2: Создание обработчиков событий

```autoit
; Обработчик console сообщений
Func _WebView2_DevTools_OnConsoleMessage($sLevel, $sMessage, $sSource, $iLine, $iColumn)
    ; $sLevel = "log", "error", "warn", "info"
    ; $sMessage = текст сообщения
    ; $sSource = имя файла (app.js)
    ; $iLine = номер строки
    ; $iColumn = номер колонки
    
    _Logger_Write("[DevTools Console " & $sLevel & "] " & $sMessage & " at " & $sSource & ":" & $iLine & ":" & $iColumn, 1)
EndFunc

; Обработчик JavaScript исключений
Func _WebView2_DevTools_OnJavaScriptException($sMessage, $sSource, $iLine, $iColumn, $sStackTrace)
    ; $sMessage = текст ошибки
    ; $sSource = имя файла (app.js)
    ; $iLine = номер строки
    ; $iColumn = номер колонки
    ; $sStackTrace = полный stack trace (JSON)
    
    _Logger_Write("=== JAVASCRIPT EXCEPTION (DevTools) ===", 2)
    _Logger_Write("[Message] " & $sMessage, 2)
    _Logger_Write("[File] " & $sSource & ":" & $iLine & ":" & $iColumn, 2)
    _Logger_Write("[Stack Trace]", 2)
    _Logger_Write($sStackTrace, 2)
    _Logger_Write("========================================", 2)
EndFunc
```

### Шаг 3: Диспетчеризация событий

Если используется система диспетчеризации (как в new_app1), добавить в `_WebView2_Bridge_On()`:

```autoit
; В WebView2_Engine_Bridge.au3
Func _WebView2_Bridge_On($sEventType, $sCallbackFunc, $iWindowID = 0)
    ; ... существующий код ...
    
    ; Добавить новые типы событий
    Case $sEventType = "devtools_console"
        ; Регистрация обработчика console
    Case $sEventType = "devtools_exception"
        ; Регистрация обработчика exception
EndFunc
```

---

## 🎯 Преимущества

### 1. Полная информация об ошибках
- ✅ Точное имя файла (не `unknown`)
- ✅ Точная строка и колонка (не `0:0`)
- ✅ Полный stack trace
- ✅ Тип ошибки (ReferenceError, TypeError, etc.)

### 2. Обход CORS
- ✅ Перехват на уровне браузера (до применения CORS)
- ✅ Работает с `file://` протоколом
- ✅ Не требует отключения CORS в настройках

### 3. Универсальность
- ✅ Работает для любого JS кода
- ✅ Перехватывает ошибки из сторонних библиотек
- ✅ Не требует модификации JS кода
- ✅ Не требует try-catch обёрток

### 4. Производительность
- ✅ Минимальный overhead (события только при ошибках)
- ✅ Простой JSON парсер (без зависимостей)
- ✅ Асинхронная обработка (не блокирует UI)

---

## 📝 Примеры использования

### Пример 1: Простая ошибка

**JavaScript:**
```javascript
const result = undefinedVariable + 10;
```

**AutoIt получит:**
```
Message: undefinedVariable is not defined
Source: app.js
Line: 149
Column: 24
Stack: ReferenceError: undefinedVariable is not defined
    at file:///D:/OSPanel/domains/localhost/apps/new_app1/gui/js/app.js:149:24
```

### Пример 2: Console.error

**JavaScript:**
```javascript
console.error("Database connection failed", { code: 500 });
```

**AutoIt получит:**
```
Level: error
Message: Database connection failed
Source: app.js
Line: 150
Column: 12
```

### Пример 3: Promise rejection

**JavaScript:**
```javascript
Promise.reject(new Error("API call failed"));
```

**AutoIt получит:**
```
Message: API call failed
Source: app.js
Line: 155
Column: 20
Stack: Error: API call failed
    at file:///D:/OSPanel/domains/localhost/apps/new_app1/gui/js/app.js:155:20
```

---

## 🔄 Совместимость

### Требования:
- ✅ WebView2 Runtime 109+ (Win7 совместимо)
- ✅ .NET Framework 4.8
- ✅ AutoIt 3.3.14+

### Протестировано:
- ✅ Windows 7 SP1
- ✅ Windows 10
- ✅ Windows 11

---

## 🐛 Отладка

### Проверка работы DevTools Protocol:

1. Добавить Debug.WriteLine в обработчики:
```csharp
Debug.WriteLine($"DevTools Exception: {message} at {fileName}:{line}:{column}");
```

2. Запустить через Visual Studio с отладчиком
3. Проверить Output окно на наличие сообщений

### Проверка COM событий в AutoIt:

```autoit
Func _WebView2_DevTools_OnJavaScriptException($sMessage, $sSource, $iLine, $iColumn, $sStackTrace)
    ConsoleWrite("!!! DevTools Exception: " & $sMessage & @CRLF)
    ; ... остальной код ...
EndFunc
```

---

## 📚 Ссылки

- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)
- [Runtime Domain](https://chromedevtools.github.io/devtools-protocol/tot/Runtime/)
- [Console Domain](https://chromedevtools.github.io/devtools-protocol/tot/Console/)
- [WebView2 API Reference](https://learn.microsoft.com/en-us/microsoft-edge/webview2/)

---

## ✅ Чеклист интеграции в AutoIt

- [ ] Прочитать этот документ полностью
- [ ] Добавить регистрацию COM событий в WebView2_Engine_Events.au3
- [ ] Создать обработчики `_WebView2_DevTools_OnConsoleMessage` и `_WebView2_DevTools_OnJavaScriptException`
- [ ] Добавить диспетчеризацию в `_WebView2_Bridge_On()` (если используется)
- [ ] Протестировать с реальной ошибкой в JavaScript
- [ ] Проверить логи AutoIt на наличие детальной информации
- [ ] Удалить старые JS обёртки для перехвата ошибок (если не нужны)

---

**Готово к интеграции в AutoIt!** 🚀
