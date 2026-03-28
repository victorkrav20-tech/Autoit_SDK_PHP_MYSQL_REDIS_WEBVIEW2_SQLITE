# DevTools Protocol Integration - WebView2 Library

## Версия: 2.2.0
**Дата:** 26.02.2026

---

## 📋 Содержание

1. [Обзор](#обзор)
2. [Архитектура](#архитектура)
3. [Типы сообщений](#типы-сообщений)
4. [Формат данных](#формат-данных)
5. [Интеграция в AutoIt](#интеграция-в-autoit)
6. [Примеры использования](#примеры-использования)
7. [Отладка DLL](#отладка-dll)
8. [Troubleshooting](#troubleshooting)

---

## Обзор

DevTools Protocol позволяет перехватывать JavaScript ошибки и console сообщения напрямую из Chrome DevTools Protocol, минуя ограничения CORS и получая точные номера строк и файлов.

### Что работает:
- ✅ Перехват `console.log`, `console.error`, `console.warn`, `console.info`
- ✅ Перехват JavaScript exceptions с полным stack trace
- ✅ Определение файла и строки ошибки
- ✅ Работа через единый канал `RaiseMessage` (JSON формат)

### Преимущества перед JS-уровнем:
- Нет ограничений CORS (файл и строка всегда определяются)
- Перехват на уровне браузера (до обработки JS)
- Полный stack trace для exceptions
- Надёжный JSON парсинг через Newtonsoft.Json

---

## Архитектура

```
Chrome DevTools Protocol
         ↓
WebViewManager.cs (подписка на события)
         ↓
OnConsoleAPICalled / OnRuntimeExceptionThrown
         ↓
JsonParser (Newtonsoft.Json) - парсинг
         ↓
RaiseMessage (JSON формат)
         ↓
Bridge_OnMessageReceived (AutoIt)
         ↓
Парсинг и обработка в AutoIt
```

### Компоненты DLL:

1. **WebViewManager.cs**
   - `RegisterEvents()` - подписка на DevTools Protocol
   - `OnConsoleAPICalled()` - обработчик console сообщений
   - `OnRuntimeExceptionThrown()` - обработчик JavaScript exceptions

2. **WebViewBridge.cs**
   - `RaiseMessage()` - отправка сообщений в AutoIt через COM

3. **JsonParser.cs**
   - Надёжный парсинг JSON через Newtonsoft.Json
   - Извлечение вложенных значений по пути (например, `args[0].value`)

---

## Типы сообщений

### 1. Console Messages (DEVTOOLS_CONSOLE)

Отправляется при вызове `console.log()`, `console.error()`, `console.warn()`, `console.info()`

**Формат JSON:**
```json
{
  "type": "DEVTOOLS_CONSOLE",
  "level": "log|error|warn|info",
  "message": "текст сообщения",
  "source": "имя_файла.js",
  "line": 123,
  "column": 45
}
```

**Пример:**
```json
{
  "type": "DEVTOOLS_CONSOLE",
  "level": "error",
  "message": "Test error message",
  "source": "app.js",
  "line": 149,
  "column": 24
}
```

### 2. JavaScript Exceptions (DEVTOOLS_EXCEPTION)

Отправляется при возникновении JavaScript ошибки (throw, ReferenceError, TypeError и т.д.)

**Формат JSON:**
```json
{
  "type": "DEVTOOLS_EXCEPTION",
  "message": "полный текст ошибки",
  "source": "имя_файла.js",
  "line": 123,
  "column": 45,
  "stackTrace": "{\"callFrames\":[...]}"
}
```

**Пример:**
```json
{
  "type": "DEVTOOLS_EXCEPTION",
  "message": "ReferenceError: undefinedVariable is not defined\\n    at http://127.0.0.1/app.js:149:24",
  "source": "app.js",
  "line": 306,
  "column": 16,
  "stackTrace": "{\"callFrames\":[{\"lineNumber\":148,\"url\":\"http://127.0.0.1/app.js\"}]}"
}
```

---

## Формат данных

### Парсинг в C# (WebViewManager.cs)

DevTools Protocol отправляет сложный JSON. Используем `JsonParser` для извлечения:

```csharp
JsonParser parser = new JsonParser();
parser.Parse(json);

// Извлечение значений
string type = parser.GetTokenValue("type");                    // "log", "error", "warn"
string message = parser.GetTokenValue("args[0].value");        // Текст сообщения
string url = parser.GetTokenValue("stackTrace.callFrames[0].url");
string line = parser.GetTokenValue("stackTrace.callFrames[0].lineNumber");
```

### Отправка в AutoIt

Формируем JSON и отправляем через `RaiseMessage`:

```csharp
string devToolsJson = $"{{\"type\":\"DEVTOOLS_CONSOLE\",\"level\":\"{type}\",\"message\":\"{escapedMessage}\",\"source\":\"{fileName}\",\"line\":{line},\"column\":{column}}}";
_bridge.RaiseMessage(devToolsJson);
```

**Важно:** Экранируем спецсимволы (`\`, `"`, `\n`, `\r`) перед отправкой!

---

## Интеграция в AutoIt

### Шаг 1: Подписка на Bridge события

```autoit
; Получаем Bridge объект
$oBridge = $oManager.GetBridge()

; Подписываемся на события
$oBridgeEvents = ObjEvent($oBridge, "Bridge_", "IBridgeEvents")
```

### Шаг 2: Обработчик сообщений

```autoit
Func Bridge_OnMessageReceived($sMessage)
    ; Проверяем тип сообщения
    If StringInStr($sMessage, '"type":"DEVTOOLS_CONSOLE"') Then
        _HandleDevToolsConsole($sMessage)
        Return
    EndIf
    
    If StringInStr($sMessage, '"type":"DEVTOOLS_EXCEPTION"') Then
        _HandleDevToolsException($sMessage)
        Return
    EndIf
    
    ; Обычные сообщения
    ConsoleWrite("[Bridge] " & $sMessage & @CRLF)
EndFunc
```

### Шаг 3: Парсинг JSON

```autoit
Func _HandleDevToolsConsole($sJson)
    Local $sLevel = _JsonExtract($sJson, "level")
    Local $sMessage = _JsonExtract($sJson, "message")
    Local $sSource = _JsonExtract($sJson, "source")
    Local $iLine = Int(_JsonExtract($sJson, "line"))
    Local $iColumn = Int(_JsonExtract($sJson, "column"))
    
    ; Логируем или обрабатываем
    ConsoleWrite("[DevTools Console] " & $sLevel & ": " & $sMessage & @CRLF)
    ConsoleWrite("  at " & $sSource & ":" & $iLine & ":" & $iColumn & @CRLF)
EndFunc

Func _HandleDevToolsException($sJson)
    Local $sMessage = _JsonExtract($sJson, "message")
    Local $sSource = _JsonExtract($sJson, "source")
    Local $iLine = Int(_JsonExtract($sJson, "line"))
    Local $iColumn = Int(_JsonExtract($sJson, "column"))
    Local $sStack = _JsonExtract($sJson, "stackTrace")
    
    ; Логируем ошибку
    ConsoleWrite("[DevTools Exception] " & $sMessage & @CRLF)
    ConsoleWrite("  at " & $sSource & ":" & $iLine & ":" & $iColumn & @CRLF)
    ConsoleWrite("  Stack: " & $sStack & @CRLF)
EndFunc

; Простой JSON парсер (regex)
Func _JsonExtract($sJson, $sKey)
    ; Для строковых значений
    Local $sPattern = '"' & $sKey & '"\s*:\s*"([^"]*)"'
    Local $aMatch = StringRegExp($sJson, $sPattern, 1)
    If @error = 0 And IsArray($aMatch) Then
        Return $aMatch[0]
    EndIf
    
    ; Для числовых значений
    $sPattern = '"' & $sKey & '"\s*:\s*(\d+)'
    $aMatch = StringRegExp($sJson, $sPattern, 1)
    If @error = 0 And IsArray($aMatch) Then
        Return $aMatch[0]
    EndIf
    
    Return ""
EndFunc
```

---

## Примеры использования

### Пример 1: Логирование всех console сообщений

```autoit
Func Bridge_OnMessageReceived($sMessage)
    If StringInStr($sMessage, '"type":"DEVTOOLS_CONSOLE"') Then
        Local $sLevel = _JsonExtract($sMessage, "level")
        Local $sMsg = _JsonExtract($sMessage, "message")
        Local $sSource = _JsonExtract($sMessage, "source")
        Local $iLine = Int(_JsonExtract($sMessage, "line"))
        
        ; Форматированный вывод
        ConsoleWrite("[" & StringUpper($sLevel) & "] " & $sMsg & " (" & $sSource & ":" & $iLine & ")" & @CRLF)
    EndIf
EndFunc
```

### Пример 2: Фильтрация только ошибок

```autoit
Func Bridge_OnMessageReceived($sMessage)
    If StringInStr($sMessage, '"type":"DEVTOOLS_CONSOLE"') Then
        Local $sLevel = _JsonExtract($sMessage, "level")
        
        ; Обрабатываем только error и warn
        If $sLevel = "error" Or $sLevel = "warn" Then
            Local $sMsg = _JsonExtract($sMessage, "message")
            Local $sSource = _JsonExtract($sMessage, "source")
            Local $iLine = Int(_JsonExtract($sMessage, "line"))
            
            _LogError($sLevel, $sMsg, $sSource, $iLine)
        EndIf
    EndIf
    
    If StringInStr($sMessage, '"type":"DEVTOOLS_EXCEPTION"') Then
        Local $sMsg = _JsonExtract($sMessage, "message")
        Local $sSource = _JsonExtract($sMessage, "source")
        Local $iLine = Int(_JsonExtract($sMessage, "line"))
        
        _LogError("exception", $sMsg, $sSource, $iLine)
    EndIf
EndFunc
```

### Пример 3: Запись в файл лога

```autoit
Global $hLogFile = FileOpen("errors.log", 1) ; Append mode

Func Bridge_OnMessageReceived($sMessage)
    If StringInStr($sMessage, '"type":"DEVTOOLS_EXCEPTION"') Then
        Local $sMsg = _JsonExtract($sMessage, "message")
        Local $sSource = _JsonExtract($sMessage, "source")
        Local $iLine = Int(_JsonExtract($sMessage, "line"))
        
        Local $sLogEntry = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
        $sLogEntry &= " [ERROR] " & $sMsg & " at " & $sSource & ":" & $iLine & @CRLF
        
        FileWrite($hLogFile, $sLogEntry)
        FileFlush($hLogFile)
    EndIf
EndFunc
```

---

## Отладка DLL

### Просмотр Debug логов из C#

DLL использует `Debug.WriteLine()` для отладочных сообщений. Чтобы их увидеть:

#### Способ 1: DebugView (рекомендуется)

1. Скачать [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) от Sysinternals
2. Запустить DebugView.exe от администратора
3. Capture → Capture Global Win32
4. Запустить AutoIt скрипт
5. В DebugView увидите все `Debug.WriteLine()` из DLL

**Пример вывода:**
```
[12345] >>> OnConsoleAPICalled CALLED <<<
[12345] Raw JSON: {"args":[{"type":"string","value":"Test"}],...}
[12345] Parsed: type=log, message=Test, file=app.js, line=123
[12345] >>> Sending via RaiseMessage: DEVTOOLS_CONSOLE (JSON) <<<
```

#### Способ 2: Visual Studio Output Window

1. Открыть проект DLL в Visual Studio
2. Debug → Attach to Process
3. Найти процесс AutoIt3.exe или ваше приложение
4. View → Output (Ctrl+Alt+O)
5. В Output window увидите Debug сообщения

#### Способ 3: Отправка через RaiseMessage

Для критичных debug сообщений можно отправлять через `RaiseMessage`:

```csharp
_bridge.RaiseMessage($"DEBUG: OnConsoleAPICalled - type={type}, message={message}");
```

В AutoIt:
```autoit
Func Bridge_OnMessageReceived($sMessage)
    If StringLeft($sMessage, 7) = "DEBUG: " Then
        ConsoleWrite($sMessage & @CRLF)
        Return
    EndIf
    ; ... остальная обработка
EndFunc
```

### Включение RAW JSON вывода

Для отладки парсинга можно временно включить вывод сырого JSON:

**В WebViewManager.cs:**
```csharp
// После парсинга добавить:
string rawJsonPreview = json.Length > 500 ? json.Substring(0, 500) + "..." : json;
_bridge.RaiseMessage($"DEBUG_RAW_CONSOLE: {rawJsonPreview}");
```

**В AutoIt:**
```autoit
Func Bridge_OnMessageReceived($sMessage)
    If StringLeft($sMessage, 18) = "DEBUG_RAW_CONSOLE:" Then
        ConsoleWrite("=== RAW JSON ===" & @CRLF)
        ConsoleWrite(StringTrimLeft($sMessage, 18) & @CRLF)
        ConsoleWrite("================" & @CRLF)
        Return
    EndIf
    ; ... остальная обработка
EndFunc
```

---

## Troubleshooting

### Проблема: Сообщения не приходят

**Проверка:**
1. Убедитесь, что подписались на Bridge события:
   ```autoit
   $oBridgeEvents = ObjEvent($oBridge, "Bridge_", "IBridgeEvents")
   ```

2. Проверьте, что DevTools Protocol инициализирован (в DebugView должно быть):
   ```
   DEVTOOLS_PROTOCOL_INITIALIZED
   ```

3. Проверьте, что `Bridge_OnMessageReceived` вызывается:
   ```autoit
   Func Bridge_OnMessageReceived($sMessage)
       ConsoleWrite("Received: " & $sMessage & @CRLF) ; Debug
       ; ...
   EndFunc
   ```

### Проблема: Неправильный level (всегда "log")

**Причина:** Парсинг извлекает `type` из `args[0].type` вместо верхнего уровня JSON.

**Решение:** Используйте `JsonParser` с путём `"type"` (без префикса):
```csharp
string type = parser.GetTokenValue("type"); // Верхний уровень JSON
```

### Проблема: Пустые message или source

**Причина:** Неправильный путь в `GetTokenValue()` или экранирование.

**Решение:**
1. Проверьте RAW JSON (включите debug вывод)
2. Убедитесь в правильности пути:
   - `args[0].value` - для message
   - `stackTrace.callFrames[0].url` - для source

### Проблема: Stack trace обрезан

**Причина:** Stack trace содержит символы `\n`, которые нужно экранировать.

**Решение:** Используйте экранирование перед отправкой:
```csharp
string escapedStack = stackTrace.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r");
```

### Проблема: COM ошибки при подписке

**Причина:** GUID интерфейса изменился, но DLL не перерегистрирована.

**Решение:**
1. Запустить `libs/WebView2/bin/Unregister.au3`
2. Перекомпилировать DLL
3. Запустить `libs/WebView2/bin/Register.au3`

---

## Следующие шаги

### Интеграция в полную библиотеку

1. **Добавить в WebView2_Engine_Bridge.au3:**
   - Функции `_WebView2_DevTools_OnConsole()` и `_WebView2_DevTools_OnException()`
   - Callback механизм для пользовательских обработчиков

2. **Добавить в WebView2_Engine_Events.au3:**
   - Регистрацию DevTools обработчиков
   - Диспетчеризацию событий

3. **Создать примеры:**
   - Логирование в файл
   - Отображение в GUI
   - Фильтрация по уровню

4. **Документация:**
   - Обновить README.md библиотеки
   - Добавить примеры использования
   - Создать FAQ

---

## Версионирование

- **v2.2.0** (26.02.2026) - DevTools Protocol Integration
  - Добавлена подписка на `Runtime.consoleAPICalled` и `Runtime.exceptionThrown`
  - Использование JsonParser для надёжного парсинга
  - Передача через единый канал `RaiseMessage` в JSON формате
  - Поддержка всех уровней console (log, error, warn, info)
  - Полный stack trace для JavaScript exceptions

---

## Контакты и поддержка

При возникновении проблем:
1. Проверьте DebugView для debug логов из DLL
2. Включите RAW JSON вывод для отладки парсинга
3. Проверьте, что DLL перерегистрирована после изменений
4. Убедитесь, что подписка на Bridge события выполнена корректно

**Тестовый скрипт:** `apps/WebView2_Test/Test_DevTools_Direct.au3`
