# WebView2 Engine Library

Модульная библиотека для работы с Microsoft Edge WebView2 в AutoIt. Предоставляет полный набор инструментов для создания современных GUI приложений с HTML/CSS/JavaScript интерфейсом.

## Архитектура

Библиотека разделена на 6 независимых модулей:

```
WebView2_Engine_Core.au3        - Базовый движок (COM объекты, инициализация)
WebView2_Engine_Events.au3      - Система событий (AutoIt ↔ JavaScript)
WebView2_Engine_Bridge.au3      - Двусторонняя связь и пушинг данных
WebView2_Engine_GUI.au3          - Управление окнами и GUI
WebView2_Engine_Navigation.au3   - Навигация и загрузка страниц
WebView2_Engine_Injection.au3    - Инъекция CSS/JS скриптов
```

## Быстрый старт

### Минимальный пример

```autoit
#include "libs\WebView2\WebView2_Engine_Core.au3"
#include "libs\WebView2\WebView2_Engine_GUI.au3"
#include "libs\WebView2\WebView2_Engine_Navigation.au3"

; Создание инстанса
$hInstance = _WebView2_Core_CreateInstance()

; Создание COM объекта
_WebView2_Core_CreateManager($hInstance)

; Создание GUI окна
_WebView2_GUI_Create($hInstance, "My App", 800, 600)

; Инициализация WebView2
$hGUI = _WebView2_GUI_GetHandle($hInstance)
_WebView2_Core_InitializeWebView($hInstance, $hGUI, 0, 0, 800, 600)

; Загрузка страницы
_WebView2_Nav_LoadLocal("gui\index.html", True, $hInstance)

; Показ окна
_WebView2_GUI_Show($hInstance)

; Главный цикл
While 1
    Sleep(100)
WEnd
```

## Модули

### 1. Core (WebView2_Engine_Core.au3)

Базовый модуль для работы с COM объектом WebView2.

**Основные функции:**
- `_WebView2_Core_CreateInstance()` - Создание инстанса
- `_WebView2_Core_CreateManager()` - Создание COM объекта
- `_WebView2_Core_InitializeWebView()` - Инициализация WebView2
- `_WebView2_Core_ExecuteScript()` - Выполнение JavaScript
- `_WebView2_Core_GetBridge()` - Получение Bridge объекта
- `_WebView2_Core_Cleanup()` - Очистка ресурсов

**Всего функций:** 17

### 2. Events (WebView2_Engine_Events.au3)

Система событий для двусторонней связи AutoIt ↔ JavaScript.

**Основные функции:**
- `_WebView2_Events_SendToJS()` - Отправка данных в JavaScript
- `_WebView2_Events_SetOnMessageReceived()` - Callback для сообщений от JS
- `_WebView2_Events_RegisterMessageHandler()` - Типизированный обработчик
- `_WebView2_Events_WaitForReady()` - Ожидание готовности WebView2
- `_WebView2_Events_SetDebugMode()` - Включение отладки

**Всего функций:** 13

### 3. Bridge (WebView2_Engine_Bridge.au3)

Упрощённый API для двусторонней связи с автоматической инъекцией engine.js.

**Функции пушинга (AutoIt → JS):**
- `_WebView2_Bridge_UpdateElement()` - Обновление текста элемента
- `_WebView2_Bridge_UpdateData()` - Универсальная для массивов/JSON
- `_WebView2_Bridge_SetHTML()` - Установка HTML содержимого
- `_WebView2_Bridge_SetClass()` - Изменение CSS класса
- `_WebView2_Bridge_ShowElement()` / `HideElement()` - Показ/скрытие
- `_WebView2_Bridge_CallJS()` - Вызов JS функции
- `_WebView2_Bridge_Notify()` - Отправка уведомления

**Функции обработки (JS → AutoIt):**
- `_WebView2_Bridge_On()` - Регистрация обработчика событий
- `_WebView2_Bridge_Send()` - Отправка произвольного события

**Всего функций:** 14

📖 **Подробная документация:** [README_Bridge.md](README_Bridge.md)

### 4. GUI (WebView2_Engine_GUI.au3)

Управление GUI окнами и обработка системных событий.

**Основные функции:**
- `_WebView2_GUI_Create()` - Создание окна
- `_WebView2_GUI_Show()` / `Hide()` - Показ/скрытие окна
- `_WebView2_GUI_SetPosition()` - Изменение позиции
- `_WebView2_GUI_SetSize()` - Изменение размера
- `_WebView2_GUI_GetHandle()` - Получение handle окна
- `_WebView2_GUI_RegisterWMHandlers()` - Регистрация WM обработчиков

**Всего функций:** 12

### 5. Navigation (WebView2_Engine_Navigation.au3)

Навигация и загрузка страниц (локальные файлы, URL, HTML).

**Основные функции:**
- `_WebView2_Nav_Load()` - Универсальная загрузка (авто-определение типа)
- `_WebView2_Nav_LoadLocal()` - Загрузка локального файла
- `_WebView2_Nav_LoadExternal()` - Загрузка внешнего URL
- `_WebView2_Nav_LoadHTML()` - Загрузка HTML строки
- `_WebView2_Nav_Reload()` - Перезагрузка страницы
- `_WebView2_Nav_GoBack()` / `GoForward()` - Навигация назад/вперёд
- `_WebView2_Nav_GetCurrentURL()` - Получение текущего URL

**Всего функций:** 11

### 6. Injection (WebView2_Engine_Injection.au3)

Инъекция CSS/JS скриптов и preload механизм.

**Основные функции:**
- `_WebView2_Injection_InjectCSS()` - Инъекция CSS кода
- `_WebView2_Injection_InjectCSSFile()` - Инъекция CSS файла
- `_WebView2_Injection_InjectJS()` - Инъекция JavaScript кода
- `_WebView2_Injection_InjectJSFile()` - Инъекция JS файла
- `_WebView2_Injection_AddPreloadScript()` - Добавление preload скрипта
- `_WebView2_Injection_Initialize()` - Инициализация системы инъекций

**Всего функций:** 17

## Зависимости

```autoit
#include "libs\Utils\Utils.au3"      ; Утилиты (логирование, файлы)
#include "libs\json\JSON.au3"        ; JSON парсинг/генерация
#include <GUIConstantsEx.au3>        ; GUI константы (только для GUI модуля)
#include <WindowsConstants.au3>      ; WM константы (только для GUI модуля)
```

## Системные требования

- AutoIt 3.3.14.0+
- Microsoft Edge WebView2 Runtime
- NetWebView2.Manager COM объект (DLL)

## Производительность

- **Пушинг данных:** ~63 обновления/сек
- **CPU в idle:** 0%
- **Батчинг:** Автоматический через `requestAnimationFrame`
- **Энергоэффективность:** Проверка изменений перед обновлением DOM

## Примеры использования

### Пример 1: Пушинг данных (массивы, JSON)

```autoit
#include "libs\WebView2\WebView2_Engine_Bridge.au3"

; Инициализация Bridge
_WebView2_Bridge_Initialize($hInstance, @ScriptDir & "\gui")

; Пушинг массива 1D
Local $aData[3] = ["Apple", "Banana", "Cherry"]
_WebView2_Bridge_UpdateData("fruits", $aData, $hInstance)

; Пушинг массива 2D
Local $aTable[2][3] = [["A1", "B1", "C1"], ["A2", "B2", "C2"]]
_WebView2_Bridge_UpdateData("table", $aTable, $hInstance)

; Пушинг JSON объекта
Local $oData = _JSON_Parse('{"name":"John","age":30}')
_WebView2_Bridge_UpdateData("user", $oData, $hInstance)
```

### Пример 2: Обработка событий JS → AutoIt

```autoit
; Регистрация обработчика
_WebView2_Bridge_On("button_click", "OnButtonClick", $hInstance)

Func OnButtonClick($vJson, $hInstance)
    Local $sText = $vJson["payload"]["text"]
    ConsoleWrite("Button clicked: " & $sText & @CRLF)
EndFunc
```

### Пример 3: Инъекция скриптов

```autoit
#include "libs\WebView2\WebView2_Engine_Injection.au3"

; Инъекция CSS
_WebView2_Injection_InjectCSS("body { background: #f0f0f0; }", $hInstance)

; Инъекция JS файла
_WebView2_Injection_InjectJSFile("scripts\custom.js", $hInstance)
```

## Отладка

Включение debug режима для каждого модуля:

```autoit
Global $g_bDebug_WebView2_Core = True
Global $g_bDebug_WebView2_Events = True
Global $g_bDebug_WebView2_GUI = True
Global $g_bDebug_WebView2_Injection = True
Global $g_bDebug_WebView2_Navigation = True
```

## Лицензия

Внутренний проект. Все права защищены.

## История версий

- **2.1.0** - Добавлена универсальная функция `_WebView2_Bridge_UpdateData()` для массивов/JSON
- **2.0.0** - Модульная архитектура, разделение на 6 файлов
- **1.0.0** - Первая версия (монолитный файл)
