# 📦 Виджеты и утилиты

## 🔔 Notifications (Toastify JS)

### Базовое использование:
```javascript
// Простые уведомления
notifySuccess('Операция выполнена!');
notifyError('Произошла ошибка!');
notifyWarning('Внимание!');
notifyInfo('Информация');
```

### Расширенные настройки:
```javascript
notifySuccess('Сохранено!', {
    duration: 5000,           // Длительность (мс), -1 = бесконечно
    gravity: 'bottom',        // 'top' или 'bottom'
    position: 'center',       // 'left', 'center', 'right'
    close: false,             // Кнопка закрытия
    stopOnFocus: true,        // Пауза при наведении
    avatar: 'icon.png',       // Иконка
    destination: 'https://...', // Ссылка при клике
    newWindow: true,          // Открывать в новом окне
    onClick: () => {          // Callback при клике
        console.log('Clicked!');
    },
    offset: { x: 50, y: 10 }, // Отступы
    style: {                  // Кастомные стили
        background: '#ff0000',
        color: '#fff',
        fontSize: '18px'
    }
});
```

### Глобальные настройки:
```javascript
window.Notifications.configure({
    duration: 5000,
    gravity: 'bottom',
    position: 'left'
});
```

---

## 💬 Tooltips (Tippy.js)

### Автоматическая инициализация (HTML):
```html
<button data-tooltip="Это подсказка">Наведи на меня</button>
<button data-tooltip="Снизу" data-tooltip-placement="bottom">Кнопка</button>
<button data-tooltip="Тёмная тема" data-tooltip-theme="dark">Кнопка</button>
```

### Программное создание:
```javascript
// Простой tooltip
createTooltip('#myButton', {
    content: 'Это подсказка'
});

// Расширенные настройки
createTooltip('.my-buttons', {
    content: 'Подсказка',
    placement: 'top',         // 'top', 'bottom', 'left', 'right', 'auto'
    theme: 'light',           // 'light', 'dark', 'light-border', 'translucent'
    animation: 'fade',        // 'fade', 'shift-away', 'shift-toward', 'scale', 'perspective'
    arrow: true,              // Показывать стрелку
    delay: [200, 0],          // [показ, скрытие] в мс
    duration: [300, 250],     // [анимация показа, скрытия] в мс
    interactive: true,        // Можно взаимодействовать с tooltip
    trigger: 'click',         // 'mouseenter', 'focus', 'click', 'manual'
    maxWidth: 500,            // Максимальная ширина
    offset: [0, 10],          // [x, y] смещение
    allowHTML: true,          // Разрешить HTML в контенте
    hideOnClick: true,        // Скрывать при клике
    appendTo: document.body,  // Куда добавлять
    zIndex: 9999,             // z-index
    followCursor: false,      // Следовать за курсором
    inertia: false,           // Инерция при движении
    touch: true,              // Поддержка touch
    sticky: false             // "Прилипать" к элементу
});
```

### Программное управление:
```javascript
// Показать/скрыть
showTooltip('#myButton');
hideTooltip('#myButton');

// Обновить контент
window.Tooltips.setContent('#myButton', 'Новый текст');

// Удалить
destroyTooltip('#myButton');
window.Tooltips.destroyAll(); // Удалить все
```

### HTML контент в tooltip:
```javascript
createTooltip('#myButton', {
    content: '<strong>Жирный</strong> <em>курсив</em>',
    allowHTML: true
});
```

### Интерактивный tooltip:
```javascript
createTooltip('#myButton', {
    content: '<button onclick="alert(\'Clicked!\')">Кликни</button>',
    allowHTML: true,
    interactive: true,
    trigger: 'click'
});
```

### Темы Tippy:
- `light` - светлая (по умолчанию)
- `dark` - тёмная
- `light-border` - светлая с рамкой
- `translucent` - полупрозрачная

### Позиции (placement):
- `top`, `top-start`, `top-end`
- `bottom`, `bottom-start`, `bottom-end`
- `left`, `left-start`, `left-end`
- `right`, `right-start`, `right-end`
- `auto` - автоматически

---

## 🎯 RequestHub

### Отправка запросов:
```javascript
try {
    const response = await window.RequestHub.send('get_app_info');
    console.log(response);
} catch (error) {
    notifyError('Ошибка: ' + error.message);
}
```

### С данными:
```javascript
const response = await window.RequestHub.send('test_request', {
    param1: 'value1',
    param2: 123
});
```

### Статистика:
```javascript
const stats = window.RequestHub.getStats();
console.log(stats);
// { total: 10, success: 8, timeout: 1, error: 1, pending: 0, successRate: '80%' }
```

---

## 📊 StatusIndicator

### Использование:
```javascript
const indicator = new StatusIndicator('#myButton');

indicator.loading('Загрузка...');
indicator.success('Готово!');
indicator.error('Ошибка!');
indicator.reset();
```

---

## 🎨 Примеры комбинаций

### Запрос с уведомлением и индикатором:
```javascript
const indicator = new StatusIndicator('#saveButton');

async function saveData() {
    indicator.loading('Сохранение...');
    
    try {
        const response = await window.RequestHub.send('save_data', data);
        indicator.success('Сохранено!');
        notifySuccess('Данные успешно сохранены!');
    } catch (error) {
        indicator.error('Ошибка!');
        notifyError('Не удалось сохранить: ' + error.message);
    }
}
```

### Кнопка с tooltip и уведомлением:
```html
<button id="deleteBtn" data-tooltip="Удалить запись">🗑️ Удалить</button>

<script>
document.getElementById('deleteBtn').addEventListener('click', async () => {
    if (confirm('Удалить?')) {
        try {
            await window.RequestHub.send('delete_item', { id: 123 });
            notifySuccess('Удалено!');
        } catch (error) {
            notifyError('Ошибка удаления');
        }
    }
});
</script>
```
