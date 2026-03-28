# 🔄 Двусторонняя связь JS ↔ AutoIt

## 📋 Содержание
1. [Архитектура системы](#архитектура-системы)
2. [JavaScript сторона](#javascript-сторона)
3. [AutoIt сторона](#autoit-сторона)
4. [Протокол обмена данными](#протокол-обмена-данными)
5. [RequestHub API](#requesthub-api)
6. [Notifications API](#notifications-api)
7. [Tooltips API](#tooltips-api)
8. [Примеры использования](#примеры-использования)

---

## 🏗️ Архитектура системы

### Общая схема:
```
┌─────────────────────────────────────────────────────────────┐
│                      JavaScript (WebView2)                   │
├─────────────────────────────────────────────────────────────┤
│  RequestHub  →  engine.js  →  WebView2 Bridge  →  AutoIt   │
│     ↓                                              ↓         │
│  Promise API                              Response Handler   │
│     ↓                                              ↓         │
│  Timeout (3s)                            JSON Response       │
│     ↓                                              ↓         │
│  resolve() / reject()  ←─────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### Компоненты:

**JavaScript:**
- `request-hub.js` - система запросов с Promise API
- `engine.js` - WebView2 движок, обработка сообщений
- `notifications.js` - обёртка для Toastify JS
- `tooltips.js` - обёртка для Tippy.js

**AutoIt:**
- `Inet_Reader_Init_Response.au3` - обработчик запросов
- `WebView2_Engine_Bridge.au3` - Bridge API
- `WebView2_Engine_Events.au3` - система событий

---

## 💻 JavaScript сторона

### 1. RequestHub - Система запросов

**Файл:** `js/utils/request-hub.js`

**Принцип работы:**
1. Создаёт уникальный ID для каждого запроса
2. Сохраняет Promise (resolve/reject) в Map
3. Устанавливает таймер (по умолчанию 3 сек)
4. Отправляет запрос в AutoIt через `engine.js`
5. Ждёт ответ или таймаут
6. Вызывает resolve() при успехе или reject() при ошибке

**Структура запроса (JS → AutoIt):**
```javascript
{
    requestId: 1,              // Уникальный ID
    requestType: 'get_app_info', // Тип запроса
    requestPayload: {...}      // Данные запроса (опционально)
}
```

**Структура ответа (AutoIt → JS):**
```javascript
{
    requestId: 1,              // ID запроса
    status: 'success',         // 'success' или 'error'
    success: true,             // boolean
    payload: {...},            // Данные ответа
    error: 'текст ошибки'      // Только при ошибке
}
```

**API:**
```javascript
// Отправка запроса
const response = await window.RequestHub.send(type, payload, timeout);

// Отмена запроса
window.RequestHub.cancel(requestId);

// Отмена всех запросов
window.RequestHub.cancelAll();

// Статистика
const stats = window.RequestHub.getStats();
// { total: 10, success: 8, timeout: 1, error: 1, pending: 0, successRate: '80%' }

// Список ожидающих запросов
const pending = window.RequestHub.getPendingRequests();

// Сброс статистики
window.RequestHub.resetStats();
```

### 2. Engine.js - WebView2 движок

**Файл:** `engine.js`

**Функция отправки:**
```javascript
WebView2Engine.sendToAutoIt(type, data)
```

**Что происходит:**
1. Формирует JSON: `{ type: type, payload: data, windowId: X, timestamp: Y }`
2. Вызывает: `window.chrome.webview.postMessage(JSON.stringify(message))`
3. Сообщение попадает в AutoIt

**Функция получения:**
```javascript
WebView2Engine.on(type, callback)
```

**Регистрирует обработчик для входящих сообщений определённого типа.**

### 3. Notifications - Уведомления

**Файл:** `js/utils/notifications.js`  
**Библиотека:** Toastify JS (6.7KB)

**API:**
```javascript
// Простые уведомления
notifySuccess('Сообщение');
notifyError('Ошибка');
notifyWarning('Предупреждение');
notifyInfo('Информация');

// С настройками
notifySuccess('Сообщение', {
    duration: 5000,           // Длительность (мс), -1 = бесконечно
    gravity: 'bottom',        // 'top' или 'bottom'
    position: 'center',       // 'left', 'center', 'right'
    close: false,             // Кнопка закрытия
    stopOnFocus: true,        // Пауза при наведении
    avatar: 'icon.png',       // Иконка
    destination: 'https://...', // Ссылка при клике
    onClick: () => {},        // Callback при клике
    offset: { x: 50, y: 10 }, // Отступы
    style: {                  // Кастомные стили
        background: '#ff0000'
    }
});

// Глобальные настройки
window.Notifications.configure({
    duration: 5000,
    gravity: 'bottom',
    position: 'left'
});
```

### 4. Tooltips - Подсказки

**Файл:** `js/utils/tooltips.js`  
**Библиотека:** Tippy.js (25KB) + Popper.js (20KB)

**API:**

**Автоматическая инициализация (HTML):**
```html
<button data-tooltip="Текст подсказки">Кнопка</button>
<button data-tooltip="Текст" data-tooltip-placement="bottom">Кнопка</button>
<button data-tooltip="Текст" data-tooltip-theme="dark">Кнопка</button>
```

**Программное создание:**
```javascript
createTooltip('#myButton', {
    content: 'Подсказка',
    placement: 'top',         // 'top', 'bottom', 'left', 'right', 'auto'
    theme: 'light',           // 'light', 'dark', 'light-border', 'translucent'
    animation: 'fade',        // 'fade', 'shift-away', 'scale', 'perspective'
    arrow: true,              // Показывать стрелку
    delay: [200, 0],          // [показ, скрытие] в мс
    duration: [300, 250],     // [анимация показа, скрытия]
    interactive: true,        // Можно взаимодействовать
    trigger: 'click',         // 'mouseenter', 'focus', 'click', 'manual'
    maxWidth: 500,            // Максимальная ширина
    allowHTML: true,          // Разрешить HTML
    hideOnClick: true         // Скрывать при клике
});

// Управление
showTooltip('#myButton');
hideTooltip('#myButton');
destroyTooltip('#myButton');
window.Tooltips.setContent('#myButton', 'Новый текст');
```

---

## 🔧 AutoIt сторона

### 1. Обработчик запросов

**Файл:** `Inet_Reader_Init_Response.au3`

**Функция:** `_Inet_Reader_OnResponse($vJson, $hInstance)`

**Что происходит:**
1. Получает распарсенный JSON от Bridge
2. Извлекает `payload` из `$vJson`
3. Читает `requestId`, `requestType`, `requestPayload`
4. Обрабатывает запрос в зависимости от типа
5. Формирует ответ (Map)
6. Преобразует Map в JSON через `_JSON_Generate()`
7. Отправляет через `_WebView2_Bridge_Send()`

**Структура входящего $vJson:**
```autoit
$vJson["type"] = "response"
$vJson["payload"] = Map с полями:
    ["requestId"] = 1
    ["requestType"] = "get_app_info"
    ["requestPayload"] = данные (может быть Null)
$vJson["windowId"] = 1
$vJson["timestamp"] = 1234567890
```

**Пример обработчика:**
```autoit
Func _Inet_Reader_OnResponse($vJson, $hInstance = 0)
    ; Извлекаем payload
    Local $oPayload = $vJson["payload"]
    Local $iRequestId = $oPayload["requestId"]
    Local $sType = $oPayload["requestType"]
    Local $oRequestPayload = $oPayload["requestPayload"]
    
    ; Обрабатываем запрос
    Local $oResponse = Null
    Local $bSuccess = True
    Local $sError = ""
    
    Switch $sType
        Case "get_app_info"
            $oResponse = _GetAppInfo()
        Case "test_request"
            $oResponse = "Test OK"
        Case Else
            $bSuccess = False
            $sError = "Неизвестный тип: " & $sType
    EndSwitch
    
    ; Формируем ответ
    Local $mResponse[]
    $mResponse["requestId"] = $iRequestId
    $mResponse["status"] = $bSuccess ? "success" : "error"
    $mResponse["success"] = $bSuccess
    $mResponse["payload"] = $oResponse
    If Not $bSuccess Then $mResponse["error"] = $sError
    
    ; Преобразуем в JSON и отправляем
    Local $sResponseJSON = _JSON_Generate($mResponse)
    _WebView2_Bridge_Send("response", $sResponseJSON, $hInstance)
    
    Return True
EndFunc
```

### 2. Регистрация обработчика

**Файл:** `Inet_Reader_Init.au3` или `Inet_Reader_Main.au3`

```autoit
; Инициализация Bridge
_WebView2_Bridge_Initialize($hInstance, $sGuiPath)

; Регистрация обработчика для типа "response"
_WebView2_Bridge_On("response", "_Inet_Reader_OnResponse", $hInstance)
```

### 3. WebView2 Bridge API

**Файл:** `libs/WebView2/WebView2_Engine_Bridge.au3`

**Функции:**

```autoit
; Инициализация Bridge
_WebView2_Bridge_Initialize($hInstance, $sGuiPath, $bSkipEngineInject = False)

; Регистрация обработчика
_WebView2_Bridge_On($sType, $sCallback, $hInstance = 0)

; Отправка сообщения в JS
_WebView2_Bridge_Send($sType, $vData = "", $hInstance = 0)
```

### 4. WebView2 Events API

**Файл:** `libs/WebView2/WebView2_Engine_Events.au3`

**Функция отправки:**
```autoit
_WebView2_Events_SendToJS($sEventType, $vData = "", $hInstance = 0)
```

**Что происходит:**
1. Формирует JSON: `{"type":"...", "payload":...}`
2. Если `$vData` это Map → преобразует через `_JSON_Generate()`
3. Если `$vData` это строка начинающаяся с `{` или `[` → вставляет как есть
4. Вызывает JS: `window.handleAutoItMessage(JSON)`

**Функция диспетчеризации:**
```autoit
_WebView2_Events_DispatchEvent($sMessage, $hInstance = 0)
```

**Что происходит:**
1. Парсит JSON: `$vJson = _JSON_Parse($sMessage)`
2. Извлекает `$sType = $vJson["type"]`
3. Ищет обработчик в `$g_aWebView2_Bridge_Handlers`
4. Фильтрует по `type` И `instanceId`
5. Вызывает: `Call($sCallback, $vJson, $hInstance)`

---

## 📡 Протокол обмена данными

### Поток данных JS → AutoIt:

```
1. JS: RequestHub.send('get_app_info')
   ↓
2. JS: Создаёт requestId=1, сохраняет Promise
   ↓
3. JS: WebView2Engine.sendToAutoIt('response', {requestId:1, requestType:'get_app_info'})
   ↓
4. JS: engine.js формирует: {type:'response', payload:{requestId:1, requestType:'get_app_info'}, windowId:1}
   ↓
5. JS: window.chrome.webview.postMessage(JSON.stringify(...))
   ↓
6. AutoIt: _WebView2_Events_Manager_OnMessageReceived($sMessage, $hInstance)
   ↓
7. AutoIt: _WebView2_Events_DispatchEvent($sMessage, $hInstance)
   ↓
8. AutoIt: $vJson = _JSON_Parse($sMessage)
   ↓
9. AutoIt: Ищет обработчик для type="response"
   ↓
10. AutoIt: Call("_Inet_Reader_OnResponse", $vJson, $hInstance)
```

### Поток данных AutoIt → JS:

```
1. AutoIt: $mResponse["requestId"] = 1, $mResponse["payload"] = {...}
   ↓
2. AutoIt: $sJSON = _JSON_Generate($mResponse)
   ↓
3. AutoIt: _WebView2_Bridge_Send("response", $sJSON, $hInstance)
   ↓
4. AutoIt: _WebView2_Events_SendToJS("response", $sJSON, $hInstance)
   ↓
5. AutoIt: Формирует: {"type":"response", "payload":{...}}
   ↓
6. AutoIt: ExecuteScript: window.handleAutoItMessage(JSON)
   ↓
7. JS: engine.js.handleAutoItMessage(messageData)
   ↓
8. JS: message = JSON.parse(messageData)
   ↓
9. JS: Ищет callback для type="response"
   ↓
10. JS: callbacks['response'](message.payload)
   ↓
11. JS: RequestHub.handleResponse(data)
   ↓
12. JS: request.resolve(data.payload) или request.reject(error)
```

---

## 🎯 RequestHub API

### Отправка запроса:
```javascript
try {
    const response = await window.RequestHub.send(
        'get_app_info',  // Тип запроса
        { param: 'value' }, // Данные (опционально)
        5000             // Таймаут в мс (опционально, по умолчанию 3000)
    );
    console.log(response); // Данные из payload
} catch (error) {
    console.error(error.message); // "Timeout: AutoIt не ответил за 3000ms"
}
```

### Типы запросов (по умолчанию):
- `test_request` - тестовый запрос
- `get_app_info` - информация о приложении
- `get_counters_status` - статус счётчиков
- `show_window` - показать окно
- `hide_window` - скрыть окно

### Добавление своего типа запроса:

**AutoIt (Inet_Reader_Init_Response.au3):**
```autoit
Switch $sType
    Case "my_custom_request"
        ; Обработка запроса
        Local $mData[]
        $mData["result"] = "OK"
        $mData["value"] = 123
        $oResponse = $mData
EndSwitch
```

**JavaScript:**
```javascript
const response = await window.RequestHub.send('my_custom_request', {
    param1: 'value1'
});
console.log(response.result); // "OK"
console.log(response.value);  // 123
```

---

## 📢 Notifications API

### Базовое использование:
```javascript
notifySuccess('Операция выполнена!');
notifyError('Произошла ошибка!');
notifyWarning('Внимание!');
notifyInfo('Информация');
```

### Расширенные настройки:
```javascript
notifySuccess('Сохранено!', {
    duration: 5000,
    gravity: 'bottom',
    position: 'center',
    onClick: () => console.log('Clicked!')
});
```

### Все опции:
- `duration` - длительность (мс), -1 = бесконечно
- `gravity` - 'top' или 'bottom'
- `position` - 'left', 'center', 'right'
- `close` - показывать кнопку закрытия
- `stopOnFocus` - пауза при наведении
- `avatar` - путь к иконке
- `destination` - URL для перехода при клике
- `newWindow` - открывать в новом окне
- `onClick` - callback при клике
- `offset` - {x, y} смещение
- `style` - объект с CSS стилями

---

## 💬 Tooltips API

### HTML (автоинициализация):
```html
<button data-tooltip="Подсказка">Кнопка</button>
<button data-tooltip="Текст" data-tooltip-placement="bottom">Кнопка</button>
<button data-tooltip="Текст" data-tooltip-theme="dark">Кнопка</button>
```

### JavaScript:
```javascript
createTooltip('#myButton', {
    content: 'Подсказка',
    placement: 'top',
    theme: 'light'
});
```

### Все опции:
- `content` - текст подсказки
- `placement` - 'top', 'bottom', 'left', 'right', 'auto'
- `theme` - 'light', 'dark', 'light-border', 'translucent'
- `animation` - 'fade', 'shift-away', 'scale', 'perspective'
- `arrow` - показывать стрелку
- `delay` - [показ, скрытие] в мс
- `duration` - [анимация показа, скрытия]
- `interactive` - можно взаимодействовать
- `trigger` - 'mouseenter', 'focus', 'click', 'manual'
- `maxWidth` - максимальная ширина
- `allowHTML` - разрешить HTML
- `hideOnClick` - скрывать при клике

---

## 💡 Примеры использования

### Пример 1: Запрос с уведомлением
```javascript
async function loadData() {
    try {
        const data = await window.RequestHub.send('get_app_info');
        notifySuccess('Данные загружены!');
        console.log(data);
    } catch (error) {
        notifyError('Ошибка загрузки: ' + error.message);
    }
}
```

### Пример 2: Запрос с индикатором
```javascript
const indicator = new StatusIndicator('#loadButton');

async function loadData() {
    indicator.loading('Загрузка...');
    
    try {
        const data = await window.RequestHub.send('get_app_info');
        indicator.success('Готово!');
        notifySuccess('Данные загружены!');
    } catch (error) {
        indicator.error('Ошибка!');
        notifyError('Ошибка: ' + error.message);
    }
}
```

### Пример 3: Кнопка с tooltip и действием
```html
<button id="saveBtn" data-tooltip="Сохранить данные">💾 Сохранить</button>

<script>
document.getElementById('saveBtn').addEventListener('click', async () => {
    try {
        await window.RequestHub.send('save_data', { data: {...} });
        notifySuccess('Сохранено!');
    } catch (error) {
        notifyError('Ошибка сохранения');
    }
});
</script>
```

---

## 🔒 Надёжность и ограничения

### ✅ Сильные стороны:
- Таймауты (3 сек по умолчанию)
- Promise API (async/await)
- Уникальные ID запросов
- Обработка ошибок на всех уровнях
- Статистика запросов
- Типизированные обработчики

### ⚠️ Ограничения:
- Нет автоматических повторных попыток
- Нет персистентности (при перезагрузке страницы очередь теряется)
- Нет приоритетов запросов
- Нет ограничения размера очереди

### 💪 Рекомендации для production:
1. Добавить retry механизм (1-2 попытки)
2. Ограничить очередь (max 10-20 запросов)
3. Добавить приоритеты (critical, normal, low)
4. Логировать все запросы/ответы
5. Мониторить successRate

---

## 📚 Дополнительные ресурсы

- `README_WIDGETS.md` - документация по виджетам
- `test-utils-page.js` - примеры использования
- [Toastify JS](https://github.com/apvarun/toastify-js)
- [Tippy.js](https://atomiks.github.io/tippyjs/)

---

**Версия:** 1.0.0  
**Дата:** 2026-03-06  
**Автор:** Kiro AI Assistant
