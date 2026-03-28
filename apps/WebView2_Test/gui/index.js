// ===============================================================================
// index.js - Логика главной страницы WebView2 Start Template
// Версия: 2.0.0
// Описание: Вся JavaScript логика для index.html
// ===============================================================================

// Состояние страницы
let pageState = {
    currentTab: 'home',
    parserRunning: false,
    startTime: Date.now(),
    statistics: {
        uptime: '00:00:00',
        totalRequests: 0,
        successRate: 0,
        memoryUsage: 0,
        activeCounters: 0,
        errorCount: 0
    }
};

// ===============================================================================
// Инициализация страницы
// ===============================================================================
document.addEventListener('DOMContentLoaded', function() {
    console.log('🏠 Главная страница загружена');
    
    // Ждем готовности движка
    const waitForEngine = () => {
        if (window.WebView2Engine && WebView2Engine.ready()) {
            initializePage();
        } else {
            setTimeout(waitForEngine, 50);
        }
    };
    waitForEngine();
});

function initializePage() {
    console.log('🔧 Инициализация главной страницы');
    
    // Регистрируем обработчики сообщений от AutoIt
    WebView2Engine.on('parser_status', handleParserStatus);
    WebView2Engine.on('statistics_update', handleStatisticsUpdate);
    WebView2Engine.on('uptime_update', handleUptimeUpdate);
    WebView2Engine.on('error_notification', handleErrorNotification);
    
    // Устанавливаем начальные значения
    updateUptime();
    updateParserStatus(false);
    
    // Уведомляем AutoIt о готовности страницы
    WebView2Engine.sendToAutoIt('page_ready', { page: 'index' });
    
    console.log('✅ Главная страница готова');
}

// ===============================================================================
// Навигация между вкладками
// ===============================================================================
function switchTab(tabId) {
    console.log(`🔄 Переключение на вкладку: ${tabId}`);
    
    // Убираем активный класс у всех табов и страниц
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));

    // Находим и активируем нужную вкладку
    const tabs = document.querySelectorAll('.tab');
    const tabIndex = ['home', 'counters', 'settings', 'logs'].indexOf(tabId);
    if (tabIndex >= 0 && tabs[tabIndex]) {
        tabs[tabIndex].classList.add('active');
    }

    // Показываем соответствующую страницу
    const targetPage = document.getElementById(tabId);
    if (targetPage) {
        targetPage.classList.add('active');
        pageState.currentTab = tabId;
    }
    
    // Уведомляем AutoIt о смене вкладки
    WebView2Engine.sendToAutoIt('tab_changed', { tab: tabId });
}

// ===============================================================================
// Управление парсером
// ===============================================================================
function startParser() {
    console.log('▶️ Запуск парсера');
    
    pageState.parserRunning = true;
    updateParserStatus(true);
    
    // Отправляем команду в AutoIt
    WebView2Engine.sendToAutoIt('start_parser');
}

function stopParser() {
    console.log('⏹️ Остановка парсера');
    
    pageState.parserRunning = false;
    updateParserStatus(false);
    
    // Отправляем команду в AutoIt
    WebView2Engine.sendToAutoIt('stop_parser');
}

function restartParser() {
    console.log('🔄 Перезапуск парсера');
    
    // Сначала останавливаем
    stopParser();
    
    // Через небольшую задержку запускаем
    setTimeout(() => {
        startParser();
    }, 500);
    
    // Отправляем команду в AutoIt
    WebView2Engine.sendToAutoIt('restart_parser');
}

// ===============================================================================
// Обновление интерфейса
// ===============================================================================
function updateParserStatus(running) {
    const statusElement = document.getElementById('parserStatus');
    const startBtn = document.getElementById('startBtn');
    const stopBtn = document.getElementById('stopBtn');
    
    if (statusElement) {
        if (running) {
            statusElement.className = 'status online';
            statusElement.innerHTML = '<span class="status-dot"></span>Работает';
        } else {
            statusElement.className = 'status offline';
            statusElement.innerHTML = '<span class="status-dot"></span>Остановлен';
        }
    }
    
    if (startBtn && stopBtn) {
        startBtn.disabled = running;
        stopBtn.disabled = !running;
    }
    
    pageState.parserRunning = running;
}

function updateUptime() {
    const uptimeElement = document.getElementById('uptime');
    if (!uptimeElement) return;
    
    const uptimeMs = Date.now() - pageState.startTime;
    const uptimeSeconds = Math.floor(uptimeMs / 1000);
    
    const hours = Math.floor(uptimeSeconds / 3600);
    const minutes = Math.floor((uptimeSeconds % 3600) / 60);
    const seconds = uptimeSeconds % 60;
    
    const uptimeString = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    uptimeElement.textContent = uptimeString;
    pageState.statistics.uptime = uptimeString;
}

function updateStatistics(stats) {
    if (!stats) return;
    
    // Обновляем внутреннее состояние
    Object.assign(pageState.statistics, stats);
    
    // Обновляем элементы интерфейса
    const elements = {
        totalRequests: document.getElementById('totalRequests'),
        successRate: document.getElementById('successRate'),
        memoryUsage: document.getElementById('memoryUsage'),
        activeCounters: document.getElementById('activeCounters'),
        errorCount: document.getElementById('errorCount')
    };
    
    if (elements.totalRequests && stats.totalRequests !== undefined) {
        elements.totalRequests.textContent = stats.totalRequests.toLocaleString();
    }
    
    if (elements.successRate && stats.successRate !== undefined) {
        elements.successRate.textContent = Math.round(stats.successRate) + '%';
    }
    
    if (elements.memoryUsage && stats.memoryUsage !== undefined) {
        elements.memoryUsage.textContent = Math.round(stats.memoryUsage) + ' MB';
    }
    
    if (elements.activeCounters && stats.activeCounters !== undefined) {
        elements.activeCounters.textContent = `${stats.activeCounters}/7`;
    }
    
    if (elements.errorCount && stats.errorCount !== undefined) {
        elements.errorCount.textContent = stats.errorCount.toString();
    }
}

function refreshData() {
    console.log('🔄 Запрос обновления данных');
    WebView2Engine.sendToAutoIt('refresh_data');
    updateUptime();
}

// ===============================================================================
// Управление режимом реального времени
// ===============================================================================
function toggleRealtime() {
    console.log('🔄 Переключение режима реального времени');
    WebView2Engine.sendToAutoIt('toggle_realtime');
}

// ===============================================================================
// Обработчики сообщений от AutoIt
// ===============================================================================
function handleParserStatus(data) {
    if (data && data.running !== undefined) {
        updateParserStatus(data.running);
    }
}

function handleStatisticsUpdate(data) {
    updateStatistics(data);
}

function handleUptimeUpdate(data) {
    updateUptime();
}

function handleErrorNotification(data) {
    console.error('❌ Ошибка от AutoIt:', data);
    
    // Можно добавить отображение уведомлений об ошибках
    if (data && data.message) {
        // Здесь можно добавить toast уведомления
        console.error('Ошибка:', data.message);
    }
}

// ===============================================================================
// Экспорт функций для глобального доступа (onclick в HTML)
// ===============================================================================
window.switchTab = switchTab;
window.startParser = startParser;
window.stopParser = stopParser;
window.restartParser = restartParser;
window.refreshData = refreshData;
window.toggleRealtime = toggleRealtime;

// Экспорт объекта страницы
window.IndexPage = {
    switchTab,
    startParser,
    stopParser,
    restartParser,
    refreshData,
    updateStatistics,
    updateUptime,
    getState: () => pageState
};

console.log('📄 index.js загружен и готов');