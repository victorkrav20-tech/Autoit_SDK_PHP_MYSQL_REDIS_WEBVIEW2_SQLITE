// ===============================================================================
// page1-component.js - Страница мониторинга (Real-time график с UI управлением)
// ===============================================================================

class Page1Component extends HTMLElement {
    constructor() {
        super();
        this.chart = null;
        this.statsInterval = null;
        this.dataGeneratorInterval = null; // Интервал для генерации тестовых данных
        // Стартовые значения для каждой линии
        this.lastValues = {
            temp: 25,
            hum: 60,
            press: 101
        };
    }
    
    connectedCallback() {
        this.render();
        
        // Инициализируем график с задержкой (ждём загрузки DOM)
        setTimeout(() => {
            this.initChart();
            this.initControls();
            this.startStatsUpdate();
            
            // АВТОЗАПУСК: запускаем график автоматически при загрузке страницы
            this.autoStart();
        }, 100);
        
        console.log('Page1: Мониторинг загружен');
    }
    
    disconnectedCallback() {
        // Очищаем график при удалении компонента
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
        
        // Останавливаем обновление статистики
        if (this.statsInterval) {
            clearInterval(this.statsInterval);
            this.statsInterval = null;
        }
        
        // Останавливаем генератор данных
        if (this.dataGeneratorInterval) {
            clearInterval(this.dataGeneratorInterval);
            this.dataGeneratorInterval = null;
        }
    }
    
    render() {
        this.innerHTML = /* html */`
            <div class="page-body">
                <div class="container-xl">
                    <div class="page-header d-print-none">
                        <div class="row g-2 align-items-center">
                            <div class="col">
                                <div class="page-pretitle">SCADA GRAPHICS</div>
                                <h2 class="page-title">📊 Real-time график #1</h2>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Панель управления -->
                    <div class="row row-cards mt-3">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">🎮 Управление</h3>
                                </div>
                                <div class="card-body">
                                    <div class="row g-3">
                                        <!-- Кнопки управления -->
                                        <div class="col-md-6">
                                            <label class="form-label">Управление графиком</label>
                                            <div class="btn-list">
                                                <button id="btn-start" class="btn btn-success">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M7 4v16l13 -8z" /></svg>
                                                    Запустить
                                                </button>
                                                <button id="btn-stop" class="btn btn-danger" disabled>
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><rect x="6" y="5" width="4" height="14" rx="1" /><rect x="14" y="5" width="4" height="14" rx="1" /></svg>
                                                    Остановить
                                                </button>
                                                <button id="btn-pause" class="btn btn-warning" disabled>
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><rect x="6" y="5" width="4" height="14" rx="1" /><rect x="14" y="5" width="4" height="14" rx="1" /></svg>
                                                    Пауза
                                                </button>
                                                <button id="btn-resume" class="btn btn-info" disabled>
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M7 4v16l13 -8z" /></svg>
                                                    Продолжить
                                                </button>
                                                <button id="btn-clear" class="btn btn-secondary">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 7l16 0" /><path d="M10 11l0 6" /><path d="M14 11l0 6" /><path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" /><path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></svg>
                                                    Очистить
                                                </button>
                                            </div>
                                        </div>
                                        
                                        <!-- Переключатели -->
                                        <div class="col-md-6">
                                            <label class="form-label">Визуализация</label>
                                            <div class="btn-list">
                                                <button id="btn-toggle-grid" class="btn btn-outline-primary">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><rect x="4" y="4" width="6" height="6" rx="1" /><rect x="14" y="4" width="6" height="6" rx="1" /><rect x="4" y="14" width="6" height="6" rx="1" /><rect x="14" y="14" width="6" height="6" rx="1" /></svg>
                                                    Сетка: ВКЛ
                                                </button>
                                                <button id="btn-toggle-series" class="btn btn-outline-success">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><polyline points="4 19 8 13 12 15 16 10 20 14 20 19 4 19" /><polyline points="4 12 7 8 11 10 16 4 20 8" /></svg>
                                                    Линия: ВКЛ
                                                </button>
                                                <div class="input-group" style="width: 200px;">
                                                    <span class="input-group-text">
                                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 21a9 9 0 0 1 0 -18c4.97 0 9 3.582 9 8c0 1.06 -.474 2.078 -1.318 2.828c-.844 .75 -1.989 1.172 -3.182 1.172h-2.5a2 2 0 0 0 -1 3.75a1.3 1.3 0 0 1 -1 2.25" /><path d="M8.5 10.5m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M12.5 7.5m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /><path d="M16.5 10.5m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" /></svg>
                                                    </span>
                                                    <input type="color" id="line-color" class="form-control" value="#206bc4" title="Выберите цвет линии" style="height: 38px; padding: 4px;">
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <div class="row g-3 mt-2">
                                        <!-- FPS -->
                                        <div class="col-md-4">
                                            <label class="form-label">FPS: <span id="fps-value">60</span></label>
                                            <input type="range" id="fps-slider" class="form-range" min="1" max="120" value="60" step="1">
                                            <div class="text-muted small">1 - 120 FPS</div>
                                        </div>
                                        
                                        <!-- Размер окна -->
                                        <div class="col-md-4">
                                            <label class="form-label">Окно данных: <span id="window-value">1000</span> точек</label>
                                            <input type="range" id="window-slider" class="form-range" min="100" max="5000" value="1000" step="100">
                                            <div class="form-check mt-2">
                                                <input class="form-check-input" type="checkbox" id="auto-cleanup" checked>
                                                <label class="form-check-label" for="auto-cleanup">
                                                    Автоочистка (всегда ровно N точек)
                                                </label>
                                            </div>
                                        </div>
                                        
                                        <!-- Диапазон Y -->
                                        <div class="col-md-4">
                                            <label class="form-label">Диапазон Y: <span id="range-value">0 - 100</span></label>
                                            <div class="input-group">
                                                <input type="number" id="range-min" class="form-control" value="0" min="-1000" max="1000">
                                                <span class="input-group-text">—</span>
                                                <input type="number" id="range-max" class="form-control" value="100" min="-1000" max="1000">
                                                <button id="btn-apply-range" class="btn btn-primary">OK</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- График -->
                    <div class="row row-cards mt-3">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">📈 Мониторинг в реальном времени</h3>
                                    <div class="ms-auto">
                                        <span id="status-badge" class="badge bg-success-lt">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-activity" width="16" height="16" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                <path d="M3 12h4l3 8l4 -16l3 8h4" />
                                            </svg>
                                            <span id="status-text">Запущен</span>
                                        </span>
                                    </div>
                                </div>
                                <div class="scada-widget-container">
                                    <div id="realtime-chart-1" style="height: 450px;"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Статистика -->
                    <div class="row row-cards mt-3">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">📊 Статистика</h3>
                                </div>
                                <div class="card-body">
                                    <div class="row">
                                        <div class="col-md-2">
                                            <div class="text-muted small">Целевой FPS</div>
                                            <div class="h3" id="stat-target-fps">60.0</div>
                                        </div>
                                        <div class="col-md-2">
                                            <div class="text-muted small">Реальный FPS</div>
                                            <div class="h3 text-success" id="stat-real-fps">0.0</div>
                                        </div>
                                        <div class="col-md-2">
                                            <div class="text-muted small">Средний FPS</div>
                                            <div class="h3" id="stat-avg-fps">0.0</div>
                                        </div>
                                        <div class="col-md-2">
                                            <div class="text-muted small">Всего точек</div>
                                            <div class="h3" id="stat-total-points">0</div>
                                        </div>
                                        <div class="col-md-2">
                                            <div class="text-muted small">Память</div>
                                            <div class="h3" id="stat-memory">0 KB</div>
                                        </div>
                                        <div class="col-md-2">
                                            <div class="text-muted small">Время работы</div>
                                            <div class="h3" id="stat-uptime">0s</div>
                                        </div>
                                    </div>
                                    <div class="row mt-3">
                                        <div class="col-md-3">
                                            <div class="text-muted small">Обновлений</div>
                                            <div class="h4" id="stat-updates">0</div>
                                        </div>
                                        <div class="col-md-3">
                                            <div class="text-muted small">Пропущено кадров</div>
                                            <div class="h4 text-warning" id="stat-dropped">0</div>
                                        </div>
                                        <div class="col-md-3">
                                            <div class="text-muted small">Окно данных</div>
                                            <div class="h4" id="stat-window">1000</div>
                                        </div>
                                        <div class="col-md-3">
                                            <div class="text-muted small">Интервал</div>
                                            <div class="h4" id="stat-interval">16ms</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
    
    initChart() {
        const container = this.querySelector('#realtime-chart-1');
        
        if (!container) {
            console.error('❌ Page1: Контейнер #realtime-chart-1 не найден');
            return;
        }
        
        // Создаём real-time график с 6 линиями (3 слева + 3 справа)
        this.chart = new ScadaRealtimeChart(container, {
            title: 'Мультилинейный график (6 осей)',
            windowSize: 1000,
            updateInterval: 16,
            showGrid: true,
            showLegend: true,
            autoStart: false,
            series: [
                // === ЛЕВЫЕ ОСИ (3 шт) ===
                { 
                    id: 'temp', 
                    label: 'Температура °C', 
                    color: '#ff6b6b', 
                    width: 2, 
                    fillAlpha: 0.1,
                    show: true,
                    scale: 'temp',
                    range: [20, 30]  // 20-30°C
                },
                { 
                    id: 'hum', 
                    label: 'Влажность %', 
                    color: '#4ecdc4', 
                    width: 2, 
                    fillAlpha: 0.1,
                    show: true,
                    scale: 'hum',
                    range: [50, 70]  // 50-70%
                },
                { 
                    id: 'press', 
                    label: 'Давление кПа', 
                    color: '#95e1d3', 
                    width: 2, 
                    fillAlpha: 0.1,
                    show: true,
                    scale: 'press',
                    range: [100, 102]  // 100-102 кПа
                },
                // === ПРАВЫЕ ОСИ (3 шт) ===
                { 
                    id: 'speed', 
                    label: 'Скорость м/с', 
                    color: '#f59e0b', 
                    width: 2, 
                    fillAlpha: 0.1,
                    show: true,
                    scale: 'speed',
                    range: [0, 100]  // 0-100 м/с
                },
                { 
                    id: 'power', 
                    label: 'Мощность кВт', 
                    color: '#8b5cf6', 
                    width: 2, 
                    fillAlpha: 0.1,
                    show: true,
                    scale: 'power',
                    range: [0, 500]  // 0-500 кВт
                },
                { 
                    id: 'voltage', 
                    label: 'Напряжение В', 
                    color: '#ec4899', 
                    width: 2, 
                    fillAlpha: 0.1,
                    show: true,
                    scale: 'voltage',
                    range: [200, 240]  // 200-240 В
                }
            ]
        });
        
        this.chart.init();
        
        console.log('✅ Page1: Real-time график инициализирован');
    }
    
    initControls() {
        // Кнопки управления
        const btnStart = this.querySelector('#btn-start');
        const btnStop = this.querySelector('#btn-stop');
        const btnPause = this.querySelector('#btn-pause');
        const btnResume = this.querySelector('#btn-resume');
        const btnClear = this.querySelector('#btn-clear');
        
        btnStart.addEventListener('click', () => {
            this.chart.start();
            this.startDataGenerator(); // Запускаем генератор тестовых данных
            this.updateButtonStates();
            this.updateStatusBadge('running');
        });
        
        btnStop.addEventListener('click', () => {
            this.chart.stop();
            this.stopDataGenerator(); // Останавливаем генератор
            this.updateButtonStates();
            this.updateStatusBadge('stopped');
        });
        
        btnPause.addEventListener('click', () => {
            this.chart.pause();
            this.updateButtonStates();
            this.updateStatusBadge('paused');
        });
        
        btnResume.addEventListener('click', () => {
            this.chart.resume();
            this.updateButtonStates();
            this.updateStatusBadge('running');
        });
        
        btnClear.addEventListener('click', () => {
            this.stopDataGenerator(); // Останавливаем генератор
            this.chart.clear();
            // Сбрасываем стартовые значения
            this.lastValues = { temp: 25, hum: 60, press: 101 };
            this.updateButtonStates();
        });
        
        // Переключатели
        const btnToggleGrid = this.querySelector('#btn-toggle-grid');
        const btnToggleSeries = this.querySelector('#btn-toggle-series');
        
        let gridState = true;
        btnToggleGrid.addEventListener('click', () => {
            gridState = !gridState;
            this.chart.toggleGrid(gridState);
            btnToggleGrid.innerHTML = `
                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><rect x="4" y="4" width="6" height="6" rx="1" /><rect x="14" y="4" width="6" height="6" rx="1" /><rect x="4" y="14" width="6" height="6" rx="1" /><rect x="14" y="14" width="6" height="6" rx="1" /></svg>
                Сетка: ${gridState ? 'ВКЛ' : 'ВЫКЛ'}
            `;
        });
        
        let seriesState = true;
        btnToggleSeries.addEventListener('click', () => {
            seriesState = !seriesState;
            this.chart.toggleSeries(1, seriesState);
            btnToggleSeries.innerHTML = `
                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><polyline points="4 19 8 13 12 15 16 10 20 14 20 19 4 19" /><polyline points="4 12 7 8 11 10 16 4 20 8" /></svg>
                Линия: ${seriesState ? 'ВКЛ' : 'ВЫКЛ'}
            `;
        });
        
        // Выбор цвета
        const lineColor = this.querySelector('#line-color');
        lineColor.addEventListener('change', (e) => {
            const color = e.target.value;
            this.chart.setLineColor(color);
        });
        
        // Слайдеры
        const fpsSlider = this.querySelector('#fps-slider');
        const fpsValue = this.querySelector('#fps-value');
        
        fpsSlider.addEventListener('input', (e) => {
            const fps = parseInt(e.target.value);
            fpsValue.textContent = fps;
        });
        
        fpsSlider.addEventListener('change', (e) => {
            const fps = parseInt(e.target.value);
            this.chart.setFPS(fps);
            
            // Перезапускаем генератор данных с новым интервалом
            if (this.chart.isRunning && !this.chart.isPaused) {
                this.stopDataGenerator();
                this.startDataGenerator();
            }
        });
        
        const windowSlider = this.querySelector('#window-slider');
        const windowValue = this.querySelector('#window-value');
        const autoCleanup = this.querySelector('#auto-cleanup');
        
        windowSlider.addEventListener('input', (e) => {
            const size = parseInt(e.target.value);
            windowValue.textContent = size;
        });
        
        windowSlider.addEventListener('change', (e) => {
            const size = parseInt(e.target.value);
            this.chart.setWindowSize(size);
        });
        
        // Автоочистка
        autoCleanup.addEventListener('change', (e) => {
            const enabled = e.target.checked;
            this.chart.setAutoCleanup(enabled);
        });
        
        // Диапазон Y
        const btnApplyRange = this.querySelector('#btn-apply-range');
        const rangeMin = this.querySelector('#range-min');
        const rangeMax = this.querySelector('#range-max');
        const rangeValue = this.querySelector('#range-value');
        
        btnApplyRange.addEventListener('click', () => {
            const min = parseFloat(rangeMin.value);
            const max = parseFloat(rangeMax.value);
            
            if (min >= max) {
                alert('Минимум должен быть меньше максимума!');
                return;
            }
            
            this.chart.setAxisRange('y', min, max);
            rangeValue.textContent = `${min} - ${max}`;
        });
        
        // Начальное состояние кнопок
        this.updateButtonStates();
    }
    
    updateButtonStates() {
        const btnStart = this.querySelector('#btn-start');
        const btnStop = this.querySelector('#btn-stop');
        const btnPause = this.querySelector('#btn-pause');
        const btnResume = this.querySelector('#btn-resume');
        
        const isRunning = this.chart.isRunning;
        const isPaused = this.chart.isPaused;
        
        btnStart.disabled = isRunning && !isPaused;
        btnStop.disabled = !isRunning;
        btnPause.disabled = !isRunning || isPaused;
        btnResume.disabled = !isPaused;
    }
    
    updateStatusBadge(status) {
        const badge = this.querySelector('#status-badge');
        const text = this.querySelector('#status-text');
        
        badge.className = 'badge';
        
        switch (status) {
            case 'running':
                badge.classList.add('bg-success-lt');
                text.textContent = 'Запущен';
                break;
            case 'stopped':
                badge.classList.add('bg-danger-lt');
                text.textContent = 'Остановлен';
                break;
            case 'paused':
                badge.classList.add('bg-warning-lt');
                text.textContent = 'Пауза';
                break;
        }
    }
    
    startStatsUpdate() {
        this.statsInterval = setInterval(() => {
            if (!this.chart) return;
            
            const stats = this.chart.getStats();
            
            this.querySelector('#stat-target-fps').textContent = stats.targetFPS;
            this.querySelector('#stat-real-fps').textContent = stats.realFPS;
            this.querySelector('#stat-avg-fps').textContent = stats.avgFPS;
            this.querySelector('#stat-total-points').textContent = stats.totalPoints.toLocaleString();
            this.querySelector('#stat-memory').textContent = stats.memory.kb + ' KB';
            this.querySelector('#stat-uptime').textContent = stats.uptime + 's';
            this.querySelector('#stat-updates').textContent = stats.totalUpdates.toLocaleString();
            this.querySelector('#stat-dropped').textContent = stats.droppedFrames;
            this.querySelector('#stat-window').textContent = stats.windowSize;
            this.querySelector('#stat-interval').textContent = stats.updateInterval + 'ms';
            
        }, 500); // Обновляем статистику каждые 500ms
    }
    
    // ========================================================================
    // ГЕНЕРАТОР ТЕСТОВЫХ ДАННЫХ (только для page1)
    // ========================================================================
    
    /**
     * Запуск генератора тестовых данных (для 6 линий СИНХРОННО)
     */
    startDataGenerator() {
        // Останавливаем если уже запущен
        this.stopDataGenerator();
        
        // Инициализируем стартовые значения для всех 6 линий
        if (!this.lastValues.speed) {
            this.lastValues.speed = 50;
            this.lastValues.power = 250;
            this.lastValues.voltage = 220;
        }
        
        // Запускаем генератор с интервалом из конфига виджета
        this.dataGeneratorInterval = setInterval(() => {
            if (this.chart && this.chart.isRunning && !this.chart.isPaused) {
                // Генерируем данные для всех 6 линий ОДНОВРЕМЕННО
                
                // Температура: 20-30°C
                const tempChange = (Math.random() - 0.5) * 0.3;
                this.lastValues.temp = Math.max(20, Math.min(30, this.lastValues.temp + tempChange));
                
                // Влажность: 50-70%
                const humChange = (Math.random() - 0.5) * 0.5;
                this.lastValues.hum = Math.max(50, Math.min(70, this.lastValues.hum + humChange));
                
                // Давление: 100-102 кПа
                const pressChange = (Math.random() - 0.5) * 0.1;
                this.lastValues.press = Math.max(100, Math.min(102, this.lastValues.press + pressChange));
                
                // Скорость: 0-100 м/с
                const speedChange = (Math.random() - 0.5) * 2;
                this.lastValues.speed = Math.max(0, Math.min(100, this.lastValues.speed + speedChange));
                
                // Мощность: 0-500 кВт
                const powerChange = (Math.random() - 0.5) * 10;
                this.lastValues.power = Math.max(0, Math.min(500, this.lastValues.power + powerChange));
                
                // Напряжение: 200-240 В
                const voltageChange = (Math.random() - 0.5) * 1;
                this.lastValues.voltage = Math.max(200, Math.min(240, this.lastValues.voltage + voltageChange));
                
                // СИНХРОННОЕ добавление: передаём массив значений для всех линий ОДНОЙ посылкой
                // Порядок: [temp, hum, press, speed, power, voltage]
                const result = this.chart.addPoint([
                    this.lastValues.temp,
                    this.lastValues.hum,
                    this.lastValues.press,
                    this.lastValues.speed,
                    this.lastValues.power,
                    this.lastValues.voltage
                ]);
                
                // Если вернулась ошибка - логируем
                if (result !== true) {
                    console.error('❌ Page1: Ошибка добавления точки:', result);
                }
            }
        }, this.chart.config.updateInterval);
        
        console.log('✅ Page1: Генератор тестовых данных запущен (6 линий СИНХРОННО через массив)');
    }
    
    /**
     * Остановка генератора тестовых данных
     */
    stopDataGenerator() {
        if (this.dataGeneratorInterval) {
            clearInterval(this.dataGeneratorInterval);
            this.dataGeneratorInterval = null;
            console.log('⏹️ Page1: Генератор тестовых данных остановлен');
        }
    }
    
    /**
     * Автозапуск графика при загрузке страницы
     */
    autoStart() {
        if (this.chart) {
            this.chart.start();
            this.startDataGenerator();
            this.updateButtonStates();
            this.updateStatusBadge('running');
            console.log('🚀 Page1: Автозапуск выполнен');
        }
    }
}

customElements.define('page-monitoring', Page1Component);
