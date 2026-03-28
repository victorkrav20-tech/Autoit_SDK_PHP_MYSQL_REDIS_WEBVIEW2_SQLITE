// ===============================================================================
// WebView2 Engine - Система связи JavaScript ↔ AutoIt
// Версия: 2.0.0 Engine
// Описание: Универсальный движок для двусторонней связи с AutoIt
// ===============================================================================

// ===============================================================================
// ЗАЩИТА ОТ ПОВТОРНОЙ ИНИЦИАЛИЗАЦИИ
// ===============================================================================
if (window.ENGINE_INITIALIZED) {
    console.log('⚠️ Engine.js уже инициализирован, пропускаю повторную инициализацию');
    console.log('   URL:', window.location.href);
    console.log('   Window ID:', window.WEBVIEW2_WINDOW_ID || 'не установлен');
    console.log('   Timestamp:', new Date().toISOString());
    // Прерываем выполнение скрипта
    throw new Error('ENGINE_ALREADY_INITIALIZED');
}
window.ENGINE_INITIALIZED = true;
console.log('� Engine.js: ПЕРВАЯ ИНИЦИАЛИЗАЦИЯ');
console.log('   URL:', window.location.href);
console.log('   Window ID:', window.WEBVIEW2_WINDOW_ID || 'не установлен');
console.log('   Timestamp:', new Date().toISOString());
console.log('   readyState:', document.readyState);
console.log('🔒 Engine.js: защита от повторной инициализации активирована');

// ===============================================================================
// ПЕРЕХВАТ ОШИБОК JAVASCRIPT → AutoIt
// ===============================================================================

// Используем addEventListener вместо window.onerror для лучшего перехвата
window.addEventListener('error', function(event) {
    // event.error содержит полный объект ошибки
    const error = event.error;
    
    const errorData = {
        type: 'js_error',
        payload: {
            message: event.message || (error ? error.message : 'Unknown error'),
            file: event.filename ? event.filename.split('/').pop() : 'unknown',
            line: event.lineno || 0,
            column: event.colno || 0,
            stack: error && error.stack ? error.stack : 'no stack available',
            errorName: error && error.name ? error.name : 'Error',
            fullSource: event.filename || 'unknown'
        },
        windowId: window.WebView2Engine ? window.WebView2Engine.windowId : 0,
        timestamp: Date.now()
    };

    // Отправляем ошибку в AutoIt
    if (window.chrome && window.chrome.webview) {
        try {
            window.chrome.webview.postMessage(JSON.stringify(errorData));
        } catch (e) {
            console.error('Не удалось отправить ошибку в AutoIt:', e);
        }
    }

    console.error('=== JS ERROR ===');
    console.error('Message:', event.message);
    console.error('File:', event.filename, 'Line:', event.lineno, 'Column:', event.colno);
    if (error && error.stack) {
        console.error('Stack:', error.stack);
    }
    console.error('================');
    
    // Не подавляем ошибку
    return false;
}, true); // true = capture phase, перехватываем раньше

// Дополнительный перехват через window.onerror (для совместимости)
window.onerror = function (message, source, lineno, colno, error) {
    // Если уже обработано через addEventListener, пропускаем
    if (error && error._handled) return false;
    if (error) error._handled = true;
    
    const errorData = {
        type: 'js_error',
        payload: {
            message: message,
            file: source ? source.split('/').pop() : 'unknown',
            line: lineno,
            column: colno,
            stack: error && error.stack ? error.stack : 'no stack available',
            errorName: error && error.name ? error.name : 'Error',
            fullSource: source || 'unknown'
        },
        windowId: window.WebView2Engine ? window.WebView2Engine.windowId : 0,
        timestamp: Date.now()
    };

    // Отправляем ошибку в AutoIt
    if (window.chrome && window.chrome.webview) {
        try {
            window.chrome.webview.postMessage(JSON.stringify(errorData));
        } catch (e) {
            console.error('Не удалось отправить ошибку в AutoIt:', e);
        }
    }

    return false;
};

// Перехват необработанных Promise ошибок
window.addEventListener('unhandledrejection', function(event) {
    const error = event.reason;
    
    const errorData = {
        type: 'js_error',
        payload: {
            message: error && error.message ? error.message : String(event.reason),
            file: 'Promise',
            line: 0,
            column: 0,
            stack: error && error.stack ? error.stack : 'no stack available',
            errorName: error && error.name ? error.name : 'UnhandledPromiseRejection',
            fullSource: 'Promise rejection'
        },
        windowId: window.WebView2Engine ? window.WebView2Engine.windowId : 0,
        timestamp: Date.now()
    };

    // Отправляем ошибку в AutoIt
    if (window.chrome && window.chrome.webview) {
        try {
            window.chrome.webview.postMessage(JSON.stringify(errorData));
        } catch (e) {
            console.error('Не удалось отправить ошибку в AutoIt:', e);
        }
    }

    console.error('=== UNHANDLED PROMISE REJECTION ===');
    console.error('Reason:', event.reason);
    if (error && error.stack) {
        console.error('Stack:', error.stack);
    }
    console.error('====================================');
});

// ===============================================================================
// ПЕРЕХВАТ CONSOLE.LOG → AutoIt
// ===============================================================================
const originalConsole = {
    log: console.log,
    warn: console.warn,
    error: console.error,
    info: console.info
};

console.log = function (...args) {
    originalConsole.log.apply(console, args);
    sendConsoleToAutoIt('log', args.join(' '));
};

console.warn = function (...args) {
    originalConsole.warn.apply(console, args);
    sendConsoleToAutoIt('warn', args.join(' '));
};

console.error = function (...args) {
    originalConsole.error.apply(console, args);
    sendConsoleToAutoIt('error', args.join(' '));
};

console.info = function (...args) {
    originalConsole.info.apply(console, args);
    sendConsoleToAutoIt('info', args.join(' '));
};

function sendConsoleToAutoIt(level, message) {
    if (window.chrome && window.chrome.webview) {
        try {
            const logData = {
                type: 'js_console',
                payload: {
                    level: level,
                    message: message,
                    timestamp: new Date().toLocaleTimeString()
                },
                windowId: window.WebView2Engine ? window.WebView2Engine.windowId : 0,
                timestamp: Date.now()
            };
            window.chrome.webview.postMessage(JSON.stringify(logData));
        } catch (e) {
            originalConsole.error('Не удалось отправить лог в AutoIt:', e);
        }
    }
}

// Глобальный объект движка
window.WebView2Engine = {
    // Состояние движка
    isReady: false,
    callbacks: {},
    windowId: 0, // ID окна (устанавливается из AutoIt)

    // Система пакетной обработки обновлений (энергоэффективность)
    updateQueue: new Map(),
    updateScheduled: false,

    // Очередь отправки сообщений (решение проблемы потери при массовой отправке)
    sendQueue: [],
    sendInProgress: false,
    sendDelay: 0.1, // 5мс между сообщениями (оптимально для производительности)
    sendIntervalId: null, // ID интервала для синхронной отправки
    maxQueueSize: 10000, // Максимальный размер очереди

    // ===============================================================================
    // Инициализация движка (минимальные логи)
    // ===============================================================================
    init: function () {
        // Проверяем доступность WebView2 API
        if (!window.chrome || !window.chrome.webview) {
            console.error('❌ WebView2 API недоступен');
            return false;
        }

        // Подписываемся на сообщения от AutoIt
        window.chrome.webview.addEventListener('message', (event) => {
            this.handleAutoItMessage(event.data);
        });

        this.isReady = true;

        // Уведомляем AutoIt о готовности (стандартизированный протокол)
        this.sendToAutoIt('engine_ready', null, 'type');

        return true;
    },

    // ===============================================================================
    // Отправка сообщений в AutoIt через очередь (решение проблемы потери сообщений)
    // ===============================================================================
    sendToAutoIt: function (command, data = null, format = 'type') {
        if (!this.isReady) {
            console.warn('⚠️ Engine не готов:', command);
            return false;
        }

        // Стандартизированный протокол: используем type + payload + windowId
        const message = {
            type: command,
            payload: data,
            windowId: this.windowId,
            timestamp: Date.now()
        };

        // Проверяем переполнение очереди (защита от утечки памяти)
        if (this.sendQueue.length >= this.maxQueueSize) {
            console.warn(`⚠️ [Engine] Очередь переполнена (${this.maxQueueSize}), удаляю старые сообщения`);
            // Удаляем первые 100 сообщений (старые)
            this.sendQueue.splice(0, 100);
        }

        // Добавляем в очередь
        this.sendQueue.push(message);
        
        // Запускаем обработку очереди если ещё не запущена
        if (!this.sendInProgress) {
            this.startSendQueue();
        }

        return true;
    },

    // ===============================================================================
    // Запуск синхронной очереди отправки (через setInterval)
    // ===============================================================================
    startSendQueue: function () {
        if (this.sendInProgress) {
            return; // Уже запущена
        }

        this.sendInProgress = true;
        const startTime = Date.now();
        const startQueueSize = this.sendQueue.length;

        // Логируем начало обработки большой очереди
        if (startQueueSize > 10) {
            console.log(`📤 [Engine] Начинаю обработку очереди: ${startQueueSize} сообщений`);
        }

        // Создаём интервал для последовательной отправки
        this.sendIntervalId = setInterval(() => {
            // Проверяем есть ли сообщения
            if (this.sendQueue.length === 0) {
                // Очередь пуста - останавливаем интервал
                this.stopSendQueue();
                
                // Логируем статистику для больших очередей
                if (startQueueSize > 10) {
                    const duration = Date.now() - startTime;
                    const speed = (startQueueSize / (duration / 1000)).toFixed(2);
                    console.log(`✅ [Engine] Очередь обработана: ${startQueueSize} сообщений за ${duration}мс (${speed} msg/sec)`);
                }
                return;
            }

            // Берём первое сообщение из очереди
            const message = this.sendQueue.shift();

            // Отправляем
            try {
                if (window.chrome && window.chrome.webview) {
                    window.chrome.webview.postMessage(JSON.stringify(message));
                } else {
                    console.error('❌ WebView2 API недоступен!');
                    this.stopSendQueue(); // Останавливаем если API недоступен
                }
            } catch (error) {
                console.error('❌ [Engine] Ошибка отправки:', error, 'Message:', message);
            }
        }, this.sendDelay); // Интервал 1мс
    },

    // ===============================================================================
    // Остановка очереди отправки
    // ===============================================================================
    stopSendQueue: function () {
        if (this.sendIntervalId) {
            clearInterval(this.sendIntervalId);
            this.sendIntervalId = null;
        }
        this.sendInProgress = false;
    },

    // ===============================================================================
    // Обработка сообщений от AutoIt
    // ===============================================================================
    handleAutoItMessage: function (messageData) {
        try {
            const message = JSON.parse(messageData);

            // Обработка пушинга данных от AutoIt
            if (message.type === 'update_element') {
                this.handleElementUpdate(message.payload);
                return;
            }

            // Логирование ответов для диагностики параллельных запросов
            if (message.type === 'response' && message.payload && message.payload.requestId) {
                // Логируем только если много ответов (стресс-тест)
                if (!this._responseCount) this._responseCount = 0;
                this._responseCount++;
                
                if (this._responseCount % 10 === 0) {
                    console.log(`📥 [Engine] Получено ответов: ${this._responseCount}`);
                }
            }

            // Вызываем зарегистрированный callback
            // Передаём payload если есть, иначе data
            if (message.type && this.callbacks[message.type]) {
                const callbackData = message.payload !== undefined ? message.payload : message.data;
                this.callbacks[message.type](callbackData);
            } else if (message.type === 'response') {
                // Если нет callback для response - это проблема!
                console.error('⚠️ [Engine] Нет callback для response! RequestId:', message.payload?.requestId);
            }

        } catch (error) {
            console.error('❌ [Engine] Ошибка обработки сообщения от AutoIt:', error, 'Data:', messageData);
        }
    },

    // ===============================================================================
    // Обработка обновления элементов от AutoIt (энергоэффективная версия)
    // ===============================================================================
    handleElementUpdate: function (data) {
        try {
            // data - это массив [elementId, value] напрямую
            const elementId = data[0];
            const value = data[1];

            // Добавляем в очередь обновлений вместо немедленного обновления
            this.updateQueue.set(elementId, value);

            // Планируем пакетное обновление если еще не запланировано
            if (!this.updateScheduled) {
                this.updateScheduled = true;
                requestAnimationFrame(() => this.processBatchUpdates());
            }
            
            // Отправляем подтверждение сразу (не ждём обновления DOM)
            this.sendToAutoIt('push_confirmed', {
                type: 'update_element',
                element: elementId,
                value: value
            });

        } catch (error) {
            console.error('❌ Ошибка обновления элемента:', error);
        }
    },

    // ===============================================================================
    // Пакетная обработка обновлений (выполняется в следующем кадре)
    // ===============================================================================
    processBatchUpdates: function () {
        this.updateScheduled = false;

        // Обрабатываем все накопленные обновления за один раз
        for (const [elementId, value] of this.updateQueue) {
            const element = document.getElementById(elementId);
            if (!element) continue;

            // Проверяем, изменилось ли значение (избегаем лишних DOM операций)
            const currentValue = element.textContent;
            if (currentValue === String(value)) continue;

            // Обновляем только если значение действительно изменилось
            element.textContent = value;

            // Энергоэффективная анимация через CSS класс
            element.classList.remove('updated');
            element.offsetHeight; // Принудительный reflow
            element.classList.add('updated');
        }

        // Очищаем очередь
        this.updateQueue.clear();
    },

    // ===============================================================================
    // Регистрация обработчиков сообщений
    // ===============================================================================
    on: function (messageType, callback) {
        this.callbacks[messageType] = callback;
    },

    // ===============================================================================
    // Утилиты для работы с DOM
    // ===============================================================================
    updateElement: function (elementId, value) {
        const element = document.getElementById(elementId);
        if (element) {
            element.textContent = value;
            return true;
        }
        console.warn('⚠️ Элемент не найден:', elementId);
        return false;
    },

    setElementHTML: function (elementId, html) {
        const element = document.getElementById(elementId);
        if (element) {
            element.innerHTML = html;
            return true;
        }
        console.warn('⚠️ Элемент не найден:', elementId);
        return false;
    },

    setElementClass: function (elementId, className) {
        const element = document.getElementById(elementId);
        if (element) {
            element.className = className;
            return true;
        }
        console.warn('⚠️ Элемент не найден:', elementId);
        return false;
    },

    showElement: function (elementId) {
        const element = document.getElementById(elementId);
        if (element) {
            element.style.display = 'block';
            return true;
        }
        return false;
    },

    hideElement: function (elementId) {
        const element = document.getElementById(elementId);
        if (element) {
            element.style.display = 'none';
            return true;
        }
        return false;
    },

    // ===============================================================================
    // Запрос данных от AutoIt
    // ===============================================================================
    requestData: function (dataType, params = null) {
        return this.sendToAutoIt('request_data', {
            type: dataType,
            params: params
        });
    },

    // ===============================================================================
    // Уведомления и статусы
    // ===============================================================================
    setStatus: function (status, message = '') {
        this.sendToAutoIt('status_update', {
            status: status,
            message: message
        });
    },

    // ===============================================================================
    // Проверка готовности
    // ===============================================================================
    ready: function () {
        return this.isReady;
    }
};

// ===============================================================================
// Автоинициализация при загрузке DOM
// ===============================================================================
document.addEventListener('DOMContentLoaded', function () {
    // Небольшая задержка для гарантии готовности WebView2
    setTimeout(() => {
        WebView2Engine.init();
    }, 100);
});

// ===============================================================================
// Глобальная функция для обработки сообщений (вызывается из AutoIt)
// ===============================================================================
window.handleAutoItMessage = function (message) {
    WebView2Engine.handleAutoItMessage(JSON.stringify(message));
};

// ===============================================================================
// Экспорт для обратной совместимости
// ===============================================================================
window.sendMessageToAutoIt = function (command, data = null) {
    return WebView2Engine.sendToAutoIt(command, data);
};

console.log('📦 WebView2 Engine загружен');


// ===============================================================================
// ОБРАБОТЧИКИ ПУШИНГА (AutoIt → JavaScript)
// ===============================================================================

// Обработчик обновления элемента
WebView2Engine.on('update_element', function(data) {
    // data - это массив [elementId, value] напрямую из payload
    const elementId = data[0];
    const value = data[1];
    
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = value;
        console.log(`✅ Element updated: ${elementId} = ${value}`);
        
        // Отправляем подтверждение обратно в AutoIt
        WebView2Engine.sendToAutoIt('push_confirmed', {
            type: 'update_element',
            element: elementId,
            value: value
        });
    } else {
        console.warn(`⚠️ Element not found: ${elementId}`);
    }
});

// Обработчик установки HTML
WebView2Engine.on('set_html', function(data) {
    const elementId = data[0];
    const html = data[1];
    
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = html;
        console.log(`✅ HTML set: ${elementId}`);
        
        WebView2Engine.sendToAutoIt('push_confirmed', {
            type: 'set_html',
            element: elementId
        });
    } else {
        console.warn(`⚠️ Element not found: ${elementId}`);
    }
});

// Обработчик установки класса
WebView2Engine.on('set_class', function(data) {
    const elementId = data[0];
    const className = data[1];
    
    const element = document.getElementById(elementId);
    if (element) {
        element.className = className;
        console.log(`✅ Class set: ${elementId} = ${className}`);
        
        WebView2Engine.sendToAutoIt('push_confirmed', {
            type: 'set_class',
            element: elementId,
            className: className
        });
    } else {
        console.warn(`⚠️ Element not found: ${elementId}`);
    }
});

// Обработчик показа элемента
WebView2Engine.on('show_element', function(data) {
    const elementId = typeof data === 'string' ? data : (data.payload || data);
    
    const element = document.getElementById(elementId);
    if (element) {
        element.style.display = 'block';
        console.log(`✅ Element shown: ${elementId}`);
        
        WebView2Engine.sendToAutoIt('push_confirmed', {
            type: 'show_element',
            element: elementId
        });
    } else {
        console.warn(`⚠️ Element not found: ${elementId}`);
    }
});

// Обработчик скрытия элемента
WebView2Engine.on('hide_element', function(data) {
    const elementId = typeof data === 'string' ? data : (data.payload || data);
    
    const element = document.getElementById(elementId);
    if (element) {
        element.style.display = 'none';
        console.log(`✅ Element hidden: ${elementId}`);
        
        WebView2Engine.sendToAutoIt('push_confirmed', {
            type: 'hide_element',
            element: elementId
        });
    } else {
        console.warn(`⚠️ Element not found: ${elementId}`);
    }
});

// Обработчик вызова JS функции
WebView2Engine.on('call_function', function(data) {
    const functionName = data[0];
    const params = data[1];
    
    if (typeof window[functionName] === 'function') {
        try {
            window[functionName].apply(null, params);
            console.log(`✅ Function called: ${functionName}()`);
            
            WebView2Engine.sendToAutoIt('push_confirmed', {
                type: 'call_function',
                function: functionName
            });
        } catch (error) {
            console.error(`❌ Function error: ${functionName}()`, error);
        }
    } else {
        console.warn(`⚠️ Function not found: ${functionName}()`);
    }
});

// Обработчик уведомлений
WebView2Engine.on('notify', function(data) {
    const type = data[0];
    const message = data[1];
    
    console.log(`🔔 Notification [${type}]: ${message}`);
    
    // Используем кастомное уведомление для автокликера
    if (message.includes('Автокликер') || message.includes('автокликер')) {
        // Проверяем на "включен" в любом регистре
        const enabled = message.toLowerCase().includes('включен');
        if (typeof window.notifyAutoClicker === 'function') {
            window.notifyAutoClicker(enabled);
        }
    } else {
        // Обычное уведомление через Toastify
        if (typeof window.Notifications !== 'undefined') {
            window.Notifications.show(message, type);
        }
    }
    
    WebView2Engine.sendToAutoIt('push_confirmed', {
        type: 'notify',
        notifyType: type,
        message: message
    });
});

// ===============================================================================
// УНИВЕРСАЛЬНЫЙ ОБРАБОТЧИК ДАННЫХ (массивы, JSON, простые типы)
// ===============================================================================
WebView2Engine.on('update_data', function(data) {
    const elementId = data[0];
    const value = data[1];
    
    const element = document.getElementById(elementId);
    if (!element) {
        console.warn(`⚠️ Element not found: ${elementId}`);
        return;
    }
    
    // Определяем тип данных
    let parsedValue = value;
    let dataType = typeof value;
    
    // Пытаемся распарсить как JSON (для массивов/объектов)
    if (typeof value === 'string' && (value.startsWith('[') || value.startsWith('{'))) {
        try {
            parsedValue = JSON.parse(value);
            dataType = Array.isArray(parsedValue) ? 'array' : 'object';
        } catch (e) {
            // Если не JSON - оставляем как строку
            parsedValue = value;
            dataType = 'string';
        }
    }
    
    // Обновляем элемент в зависимости от типа
    if (Array.isArray(parsedValue)) {
        // Массив - отображаем как JSON с форматированием
        element.textContent = JSON.stringify(parsedValue, null, 2);
        console.log(`✅ Array updated: ${elementId}`, parsedValue);
    } else if (typeof parsedValue === 'object' && parsedValue !== null) {
        // Объект - отображаем как JSON с форматированием
        element.textContent = JSON.stringify(parsedValue, null, 2);
        console.log(`✅ Object updated: ${elementId}`, parsedValue);
    } else {
        // Простое значение
        element.textContent = parsedValue;
        console.log(`✅ Value updated: ${elementId} = ${parsedValue}`);
    }
    
    // Анимация обновления
    element.classList.remove('updated');
    element.offsetHeight; // Принудительный reflow
    element.classList.add('updated');
    
    // Подтверждение
    WebView2Engine.sendToAutoIt('push_confirmed', {
        type: 'update_data',
        element: elementId,
        dataType: dataType,
        isArray: Array.isArray(parsedValue),
        arrayDimension: Array.isArray(parsedValue) ? (Array.isArray(parsedValue[0]) ? '2D' : '1D') : null
    });
});

// ===============================================================================
// ОБРАБОТЧИК УСТАНОВКИ ID ОКНА (от AutoIt)
// ===============================================================================
WebView2Engine.on('set_window_id', function(windowId) {
    WebView2Engine.windowId = windowId;
    // Логирование убрано - служебное событие
});

// ===============================================================================
// ОБРАБОТЧИК ТАБЛИЦЫ ДАТЧИКОВ (ТЕСТ ВЫСОКОЙ НАГРУЗКИ)
// ===============================================================================
WebView2Engine.on('SENSOR_TABLE', function(data) {
    try {
        console.log('📥 Получена таблица, тип данных:', typeof data, 'длина:', Array.isArray(data) ? data.length : 'не массив');
        
        // data уже является массивом (payload передаётся напрямую)
        const table = data;
        
        // Обновляем таблицу на странице
        const tbody = document.querySelector('#dataTable tbody');
        if (tbody) {
            // Очищаем старые данные
            tbody.innerHTML = '';
            
            // Добавляем новые строки
            table.forEach(row => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>${row[0]}</td>
                    <td>${row[1]}</td>
                    <td>${row[2]}</td>
                    <td><span class="status-${row[3]}">${row[3]}</span></td>
                `;
                tbody.appendChild(tr);
            });
        }
        
        // Отправляем ACK обратно в AutoIt
        console.log('📤 Отправляю ACK...');
        WebView2Engine.sendToAutoIt('ack_received', {
            timestamp: Date.now(),
            rowsReceived: table.length
        });
        console.log('✅ ACK отправлен');
        
    } catch (error) {
        console.error('❌ Ошибка обработки таблицы:', error);
    }
});

console.log('📦 Push handlers registered');
