// ===============================================================================
// test11.js - Тесты для Full Bridge
// ===============================================================================

// Обновляем статус engine после инициализации
WebView2Engine.on('engine_ready', function() {
    document.getElementById('engine-status').textContent = 'Ready ✅';
    console.log('Engine готов к работе!');
});

// ===============================================================================
// Console Tests
// ===============================================================================
function testConsoleLog() {
    console.log('Это тестовое сообщение console.log');
    updateStatus('Отправлен console.log');
}

function testConsoleWarn() {
    console.warn('Это предупреждение console.warn');
    updateStatus('Отправлен console.warn');
}

function testConsoleError() {
    console.error('Это ошибка console.error');
    updateStatus('Отправлен console.error');
}

function testConsoleInfo() {
    console.info('Это информация console.info');
    updateStatus('Отправлен console.info');
}

// ===============================================================================
// Error Tests
// ===============================================================================
function testJSError() {
    updateStatus('Генерация JS ошибки...');
    // Намеренная ошибка
    throw new Error('Это тестовая ошибка JavaScript!');
}

function testUndefinedError() {
    updateStatus('Обращение к undefined переменной...');
    // Обращение к несуществующей переменной
    console.log(thisVariableDoesNotExist);
}

// ===============================================================================
// Message Tests
// ===============================================================================
function testSimpleMessage() {
    WebView2Engine.sendToAutoIt('simple_test', 'Привет из JavaScript!');
    updateStatus('Отправлено простое сообщение');
}

function testJSONMessage() {
    WebView2Engine.sendToAutoIt('json_test', {
        action: 'button_click',
        button_id: 'test_button',
        timestamp: Date.now()
    });
    updateStatus('Отправлено JSON сообщение');
}

function testDataMessage() {
    WebView2Engine.sendToAutoIt('data_test', {
        sensor_id: 'TEMP_001',
        value: 25.5,
        unit: 'celsius',
        status: 'ok'
    });
    updateStatus('Отправлены данные датчика');
}

// ===============================================================================
// Утилиты
// ===============================================================================
function updateStatus(message) {
    document.getElementById('status').textContent = message;
    console.log('Status:', message);
}

console.log('test11.js загружен');
