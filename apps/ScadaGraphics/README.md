# NEW_APP1 - Эталонный шаблон SCADA-приложения

**Версия:** 1.0.0  
**Дата:** 24.02.2026  
**Статус:** ✅ Миграция на Web Components завершена, всё работает!

---

## 📂 СТРУКТУРА ПРОЕКТА

```
apps/new_app1/
├── gui/
│   ├── css/                    ✅ Создано
│   │   ├── theme.css          - Цветовая палитра
│   │   ├── buttons.css        - Типизированные кнопки
│   │   ├── inputs.css         - Поля ввода и формы
│   │   ├── tables.css         - Таблицы данных
│   │   ├── dropdowns.css      - Выпадающие списки
│   │   ├── texts.css          - Типографика
│   │   ├── header.css         - Стили шапки
│   │   └── app.css            - Специфические стили
│   ├── js/                     ✅ Создано
│   │   ├── header-component.js - Web Component шапки с навигацией
│   │   └── app.js             - Логика приложения
│   ├── pages/                  ✅ Создано (Web Components)
│   │   ├── page1-component.js - Мониторинг (HTML внутри JS)
│   │   ├── page2-component.js - Аналитика (HTML внутри JS)
│   │   └── page3-component.js - Настройки (HTML внутри JS)
│   ├── engine.js               ✅ Перемещён на уровень выше (специфика Bridge)
│   └── index.html              ✅ Создано
├── data/
│   └── config.json             ✅ Создано
├── new_app1.au3                ✅ Создано
└── README.md                   ✅ Этот файл
```

**Примечание:** `engine.js` находится в `gui/engine.js` (на уровень выше `js/`), так как это требование модуля Bridge для корректной работы.

---

## ✅ ЧТО СДЕЛАНО

### AutoIt (new_app1.au3)
- ✅ Инициализация SDK и WebView2
- ✅ Создание GUI (1200x700)
- ✅ Венгерская нотация с префиксом `ScadaGraphics`
- ✅ Инициализация Bridge (`_WebView2_Bridge_Initialize`)
- ✅ Регистрация обработчиков:
  - `_ScadaGraphics_OnPushConfirmed($vJson)` - подтверждения пушинга
  - `_ScadaGraphics_OnConsole($vJson)` - логи консоли JS
  - `_ScadaGraphics_OnJSError($vJson)` - ошибки JS
- ✅ Тестовый режим (3 секунды и выход)
- ✅ **Консоль JavaScript работает** - все логи видны в AutoIt

### HTML/CSS
- ✅ 8 модульных CSS файлов (theme, buttons, inputs, tables, dropdowns, texts, header, app)
- ✅ SCADA-стиль (тёмная тема, типизированные компоненты)
- ✅ Адаптивная структура с статус-баром

### JavaScript - Web Components
- ✅ **Миграция на Web Components завершена!**
- ✅ `engine.js` - перехват консоли и ошибок, отправка в AutoIt (перемещён в `gui/`)
- ✅ `header-component.js` - Web Component шапки с навигацией
- ✅ `page1-component.js` - Web Component страницы мониторинга (HTML внутри JS с подсветкой `/* html */`)
- ✅ `page2-component.js` - Web Component страницы аналитики (HTML внутри JS с подсветкой `/* html */`)
- ✅ `page3-component.js` - Web Component страницы настроек (HTML внутри JS с подсветкой `/* html */`)
- ✅ `app.js` - логика приложения, обработка датчиков
- ✅ **Навигация работает** - переключение между страницами без CORS ошибок
- ✅ **Нет CORS проблем** - всё загружается через `<script src="">`

### Архитектура
- ✅ **Модульность сохранена** - каждая страница в отдельном JS файле
- ✅ **HTML в JS с подсветкой** - используется `this.innerHTML = /* html */` для подсветки синтаксиса
- ✅ **Нативные Web Components** - без внешних библиотек
- ✅ **Событийная модель** - навигация через события кнопок

---

## 🎉 РЕШЕНИЕ ПРОБЛЕМЫ CORS

### Проблема (была):
- `XMLHttpRequest` и `fetch()` не работают с `file://` протоколом
- WebView2 блокирует загрузку HTML файлов из соображений безопасности
- Модульная архитектура (header.html + pages/*.html) не загружалась

### Решение (реализовано):
✅ **Web Components с HTML внутри JS**
- Каждая страница = Web Component (Custom Element)
- HTML код внутри JS с подсветкой синтаксиса: `this.innerHTML = /* html */`
- Загрузка через `<script src="">` - нет CORS
- Модульность сохранена - каждая страница в отдельном файле

### Преимущества:
- ✅ Нет CORS ошибок
- ✅ Модульная структура (каждая страница в отдельном JS файле)
- ✅ Подсветка HTML синтаксиса в редакторе (через `/* html */`)
- ✅ Нативная поддержка браузера (без библиотек)
- ✅ Легко масштабировать (добавить новую страницу = создать новый компонент)
- ✅ Инкапсуляция логики внутри компонента

---

## 📚 ПРИМЕРЫ КОДА

### header-component.js
```javascript
class HeaderComponent extends HTMLElement {
    connectedCallback() {
        this.innerHTML = /* html */`
            <div class="app-header">
                <div class="nav-bar">
                    <button class="nav-btn active" data-page="page1">📊 Мониторинг</button>
                    <button class="nav-btn" data-page="page2">📈 Аналитика</button>
                    <button class="nav-btn" data-page="page3">⚙️ Настройки</button>
                </div>
            </div>
        `;
        
        // Навешиваем обработчики
        this.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.switchPage(btn.dataset.page);
            });
        });
    }
    
    switchPage(pageId) {
        // Скрываем все страницы
        document.querySelectorAll('[id^="page"]').forEach(page => {
            page.style.display = 'none';
        });
        
        // Показываем выбранную
        document.getElementById(pageId).style.display = 'block';
        
        // Обновляем активную кнопку
        this.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.remove('active');
            if (btn.dataset.page === pageId) {
                btn.classList.add('active');
            }
        });
        
        // Уведомляем AutoIt
        if (window.chrome && window.chrome.webview) {
            window.chrome.webview.postMessage(`NAV_CHANGED|${pageId}`);
        }
    }
}

customElements.define('app-header', HeaderComponent);
```

### index.html
```html
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>new_app1 - SCADA Template</title>
    
    <!-- CSS -->
    <link rel="stylesheet" href="css/theme.css">
    <link rel="stylesheet" href="css/buttons.css">
    <link rel="stylesheet" href="css/inputs.css">
    <link rel="stylesheet" href="css/tables.css">
    <link rel="stylesheet" href="css/dropdowns.css">
    <link rel="stylesheet" href="css/texts.css">
    <link rel="stylesheet" href="css/header.css">
    <link rel="stylesheet" href="css/app.css">
</head>
<body>
    <div class="app-container">
        <!-- Шапка как Web Component -->
        <app-header></app-header>
        
        <!-- Контент страниц как Web Components -->
        <div class="content-area">
            <page-monitoring id="page1" style="display: block;"></page-monitoring>
            <page-analytics id="page2" style="display: none;"></page-analytics>
            <page-settings id="page3" style="display: none;"></page-settings>
        </div>
        
        <!-- Статус-бар -->
        <div class="status-bar">
            <div class="status-item">
                <span class="status-dot"></span>
                <span>Система активна</span>
            </div>
            <div class="status-item">
                <span>Текущая страница: <strong id="currentPageName">Мониторинг</strong></span>
            </div>
            <div class="status-item">
                <span>Обновлено: <strong id="lastUpdate">--:--:--</strong></span>
            </div>
        </div>
    </div>

    <!-- JavaScript -->
    <script src="engine.js"></script>
    <script src="js/header-component.js"></script>
    <script src="pages/page1-component.js"></script>
    <script src="pages/page2-component.js"></script>
    <script src="pages/page3-component.js"></script>
    <script src="js/app.js"></script>
</body>
</html>
```

**Примечание:** `engine.js` подключается из `gui/engine.js`, а не из `gui/js/engine.js` - это требование модуля Bridge.

---

## 🎯 АРХИТЕКТУРА

### Ключевые особенности:
- ✅ **Модульная структура CSS** - 8 отдельных файлов (theme, buttons, inputs, tables, dropdowns, texts, header, app)
- ✅ **Венгерская нотация** - префикс `ScadaGraphics` для всех переменных и функций
- ✅ **Web Components** - нативные Custom Elements без библиотек
- ✅ **HTML в JS с подсветкой** - `this.innerHTML = /* html */` для подсветки синтаксиса
- ✅ **Событийная модель** - OnEventMode в AutoIt, события в JS
- ✅ **Bridge коммуникация** - двусторонняя связь AutoIt ↔ JavaScript
- ✅ **Консоль в AutoIt** - все `console.log()` и `console.error()` видны в логах

### Специфика engine.js:
`engine.js` находится в `gui/engine.js` (на уровень выше `js/`), так как это требование модуля WebView2 Bridge для корректной работы. Не перемещать!

---

## � СЛЕДУЮЩИЕ ШАГИ

1. ✅ **Миграция на Web Components** - завершена
2. ✅ **Консоль работает** - все логи видны в AutoIt
3. ⏳ **Добавить основной цикл** - убрать тестовый режим, добавить `While 1`
4. ⏳ **Реализовать пушинг данных** - генерация и отправка данных датчиков каждые 500мс
5. ⏳ **Тестирование** - проверить все функции в рабочем режиме

---

## � ОТЛАДКА

### Проверка консоли:
```autoit
; В new_app1.au3 обработчики работают:
Func _ScadaGraphics_OnConsole($vJson)
    Local $sLevel = $vJson["payload"]["level"]
    Local $sMessage = $vJson["payload"]["message"]
    _Logger_Write("[JS Console] " & $sMessage, 1)
EndFunc
```

### Логи при запуске (всё работает):
```
✅ SDK инициализирован: new_app1 / Main
✅ WebView2 инициализирован успешно
✅ Bridge инициализирован
✅ Обработчики сообщений зарегистрированы
ℹ️ [JS Console.log] Header: Компонент шапки загружен
ℹ️ [JS Console.log] Page1: Компонент мониторинга загружен
ℹ️ [JS Console.log] Page2: Компонент аналитики загружен
ℹ️ [JS Console.log] Page3: Компонент настроек загружен
ℹ️ [JS Console.log] App: Инициализировано 10 датчиков
✅ Engine.js готов к работе
```

---

## 📝 ПРИМЕЧАНИЯ

- ✅ Приложение запускается без ошибок
- ✅ GUI отображается корректно
- ✅ Все страницы загружаются
- ✅ Навигация работает
- ✅ Консоль JavaScript видна в AutoIt
- ✅ Нет CORS ошибок
- ⏳ Тестовый режим (3 секунды и выход) - требуется заменить на основной цикл

**Дата последнего обновления:** 24.02.2026  
**Статус:** ✅ Миграция завершена, готово к добавлению основного функционала
