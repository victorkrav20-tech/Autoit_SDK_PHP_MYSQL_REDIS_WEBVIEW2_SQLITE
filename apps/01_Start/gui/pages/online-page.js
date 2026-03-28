// ===============================================================================
// Online Page - Страница мониторинга счётчиков в реальном времени
// Версия: 1.0.0
// ===============================================================================

class OnlinePage extends HTMLElement {
    constructor() {
        super();
        this.counters = new Map(); // Хранилище данных счётчиков
        this.isActive = false; // Активна ли страница
        this.updateInterval = null; // Интервал обновления
        
        // Статистика DOM обновлений
        this.domUpdateStats = {
            totalUpdates: 0,
            dataStatusUpdates: 0,
            workingStatusUpdates: 0,
            lastTimeUpdates: 0,
            lastLogTime: Date.now()
        };
    }

    connectedCallback() {
        this.render();
        this.initCounters();
        this.attachEventListeners();
        this.startMonitoring();
        console.log('✅ Online Page загружена');
    }

    disconnectedCallback() {
        this.stopMonitoring();
        console.log('👋 Online Page выгружена');
    }

    // ===============================================================================
    // Инициализация счётчиков
    // ===============================================================================
    initCounters() {
        for (let i = 1; i <= 7; i++) {
            this.counters.set(i, {
                id: i,
                name: `Counter ${i}`,
                type: '',
                enabled: false,
                windowVisible: false,
                lastDataTime: null,
                lastFlow: null,
                flowHistory: [], // История расхода за последние 5 сек
                dataStatus: 'no_data', // no_data, fresh, stale, timeout
                workingStatus: 'no_data' // no_data, working, stopped
            });
        }
    }

    // ===============================================================================
    // Рендеринг HTML
    // ===============================================================================
    render() {
        this.innerHTML = `
            <div class="page-header d-print-none">
                <div class="container-xl">
                    <div class="row g-2 align-items-center">
                        <div class="col">
                            <div class="page-pretitle">Мониторинг</div>
                            <h2 class="page-title">Онлайн</h2>
                        </div>
                        <div class="col-auto">
                            <button id="btn-refresh-all" class="btn btn-primary">
                                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                    <path d="M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4" />
                                    <path d="M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4" />
                                </svg>
                                Обновить всё
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="page-body">
                <div class="container-xl">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Мониторинг счётчиков</h3>
                            <div class="card-actions">
                                <span class="badge bg-blue" id="update-indicator">
                                    <span class="spinner-border spinner-border-sm me-1" role="status"></span>
                                    Обновление...
                                </span>
                            </div>
                        </div>
                        <div class="table-responsive">
                            <table class="table table-vcenter card-table">
                                <thead>
                                    <tr>
                                        <th class="w-1">№</th>
                                        <th>Название</th>
                                        <th>Статус данных</th>
                                        <th>Работа счётчика</th>
                                        <th>Последние данные</th>
                                        <th class="w-1">Парсинг</th>
                                        <th class="w-1">Окно</th>
                                    </tr>
                                </thead>
                                <tbody id="counters-table-body">
                                    ${this.renderTableRows()}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    renderTableRows() {
        let html = '';
        for (let i = 1; i <= 7; i++) {
            html += `
                <tr data-counter-id="${i}">
                    <td class="text-muted">${i}</td>
                    <td>
                        <div class="counter-name" id="counter-${i}-name">Counter ${i}</div>
                        <div class="text-muted small" id="counter-${i}-type">—</div>
                    </td>
                    <td>
                        <span class="badge" id="counter-${i}-data-status">
                            <span class="spinner-border spinner-border-sm me-1" role="status"></span>
                            Загрузка...
                        </span>
                    </td>
                    <td>
                        <div id="counter-${i}-working-status">
                            <span class="badge bg-secondary">❌ Нет данных</span>
                            <div class="text-muted small mt-1">—</div>
                        </div>
                    </td>
                    <td>
                        <div id="counter-${i}-last-time" class="text-muted">—</div>
                    </td>
                    <td>
                        <button class="btn btn-sm btn-toggle-parsing" 
                                data-counter-id="${i}"
                                data-tooltip="Включить/выключить парсинг данных"
                                disabled>
                            <span class="spinner-border spinner-border-sm" role="status"></span>
                        </button>
                    </td>
                    <td>
                        <button class="btn btn-sm btn-toggle-window" 
                                data-counter-id="${i}"
                                data-tooltip="Показать/скрыть окно счётчика"
                                disabled>
                            <span class="spinner-border spinner-border-sm" role="status"></span>
                        </button>
                    </td>
                </tr>
            `;
        }
        return html;
    }

    // ===============================================================================
    // Подключение обработчиков событий
    // ===============================================================================
    attachEventListeners() {
        // Кнопка "Обновить всё"
        document.getElementById('btn-refresh-all')?.addEventListener('click', () => {
            this.refreshAllData();
        });

        // Кнопки переключения парсинга
        document.querySelectorAll('.btn-toggle-parsing').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const counterId = parseInt(e.currentTarget.dataset.counterId);
                this.toggleParsing(counterId);
            });
        });

        // Кнопки переключения окна
        document.querySelectorAll('.btn-toggle-window').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const counterId = parseInt(e.currentTarget.dataset.counterId);
                this.toggleWindow(counterId);
            });
        });

        // Подписка на события данных от счётчиков
        for (let i = 1; i <= 7; i++) {
            window.WebView2Engine.on(`counter_${i}_data`, (data) => {
                if (this.isActive) {
                    this.handleCounterData(i, data);
                }
            });
        }
    }

    // ===============================================================================
    // Мониторинг (запуск/остановка)
    // ===============================================================================
    startMonitoring() {
        this.isActive = true;
        
        // Первоначальная загрузка данных (с небольшой задержкой)
        setTimeout(() => {
            this.loadInitialData();
        }, 500);
        
        // Обновление данных каждые 100ms
        this.updateInterval = setInterval(() => {
            if (this.isActive) {
                this.refreshCountersData();
            }
        }, 100);
        
        console.log('🔄 Мониторинг запущен (обновление каждые 100ms)');
    }

    stopMonitoring() {
        this.isActive = false;
        
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
        
        console.log('⏸️ Мониторинг остановлен');
    }

    // ===============================================================================
    // Обновление данных
    // ===============================================================================
    async loadInitialData() {
        console.log('🔄 [OnlinePage] Загружаю начальные данные...');
        
        try {
            // 1. Загружаем статусы счётчиков (enabled, name, window_visible)
            console.log('📤 [OnlinePage] Запрашиваю статусы счётчиков...');
            const statuses = await window.RequestHub.send('get_counters_status');
            
            if (Array.isArray(statuses)) {
                console.log('✅ [OnlinePage] Получены статусы:', statuses);
                statuses.forEach((counterData, index) => {
                    const counterId = index + 1;
                    this.updateCounterInfo(counterId, counterData);
                });
            }
            
            // 2. Загружаем последние 10 записей для инициализации истории
            console.log('📤 [OnlinePage] Запрашиваю последние 10 записей...');
            const lastData = await window.RequestHub.send('get_all_counters_last_data', { count: 10 });
            
            if (lastData) {
                console.log('✅ [OnlinePage] Получены данные буфера:', lastData);
                this.initFlowHistory(lastData);
            }
            
            console.log('✅ [OnlinePage] Начальные данные загружены');
        } catch (error) {
            console.error('❌ [OnlinePage] Ошибка загрузки начальных данных:', error);
            if (window.notifyError) {
                window.notifyError('Ошибка загрузки данных: ' + error.message);
            }
        }
    }

    async refreshCountersData() {
        try {
            // Запрашиваем только последнюю запись от каждого счётчика (обычный send)
            const lastData = await window.RequestHub.send('get_all_counters_last_data', { count: 1 });
            
            if (lastData) {
                this.updateFromBufferData(lastData);
            }
        } catch (error) {
            console.error('❌ [OnlinePage] Ошибка обновления данных:', error);
        }
    }

    async refreshAllData() {
        console.log('🔄 [OnlinePage] Начинаю обновление данных...');
        
        const indicator = document.getElementById('update-indicator');
        if (indicator) {
            indicator.classList.remove('bg-success');
            indicator.classList.add('bg-blue');
            indicator.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status"></span>Обновление...';
        }

        try {
            console.log('📤 [OnlinePage] Отправляю запрос get_counters_status...');
            
            // Используем обычный send (только события)
            const response = await window.RequestHub.send('get_counters_status');
            
            console.log('✅ [OnlinePage] Получен ответ:', response);
            
            // RequestHub возвращает payload напрямую (уже распакованный)
            // Проверяем что это массив
            let counters = null;
            
            if (Array.isArray(response)) {
                // Ответ пришёл напрямую как массив
                counters = response;
            } else if (response && response.payload) {
                // Ответ обёрнут в payload
                counters = response.payload;
            } else if (response && Array.isArray(response.response)) {
                // Ответ в поле response (как на тестовой странице)
                counters = response.response;
            }
            
            if (counters && Array.isArray(counters)) {
                console.log('📊 [OnlinePage] Данные счётчиков:', counters);
                
                // Обновляем данные каждого счётчика
                counters.forEach((counterData, index) => {
                    const counterId = index + 1;
                    console.log(`🔄 [OnlinePage] Обновляю счётчик #${counterId}:`, counterData);
                    this.updateCounterInfo(counterId, counterData);
                });
                
                if (indicator) {
                    indicator.classList.remove('bg-blue');
                    indicator.classList.add('bg-success');
                    indicator.innerHTML = '✓ Обновлено';
                    
                    setTimeout(() => {
                        indicator.style.display = 'none';
                    }, 2000);
                }
                
                console.log('✅ [OnlinePage] Данные обновлены');
            } else {
                console.warn('⚠️ [OnlinePage] Ответ не содержит массив счётчиков:', response);
            }
        } catch (error) {
            console.error('❌ [OnlinePage] Ошибка обновления данных:', error);
            
            if (indicator) {
                indicator.classList.remove('bg-blue');
                indicator.classList.add('bg-danger');
                indicator.innerHTML = '✗ Ошибка';
            }
            
            if (window.notifyError) {
                window.notifyError('Ошибка загрузки данных: ' + error.message);
            }
        }
    }

    updateCounterInfo(counterId, data) {
        const counter = this.counters.get(counterId);
        if (!counter) {
            console.warn(`⚠️ [updateCounterInfo] Счётчик #${counterId} не найден в Map`);
            return;
        }

        console.log(`📝 [updateCounterInfo] Обновляю счётчик #${counterId}:`, data);

        // Обновляем базовую информацию
        counter.name = data.name || `Counter ${counterId}`;
        counter.enabled = data.enabled || false;
        counter.windowVisible = data.window_visible || false;
        
        // НЕ обновляем lastDataTime из статусов (там TimerInit, не timestamp!)
        // Время обновляется только из буфера в updateFromBufferData()
        
        // Обновляем UI - название
        const nameEl = document.getElementById(`counter-${counterId}-name`);
        if (nameEl) {
            nameEl.textContent = counter.name;
            console.log(`✅ [updateCounterInfo] Обновлено имя счётчика #${counterId}: ${counter.name}`);
        } else {
            console.warn(`⚠️ [updateCounterInfo] Элемент counter-${counterId}-name не найден`);
        }
        
        // Обновляем кнопки
        this.updateParsingButton(counterId, counter.enabled);
        this.updateWindowButton(counterId, counter.windowVisible);
        
        console.log(`✅ [updateCounterInfo] Счётчик #${counterId} обновлён полностью`);
    }

    // ===============================================================================
    // Обработка данных из буфера
    // ===============================================================================
    initFlowHistory(bufferData) {
        console.log('📊 [initFlowHistory] Инициализирую историю расхода из буфера');
        
        for (let i = 1; i <= 7; i++) {
            const counterKey = `counter${i}`;
            const records = bufferData[counterKey];
            
            if (!records || !Array.isArray(records) || records.length === 0) {
                console.log(`⚠️ [initFlowHistory] Нет данных для счётчика #${i}`);
                continue;
            }
            
            const counter = this.counters.get(i);
            if (!counter) continue;
            
            // Очищаем текущую историю
            counter.flowHistory = [];
            
            // Добавляем записи из буфера
            records.forEach(record => {
                const flow = parseFloat(record.flow) || 0;
                const timestamp = this.parseTimestamp(record.timestamp);
                
                if (timestamp) {
                    counter.flowHistory.push({ flow, timestamp });
                }
            });
            
            // Обновляем последние данные
            if (counter.flowHistory.length > 0) {
                const lastRecord = counter.flowHistory[counter.flowHistory.length - 1];
                counter.lastFlow = lastRecord.flow;
                counter.lastDataTime = lastRecord.timestamp;
            }
            
            console.log(`✅ [initFlowHistory] Счётчик #${i}: загружено ${counter.flowHistory.length} записей`);
        }
        
        // Обновляем UI
        this.updateAllStatuses();
    }

    updateFromBufferData(bufferData) {
        const now = Date.now();
        
        for (let i = 1; i <= 7; i++) {
            const counterKey = `counter${i}`;
            const records = bufferData[counterKey];
            
            if (!records || !Array.isArray(records) || records.length === 0) {
                continue;
            }
            
            const counter = this.counters.get(i);
            if (!counter) continue;
            
            // Обрабатываем последнюю запись
            const record = records[records.length - 1];
            const flow = parseFloat(record.flow) || 0;
            const timestampStr = record.timestamp;
            const timestamp = this.parseTimestamp(timestampStr);
            
            // Обновляем время последних данных
            if (timestamp) {
                counter.lastDataTime = timestamp;
            }
            
            counter.lastFlow = flow;
            
            // Добавляем в историю расхода
            if (timestamp) {
                counter.flowHistory.push({ flow, timestamp });
            }
            
            // Удаляем старые значения (>5 сек)
            counter.flowHistory = counter.flowHistory.filter(
                item => (now - item.timestamp) < 5000
            );
            
            // Ограничиваем размер истории
            if (counter.flowHistory.length > 10) {
                counter.flowHistory.shift();
            }
        }
        
        // Обновляем статусы UI
        this.updateAllStatuses();
    }

    parseTimestamp(timestampStr) {
        if (!timestampStr) return null;
        
        try {
            // Формат: "YYYY-MM-DD HH:MM:SS.mmm"
            const parts = timestampStr.split(' ');
            if (parts.length !== 2) return null;
            
            const dateParts = parts[0].split('-');
            const timeParts = parts[1].split(':');
            
            if (dateParts.length !== 3 || timeParts.length !== 3) return null;
            
            const year = parseInt(dateParts[0]);
            const month = parseInt(dateParts[1]) - 1; // Месяцы с 0
            const day = parseInt(dateParts[2]);
            const hour = parseInt(timeParts[0]);
            const minute = parseInt(timeParts[1]);
            const secondParts = timeParts[2].split('.');
            const second = parseInt(secondParts[0]);
            const millisecond = secondParts.length > 1 ? parseInt(secondParts[1]) : 0;
            
            return new Date(year, month, day, hour, minute, second, millisecond).getTime();
        } catch (error) {
            console.error('❌ [parseTimestamp] Ошибка парсинга:', timestampStr, error);
            return null;
        }
    }

    // ===============================================================================
    // Обработка данных от счётчиков (события - оставляем для совместимости)
    // ===============================================================================
    handleCounterData(counterId, data) {
        const counter = this.counters.get(counterId);
        if (!counter) return;

        const now = Date.now();
        
        // Обновляем время последних данных
        counter.lastDataTime = now;
        
        // Извлекаем расход из данных
        let flow = null;
        if (data && data.main && data.main[0]) {
            flow = parseFloat(data.main[0]) || 0;
        }
        
        // Добавляем в историю расхода
        if (flow !== null) {
            counter.flowHistory.push({ flow, timestamp: now });
            
            // Удаляем старые значения (>5 сек)
            counter.flowHistory = counter.flowHistory.filter(
                item => (now - item.timestamp) < 5000
            );
            
            // Ограничиваем размер истории
            if (counter.flowHistory.length > 10) {
                counter.flowHistory.shift();
            }
            
            counter.lastFlow = flow;
        }
        
        // Обновляем статусы
        this.updateCounterStatuses(counterId);
    }

    // ===============================================================================
    // Обновление статусов
    // ===============================================================================
    updateAllStatuses() {
        for (let i = 1; i <= 7; i++) {
            this.updateCounterStatuses(i);
        }
        
        // Логируем статистику каждые 100 обновлений
        if (this.domUpdateStats.totalUpdates > 0 && this.domUpdateStats.totalUpdates % 100 === 0) {
            const now = Date.now();
            const elapsed = ((now - this.domUpdateStats.lastLogTime) / 1000).toFixed(2);
            
            console.log(`📊 [DOM Stats] Обновлений: ${this.domUpdateStats.totalUpdates} | ` +
                `DataStatus: ${this.domUpdateStats.dataStatusUpdates} | ` +
                `WorkingStatus: ${this.domUpdateStats.workingStatusUpdates} | ` +
                `LastTime: ${this.domUpdateStats.lastTimeUpdates} | ` +
                `Время: ${elapsed}с | ` +
                `Timestamp: ${new Date(now).toLocaleTimeString('ru-RU')}`);
            
            this.domUpdateStats.lastLogTime = now;
        }
    }

    updateCounterStatuses(counterId) {
        const counter = this.counters.get(counterId);
        if (!counter) return;

        const now = Date.now();
        
        // Определяем статус данных (актуальность)
        if (!counter.lastDataTime) {
            counter.dataStatus = 'no_data';
        } else {
            const elapsed = (now - counter.lastDataTime) / 1000; // в секундах
            
            if (elapsed < 0.5) {
                counter.dataStatus = 'fresh'; // 🟢 Актуально
            } else if (elapsed < 3) {
                counter.dataStatus = 'stale'; // 🟡 Устарело
            } else {
                counter.dataStatus = 'timeout'; // 🔴 Таймаут
            }
        }
        
        // Определяем статус работы счётчика
        counter.workingStatus = this.calculateWorkingStatus(counter);
        
        // Обновляем UI
        this.updateDataStatusUI(counterId, counter);
        this.updateWorkingStatusUI(counterId, counter);
        this.updateLastTimeUI(counterId, counter);
    }

    calculateWorkingStatus(counter) {
        if (counter.flowHistory.length < 2) {
            return { status: 'no_data', icon: '❌', text: 'Нет данных', color: 'secondary' };
        }
        
        // Проверяем изменился ли расход
        const flows = counter.flowHistory.map(item => item.flow);
        const minFlow = Math.min(...flows);
        const maxFlow = Math.max(...flows);
        const delta = Math.abs(maxFlow - minFlow);
        
        // Если разница больше 0.1 - счётчик работает
        if (delta > 0.1) {
            return { 
                status: 'working', 
                icon: '▶️', 
                text: 'Работает',
                color: 'success',
                flow: counter.lastFlow
            };
        } else {
            return { 
                status: 'stopped', 
                icon: '⏸️', 
                text: 'Остановлен',
                color: 'warning',
                flow: counter.lastFlow
            };
        }
    }

    updateDataStatusUI(counterId, counter) {
        const el = document.getElementById(`counter-${counterId}-data-status`);
        if (!el) return;

        let html = '';
        let className = 'badge';
        let updated = false;
        
        switch (counter.dataStatus) {
            case 'fresh':
                className += ' bg-success';
                const elapsed = counter.lastDataTime ? 
                    ((Date.now() - counter.lastDataTime) / 1000).toFixed(1) : '—';
                html = `🟢 ${elapsed}с`;
                break;
            case 'stale':
                className += ' bg-warning';
                const elapsedStale = counter.lastDataTime ? 
                    ((Date.now() - counter.lastDataTime) / 1000).toFixed(1) : '—';
                html = `🟡 ${elapsedStale}с`;
                break;
            case 'timeout':
                className += ' bg-danger';
                const elapsedTimeout = counter.lastDataTime ? 
                    ((Date.now() - counter.lastDataTime) / 1000).toFixed(1) : '—';
                html = `🔴 ${elapsedTimeout}с`;
                break;
            default:
                className += ' bg-secondary';
                html = '⚪ Нет данных';
        }
        
        // Обновляем только если изменилось
        if (el.dataset.lastStatus !== counter.dataStatus) {
            el.className = className;
            el.dataset.lastStatus = counter.dataStatus;
            updated = true;
        }
        
        // Текст обновляем всегда (elapsed время меняется)
        if (el.innerHTML !== html) {
            el.innerHTML = html;
            updated = true;
        }
        
        // Статистика
        if (updated) {
            this.domUpdateStats.dataStatusUpdates++;
            this.domUpdateStats.totalUpdates++;
        }
    }

    updateWorkingStatusUI(counterId, counter) {
        const el = document.getElementById(`counter-${counterId}-working-status`);
        if (!el) return;

        const status = counter.workingStatus;
        const flowText = status.flow !== undefined ? 
            `Расход: ${status.flow.toFixed(2)}` : '—';
        
        const newHTML = `
            <span class="badge bg-${status.color}">${status.icon} ${status.text}</span>
            <div class="text-muted small mt-1">${flowText}</div>
        `;
        
        // Округляем flow до 2 знаков для сравнения
        const currentFlow = status.flow !== undefined ? status.flow.toFixed(2) : null;
        const lastFlow = el.dataset.lastFlow;
        
        // Обновляем только если изменился статус ИЛИ flow изменился значительно
        if (el.dataset.lastStatus !== status.status || lastFlow !== currentFlow) {
            el.innerHTML = newHTML;
            el.dataset.lastStatus = status.status;
            el.dataset.lastFlow = currentFlow;
            
            // Статистика
            this.domUpdateStats.workingStatusUpdates++;
            this.domUpdateStats.totalUpdates++;
        }
    }

    updateLastTimeUI(counterId, counter) {
        const el = document.getElementById(`counter-${counterId}-last-time`);
        if (!el) return;

        let updated = false;
        
        if (counter.lastDataTime) {
            const date = new Date(counter.lastDataTime);
            const newText = date.toLocaleTimeString('ru-RU');
            
            // Обновляем только если изменилось
            if (el.textContent !== newText) {
                el.textContent = newText;
                el.classList.remove('text-muted');
                updated = true;
            }
        } else {
            if (el.textContent !== '—') {
                el.textContent = '—';
                el.classList.add('text-muted');
                updated = true;
            }
        }
        
        // Статистика
        if (updated) {
            this.domUpdateStats.lastTimeUpdates++;
            this.domUpdateStats.totalUpdates++;
        }
    }

    // ===============================================================================
    // Управление кнопками
    // ===============================================================================
    updateParsingButton(counterId, enabled) {
        const btn = document.querySelector(`.btn-toggle-parsing[data-counter-id="${counterId}"]`);
        if (!btn) return;

        btn.disabled = false;
        btn.className = `btn btn-sm btn-toggle-parsing ${enabled ? 'btn-success' : 'btn-outline-secondary'}`;
        btn.innerHTML = enabled ? '✓ ВКЛ' : 'ВЫКЛ';
    }

    updateWindowButton(counterId, visible) {
        const btn = document.querySelector(`.btn-toggle-window[data-counter-id="${counterId}"]`);
        if (!btn) return;

        btn.disabled = false;
        btn.className = `btn btn-sm btn-toggle-window ${visible ? 'btn-primary' : 'btn-outline-secondary'}`;
        btn.innerHTML = visible ? '👁️ Показать' : '🙈 Скрыть';
    }

    // ===============================================================================
    // Действия с счётчиками
    // ===============================================================================
    async toggleParsing(counterId) {
        const btn = document.querySelector(`.btn-toggle-parsing[data-counter-id="${counterId}"]`);
        if (!btn) return;

        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status"></span>';

        try {
            const response = await window.RequestHub.sendReliable('toggle_counter_parsing', { 
                counterId: counterId 
            });
            
            console.log(`✅ [toggleParsing] Ответ для счётчика ${counterId}:`, response);
            
            // RequestHub возвращает payload напрямую
            if (response && response.enabled !== undefined) {
                const newState = response.enabled;
                this.updateParsingButton(counterId, newState);
                if (window.notifySuccess) {
                    window.notifySuccess(`Парсинг счётчика ${counterId} ${newState ? 'включен' : 'выключен'}`);
                }
            } else {
                throw new Error('Некорректный ответ от сервера');
            }
        } catch (error) {
            console.error(`❌ Ошибка переключения парсинга счётчика ${counterId}:`, error);
            if (window.notifyError) {
                window.notifyError('Ошибка: ' + error.message);
            }
            btn.disabled = false;
            btn.innerHTML = '⚠️';
        }
    }

    async toggleWindow(counterId) {
        const btn = document.querySelector(`.btn-toggle-window[data-counter-id="${counterId}"]`);
        if (!btn) return;

        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status"></span>';

        try {
            const response = await window.RequestHub.sendReliable('toggle_counter_window', { 
                counterId: counterId 
            });
            
            console.log(`✅ [toggleWindow] Ответ для счётчика ${counterId}:`, response);
            
            // RequestHub возвращает payload напрямую
            if (response && response.visible !== undefined) {
                const newState = response.visible;
                this.updateWindowButton(counterId, newState);
                if (window.notifySuccess) {
                    window.notifySuccess(`Окно счётчика ${counterId} ${newState ? 'показано' : 'скрыто'}`);
                }
            } else {
                throw new Error('Некорректный ответ от сервера');
            }
        } catch (error) {
            console.error(`❌ Ошибка переключения окна счётчика ${counterId}:`, error);
            if (window.notifyError) {
                window.notifyError('Ошибка: ' + error.message);
            }
            btn.disabled = false;
            btn.innerHTML = '⚠️';
        }
    }
}

// Регистрация компонента
customElements.define('page-online', OnlinePage);

console.log('✅ Online Page компонент зарегистрирован');
