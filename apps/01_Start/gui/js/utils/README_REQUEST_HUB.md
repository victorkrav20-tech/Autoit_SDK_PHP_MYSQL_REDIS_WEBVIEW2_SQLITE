# RequestHub - Система надёжных запросов JavaScript ↔ AutoIt

**Версия:** 2.0.0  
**Файл:** `request-hub.js`  
**Назначение:** Двусторонняя связь с AutoIt через Promise API с поддержкой надёжной доставки

---

## 📋 Содержание

1. [Быстрый старт](#быстрый-старт)
2. [API методы](#api-методы)
3. [Надёжная доставка (sendReliable)](#надёжная-доставка-sendreliable)
4. [Примеры использования](#примеры-использования)
5. [Статистика](#статистика)
6. [Best Practices для SCADA](#best-practices-для-scada)

---

## 🚀 Быстрый старт

### Базовое использование:

```javascript
// Простой запрос
const response = await RequestHub.send('get_sensor_data', { id: 1 });
console.log('Данные датчика:', response);

// Надёжный запрос (для критичных данных)
const response = await RequestHub.sendReliable('set_valve_state', { valve: 2, state: 'open' });
console.log('Клапан открыт:', response);
```

---

## 📚 API методы

### `send(type, payload, timeout)`

**Описание:** Отправляет один запрос к AutoIt с таймаутом.

**Параметры:**
- `type` (string) - тип запроса (например: 'get_sensor_data', 'set_valve_state')
- `payload` (object|null) - данные запроса
- `timeout` (number) - таймаут в мс (по умолчанию 3000мс)

**Возвращает:** Promise с ответом от AutoIt

**Пример:**
```javascript
try {
    const data = await RequestHub.send('get_sensor_data', { id: 1 }, 5000);
    console.log('Успех:', data);
} catch (error) {
    console.error('Ошибка:', error.message);
}
```

---

### `sendReliable(type, payload, options)`

**Описание:** Надёжная отправка с избыточностью (5 копий параллельно + retry до 3 раз).

**Параметры:**
- `type` (string) - тип запроса
- `payload` (object|null) - данные запроса
- `options` (object) - настройки надёжности:
  - `copies` (number) - количество копий (по умолчанию 5)
  - `timeout` (number) - таймаут для каждой копии (по умолчанию 300мс)
  - `maxRetries` (number) - максимум переотправок (по умолчанию 3)
  - `retryDelay` (number) - задержка между retry (по умолчанию 50мс)

**Возвращает:** Promise с ответом от AutoIt

**Как работает:**
1. Отправляет 5 копий запроса одновременно
2. Останавливается на первой успешной копии
3. Если все 5 провалились → пауза 50мс → переотправка (до 3 раз)
4. Итого: до 15 копий максимум (5 × 3 попытки)

**Пример:**
```javascript
// С настройками по умолчанию (5 копий, 300мс таймаут, 3 retry)
const data = await RequestHub.sendReliable('get_critical_sensor', { id: 1 });

// С кастомными настройками
const data = await RequestHub.sendReliable('emergency_stop', null, {
    copies: 10,        // 10 копий для максимальной надёжности
    timeout: 500,      // 500мс таймаут
    maxRetries: 5,     // 5 переотправок
    retryDelay: 100    // 100мс между попытками
});
```

---

### `getStats()`

**Описание:** Получить статистику запросов.

**Возвращает:** Объект со статистикой:
```javascript
{
    total: 150,           // Всего запросов
    success: 145,         // Успешных
    timeout: 3,           // Таймаутов
    error: 2,             // Ошибок
    pending: 5,           // Ожидающих ответа
    successRate: '96.67%' // Процент успеха
}
```

**Пример:**
```javascript
const stats = RequestHub.getStats();
console.log('Успешность:', stats.successRate);
```

---

### `resetStats()`

**Описание:** Сбросить статистику запросов.

**Пример:**
```javascript
RequestHub.resetStats();
```

---

### `cancel(requestId)`

**Описание:** Отменить конкретный запрос по ID.

**Параметры:**
- `requestId` (number) - ID запроса

**Возвращает:** true если запрос отменён, false если не найден

---

### `cancelAll()`

**Описание:** Отменить все ожидающие запросы.

**Возвращает:** Количество отменённых запросов

**Пример:**
```javascript
const cancelled = RequestHub.cancelAll();
console.log(`Отменено запросов: ${cancelled}`);
```

---

## 🛡️ Надёжная доставка (sendReliable)

### Когда использовать:

✅ **Используй sendReliable() для:**
- Критичных команд (открытие/закрытие клапанов, аварийная остановка)
- Запросов данных датчиков в реальном времени
- Установки параметров оборудования
- Любых операций где важна 100% доставка

❌ **НЕ используй sendReliable() для:**
- Некритичных запросов (получение информации о приложении)
- Частых опросов (каждые 100мс) - создаст большую нагрузку
- Больших данных (лучше использовать обычный send с увеличенным таймаутом)

---

### Математика надёжности:

**При 20% потерь (плохая связь):**
- 1 копия: 20% провал
- 5 копий: 0.2^5 = 0.00032 = **0.032% провал** → **99.968% успех**
- С 3 retry: практически **100% успех**

**При 50% потерь (очень плохая связь):**
- 5 копий: 0.5^5 = 0.03125 = **3.125% провал** → **96.875% успех**
- С 3 retry: (0.03125)^3 = **0.003% провал** → **99.997% успех**

**При 90% потерь (катастрофическая связь):**
- 5 копий: 0.9^5 = 0.59 = **59% провал** → **41% успех**
- С 3 retry: 0.59^3 = 0.206 = **20.6% провал** → **79.4% успех**

---

## 💡 Примеры использования

### Пример 1: Получение данных датчика

```javascript
async function getSensorData(sensorId) {
    try {
        // Надёжный запрос для критичных данных
        const data = await RequestHub.sendReliable('get_sensor_data', { 
            id: sensorId 
        });
        
        return {
            temperature: data.temperature,
            pressure: data.pressure,
            timestamp: data.timestamp
        };
    } catch (error) {
        console.error(`Ошибка получения данных датчика #${sensorId}:`, error);
        throw error;
    }
}

// Использование
const sensor1 = await getSensorData(1);
console.log('Температура:', sensor1.temperature);
```

---

### Пример 2: Управление клапаном

```javascript
async function setValveState(valveId, state) {
    try {
        // Критичная команда - используем максимальную надёжность
        const response = await RequestHub.sendReliable('set_valve_state', {
            valve: valveId,
            state: state  // 'open' или 'closed'
        }, {
            copies: 10,      // 10 копий для максимальной надёжности
            timeout: 500,    // 500мс таймаут
            maxRetries: 5    // 5 переотправок
        });
        
        console.log(`✅ Клапан #${valveId} ${state === 'open' ? 'открыт' : 'закрыт'}`);
        return response;
    } catch (error) {
        console.error(`❌ Ошибка управления клапаном #${valveId}:`, error);
        // Критичная ошибка - показываем уведомление
        notifyError(`Не удалось ${state === 'open' ? 'открыть' : 'закрыть'} клапан #${valveId}`);
        throw error;
    }
}

// Использование
await setValveState(2, 'open');
```

---

### Пример 3: Аварийная остановка

```javascript
async function emergencyStop() {
    try {
        // Максимальная надёжность для аварийной команды
        const response = await RequestHub.sendReliable('emergency_stop', null, {
            copies: 15,       // 15 копий!
            timeout: 1000,    // 1 сек таймаут
            maxRetries: 10,   // 10 переотправок
            retryDelay: 0     // Без задержки между попытками
        });
        
        console.log('🛑 АВАРИЙНАЯ ОСТАНОВКА ВЫПОЛНЕНА');
        notifySuccess('Аварийная остановка выполнена', { duration: 5000 });
        return response;
    } catch (error) {
        console.error('❌ КРИТИЧЕСКАЯ ОШИБКА: Аварийная остановка не выполнена!', error);
        notifyError('КРИТИЧЕСКАЯ ОШИБКА: Аварийная остановка не выполнена!', { duration: 10000 });
        throw error;
    }
}

// Использование
document.getElementById('emergency-stop-btn').addEventListener('click', async () => {
    if (confirm('Выполнить аварийную остановку?')) {
        await emergencyStop();
    }
});
```

---

### Пример 4: Опрос датчиков в реальном времени

```javascript
class SensorMonitor {
    constructor(sensorIds) {
        this.sensorIds = sensorIds;
        this.intervalId = null;
        this.pollInterval = 1000; // 1 секунда
    }
    
    start() {
        this.intervalId = setInterval(async () => {
            await this.pollSensors();
        }, this.pollInterval);
    }
    
    stop() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
    }
    
    async pollSensors() {
        // Опрашиваем все датчики параллельно
        const promises = this.sensorIds.map(id => 
            RequestHub.sendReliable('get_sensor_data', { id })
                .catch(error => {
                    console.warn(`Датчик #${id} недоступен:`, error);
                    return null; // Возвращаем null при ошибке
                })
        );
        
        const results = await Promise.all(promises);
        
        // Обновляем UI
        results.forEach((data, index) => {
            if (data) {
                this.updateSensorDisplay(this.sensorIds[index], data);
            }
        });
    }
    
    updateSensorDisplay(sensorId, data) {
        const element = document.getElementById(`sensor-${sensorId}`);
        if (element) {
            element.textContent = `${data.temperature}°C`;
        }
    }
}

// Использование
const monitor = new SensorMonitor([1, 2, 3, 4, 5]);
monitor.start();

// Остановка при уходе со страницы
window.addEventListener('beforeunload', () => {
    monitor.stop();
});
```

---

## 📊 Статистика

### Мониторинг надёжности:

```javascript
// Показываем статистику каждые 10 секунд
setInterval(() => {
    const stats = RequestHub.getStats();
    console.log('📊 Статистика RequestHub:', stats);
    
    // Предупреждение если успешность падает ниже 95%
    const successRate = parseFloat(stats.successRate);
    if (successRate < 95) {
        console.warn('⚠️ Низкая успешность запросов:', stats.successRate);
        notifyWarning(`Проблемы со связью: ${stats.successRate} успешных запросов`);
    }
}, 10000);
```

---

## 🎯 Best Practices для SCADA

### 1. Используй правильный метод для задачи:

```javascript
// ❌ Плохо - избыточность для некритичных данных
const appInfo = await RequestHub.sendReliable('get_app_info');

// ✅ Хорошо - обычный запрос для некритичных данных
const appInfo = await RequestHub.send('get_app_info');

// ✅ Хорошо - надёжный запрос для критичных команд
const result = await RequestHub.sendReliable('set_valve_state', { valve: 1, state: 'open' });
```

---

### 2. Обрабатывай ошибки правильно:

```javascript
// ❌ Плохо - игнорируем ошибки
const data = await RequestHub.sendReliable('get_sensor_data', { id: 1 }).catch(() => null);

// ✅ Хорошо - логируем и показываем пользователю
try {
    const data = await RequestHub.sendReliable('get_sensor_data', { id: 1 });
    return data;
} catch (error) {
    console.error('Ошибка получения данных датчика:', error);
    notifyError('Датчик недоступен');
    throw error; // Пробрасываем дальше
}
```

---

### 3. Настраивай параметры под задачу:

```javascript
// Для быстрых некритичных запросов
const data = await RequestHub.send('get_status', null, 1000); // 1 сек таймаут

// Для критичных команд
const result = await RequestHub.sendReliable('emergency_stop', null, {
    copies: 10,
    timeout: 1000,
    maxRetries: 5
});

// Для частых опросов
const data = await RequestHub.sendReliable('get_sensor_data', { id: 1 }, {
    copies: 3,        // Меньше копий для снижения нагрузки
    timeout: 200,     // Короткий таймаут
    maxRetries: 2     // Меньше retry
});
```

---

### 4. Мониторь производительность:

```javascript
// Логируем медленные запросы
const startTime = performance.now();
const data = await RequestHub.sendReliable('get_sensor_data', { id: 1 });
const duration = performance.now() - startTime;

if (duration > 500) {
    console.warn(`⚠️ Медленный запрос: ${duration.toFixed(0)}мс`);
}
```

---

### 5. Используй батчинг для множественных запросов:

```javascript
// ❌ Плохо - последовательные запросы
for (let i = 1; i <= 10; i++) {
    await RequestHub.sendReliable('get_sensor_data', { id: i });
}

// ✅ Хорошо - параллельные запросы
const promises = [];
for (let i = 1; i <= 10; i++) {
    promises.push(RequestHub.sendReliable('get_sensor_data', { id: i }));
}
const results = await Promise.all(promises);
```

---

## 🔧 Отладка

### Включение детального логирования:

```javascript
// В консоли браузера
RequestHub.debug = true; // Включить детальное логирование

// Теперь все запросы будут логироваться
const data = await RequestHub.sendReliable('test', null);
```

---

## 📝 Заметки

- **Таймауты:** По умолчанию 3000мс для `send()` и 300мс для `sendReliable()`
- **Retry:** Только в `sendReliable()`, обычный `send()` не переотправляет
- **Производительность:** `sendReliable()` создаёт больше нагрузки, используй разумно
- **Статистика:** Сбрасывается при перезагрузке страницы

---

## 🆘 Troubleshooting

**Проблема:** Все запросы возвращают таймаут

**Решение:**
1. Проверь что AutoIt приложение запущено
2. Проверь что WebView2Engine инициализирован: `console.log(WebView2Engine.isReady)`
3. Проверь логи AutoIt на ошибки

---

**Проблема:** Низкая успешность запросов (<95%)

**Решение:**
1. Проверь статистику: `RequestHub.getStats()`
2. Увеличь таймаут: `RequestHub.sendReliable('...', null, { timeout: 500 })`
3. Увеличь количество копий: `{ copies: 10 }`
4. Проверь нагрузку на AutoIt (CPU, память)

---

**Проблема:** Медленные запросы (>1 сек)

**Решение:**
1. Используй `send()` вместо `sendReliable()` для некритичных данных
2. Уменьши количество копий: `{ copies: 3 }`
3. Уменьши maxRetries: `{ maxRetries: 2 }`
4. Проверь очередь в engine.js (sendDelay)

---

## 📚 См. также

- [README_COMMUNICATION.md](../README_COMMUNICATION.md) - Общая документация по системе связи
- [engine.js](../engine.js) - Транспортный слой
- [Inet_Reader_Init_Response.au3](../../../Inet_Reader_Init_Response.au3) - Обработчик на стороне AutoIt
