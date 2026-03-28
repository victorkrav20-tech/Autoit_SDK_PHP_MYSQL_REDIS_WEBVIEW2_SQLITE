# 💬 Продвинутые интерактивные подсказки (Tippy.js)

**Версия:** 1.0.0  
**Дата:** 06.03.2026  
**Библиотека:** Tippy.js + Popper.js

---

## 📋 СОДЕРЖАНИЕ

1. [Что такое интерактивные подсказки](#что-такое-интерактивные-подсказки)
2. [Базовое использование](#базовое-использование)
3. [Интерактивные подсказки с кнопками](#интерактивные-подсказки-с-кнопками)
4. [Цвета и стили](#цвета-и-стили)
5. [Полупрозрачность](#полупрозрачность)
6. [Ссылки и навигация](#ссылки-и-навигация)
7. [Темы оформления](#темы-оформления)
8. [Продвинутые примеры](#продвинутые-примеры)

---

## 🎯 ЧТО ТАКОЕ ИНТЕРАКТИВНЫЕ ПОДСКАЗКИ

**Интерактивные подсказки** - это всплывающие окна с HTML контентом, которые могут содержать:
- ✅ Кнопки и ссылки
- ✅ Цветной текст и фон
- ✅ Полупрозрачность
- ✅ Изображения и иконки
- ✅ Формы ввода
- ✅ Любой HTML контент

**Отличие от обычных подсказок:**
- Обычные: только текст, появляются при наведении
- Интерактивные: HTML контент, можно кликать внутри, открываются по клику

---

## 🚀 БАЗОВОЕ ИСПОЛЬЗОВАНИЕ

### 1. Подключение библиотек (уже подключено в index.html)

```html
<!-- Popper.js (позиционирование) -->
<script src="js/libs/popper.min.js"></script>

<!-- Tippy.js (подсказки) -->
<link href="css/tippy.min.css" rel="stylesheet">
<script src="js/libs/tippy.min.js"></script>

<!-- Наша обёртка -->
<script src="js/utils/tooltips.js"></script>
```

### 2. Простая подсказка через data-атрибут

```html
<button data-tooltip="Это простая подсказка">
    Наведи на меня
</button>
```

### 3. Подсказка через JavaScript

```javascript
createTooltip('#myButton', {
    content: 'Это подсказка через JS',
    placement: 'top'
});
```

---

## 🎨 ИНТЕРАКТИВНЫЕ ПОДСКАЗКИ С КНОПКАМИ

### Пример 1: Навигация по счётчикам (из test-utils-page.js)

```javascript
createTooltip('#btn-tooltip-navigation', {
    content: `
        <div style="padding: 8px;">
            <div style="font-weight: 600; margin-bottom: 12px; color: #206bc4;">
                Быстрый переход:
            </div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 6px;">
                <button class="btn btn-sm btn-outline-primary" onclick="navigateToCounter(1)">
                    Счётчик 1
                </button>
                <button class="btn btn-sm btn-outline-success" onclick="navigateToCounter(2)">
                    Счётчик 2
                </button>
                <button class="btn btn-sm btn-outline-info" onclick="navigateToCounter(3)">
                    Счётчик 3
                </button>
                <button class="btn btn-sm btn-outline-warning" onclick="navigateToCounter(4)">
                    Счётчик 4
                </button>
                <button class="btn btn-sm btn-outline-danger" onclick="navigateToCounter(5)">
                    Счётчик 5
                </button>
                <button class="btn btn-sm btn-outline-secondary" onclick="navigateToCounter(6)">
                    Счётчик 6
                </button>
                <button class="btn btn-sm btn-outline-dark" onclick="navigateToCounter(7)">
                    Счётчик 7
                </button>
                <button class="btn btn-sm btn-primary" onclick="navigateToCounter('online')">
                    Онлайн
                </button>
            </div>
        </div>
    `,
    allowHTML: true,           // Разрешить HTML
    interactive: true,         // Можно кликать внутри
    trigger: 'click',          // Открывается по клику
    placement: 'bottom',       // Позиция
    theme: 'light-border',     // Тема
    maxWidth: 350              // Максимальная ширина
});
```

**Глобальная функция для навигации:**

```javascript
window.navigateToCounter = function(counterId) {
    const pageId = typeof counterId === 'number' ? `counter${counterId}` : counterId;
    const header = document.querySelector('app-header');
    
    if (header && header.switchPage) {
        header.switchPage(pageId);
        console.log(`✅ Переход на страницу: ${pageId}`);
    }
};
```

### Пример 2: Меню действий

```javascript
createTooltip('#actionButton', {
    content: `
        <div style="padding: 10px;">
            <button class="btn btn-sm btn-success w-100 mb-2" onclick="doAction('save')">
                💾 Сохранить
            </button>
            <button class="btn btn-sm btn-danger w-100 mb-2" onclick="doAction('delete')">
                🗑️ Удалить
            </button>
            <button class="btn btn-sm btn-info w-100" onclick="doAction('export')">
                📤 Экспорт
            </button>
        </div>
    `,
    allowHTML: true,
    interactive: true,
    trigger: 'click',
    placement: 'right'
});
```

---

## 🎨 ЦВЕТА И СТИЛИ

### 1. Цветной текст

```javascript
createTooltip('#colorText', {
    content: `
        <div>
            <span style="color: #e74c3c;">Красный текст</span><br>
            <span style="color: #3498db;">Синий текст</span><br>
            <span style="color: #2ecc71;">Зелёный текст</span><br>
            <span style="color: #f39c12;">Оранжевый текст</span>
        </div>
    `,
    allowHTML: true
});
```

### 2. Цветной фон

```javascript
createTooltip('#colorBg', {
    content: `
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                    color: white; 
                    padding: 15px; 
                    border-radius: 8px;">
            <strong>Градиентный фон</strong><br>
            Красивое оформление
        </div>
    `,
    allowHTML: true,
    theme: 'transparent' // Убираем стандартный фон
});
```

### 3. Цветные блоки (Badge)

```javascript
createTooltip('#badges', {
    content: `
        <div style="padding: 8px;">
            <span class="badge bg-success">Активен</span>
            <span class="badge bg-danger">Ошибка</span>
            <span class="badge bg-warning">Внимание</span>
            <span class="badge bg-info">Информация</span>
        </div>
    `,
    allowHTML: true
});
```

### 4. Таблица с цветами

```javascript
createTooltip('#colorTable', {
    content: `
        <table style="border-collapse: collapse;">
            <tr>
                <td style="background: #e74c3c; color: white; padding: 8px;">Критично</td>
                <td style="padding: 8px;">5 ошибок</td>
            </tr>
            <tr>
                <td style="background: #f39c12; color: white; padding: 8px;">Внимание</td>
                <td style="padding: 8px;">12 предупреждений</td>
            </tr>
            <tr>
                <td style="background: #2ecc71; color: white; padding: 8px;">OK</td>
                <td style="padding: 8px;">Всё работает</td>
            </tr>
        </table>
    `,
    allowHTML: true,
    maxWidth: 300
});
```

---

## 🌫️ ПОЛУПРОЗРАЧНОСТЬ

### 1. Полупрозрачный фон

```javascript
createTooltip('#transparent', {
    content: `
        <div style="background: rgba(0, 0, 0, 0.8); 
                    color: white; 
                    padding: 15px; 
                    border-radius: 8px;
                    backdrop-filter: blur(10px);">
            <strong>Полупрозрачный фон</strong><br>
            С эффектом размытия
        </div>
    `,
    allowHTML: true,
    theme: 'transparent'
});
```

### 2. Полупрозрачные элементы

```javascript
createTooltip('#semiTransparent', {
    content: `
        <div style="padding: 10px;">
            <div style="background: rgba(231, 76, 60, 0.3); padding: 8px; margin-bottom: 5px;">
                30% красный
            </div>
            <div style="background: rgba(52, 152, 219, 0.5); padding: 8px; margin-bottom: 5px;">
                50% синий
            </div>
            <div style="background: rgba(46, 204, 113, 0.7); padding: 8px;">
                70% зелёный
            </div>
        </div>
    `,
    allowHTML: true
});
```

### 3. Стеклянный эффект (Glassmorphism)

```javascript
createTooltip('#glass', {
    content: `
        <div style="background: rgba(255, 255, 255, 0.1);
                    backdrop-filter: blur(10px) saturate(180%);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    border-radius: 12px;
                    padding: 20px;
                    color: white;
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);">
            <strong>Стеклянный эффект</strong><br>
            Современный дизайн
        </div>
    `,
    allowHTML: true,
    theme: 'transparent'
});
```

---

## 🔗 ССЫЛКИ И НАВИГАЦИЯ

### 1. Обычные ссылки

```javascript
createTooltip('#links', {
    content: `
        <div style="padding: 10px;">
            <a href="https://example.com" target="_blank" style="color: #3498db;">
                🔗 Внешняя ссылка
            </a><br>
            <a href="#section1" style="color: #2ecc71;">
                📍 Якорь на странице
            </a>
        </div>
    `,
    allowHTML: true,
    interactive: true
});
```

### 2. Ссылки с иконками

```javascript
createTooltip('#iconLinks', {
    content: `
        <div style="padding: 10px;">
            <a href="#" onclick="openDocs(); return false;" 
               style="display: block; margin-bottom: 8px; color: #3498db; text-decoration: none;">
                📚 Документация
            </a>
            <a href="#" onclick="openSettings(); return false;" 
               style="display: block; margin-bottom: 8px; color: #9b59b6; text-decoration: none;">
                ⚙️ Настройки
            </a>
            <a href="#" onclick="openHelp(); return false;" 
               style="display: block; color: #e67e22; text-decoration: none;">
                ❓ Помощь
            </a>
        </div>
    `,
    allowHTML: true,
    interactive: true
});
```

### 3. Навигационное меню

```javascript
createTooltip('#navMenu', {
    content: `
        <div style="padding: 8px; min-width: 200px;">
            <div style="font-weight: 600; margin-bottom: 10px; color: #34495e;">
                Навигация
            </div>
            <a href="#" onclick="navigate('dashboard')" 
               style="display: block; padding: 6px 10px; margin-bottom: 4px; 
                      background: #ecf0f1; border-radius: 4px; text-decoration: none; color: #2c3e50;">
                🏠 Главная
            </a>
            <a href="#" onclick="navigate('analytics')" 
               style="display: block; padding: 6px 10px; margin-bottom: 4px; 
                      background: #ecf0f1; border-radius: 4px; text-decoration: none; color: #2c3e50;">
                📊 Аналитика
            </a>
            <a href="#" onclick="navigate('settings')" 
               style="display: block; padding: 6px 10px; 
                      background: #ecf0f1; border-radius: 4px; text-decoration: none; color: #2c3e50;">
                ⚙️ Настройки
            </a>
        </div>
    `,
    allowHTML: true,
    interactive: true,
    trigger: 'click'
});
```

---

## 🎭 ТЕМЫ ОФОРМЛЕНИЯ

### Встроенные темы Tippy.js

```javascript
// 1. Светлая тема (по умолчанию)
createTooltip('#light', {
    content: 'Светлая тема',
    theme: 'light'
});

// 2. Светлая с рамкой
createTooltip('#lightBorder', {
    content: 'Светлая тема с рамкой',
    theme: 'light-border'
});

// 3. Тёмная тема
createTooltip('#dark', {
    content: 'Тёмная тема',
    theme: 'dark'
});

// 4. Полупрозрачная
createTooltip('#translucent', {
    content: 'Полупрозрачная тема',
    theme: 'translucent'
});

// 5. Прозрачная (без фона)
createTooltip('#transparent', {
    content: '<div style="background: #3498db; color: white; padding: 10px;">Свой фон</div>',
    allowHTML: true,
    theme: 'transparent'
});
```

### Кастомная тема через CSS

```css
/* В вашем CSS файле */
.tippy-box[data-theme~='custom'] {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-radius: 12px;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
}

.tippy-box[data-theme~='custom'][data-placement^='top'] > .tippy-arrow::before {
    border-top-color: #667eea;
}
```

```javascript
createTooltip('#custom', {
    content: 'Кастомная тема',
    theme: 'custom'
});
```

---

## 🚀 ПРОДВИНУТЫЕ ПРИМЕРЫ

### 1. Форма ввода в подсказке

```javascript
createTooltip('#formTooltip', {
    content: `
        <div style="padding: 15px; min-width: 250px;">
            <h4 style="margin-top: 0;">Быстрый поиск</h4>
            <input type="text" 
                   class="form-control mb-2" 
                   placeholder="Введите запрос..."
                   id="quickSearch">
            <button class="btn btn-primary btn-sm w-100" 
                    onclick="performSearch()">
                🔍 Найти
            </button>
        </div>
    `,
    allowHTML: true,
    interactive: true,
    trigger: 'click',
    placement: 'bottom'
});
```

### 2. Карточка с информацией

```javascript
createTooltip('#infoCard', {
    content: `
        <div style="padding: 15px; max-width: 300px;">
            <div style="display: flex; align-items: center; margin-bottom: 10px;">
                <div style="width: 50px; height: 50px; background: #3498db; 
                            border-radius: 50%; display: flex; align-items: center; 
                            justify-content: center; color: white; font-size: 24px;">
                    👤
                </div>
                <div style="margin-left: 15px;">
                    <strong>Иван Иванов</strong><br>
                    <span style="color: #7f8c8d; font-size: 12px;">Администратор</span>
                </div>
            </div>
            <div style="border-top: 1px solid #ecf0f1; padding-top: 10px;">
                <div style="margin-bottom: 5px;">
                    📧 ivan@example.com
                </div>
                <div style="margin-bottom: 5px;">
                    📱 +7 (999) 123-45-67
                </div>
                <div>
                    🏢 Отдел разработки
                </div>
            </div>
        </div>
    `,
    allowHTML: true,
    interactive: true,
    placement: 'right'
});
```

### 3. График/Статистика

```javascript
createTooltip('#stats', {
    content: `
        <div style="padding: 15px; min-width: 250px;">
            <h5 style="margin-top: 0;">Статистика за сегодня</h5>
            <div style="margin-bottom: 10px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                    <span>Запросов:</span>
                    <strong style="color: #3498db;">1,234</strong>
                </div>
                <div style="height: 4px; background: #ecf0f1; border-radius: 2px;">
                    <div style="width: 75%; height: 100%; background: #3498db; border-radius: 2px;"></div>
                </div>
            </div>
            <div style="margin-bottom: 10px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                    <span>Ошибок:</span>
                    <strong style="color: #e74c3c;">23</strong>
                </div>
                <div style="height: 4px; background: #ecf0f1; border-radius: 2px;">
                    <div style="width: 15%; height: 100%; background: #e74c3c; border-radius: 2px;"></div>
                </div>
            </div>
            <div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                    <span>Успешных:</span>
                    <strong style="color: #2ecc71;">1,211</strong>
                </div>
                <div style="height: 4px; background: #ecf0f1; border-radius: 2px;">
                    <div style="width: 98%; height: 100%; background: #2ecc71; border-radius: 2px;"></div>
                </div>
            </div>
        </div>
    `,
    allowHTML: true,
    interactive: true
});
```

### 4. Уведомление с действиями

```javascript
createTooltip('#notification', {
    content: `
        <div style="padding: 15px; max-width: 300px;">
            <div style="display: flex; align-items: start; margin-bottom: 10px;">
                <div style="font-size: 24px; margin-right: 10px;">⚠️</div>
                <div>
                    <strong>Требуется обновление</strong><br>
                    <span style="color: #7f8c8d; font-size: 13px;">
                        Доступна новая версия 2.0.1
                    </span>
                </div>
            </div>
            <div style="display: flex; gap: 8px;">
                <button class="btn btn-primary btn-sm" onclick="updateNow()">
                    Обновить
                </button>
                <button class="btn btn-outline-secondary btn-sm" onclick="remindLater()">
                    Позже
                </button>
            </div>
        </div>
    `,
    allowHTML: true,
    interactive: true,
    trigger: 'click',
    placement: 'bottom'
});
```

---

## ⚙️ ПАРАМЕТРЫ КОНФИГУРАЦИИ

### Основные параметры

```javascript
createTooltip('#element', {
    // Контент
    content: 'Текст подсказки',           // Текст или HTML
    allowHTML: false,                      // Разрешить HTML (по умолчанию false)
    
    // Позиционирование
    placement: 'top',                      // top, bottom, left, right, auto
    offset: [0, 10],                       // Смещение [x, y] в пикселях
    
    // Поведение
    trigger: 'mouseenter focus',           // mouseenter, click, focusin, manual
    interactive: false,                    // Можно ли кликать внутри
    hideOnClick: true,                     // Скрывать при клике вне
    
    // Анимация
    animation: 'fade',                     // fade, shift-away, shift-toward, scale
    duration: [300, 250],                  // [показ, скрытие] в мс
    delay: [0, 0],                         // [показ, скрытие] в мс
    
    // Внешний вид
    theme: 'light',                        // light, dark, light-border, translucent, transparent
    maxWidth: 350,                         // Максимальная ширина в px
    arrow: true,                           // Показывать стрелку
    
    // Дополнительно
    appendTo: document.body,               // Куда добавлять элемент
    zIndex: 9999,                          // Z-index
    touch: true                            // Поддержка touch устройств
});
```

---

## 📝 BEST PRACTICES

### 1. Используйте интерактивные подсказки для:
- ✅ Навигационных меню
- ✅ Форм быстрого ввода
- ✅ Карточек с информацией
- ✅ Списков действий
- ✅ Подтверждений операций

### 2. НЕ используйте для:
- ❌ Длинных текстов (используйте модальные окна)
- ❌ Критичных уведомлений (используйте toast)
- ❌ Сложных форм (используйте отдельные страницы)

### 3. Рекомендации по дизайну:
- Используйте `maxWidth: 350` для читаемости
- Добавляйте `padding: 10-15px` для комфорта
- Используйте цвета из палитры проекта
- Добавляйте иконки для наглядности
- Группируйте связанные элементы

### 4. Производительность:
- Не создавайте слишком много подсказок одновременно
- Используйте `trigger: 'click'` для сложного контента
- Очищайте подсказки при удалении элементов

---

## 🔧 ОТЛАДКА

### Проверка инициализации

```javascript
// Проверить что Tippy загружен
console.log('Tippy:', typeof tippy !== 'undefined' ? '✅' : '❌');

// Проверить что createTooltip доступна
console.log('createTooltip:', typeof createTooltip !== 'undefined' ? '✅' : '❌');
```

### Логирование событий

```javascript
createTooltip('#debug', {
    content: 'Debug tooltip',
    onShow(instance) {
        console.log('Показана подсказка:', instance);
    },
    onHide(instance) {
        console.log('Скрыта подсказка:', instance);
    },
    onCreate(instance) {
        console.log('Создана подсказка:', instance);
    }
});
```

---

**Версия:** 1.0.0 | **Дата:** 06.03.2026 | **Автор:** Kiro AI Assistant
