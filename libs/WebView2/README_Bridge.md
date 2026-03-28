# 🌉 WebView2 Bridge - Двусторонняя связь AutoIt ↔ JavaScript

**Версия:** 2.1.0  
**Дата:** 23.02.2026  
**Статус:** Production Ready ✅

---

## 📋 СОДЕРЖАНИЕ

1. [Что такое Bridge](#что-такое-bridge)
2. [Быстрый старт](#быстрый-старт)
3. [Функции пушинга (AutoIt → JS)](#функции-пушинга-autoit--js)
4. [Обработка событий (JS → AutoIt)](#обработка-событий-js--autoit)
5. [Типы данных](#типы-данных)
6. [Производительность](#производительность)
7. [Примеры использования](#примеры-использования)

---

## 🎯 ЧТО ТАКОЕ BRIDGE

**Bridge** - это упрощённый API для двусторонней связи между AutoIt и JavaScript в WebView2.

### Возможности:
- ✅ **Пушинг данных** AutoIt → JavaScript (обновление UI в реальном времени)
- ✅ **Обработка событий** JavaScript → AutoIt (клики, формы, пользовательские события)
- ✅ **Поддержка всех типов данных** (строки, числа, массивы 1D/2D, JSON объекты)
- ✅ **Автоматические подтверждения** (каждое обновление подтверждается)
- ✅ **Энергоэффективность** (батчинг обновлений, 0% CPU в idle)
- ✅ **Автоматическая инъекция** engine.js (не нужно подключать вручную)

---

## 🚀 БЫСТРЫЙ СТАРТ

### 1. Инициализация Bridge (AutoIt)

```autoit
#include "..\..\libs\SDK_Init.au3"

; Инициализация SDK и WebView2
_SDK_Init("MyApp", True, 1, 3, True)
_SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

; Создание GUI
_WebView2_GUI_Create(0, "My Application", 1200, 800)
_WebView2_Events_WaitForReady(0, 10000)

; Инициализация Bridge
_WebView2_Bridge_Initialize(0, @ScriptDir & "\gui")

; Регистрация обработчика событий от JS
_WebView2_Bridge_On("button_click", "_HandleButtonClick", 0)

; Загрузка страницы
_WebView2_Nav_Load("index.html", False, 0)
_WebView2_GUI_Show()

; Основной цикл
While 1
    Sleep(1)
WEnd

; Обработчик события от JavaScript
Func _HandleButtonClick($vJson)
    Local $sButtonId = $vJson["payload"]["id"]
    _Logger_Write("Кнопка нажата: " & $sButtonId, 1)
EndFunc
```

### 2. Отправка данных в JavaScript (AutoIt)

```autoit
; Простые типы
_WebView2_Bridge_UpdateElement("temp_value", "25.5°C", 0)

; Массивы и JSON (универсальная функция)
Local $aData[5] = [10, 20, 30, 40, 50]
_WebView2_Bridge_UpdateData("chart_data", $aData, 0)
```

### 3. Отправка событий в AutoIt (JavaScript)

```javascript
// В вашем JS файле (index.js)
document.getElementById('myButton').addEventListener('click', function() {
    WebView2Engine.sendToAutoIt('button_click', {
        id: 'myButton',
        timestamp: Date.now()
    });
});
```

---

## 📤 ФУНКЦИИ ПУШИНГА (AutoIt → JS)

### 1. UpdateElement - Обновление текста элемента

```autoit
_WebView2_Bridge_UpdateElement($sElementId, $vValue, $hInstance = 0)
```

**Параметры:**
- `$sElementId` - ID элемента на странице
- `$vValue` - новое значение (string/number)
- `$hInstance` - ID инстанса WebView2 (по умолчанию 0)

**Пример:**
```autoit
_WebView2_Bridge_UpdateElement("temp_value", "25.5°C", 0)
_WebView2_Bridge_UpdateElement("counter", 42, 0)
```

---

### 2. UpdateData - Универсальное обновление (НОВОЕ!)

```autoit
_WebView2_Bridge_UpdateData($sElementId, $vData, $hInstance = 0)
```

**Поддерживает:**
- ✅ Строки и числа
- ✅ Массивы 1D: `[10, 20, 30]`
- ✅ Массивы 2D: `[["A", "B"], ["C", "D"]]`
- ✅ JSON объекты: `'{"temp": 25.5, "status": "ok"}'`
- ✅ Смешанные массивы: `["Sensor-01", 25.5, "Active"]`

**Примеры:**
```autoit
; 1D массив
Local $aData[5] = [10, 20, 30, 40, 50]
_WebView2_Bridge_UpdateData("chart_data", $aData, 0)

; 2D массив (таблица)
Local $aTable[3][3]
$aTable[0][0] = "Name"
$aTable[0][1] = "Age"
$aTable[0][2] = "City"
$aTable[1][0] = "Alice"
$aTable[1][1] = 25
$aTable[1][2] = "Moscow"
$aTable[2][0] = "Bob"
$aTable[2][1] = 30
$aTable[2][2] = "London"
_WebView2_Bridge_UpdateData("table_data", $aTable, 0)

; JSON объект
Local $sJSON = '{"temperature": 25.5, "pressure": 1013, "status": "ok"}'
_WebView2_Bridge_UpdateData("sensor_data", $sJSON, 0)
```

---

### 3. SetHTML - Установка HTML содержимого

```autoit
_WebView2_Bridge_SetHTML($sElementId, $sHTML, $hInstance = 0)
```

**Пример:**
```autoit
_WebView2_Bridge_SetHTML("content", "<b>Bold</b> <i>Italic</i>", 0)
```

---

### 4. SetClass - Установка CSS класса

```autoit
_WebView2_Bridge_SetClass($sElementId, $sClassName, $hInstance = 0)
```

**Пример:**
```autoit
_WebView2_Bridge_SetClass("status", "active", 0)
_WebView2_Bridge_SetClass("status", "inactive", 0)
```

---

### 5. ShowElement / HideElement - Показать/Скрыть элемент

```autoit
_WebView2_Bridge_ShowElement($sElementId, $hInstance = 0)
_WebView2_Bridge_HideElement($sElementId, $hInstance = 0)
```

**Пример:**
```autoit
_WebView2_Bridge_HideElement("warning", 0)
Sleep(2000)
_WebView2_Bridge_ShowElement("warning", 0)
```

---

### 6. CallJS - Вызов JavaScript функции

```autoit
_WebView2_Bridge_CallJS($sFunctionName, $aParams = "", $hInstance = 0)
```

**Пример:**
```autoit
; Вызов функции без параметров
_WebView2_Bridge_CallJS("refreshChart", "", 0)

; Вызов функции с параметрами
Local $aParams[2] = ["temperature", 25.5]
_WebView2_Bridge_CallJS("updateSensor", $aParams, 0)
```

---

### 7. Notify - Отправка уведомления

```autoit
_WebView2_Bridge_Notify($sType, $sMessage, $hInstance = 0)
```

**Типы:** `info`, `warning`, `error`, `success`

**Пример:**
```autoit
_WebView2_Bridge_Notify("success", "Данные сохранены", 0)
_WebView2_Bridge_Notify("error", "Ошибка подключения", 0)
```

---

## 📥 ОБРАБОТКА СОБЫТИЙ (JS → AutoIt)

### 1. Регистрация обработчика (AutoIt)

```autoit
_WebView2_Bridge_On($sType, $sCallback, $hInstance = 0)
```

**Параметры:**
- `$sType` - тип события (например "button_click", "form_submit")
- `$sCallback` - имя функции-обработчика
- `$hInstance` - ID инстанса WebView2

**Пример:**
```autoit
; Регистрация обработчика
_WebView2_Bridge_On("button_click", "_HandleButtonClick", 0)
_WebView2_Bridge_On("form_submit", "_HandleFormSubmit", 0)

; Функция-обработчик
Func _HandleButtonClick($vJson)
    Local $sButtonId = $vJson["payload"]["id"]
    Local $sText = $vJson["payload"]["text"]
    
    _Logger_Write("Кнопка: " & $sButtonId & ", Текст: " & $sText, 1)
EndFunc

Func _HandleFormSubmit($vJson)
    Local $sName = $vJson["payload"]["name"]
    Local $sEmail = $vJson["payload"]["email"]
    
    _Logger_Write("Форма: " & $sName & " (" & $sEmail & ")", 1)
EndFunc
```

---

### 2. Отправка события из JavaScript

```javascript
// Простое событие
WebView2Engine.sendToAutoIt('button_click', {
    id: 'saveButton',
    text: 'Save'
});

// Событие с данными формы
WebView2Engine.sendToAutoIt('form_submit', {
    name: document.getElementById('name').value,
    email: document.getElementById('email').value
});

// Событие с массивом
WebView2Engine.sendToAutoIt('chart_data', {
    values: [10, 20, 30, 40, 50],
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May']
});
```

---

## 📊 ТИПЫ ДАННЫХ

### AutoIt → JavaScript

| Тип данных | AutoIt | JavaScript | Функция |
|------------|--------|------------|---------|
| Строка | `"Hello"` | `"Hello"` | `UpdateElement` / `UpdateData` |
| Число | `25.5` | `25.5` | `UpdateElement` / `UpdateData` |
| Массив 1D | `[10, 20, 30]` | `[10, 20, 30]` | `UpdateData` |
| Массив 2D | `[["A","B"],["C","D"]]` | `[["A","B"],["C","D"]]` | `UpdateData` |
| JSON объект | `'{"temp":25.5}'` | `{temp: 25.5}` | `UpdateData` |

### JavaScript → AutoIt

| Тип данных | JavaScript | AutoIt | Доступ |
|------------|------------|--------|--------|
| Строка | `"Hello"` | `"Hello"` | `$vJson["payload"]["field"]` |
| Число | `42` | `42` | `$vJson["payload"]["field"]` |
| Массив | `[1,2,3]` | Массив | `$vJson["payload"]["field"]` |
| Объект | `{a:1, b:2}` | Dictionary | `$vJson["payload"]["field"]` |

---

## ⚡ ПРОИЗВОДИТЕЛЬНОСТЬ

### Энергоэффективность

**engine.js оптимизирован для минимальной нагрузки:**
- ✅ **0% CPU в режиме ожидания** (событийная модель, нет циклов)
- ✅ **Батчинг обновлений** (группировка в один кадр через `requestAnimationFrame`)
- ✅ **Проверка изменений** (пропускаем если значение не изменилось)
- ✅ **CSS анимации** (GPU ускорение вместо JavaScript)

### Тесты производительности

**Speed Test (100 обновлений):**
- Время: 1.6 секунды
- Скорость: ~63 обновления/сек
- Подтверждения: 100/100 получены
- CPU: Минимальная нагрузка

**Массовые обновления:**
- 1D массив (5 элементов): < 1 мс
- 2D массив (3x3): < 1 мс
- JSON объект (4 поля): < 1 мс

---

## 💡 ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ

### Пример 1: Датчик температуры в реальном времени

**AutoIt:**
```autoit
#include "..\..\libs\SDK_Init.au3"

_SDK_Init("TempMonitor", True, 1, 3, True)
_SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

_WebView2_GUI_Create(0, "Temperature Monitor", 800, 600)
_WebView2_Events_WaitForReady(0, 10000)
_WebView2_Bridge_Initialize(0, @ScriptDir & "\gui")

_WebView2_Nav_Load("index.html", False, 0)
_WebView2_GUI_Show()

; Таймер обновления
Global $hUpdateTimer = TimerInit()

While 1
    ; Обновляем каждую секунду
    If TimerDiff($hUpdateTimer) >= 1000 Then
        Local $fTemp = Random(20, 30, 2)  ; Случайная температура
        _WebView2_Bridge_UpdateElement("temp_value", Round($fTemp, 1) & "°C", 0)
        $hUpdateTimer = TimerInit()
    EndIf
    Sleep(1)
WEnd
```

**HTML (index.html):**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Temperature Monitor</title>
    <style>
        .temp-display {
            font-size: 48px;
            font-weight: bold;
            text-align: center;
            padding: 50px;
            transition: all 0.3s ease;
        }
        .temp-display.updated {
            transform: scale(1.1);
            color: #4CAF50;
        }
    </style>
</head>
<body>
    <div class="temp-display" id="temp_value">Waiting...</div>
    <script src="engine.js"></script>
</body>
</html>
```

---

### Пример 2: Таблица данных с обновлением

**AutoIt:**
```autoit
; Получаем данные из базы
Local $aData = _MySQL_Select("sensors", "*", "", "id ASC", 10)

; Отправляем в JavaScript
_WebView2_Bridge_UpdateData("table_data", $aData, 0)
```

**JavaScript:**
```javascript
WebView2Engine.on('update_data', function(data) {
    const elementId = data[0];
    const jsonData = JSON.parse(data[1]);
    
    if (elementId === 'table_data' && Array.isArray(jsonData)) {
        // Создаём таблицу
        let html = '<table><thead><tr>';
        
        // Заголовки (первая строка)
        jsonData[0].forEach(header => {
            html += `<th>${header}</th>`;
        });
        html += '</tr></thead><tbody>';
        
        // Данные (остальные строки)
        for (let i = 1; i < jsonData.length; i++) {
            html += '<tr>';
            jsonData[i].forEach(cell => {
                html += `<td>${cell}</td>`;
            });
            html += '</tr>';
        }
        html += '</tbody></table>';
        
        document.getElementById('table_data').innerHTML = html;
    }
});
```

---

### Пример 3: Форма с отправкой в AutoIt

**HTML:**
```html
<form id="myForm">
    <input type="text" id="name" placeholder="Name">
    <input type="email" id="email" placeholder="Email">
    <button type="submit">Submit</button>
</form>

<script src="engine.js"></script>
<script>
document.getElementById('myForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    WebView2Engine.sendToAutoIt('form_submit', {
        name: document.getElementById('name').value,
        email: document.getElementById('email').value
    });
});
</script>
```

**AutoIt:**
```autoit
_WebView2_Bridge_On("form_submit", "_HandleFormSubmit", 0)

Func _HandleFormSubmit($vJson)
    Local $sName = $vJson["payload"]["name"]
    Local $sEmail = $vJson["payload"]["email"]
    
    ; Сохраняем в базу
    _MySQL_Insert("users", "name,email", $sName & "," & $sEmail)
    
    ; Уведомляем пользователя
    _WebView2_Bridge_Notify("success", "Данные сохранены!", 0)
EndFunc
```

---

### Пример 4: График в реальном времени

**AutoIt:**
```autoit
; Собираем данные за последние 10 секунд
Local $aValues[10]
For $i = 0 To 9
    $aValues[$i] = Random(10, 50)
Next

; Отправляем в JavaScript
_WebView2_Bridge_UpdateData("chart_values", $aValues, 0)
```

**JavaScript (с Chart.js):**
```javascript
let myChart = null;

WebView2Engine.on('update_data', function(data) {
    const elementId = data[0];
    const jsonData = JSON.parse(data[1]);
    
    if (elementId === 'chart_values' && Array.isArray(jsonData)) {
        if (!myChart) {
            // Создаём график
            const ctx = document.getElementById('myChart').getContext('2d');
            myChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: jsonData.map((_, i) => i),
                    datasets: [{
                        label: 'Temperature',
                        data: jsonData,
                        borderColor: 'rgb(75, 192, 192)',
                        tension: 0.1
                    }]
                }
            });
        } else {
            // Обновляем данные
            myChart.data.datasets[0].data = jsonData;
            myChart.update();
        }
    }
});
```

---

## 🔧 ВСТРОЕННЫЕ ОБРАБОТЧИКИ

Bridge автоматически регистрирует обработчики для:

### 1. Console.log → AutoIt
Все `console.log/warn/error/info` автоматически отправляются в AutoIt логи.

### 2. JavaScript ошибки → AutoIt
Все ошибки JavaScript автоматически логируются в AutoIt.

### 3. Engine Ready
Событие `engine_ready` отправляется когда engine.js готов к работе.

### 4. Push Confirmed
Каждое обновление автоматически подтверждается событием `push_confirmed`.

---

## 📝 ЗАМЕТКИ

1. **Автоматическая инъекция:** engine.js автоматически доступен на всех страницах, не нужно подключать вручную.

2. **Подтверждения:** Каждое обновление через Bridge автоматически подтверждается событием `push_confirmed`.

3. **JSON сериализация:** Массивы и объекты автоматически преобразуются в JSON через `_JSON_GenerateCompact()`.

4. **Производительность:** Батчинг обновлений работает автоматически, не нужно ничего настраивать.

5. **Обратная совместимость:** Старые функции `_WebView2_Events_SendToJS()` продолжают работать.

---

## 🎯 СЛЕДУЮЩИЕ ШАГИ

1. Изучите примеры в `apps/WebView2_Test/Test_12_Push.au3`
2. Посмотрите `apps/WebView2_Test/gui/test12.html` и `test12.js`
3. Создайте свой проект на основе шаблона
4. Используйте `_WebView2_Bridge_UpdateData()` для всех типов данных

---

**Версия:** 2.1.0 | **Дата:** 23.02.2026 | **Статус:** Production Ready ✅
