// ===============================================================================
// Test Utils Page - Тестовая страница для проверки утилит
// Версия: 1.0.0
// ===============================================================================

class TestUtilsPage extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        this.render();
        this.attachEventListeners();
    }

    render() {
        this.innerHTML = `
            <div class="page-header d-print-none">
                <div class="container-xl">
                    <div class="row g-2 align-items-center">
                        <div class="col">
                            <h2 class="page-title">Тест утилит</h2>
                            <div class="text-muted mt-1">Проверка RequestHub, Toast и Tooltips</div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="page-body">
                <div class="container-xl">
                    <!-- RequestHub Tests -->
                    <div class="card mb-3">
                        <div class="card-header">
                            <h3 class="card-title">RequestHub - Запросы к AutoIt</h3>
                        </div>
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-4">
                                    <button id="btn-test-request" class="btn btn-primary w-100">
                                        Тестовый запрос
                                    </button>
                                </div>
                                <div class="col-md-4">
                                    <button id="btn-get-app-info" class="btn btn-info w-100">
                                        Информация о приложении
                                    </button>
                                </div>
                                <div class="col-md-4">
                                    <button id="btn-get-counters" class="btn btn-success w-100">
                                        Статус счётчиков
                                    </button>
                                </div>
                            </div>
                            <div class="mt-3">
                                <label class="form-label">Результат запроса:</label>
                                <pre id="request-result" class="bg-dark text-light p-3 rounded" style="max-height: 300px; overflow-y: auto;">Нажмите на кнопку для отправки запроса...</pre>
                            </div>
                        </div>
                    </div>

                    <!-- Toast Tests -->
                    <div class="card mb-3">
                        <div class="card-header">
                            <h3 class="card-title">Toast - Уведомления</h3>
                        </div>
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-3">
                                    <button id="btn-toast-success" class="btn btn-success w-100" 
                                            data-tooltip="Показать успешное уведомление" 
                                            data-tooltip-placement="top">
                                        Success
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-toast-error" class="btn btn-danger w-100"
                                            data-tooltip="Показать ошибку"
                                            data-tooltip-placement="top">
                                        Error
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-toast-warning" class="btn btn-warning w-100"
                                            data-tooltip="Показать предупреждение"
                                            data-tooltip-placement="top">
                                        Warning
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-toast-info" class="btn btn-info w-100"
                                            data-tooltip="Показать информацию"
                                            data-tooltip-placement="top">
                                        Info
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- RequestHub Stats -->
                    <!-- RequestHub Stats -->
                    <div class="card mb-3">
                        <div class="card-header">
                            <h3 class="card-title">RequestHub - Статистика</h3>
                        </div>
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <button id="btn-show-stats" class="btn btn-outline-primary w-100"
                                            data-tooltip="Показать статистику запросов (успешные, ошибки, таймауты)"
                                            data-tooltip-placement="right">
                                        Показать статистику
                                    </button>
                                </div>
                                <div class="col-md-6">
                                    <button id="btn-show-last-request" class="btn btn-outline-info w-100"
                                            data-tooltip="Показать информацию о последнем запросе (тип, payload, ответ)"
                                            data-tooltip-placement="left">
                                        Последний запрос
                                    </button>
                                </div>
                            </div>
                            <pre id="stats-result" class="bg-dark text-light p-3 rounded mt-3" style="display: none;"></pre>
                        </div>
                    </div>

                    <!-- Advanced Notifications Demo -->
                    <div class="card mb-3">
                        <div class="card-header">
                            <h3 class="card-title">🎨 Продвинутые уведомления</h3>
                        </div>
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-3">
                                    <button id="btn-toast-long" class="btn btn-outline-primary w-100"
                                            data-tooltip="Уведомление на 10 секунд"
                                            data-tooltip-theme="dark">
                                        Долгое (10s)
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-toast-bottom" class="btn btn-outline-success w-100"
                                            data-tooltip="Уведомление снизу по центру">
                                        Снизу по центру
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-toast-left" class="btn btn-outline-warning w-100"
                                            data-tooltip="Уведомление слева сверху">
                                        Слева сверху
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-toast-click" class="btn btn-outline-info w-100"
                                            data-tooltip="Уведомление с действием при клике">
                                        С действием
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Stress Tests -->
                    <div class="card mb-3">
                        <div class="card-header">
                            <h3 class="card-title">🔬 Стресс-тесты RequestHub</h3>
                        </div>
                        <div class="card-body">
                            <div class="row g-3 mb-3">
                                <div class="col-md-3">
                                    <button id="btn-stress-sequential" class="btn btn-outline-primary w-100"
                                            data-tooltip="100 запросов один за другим с автоматической переотправкой при ошибке (до 3 попыток). Замер общего времени и средней скорости."
                                            data-tooltip-placement="top">
                                        ⚡ Последовательный (100 + retry)
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-stress-hybrid" class="btn btn-outline-success w-100"
                                            data-tooltip="100 запросов последовательно, но каждый отправляет 5 копий параллельно. Первая пришедшая = успех. Высокая надёжность!"
                                            data-tooltip-placement="top">
                                        � Гибридный (100 × 5 копий)
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-stress-parallel" class="btn btn-outline-warning w-100"
                                            data-tooltip="1000 запросов одновременно. Проверка очереди и нагрузки на AutoIt."
                                            data-tooltip-placement="top">
                                        🚀 Параллельный (1000)
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-stress-burst" class="btn btn-outline-info w-100"
                                            data-tooltip="10 волн по 10 запросов с паузой 500мс. Имитация реальной нагрузки."
                                            data-tooltip-placement="top">
                                        🌊 Волновой (10x10)
                                    </button>
                                </div>
                            </div>
                            <div class="alert alert-info mb-3" role="alert">
                                <strong>Что тестируем:</strong> Скорость, задержки (min/max/avg/median/p95), надёжность (success/timeout/error %), разлёт времени ответов
                            </div>
                            <div id="stress-test-progress" class="mb-3" style="display: none;">
                                <div class="progress">
                                    <div id="stress-progress-bar" class="progress-bar progress-bar-striped progress-bar-animated" 
                                         role="progressbar" style="width: 0%"></div>
                                </div>
                                <div class="text-center mt-2">
                                    <span id="stress-progress-text">Выполнение теста...</span>
                                </div>
                            </div>
                            <pre id="stress-test-result" class="bg-dark text-light p-3 rounded" style="max-height: 400px; overflow-y: auto; display: none;"></pre>
                        </div>
                    </div>

                    <!-- Advanced Tooltips Demo -->
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">💬 Продвинутые подсказки</h3>
                        </div>
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-3">
                                    <button id="btn-tooltip-dark" class="btn btn-dark w-100"
                                            data-tooltip="Тёмная тема подсказки"
                                            data-tooltip-theme="dark"
                                            data-tooltip-placement="top">
                                        Тёмная тема
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-tooltip-html" class="btn btn-primary w-100">
                                        HTML контент
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-tooltip-interactive" class="btn btn-success w-100">
                                        Интерактивная
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-tooltip-delay" class="btn btn-warning w-100"
                                            data-tooltip="Появляется с задержкой 1 секунда"
                                            data-tooltip-placement="left">
                                        С задержкой
                                    </button>
                                </div>
                            </div>
                            <div class="row g-3 mt-2">
                                <div class="col-md-3">
                                    <button id="btn-tooltip-bottom" class="btn btn-info w-100"
                                            data-tooltip="Подсказка снизу"
                                            data-tooltip-placement="bottom">
                                        Снизу
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-tooltip-left" class="btn btn-secondary w-100"
                                            data-tooltip="Подсказка слева"
                                            data-tooltip-placement="left">
                                        Слева
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-tooltip-right" class="btn btn-danger w-100"
                                            data-tooltip="Подсказка справа"
                                            data-tooltip-placement="right">
                                        Справа
                                    </button>
                                </div>
                                <div class="col-md-3">
                                    <button id="btn-tooltip-click" class="btn btn-outline-primary w-100"
                                            data-tooltip="Открывается по клику"
                                            data-tooltip-placement="top">
                                        По клику
                                    </button>
                                </div>
                            </div>
                            <div class="row g-3 mt-2">
                                <div class="col-md-12">
                                    <button id="btn-tooltip-navigation" class="btn btn-primary w-100">
                                        Навигация по счётчикам
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    attachEventListeners() {
        // RequestHub Tests
        document.getElementById('btn-test-request').addEventListener('click', () => this.testRequest());
        document.getElementById('btn-get-app-info').addEventListener('click', () => this.getAppInfo());
        document.getElementById('btn-get-counters').addEventListener('click', () => this.getCountersStatus());

        // Toast Tests
        document.getElementById('btn-toast-success').addEventListener('click', () => {
            window.notifySuccess('Операция выполнена успешно!');
        });
        document.getElementById('btn-toast-error').addEventListener('click', () => {
            window.notifyError('Произошла ошибка!');
        });
        document.getElementById('btn-toast-warning').addEventListener('click', () => {
            window.notifyWarning('Внимание! Проверьте данные.');
        });
        document.getElementById('btn-toast-info').addEventListener('click', () => {
            window.notifyInfo('Информационное сообщение.');
        });

        // Stats
        document.getElementById('btn-show-stats').addEventListener('click', () => {
            const stats = window.RequestHub.getStats();
            const statsEl = document.getElementById('stats-result');
            statsEl.textContent = JSON.stringify(stats, null, 2);
            statsEl.style.display = 'block';
        });

        // Last Request
        document.getElementById('btn-show-last-request').addEventListener('click', () => {
            const lastRequest = window.RequestHub.getLastRequest();
            const statsEl = document.getElementById('stats-result');
            statsEl.textContent = JSON.stringify(lastRequest, null, 2);
            statsEl.style.display = 'block';
        });

        // ===============================================================================
        // Stress Tests
        // ===============================================================================
        
        document.getElementById('btn-stress-sequential').addEventListener('click', () => {
            this.runSequentialStressTest();
        });

        document.getElementById('btn-stress-hybrid').addEventListener('click', () => {
            this.runHybridStressTest();
        });

        document.getElementById('btn-stress-parallel').addEventListener('click', () => {
            this.runParallelStressTest();
        });

        document.getElementById('btn-stress-burst').addEventListener('click', () => {
            this.runBurstStressTest();
        });

        // ===============================================================================
        // Advanced Notifications
        // ===============================================================================
        
        // Долгое уведомление (10 секунд)
        document.getElementById('btn-toast-long').addEventListener('click', () => {
            notifyInfo('Это уведомление будет показано 10 секунд', { duration: 10000 });
        });

        // Уведомление снизу по центру
        document.getElementById('btn-toast-bottom').addEventListener('click', () => {
            notifySuccess('Уведомление снизу по центру!', {
                gravity: 'bottom',
                position: 'center'
            });
        });

        // Уведомление слева сверху
        document.getElementById('btn-toast-left').addEventListener('click', () => {
            notifyWarning('Уведомление слева сверху!', {
                gravity: 'top',
                position: 'left'
            });
        });

        // Уведомление с действием при клике
        document.getElementById('btn-toast-click').addEventListener('click', () => {
            notifyInfo('Кликни на меня!', {
                duration: 5000,
                onClick: () => {
                    alert('Вы кликнули на уведомление!');
                }
            });
        });

        // ===============================================================================
        // Advanced Tooltips
        // ===============================================================================
        
        // HTML контент в tooltip
        createTooltip('#btn-tooltip-html', {
            content: '<strong>Жирный текст</strong><br><em>Курсив</em><br><u>Подчёркнутый</u>',
            allowHTML: true,
            placement: 'top',
            theme: 'light-border'
        });

        // Интерактивный tooltip
        createTooltip('#btn-tooltip-interactive', {
            content: '<button class="btn btn-sm btn-primary" onclick="alert(\'Работает!\')">Кликни меня</button>',
            allowHTML: true,
            interactive: true,
            trigger: 'click',
            placement: 'bottom'
        });

        // Tooltip с задержкой
        createTooltip('#btn-tooltip-delay', {
            content: 'Появился с задержкой!',
            delay: [1000, 0],
            placement: 'right'
        });

        // Tooltip по клику
        createTooltip('#btn-tooltip-click', {
            content: 'Открывается по клику, а не при наведении',
            trigger: 'click',
            placement: 'bottom',
            theme: 'translucent'
        });

        // Интерактивная навигация по счётчикам
        createTooltip('#btn-tooltip-navigation', {
            content: `
                <div style="padding: 8px;">
                    <div style="font-weight: 600; margin-bottom: 12px; color: #206bc4;">Быстрый переход:</div>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 6px;">
                        <button class="btn btn-sm btn-outline-primary" onclick="navigateToCounter(1)">Счётчик 1</button>
                        <button class="btn btn-sm btn-outline-success" onclick="navigateToCounter(2)">Счётчик 2</button>
                        <button class="btn btn-sm btn-outline-info" onclick="navigateToCounter(3)">Счётчик 3</button>
                        <button class="btn btn-sm btn-outline-warning" onclick="navigateToCounter(4)">Счётчик 4</button>
                        <button class="btn btn-sm btn-outline-danger" onclick="navigateToCounter(5)">Счётчик 5</button>
                        <button class="btn btn-sm btn-outline-secondary" onclick="navigateToCounter(6)">Счётчик 6</button>
                        <button class="btn btn-sm btn-outline-dark" onclick="navigateToCounter(7)">Счётчик 7</button>
                        <button class="btn btn-sm btn-primary" onclick="navigateToCounter('online')">Онлайн</button>
                    </div>
                </div>
            `,
            allowHTML: true,
            interactive: true,
            trigger: 'click',
            placement: 'bottom',
            theme: 'light-border',
            maxWidth: 350
        });
    }

    // ===============================================================================
    // RequestHub Methods
    // ===============================================================================

    async testRequest() {
        const resultEl = document.getElementById('request-result');
        resultEl.textContent = 'Отправка запроса...';

        try {
            const response = await window.RequestHub.send('test_request', { test: true });
            resultEl.textContent = JSON.stringify(response, null, 2);
            window.notifySuccess('Тестовый запрос выполнен!');
        } catch (error) {
            resultEl.textContent = 'Ошибка: ' + error.message;
            window.notifyError('Ошибка запроса: ' + error.message);
        }
    }

    async getAppInfo() {
        const resultEl = document.getElementById('request-result');
        resultEl.textContent = 'Получение информации...';

        try {
            const response = await window.RequestHub.sendReliable('get_app_info');
            resultEl.textContent = JSON.stringify(response, null, 2);
            window.notifySuccess('Информация получена!');
        } catch (error) {
            resultEl.textContent = 'Ошибка: ' + error.message;
            window.notifyError('Ошибка запроса: ' + error.message);
        }
    }

    async getCountersStatus() {
        const resultEl = document.getElementById('request-result');
        resultEl.textContent = 'Получение статуса счётчиков...';

        try {
            const response = await window.RequestHub.sendReliable('get_counters_status');
            resultEl.textContent = JSON.stringify(response, null, 2);
            window.notifySuccess('Статус получен!');
        } catch (error) {
            resultEl.textContent = 'Ошибка: ' + error.message;
            window.notifyError('Ошибка запроса: ' + error.message);
        }
    }

    // ===============================================================================
    // Stress Test Methods
    // ===============================================================================

    showProgress(show = true) {
        const progressEl = document.getElementById('stress-test-progress');
        progressEl.style.display = show ? 'block' : 'none';
    }

    updateProgress(percent, text) {
        const progressBar = document.getElementById('stress-progress-bar');
        const progressText = document.getElementById('stress-progress-text');
        progressBar.style.width = percent + '%';
        progressText.textContent = text;
    }

    showResult(result) {
        const resultEl = document.getElementById('stress-test-result');
        resultEl.textContent = result;
        resultEl.style.display = 'block';
    }

    calculateStats(latencies) {
        if (latencies.length === 0) return null;

        const sorted = [...latencies].sort((a, b) => a - b);
        const sum = sorted.reduce((a, b) => a + b, 0);
        
        return {
            min: Math.round(sorted[0]),
            max: Math.round(sorted[sorted.length - 1]),
            avg: Math.round(sum / sorted.length),
            median: Math.round(sorted[Math.floor(sorted.length / 2)]),
            p95: Math.round(sorted[Math.floor(sorted.length * 0.95)]),
            jitter: Math.round(sorted[sorted.length - 1] - sorted[0])
        };
    }

    formatResult(testName, totalTime, count, results) {
        const success = results.filter(r => r.status === 'success').length;
        const timeout = results.filter(r => r.status === 'timeout').length;
        const error = results.filter(r => r.status === 'error').length;
        
        const successLatencies = results
            .filter(r => r.status === 'success')
            .map(r => r.latency);
        
        const stats = this.calculateStats(successLatencies);
        const throughput = (count / (totalTime / 1000)).toFixed(2);
        const successRate = ((success / count) * 100).toFixed(1);

        return `
📊 СТРЕСС-ТЕСТ: ${testName}
${'='.repeat(80)}

⏱️  ВРЕМЯ ВЫПОЛНЕНИЯ
   Общее время:        ${(totalTime / 1000).toFixed(2)} сек
   Скорость:           ${throughput} запросов/сек

📈 ЗАДЕРЖКИ (мс)
   Минимальная:        ${stats.min} мс
   Максимальная:       ${stats.max} мс
   Средняя:            ${stats.avg} мс
   Медиана (50%):      ${stats.median} мс
   95-й перцентиль:    ${stats.p95} мс
   Разлёт (jitter):    ${stats.jitter} мс

✅ НАДЁЖНОСТЬ
   Всего запросов:     ${count}
   Успешных:           ${success} (${successRate}%)
   Таймаутов:          ${timeout} (${((timeout / count) * 100).toFixed(1)}%)
   Ошибок:             ${error} (${((error / count) * 100).toFixed(1)}%)

${'='.repeat(80)}
        `.trim();
    }

    formatResultWithRetries(testName, totalTime, count, results, totalRetries) {
        const success = results.filter(r => r.status === 'success').length;
        const timeout = results.filter(r => r.status === 'timeout').length;
        const error = results.filter(r => r.status === 'error').length;
        
        const successLatencies = results
            .filter(r => r.status === 'success')
            .map(r => r.latency);
        
        const stats = this.calculateStats(successLatencies);
        const throughput = (count / (totalTime / 1000)).toFixed(2);
        const successRate = ((success / count) * 100).toFixed(1);

        // Статистика по попыткам
        const retriedRequests = results.filter(r => r.retried).length;
        const attempt1 = results.filter(r => r.status === 'success' && r.attempts === 1).length;
        const attempt2 = results.filter(r => r.status === 'success' && r.attempts === 2).length;
        const attempt3 = results.filter(r => r.status === 'success' && r.attempts === 3).length;
        const totalAttempts = count + totalRetries;

        return `
📊 СТРЕСС-ТЕСТ: ${testName}
${'='.repeat(80)}

⏱️  ВРЕМЯ ВЫПОЛНЕНИЯ
   Общее время:        ${(totalTime / 1000).toFixed(2)} сек
   Скорость:           ${throughput} запросов/сек

📈 ЗАДЕРЖКИ (мс)
   Минимальная:        ${stats.min} мс
   Максимальная:       ${stats.max} мс
   Средняя:            ${stats.avg} мс
   Медиана (50%):      ${stats.median} мс
   95-й перцентиль:    ${stats.p95} мс
   Разлёт (jitter):    ${stats.jitter} мс

✅ НАДЁЖНОСТЬ
   Всего запросов:     ${count}
   Успешных:           ${success} (${successRate}%)
   Таймаутов:          ${timeout} (${((timeout / count) * 100).toFixed(1)}%)
   Ошибок:             ${error} (${((error / count) * 100).toFixed(1)}%)

🔄 ПЕРЕОТПРАВКИ (автоматический retry)
   Переотправлено:     ${retriedRequests} запросов (${((retriedRequests / count) * 100).toFixed(1)}%)
   Всего попыток:      ${totalAttempts} (${count} + ${totalRetries} retry)
   Успех с 1 попытки:  ${attempt1} (${((attempt1 / count) * 100).toFixed(1)}%)
   Успех с 2 попытки:  ${attempt2} (${((attempt2 / count) * 100).toFixed(1)}%)
   Успех с 3 попытки:  ${attempt3} (${((attempt3 / count) * 100).toFixed(1)}%)

${'='.repeat(80)}
        `.trim();
    }

    formatResultHybrid(testName, totalTime, count, results, totalCopiesSent, totalCopiesSucceeded) {
        const success = results.filter(r => r.status === 'success').length;
        const timeout = results.filter(r => r.status === 'timeout').length;
        const error = results.filter(r => r.status === 'error').length;
        
        const successLatencies = results
            .filter(r => r.status === 'success')
            .map(r => r.latency);
        
        const stats = this.calculateStats(successLatencies);
        const throughput = (count / (totalTime / 1000)).toFixed(2);
        const successRate = ((success / count) * 100).toFixed(1);
        const copySuccessRate = ((totalCopiesSucceeded / totalCopiesSent) * 100).toFixed(1);

        // Статистика по копиям
        const avgCopiesSucceeded = results
            .filter(r => r.status === 'success')
            .reduce((sum, r) => sum + r.copiesSucceeded, 0) / success;

        return `
📊 СТРЕСС-ТЕСТ: ${testName}
${'='.repeat(80)}

⏱️  ВРЕМЯ ВЫПОЛНЕНИЯ
   Общее время:        ${(totalTime / 1000).toFixed(2)} сек
   Скорость:           ${throughput} запросов/сек

📈 ЗАДЕРЖКИ (мс)
   Минимальная:        ${stats.min} мс
   Максимальная:       ${stats.max} мс
   Средняя:            ${stats.avg} мс
   Медиана (50%):      ${stats.median} мс
   95-й перцентиль:    ${stats.p95} мс
   Разлёт (jitter):    ${stats.jitter} мс

✅ НАДЁЖНОСТЬ
   Всего запросов:     ${count}
   Успешных:           ${success} (${successRate}%)
   Таймаутов:          ${timeout} (${((timeout / count) * 100).toFixed(1)}%)
   Ошибок:             ${error} (${((error / count) * 100).toFixed(1)}%)

📦 ИЗБЫТОЧНОСТЬ (5 копий на запрос)
   Всего копий:        ${totalCopiesSent} (${count} × 5)
   Успешных копий:     ${totalCopiesSucceeded} (${copySuccessRate}%)
   Провалов копий:     ${totalCopiesSent - totalCopiesSucceeded} (${(100 - parseFloat(copySuccessRate)).toFixed(1)}%)
   Среднее успешных:   ${avgCopiesSucceeded.toFixed(1)} копий на запрос

${'='.repeat(80)}
        `.trim();
    }

    async runSequentialStressTest() {
        const count = 100;
        const maxRetries = 3; // Максимум 3 попытки на запрос
        const retryDelay = 50; // 50мс между попытками
        const retryTimeout = 100; // 100мс таймаут для всех попыток (быстрая проверка)
        const testName = 'Последовательный (100 запросов с переотправкой)';
        
        notifyInfo(`Запуск теста: ${testName}`, { duration: 2000 });
        this.showProgress(true);
        this.updateProgress(0, 'Подготовка...');
        
        const results = [];
        let totalRetries = 0;
        const startTime = performance.now();
        
        for (let i = 0; i < count; i++) {
            this.updateProgress(((i + 1) / count) * 100, `Запрос ${i + 1}/${count}...`);
            
            let success = false;
            let attempts = 0;
            let lastError = null;
            let firstAttemptTime = performance.now();
            
            // Пытаемся отправить запрос до maxRetries раз
            while (!success && attempts < maxRetries) {
                attempts++;
                
                const reqStart = performance.now();
                try {
                    // Все попытки с быстрым таймаутом 100мс
                    await window.RequestHub.send('test_request', { index: i, attempt: attempts }, retryTimeout);
                    const latency = performance.now() - reqStart;
                    
                    results.push({ 
                        status: 'success', 
                        latency,
                        attempts: attempts,
                        retried: attempts > 1,
                        totalTime: performance.now() - firstAttemptTime
                    });
                    success = true;
                    
                    if (attempts > 1) {
                        totalRetries++;
                        console.log(`✅ [Sequential Test] Запрос #${i} успешен с попытки ${attempts} (${latency.toFixed(0)}мс)`);
                    }
                    
                } catch (error) {
                    lastError = error;
                    const latency = performance.now() - reqStart;
                    console.warn(`⚠️ [Sequential Test] Запрос #${i} попытка ${attempts}/${maxRetries} провалилась за ${latency.toFixed(0)}мс: ${error.message}`);
                    
                    // Если не последняя попытка - ждём и пробуем снова
                    if (attempts < maxRetries) {
                        await new Promise(resolve => setTimeout(resolve, retryDelay));
                    }
                }
            }
            
            // Если все попытки провалились
            if (!success) {
                const latency = performance.now() - firstAttemptTime;
                results.push({
                    status: lastError.message.includes('Timeout') ? 'timeout' : 'error',
                    latency,
                    attempts: attempts,
                    retried: attempts > 1,
                    error: lastError.message
                });
                console.error(`❌ [Sequential Test] Запрос #${i} провалился после ${attempts} попыток`);
            }
        }
        
        const totalTime = performance.now() - startTime;
        
        this.showProgress(false);
        this.showResult(this.formatResultWithRetries(testName, totalTime, count, results, totalRetries));
        notifySuccess('Тест завершён!', { duration: 3000 });
    }

    async runHybridStressTest() {
        const count = 100;
        const testName = 'Гибридный (100 запросов через sendReliable)';
        
        notifyInfo(`Запуск теста: ${testName}`, { duration: 2000 });
        this.showProgress(true);
        this.updateProgress(0, 'Подготовка...');
        
        const results = [];
        const startTime = performance.now();
        
        for (let i = 0; i < count; i++) {
            this.updateProgress(((i + 1) / count) * 100, `Запрос ${i + 1}/${count} (sendReliable: 5 копий × 3 retry)...`);
            
            const reqStart = performance.now();
            
            try {
                // Используем новый метод sendReliable()
                const response = await window.RequestHub.sendReliable('test_request', { index: i });
                const latency = performance.now() - reqStart;
                
                results.push({
                    status: 'success',
                    latency
                });
                
                console.log(`✅ [Hybrid Test] Запрос #${i} успешен (${latency.toFixed(0)}мс)`);
                
            } catch (error) {
                const latency = performance.now() - reqStart;
                
                results.push({
                    status: 'timeout',
                    latency,
                    error: error.message
                });
                
                console.error(`❌ [Hybrid Test] Запрос #${i} провалился: ${error.message} (${latency.toFixed(0)}мс)`);
            }
        }
        
        const totalTime = performance.now() - startTime;
        
        this.showProgress(false);
        this.showResult(this.formatResult(testName, totalTime, count, results));
        notifySuccess('Тест завершён!', { duration: 3000 });
    }

    async runParallelStressTest() {
        const count = 1000;
        const testName = 'Параллельный (1000 запросов одновременно)';
        const parallelTimeout = 10000; // 10 секунд для параллельных запросов
        
        notifyInfo(`Запуск теста: ${testName}`, { duration: 2000 });
        this.showProgress(true);
        this.updateProgress(50, 'Отправка всех запросов...');
        
        // Сброс счётчика ответов в engine
        if (window.WebView2Engine) {
            window.WebView2Engine._responseCount = 0;
        }
        
        const startTime = performance.now();
        const requestIds = [];
        
        const promises = Array.from({ length: count }, (_, i) => {
            const reqStart = performance.now();
            requestIds.push(window.RequestHub.requestIdCounter + 1);
            
            return window.RequestHub.send('test_request', { index: i }, parallelTimeout)
                .then(() => ({
                    status: 'success',
                    latency: performance.now() - reqStart,
                    index: i
                }))
                .catch(error => {
                    // Детальное логирование ошибок
                    console.error(`❌ [Parallel Test] Запрос #${i} failed:`, error.message);
                    return {
                        status: error.message.includes('Timeout') ? 'timeout' : 'error',
                        latency: performance.now() - reqStart,
                        index: i,
                        error: error.message
                    };
                });
        });
        
        console.log(`📊 [Parallel Test] Отправлено ${count} запросов с таймаутом ${parallelTimeout}мс, IDs: ${requestIds[0]}-${requestIds[requestIds.length-1]}`);
        
        const results = await Promise.all(promises);
        const totalTime = performance.now() - startTime;
        
        // Анализ результатов
        const timeouts = results.filter(r => r.status === 'timeout');
        if (timeouts.length > 0) {
            console.warn(`⚠️ [Parallel Test] Таймауты (${timeouts.length}):`, timeouts.map(t => t.index));
        }
        
        this.showProgress(false);
        this.showResult(this.formatResult(testName, totalTime, count, results));
        notifySuccess('Тест завершён!', { duration: 3000 });
    }

    async runBurstStressTest() {
        const waves = 10;
        const perWave = 10;
        const pauseMs = 500;
        const totalCount = waves * perWave;
        const testName = `Волновой (${waves} волн по ${perWave} запросов)`;
        
        notifyInfo(`Запуск теста: ${testName}`, { duration: 2000 });
        this.showProgress(true);
        
        const results = [];
        const startTime = performance.now();
        
        for (let wave = 0; wave < waves; wave++) {
            this.updateProgress(
                ((wave + 1) / waves) * 100, 
                `Волна ${wave + 1}/${waves} (${perWave} запросов)...`
            );
            
            const wavePromises = Array.from({ length: perWave }, (_, i) => {
                const reqStart = performance.now();
                return window.RequestHub.send('test_request', { wave, index: i })
                    .then(() => ({
                        status: 'success',
                        latency: performance.now() - reqStart
                    }))
                    .catch(error => ({
                        status: error.message.includes('Timeout') ? 'timeout' : 'error',
                        latency: performance.now() - reqStart
                    }));
            });
            
            const waveResults = await Promise.all(wavePromises);
            results.push(...waveResults);
            
            // Пауза между волнами (кроме последней)
            if (wave < waves - 1) {
                await new Promise(resolve => setTimeout(resolve, pauseMs));
            }
        }
        
        const totalTime = performance.now() - startTime;
        
        this.showProgress(false);
        this.showResult(this.formatResult(testName, totalTime, totalCount, results));
        notifySuccess('Тест завершён!', { duration: 3000 });
    }
}

// Регистрация компонента
customElements.define('page-test-utils', TestUtilsPage);

// ===============================================================================
// Глобальная функция навигации (для интерактивных подсказок)
// ===============================================================================
window.navigateToCounter = function(counterId) {
    const pageId = typeof counterId === 'number' ? `counter${counterId}` : counterId;
    const header = document.querySelector('app-header');
    
    if (header && header.switchPage) {
        header.switchPage(pageId);
        console.log(`✅ Переход на страницу: ${pageId}`);
    } else {
        console.error('❌ Header компонент не найден');
    }
};

console.log('✅ Test Utils Page загружена');
