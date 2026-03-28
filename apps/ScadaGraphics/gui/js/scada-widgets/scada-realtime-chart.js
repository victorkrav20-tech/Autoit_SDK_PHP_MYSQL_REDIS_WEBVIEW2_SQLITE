// ===============================================================================
// scada-realtime-chart.js - Real-time график для SCADA систем (ПОЛНАЯ ВЕРСИЯ)
// ===============================================================================
// Версия: 2.0.0
// Дата: 02.03.2026
// Описание: Полнофункциональный виджет для real-time мониторинга

class ScadaRealtimeChart extends ScadaChartBase {
    constructor(container, config = {}) {
        // Конфигурация по умолчанию
        const defaultConfig = {
            title: 'Real-time график',
            windowSize: 1000,           // Количество точек в окне
            updateInterval: 16,         // Интервал обновления (мс) - 60 FPS
            minValue: 0,                // Минимальное значение Y
            maxValue: 100,              // Максимальное значение Y
            showGrid: true,             // Показывать сетку
            showLegend: true,           // Показывать легенду
            autoStart: true,            // Автозапуск
            useRelativeIndices: true,   // Относительные индексы (0-999)
            series: []                  // Массив линий: [{ id, label, color, width, fillAlpha }]
        };
        
        const cfg = { ...defaultConfig, ...config };
        
        // Если series пустой - создаём одну линию по умолчанию (обратная совместимость)
        if (cfg.series.length === 0) {
            cfg.series = [{
                id: 'default',
                label: cfg.title || 'Датчик',
                color: '#206bc4',
                width: 2,
                fillAlpha: 0.1,
                show: true  // По умолчанию включена
            }];
        }
        
        // Нормализуем series: добавляем show: true и scale если не указано
        cfg.series.forEach((s, idx) => {
            if (s.show === undefined) {
                s.show = true;
            }
            // Если scale не указан - создаём уникальный для каждой линии
            if (!s.scale) {
                s.scale = `scale_${idx}`;
            }
            // Если range не указан - используем общий диапазон
            if (!s.range) {
                s.range = [cfg.minValue, cfg.maxValue];
            }
        });
        
        // Создаём scales (шкалы) для каждой уникальной scale
        const scales = { x: { time: false, auto: false } };
        const uniqueScales = [...new Set(cfg.series.map(s => s.scale))];
        
        uniqueScales.forEach(scaleName => {
            const serie = cfg.series.find(s => s.scale === scaleName);
            scales[scaleName] = {
                auto: false,
                range: serie.range
            };
        });
        
        // Создаём axes (оси) - X ось + Y оси для каждой шкалы
        const axes = [
            {
                stroke: "#495057",
                grid: { 
                    show: cfg.showGrid,
                    stroke: "#dee2e6", 
                    width: 1 
                },
                ticks: { stroke: "#adb5bd", width: 1 }
            }
        ];
        
        // Добавляем Y оси для каждой уникальной шкалы
        uniqueScales.forEach((scaleName, idx) => {
            const serie = cfg.series.find(s => s.scale === scaleName);
            
            // Распределяем оси: первые 3 слева, остальные справа
            const side = idx < 3 ? 3 : 1; // 3 = left, 1 = right
            
            // Минимальные отступы между осями (gap) - только для разделения
            let gap = 0;
            if (idx === 1) gap = 0;   // Вторая ось слева - без отступа
            if (idx === 2) gap = 0;   // Третья ось слева - без отступа
            if (idx === 4) gap = 0;   // Вторая ось справа - без отступа
            if (idx === 5) gap = 0;   // Третья ось справа - без отступа
            
            // Ширина оси (size) - чем больше, тем дальше числа от графика
            let axisSize = 50;
            if (idx === 1 || idx === 4) axisSize = 50;  // Вторая ось
            if (idx === 2 || idx === 5) axisSize = 50;  // Третья ось
            
            axes.push({
                scale: scaleName,
                side: side,
                gap: gap,
                
                // === ВЕРТИКАЛЬНАЯ ЛИНИЯ ОСИ ===
                stroke: serie.color,        // Цвет линии оси
                
                // === СЕТКА ===
                grid: { 
                    show: cfg.showGrid && idx === 0, // Сетка только для первой оси
                    stroke: "#dee2e6", 
                    width: 1 
                },
                
                // === ЧЁРТОЧКИ (TICKS) - жирные и яркие ===
                ticks: { 
                    show: true,
                    stroke: serie.color,    // Цвет чёрточек = цвет линии
                    width: 3,               // Толщина чёрточек
                    size: 10                // Длина чёрточек
                },
                
                // === ШРИФТЫ - крупнее и жирнее ===
                font: "bold 12px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
                labelFont: "bold 13px -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
                
                // === ОТСТУПЫ - числа ВПЛОТНУЮ к чёрточкам ===
                labelGap: 0,                // Отступ чисел от чёрточек = 0
                
                // === РАЗМЕРЫ ===
                size: axisSize,             // Ширина области оси
                labelSize: 20               // Высота заголовка
            });
        });
        
        // Генерируем опции uPlot на основе series
        const uplotSeries = [
            { label: "Индекс" } // Первая серия - это X ось
        ];
        
        // Добавляем каждую линию
        cfg.series.forEach(s => {
            const hexToRgba = (hex, alpha) => {
                const r = parseInt(hex.slice(1, 3), 16);
                const g = parseInt(hex.slice(3, 5), 16);
                const b = parseInt(hex.slice(5, 7), 16);
                return `rgba(${r}, ${g}, ${b}, ${alpha})`;
            };
            
            uplotSeries.push({
                label: s.label,
                scale: s.scale, // Привязка к шкале
                stroke: s.color,
                width: s.width || 2,
                fill: hexToRgba(s.color, s.fillAlpha || 0.1),
                show: s.show  // Используем значение из конфига
            });
        });
        
        // Опции uPlot
        const options = {
            width: container.offsetWidth || 800,
            height: 400,
            scales: scales,
            series: uplotSeries,
            axes: axes,
            legend: {
                show: cfg.showLegend,
                live: true
            }
        };
        
        super(container, options);
        
        // Конфигурация виджета
        this.config = cfg;
        
        // Карта серий: id → индекс в массиве data (1-based, т.к. 0 - это X)
        this.seriesMap = new Map();
        cfg.series.forEach((s, idx) => {
            this.seriesMap.set(s.id, idx + 1); // +1 потому что 0 - это X ось
        });
        
        // Состояние
        this.isRunning = false;
        this.isPaused = false;
        this.currentIndex = 0;
        this.lastValue = 50;
        this.totalPoints = 0;
        this.autoCleanup = true;  // Автоочистка по умолчанию включена
        
        // FPS мониторинг
        this.frameCount = 0;
        this.lastFPSTime = Date.now();
        this.realFPS = 0;
        this.fpsHistory = [];
        
        // Статистика
        this.stats = {
            startTime: null,
            totalUpdates: 0,
            droppedFrames: 0,
            avgFPS: 0,
            memoryUsage: 0
        };
    }
    
    // ========================================================================
    // ГЕНЕРАЦИЯ ДАННЫХ
    // ========================================================================
    
    /**
     * Генерация начальных данных (пустые массивы для всех линий)
     */
    generateInitialData() {
        // Создаём массив: [индексы, линия1, линия2, ...]
        this.data = [[]]; // Первый массив - индексы X
        
        // Добавляем пустой массив для каждой линии
        this.config.series.forEach(() => {
            this.data.push([]);
        });
        
        this.lastValue = 50; // Стартовое значение для первой точки
        this.currentIndex = 0;
    }
    
    /**
     * Добавление новой точки данных (СИНХРОННОЕ для всех линий)
     * @param {Array|number} values - Массив значений для всех линий [v1, v2, v3] или одно значение (если линия одна)
     * @returns {boolean|object} true если успешно, объект с ошибкой если нет
     */
    addPoint(values) {
        if (!this.data || this.isPaused) return false;
        
        const seriesCount = this.config.series.length;
        
        // Обратная совместимость: если линия одна и передано число
        if (seriesCount === 1 && typeof values === 'number') {
            values = [values];
        }
        
        // Проверка: values должен быть массивом
        if (!Array.isArray(values)) {
            const error = {
                error: 'INVALID_TYPE',
                message: `❌ addPoint(): ожидается массив значений, получено: ${typeof values}`,
                expected: seriesCount,
                received: 0
            };
            console.error(error.message);
            return error;
        }
        
        // Проверка: количество значений должно совпадать с количеством линий
        if (values.length !== seriesCount) {
            const error = {
                error: 'SERIES_MISMATCH',
                message: `❌ addPoint(): требуется ${seriesCount} значений (линий: ${seriesCount}), передано: ${values.length}`,
                expected: seriesCount,
                received: values.length,
                seriesIds: this.config.series.map(s => s.id)
            };
            console.error(error.message);
            console.error(`   Линии: ${error.seriesIds.join(', ')}`);
            return error;
        }
        
        // Проверка: все значения должны быть числами
        for (let i = 0; i < values.length; i++) {
            if (typeof values[i] !== 'number' || isNaN(values[i])) {
                const error = {
                    error: 'INVALID_VALUE',
                    message: `❌ addPoint(): значение [${i}] не является числом: ${values[i]}`,
                    index: i,
                    value: values[i],
                    seriesId: this.config.series[i].id
                };
                console.error(error.message);
                return error;
            }
        }
        
        this.totalPoints++;
        this.stats.totalUpdates++;
        
        // СИНХРОННОЕ добавление: все линии получают значения одновременно
        for (let i = 0; i < seriesCount; i++) {
            const seriesIndex = i + 1; // +1 потому что 0 - это X ось
            this.data[seriesIndex].push(parseFloat(values[i].toFixed(2)));
        }
        
        // АВТООЧИСТКА: Если включена И превышен лимит
        if (this.autoCleanup && this.data[1].length > this.config.windowSize) {
            // Удаляем первую точку из всех линий синхронно
            for (let i = 1; i < this.data.length; i++) {
                this.data[i].shift();
            }
        }
        
        // Пересоздаём массив индексов (всегда 0, 1, 2, ... N-1)
        const currentLength = this.data[1].length;
        this.data[0] = Array.from({ length: currentLength }, (_, i) => i);
        
        // Обновляем график
        if (this.chart) {
            this.chart.setData(this.data);
            
            // ФИКСИРОВАННЫЙ диапазон X: всегда от 0 до windowSize-1
            this.chart.setScale('x', { 
                min: 0, 
                max: this.config.windowSize - 1 
            });
        }
        
        // Обновляем FPS
        this.updateFPS();
        
        // Логируем статистику каждые 10000 точек (снижена частота)
        if (this.totalPoints % 10000 === 0) {
            console.log(`📊 ScadaRealtimeChart: ${this.totalPoints} точек, FPS: ${this.realFPS.toFixed(1)}, память: ${this.getMemoryUsage().kb} KB, в памяти: ${this.data[0].length} точек`);
        }
        
        return true;
    }
    
    /**
     * Добавление нескольких точек за раз (BATCH режим)
     * @param {Array} pointsArray - Массив массивов: [[v1,v2,v3], [v1,v2,v3], ...]
     * @returns {object} Результат: { success: number, failed: number, errors: [] }
     */
    addPoints(pointsArray) {
        if (!Array.isArray(pointsArray)) {
            console.error('❌ addPoints(): ожидается массив массивов точек');
            return { success: 0, failed: 1, errors: ['INVALID_TYPE'] };
        }
        
        if (pointsArray.length === 0 || pointsArray.length > 100) {
            console.error(`❌ addPoints(): можно добавить от 1 до 100 точек за раз, передано: ${pointsArray.length}`);
            return { success: 0, failed: pointsArray.length, errors: ['OUT_OF_RANGE'] };
        }
        
        const result = {
            success: 0,
            failed: 0,
            errors: []
        };
        
        for (let i = 0; i < pointsArray.length; i++) {
            const res = this.addPoint(pointsArray[i]);
            
            if (res === true) {
                result.success++;
            } else {
                result.failed++;
                result.errors.push({
                    index: i,
                    error: res
                });
            }
        }
        
        return result;
    }
    
    // ========================================================================
    // УПРАВЛЕНИЕ ЛИНИЯМИ (SERIES)
    // ========================================================================
    
    /**
     * Добавление новой линии динамически
     * @param {string} id - Уникальный ID линии
     * @param {object} config - Конфигурация: { label, color, width, fillAlpha }
     */
    addSeries(id, config = {}) {
        // Проверка на дубликат
        if (this.seriesMap.has(id)) {
            console.error(`❌ ScadaRealtimeChart.addSeries(): серия "${id}" уже существует!`);
            return false;
        }
        
        const hexToRgba = (hex, alpha) => {
            const r = parseInt(hex.slice(1, 3), 16);
            const g = parseInt(hex.slice(3, 5), 16);
            const b = parseInt(hex.slice(5, 7), 16);
            return `rgba(${r}, ${g}, ${b}, ${alpha})`;
        };
        
        const seriesConfig = {
            id: id,
            label: config.label || id,
            color: config.color || '#206bc4',
            width: config.width || 2,
            fillAlpha: config.fillAlpha || 0.1
        };
        
        // Добавляем в конфиг
        this.config.series.push(seriesConfig);
        
        // Добавляем в карту (индекс = текущая длина data)
        const newIndex = this.data.length;
        this.seriesMap.set(id, newIndex);
        
        // Добавляем пустой массив для новой линии
        const currentLength = this.data[0].length;
        this.data.push(new Array(currentLength).fill(null));
        
        // Добавляем серию в uPlot
        this.options.series.push({
            label: seriesConfig.label,
            stroke: seriesConfig.color,
            width: seriesConfig.width,
            fill: hexToRgba(seriesConfig.color, seriesConfig.fillAlpha),
            show: true
        });
        
        // Пересоздаём график с новой серией
        if (this.chart) {
            const wasRunning = this.isRunning;
            const wasPaused = this.isPaused;
            
            this.chart.destroy();
            this.chart = null;
            
            super.init();
            
            if (wasRunning) {
                this.isRunning = true;
                this.isPaused = wasPaused;
            }
        }
        
        console.log(`✅ ScadaRealtimeChart: Добавлена серия "${id}"`);
        return true;
    }
    
    /**
     * Удаление линии
     * @param {string} id - ID линии для удаления
     */
    removeSeries(id) {
        if (!this.seriesMap.has(id)) {
            console.error(`❌ ScadaRealtimeChart.removeSeries(): серия "${id}" не найдена!`);
            return false;
        }
        
        // Нельзя удалить последнюю линию
        if (this.config.series.length === 1) {
            console.error('❌ ScadaRealtimeChart.removeSeries(): нельзя удалить последнюю серию!');
            return false;
        }
        
        const seriesIndex = this.seriesMap.get(id);
        
        // Удаляем из конфига
        const configIndex = this.config.series.findIndex(s => s.id === id);
        this.config.series.splice(configIndex, 1);
        
        // Удаляем из данных
        this.data.splice(seriesIndex, 1);
        
        // Удаляем из опций uPlot
        this.options.series.splice(seriesIndex, 1);
        
        // Пересоздаём карту (индексы изменились)
        this.seriesMap.clear();
        this.config.series.forEach((s, idx) => {
            this.seriesMap.set(s.id, idx + 1);
        });
        
        // Пересоздаём график
        if (this.chart) {
            const wasRunning = this.isRunning;
            const wasPaused = this.isPaused;
            
            this.chart.destroy();
            this.chart = null;
            
            super.init();
            
            if (wasRunning) {
                this.isRunning = true;
                this.isPaused = wasPaused;
            }
        }
        
        console.log(`✅ ScadaRealtimeChart: Удалена серия "${id}"`);
        return true;
    }
    
    /**
     * Получить список всех линий
     * @returns {Array} Массив объектов с информацией о линиях
     */
    getSeries() {
        return this.config.series.map(s => ({
            id: s.id,
            label: s.label,
            color: s.color,
            width: s.width,
            fillAlpha: s.fillAlpha,
            visible: this.options.series[this.seriesMap.get(s.id)].show
        }));
    }
    
    /**
     * Показать/скрыть линию
     * @param {string} id - ID линии
     * @param {boolean} show - true = показать, false = скрыть
     */
    toggleSeriesById(id, show = null) {
        if (!this.seriesMap.has(id)) {
            console.error(`❌ ScadaRealtimeChart.toggleSeriesById(): серия "${id}" не найдена!`);
            return false;
        }
        
        const seriesIndex = this.seriesMap.get(id);
        
        if (show === null) {
            show = !this.options.series[seriesIndex].show;
        }
        
        if (this.chart) {
            this.chart.setSeries(seriesIndex, { show });
        }
        
        this.options.series[seriesIndex].show = show;
        return true;
    }
    
    // ========================================================================
    // УПРАВЛЕНИЕ
    // ========================================================================
    
    /**
     * Запуск real-time обновления
    /**
     * Запуск real-time обновления
     * ВНИМАНИЕ: Виджет НЕ генерирует данные сам!
     * Данные должны поступать извне через addPoint(seriesId, value)
     */
    start() {
        if (this.isRunning && !this.isPaused) return;
        
        this.isRunning = true;
        this.isPaused = false;
        this.stats.startTime = Date.now();
    }
    
    /**
     * Остановка real-time обновления
     */
    stop() {
        if (!this.isRunning) return;
        
        this.isRunning = false;
        this.isPaused = false;
    }
    
    /**
     * Пауза
     */
    pause() {
        if (!this.isRunning || this.isPaused) return;
        
        this.isPaused = true;
    }
    
    /**
     * Продолжить после паузы
     */
    resume() {
        if (!this.isRunning || !this.isPaused) return;
        
        this.isPaused = false;
    }
    
    /**
     * Очистка данных
     */
    clear() {
        this.stop();
        this.generateInitialData();
        
        if (this.chart) {
            this.chart.setData(this.data);
        }
        
        this.totalPoints = 0;
        this.stats.totalUpdates = 0;
        this.stats.droppedFrames = 0;
        this.fpsHistory = [];
    }
    
    // ========================================================================
    // НАСТРОЙКИ
    // ========================================================================
    
    /**
     * Изменить FPS
     */
    setFPS(fps) {
        if (fps <= 0 || fps > 120) {
            console.error('❌ ScadaRealtimeChart: FPS должен быть от 1 до 120');
            return;
        }
        
        const newInterval = Math.floor(1000 / fps);
        this.config.updateInterval = newInterval;
        
        // Перезапускаем если работает
        if (this.isRunning) {
            this.stop();
            this.start();
        }
    }
    
    /**
     * Изменить размер окна данных
     */
    setWindowSize(size) {
        if (size < 10 || size > 10000) {
            console.error('❌ ScadaRealtimeChart: Размер окна должен быть от 10 до 10000');
            return;
        }
        
        const oldSize = this.config.windowSize;
        this.config.windowSize = size;
        
        // Если автоочистка включена И данных больше чем новое окно - обрезаем
        if (this.autoCleanup && this.data && this.data[0].length > size) {
            // Берём последние N точек
            this.data[0] = this.data[0].slice(-size);
            this.data[1] = this.data[1].slice(-size);
            
            // Пересчитываем индексы: 0, 1, 2, ... size-1
            for (let i = 0; i < this.data[0].length; i++) {
                this.data[0][i] = i;
            }
        }
        
        // Обновляем график с новым диапазоном
        if (this.chart) {
            this.chart.setData(this.data);
            
            // ФИКСИРОВАННЫЙ диапазон X: всегда от 0 до windowSize
            this.chart.setScale('x', { 
                min: 0, 
                max: size - 1 
            });
        }
    }
    
    /**
     * Включить/выключить автоочистку
     */
    setAutoCleanup(enabled) {
        this.autoCleanup = enabled;
        
        // Если включили автоочистку и данных больше чем окно - обрезаем сразу
        if (enabled && this.data && this.data[0].length > this.config.windowSize) {
            // Берём последние N точек
            this.data[0] = this.data[0].slice(-this.config.windowSize);
            this.data[1] = this.data[1].slice(-this.config.windowSize);
            
            // Пересчитываем индексы: 0, 1, 2, ... windowSize-1
            for (let i = 0; i < this.data[0].length; i++) {
                this.data[0][i] = i;
            }
            
            if (this.chart) {
                this.chart.setData(this.data);
                
                // ФИКСИРОВАННЫЙ диапазон X
                this.chart.setScale('x', { 
                    min: 0, 
                    max: this.config.windowSize - 1 
                });
            }
        }
    }
    
    /**
     * Изменить интервал обновления
     */
    setUpdateInterval(ms) {
        if (ms < 1 || ms > 10000) {
            console.error('❌ ScadaRealtimeChart: Интервал должен быть от 1 до 10000 мс');
            return;
        }
        
        this.config.updateInterval = ms;
        
        if (this.isRunning) {
            this.stop();
            this.start();
        }
    }
    
    // ========================================================================
    // ВИЗУАЛИЗАЦИЯ
    // ========================================================================
    
    /**
     * Вкл/выкл сетку
     */
    toggleGrid(show = null) {
        if (show === null) {
            show = !this.config.showGrid;
        }
        
        this.config.showGrid = show;
        
        if (this.chart) {
            // Обновляем опции осей
            this.options.axes[0].grid.show = show;
            this.options.axes[1].grid.show = show;
            
            // Пересоздаём график (uPlot не поддерживает динамическое изменение)
            const wasRunning = this.isRunning;
            const wasPaused = this.isPaused;
            const oldData = this.data;
            
            // Останавливаем обновление
            if (wasRunning) {
                this.stop();
            }
            
            // Уничтожаем старый график
            if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }
            
            // Создаём новый график с обновлёнными опциями
            super.init();
            
            // Восстанавливаем состояние
            if (wasRunning) {
                if (wasPaused) {
                    this.start();
                    this.pause();
                } else {
                    this.start();
                }
            }
        }
    }
    
    /**
     * Установить стиль сетки
     */
    setGridStyle(style = {}) {
        const { stroke, width } = style;
        
        if (this.chart) {
            if (stroke) {
                this.options.axes[0].grid.stroke = stroke;
                this.options.axes[1].grid.stroke = stroke;
            }
            
            if (width) {
                this.options.axes[0].grid.width = width;
                this.options.axes[1].grid.width = width;
            }
        }
    }
    
    /**
     * Установить диапазон оси
     */
    setAxisRange(axis, min, max) {
        if (!this.chart) return;
        
        if (axis === 'x' || axis === 0) {
            this.chart.setScale('x', { min, max });
        } else if (axis === 'y' || axis === 1) {
            this.chart.setScale('y', { min, max });
            this.config.minValue = min;
            this.config.maxValue = max;
        }
    }
    
    /**
     * Вкл/выкл ось
     */
    toggleAxis(axis, show = null) {
        if (!this.chart) return;
        
        const axisIdx = axis === 'x' || axis === 0 ? 0 : 1;
        
        if (show === null) {
            show = !this.options.axes[axisIdx].show;
        }
        
        this.options.axes[axisIdx].show = show;
    }
    
    /**
     * Вкл/выкл серию
     */
    toggleSeries(idx, show = null) {
        if (!this.chart) return;
        
        if (show === null) {
            show = !this.options.series[idx].show;
        }
        
        this.chart.setSeries(idx, { show });
        this.options.series[idx].show = show;
    }
    
    /**
     * Установить стиль серии
     */
    setSeriesStyle(idx, style = {}) {
        if (!this.chart) return;
        
        const { stroke, width, fill } = style;
        
        if (stroke) {
            this.options.series[idx].stroke = stroke;
            this.config.lineColor = stroke;
        }
        if (width) {
            this.options.series[idx].width = width;
            this.config.lineWidth = width;
        }
        if (fill) {
            this.options.series[idx].fill = fill;
        }
        
        // Пересоздаём график для применения стилей
        const wasRunning = this.isRunning;
        const wasPaused = this.isPaused;
        
        if (wasRunning) {
            this.stop();
        }
        
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
        
        super.init();
        
        if (wasRunning) {
            if (wasPaused) {
                this.start();
                this.pause();
            } else {
                this.start();
            }
        }
    }
    
    /**
     * Установить цвет линии
     */
    setLineColor(color) {
        const hexToRgba = (hex, alpha) => {
            const r = parseInt(hex.slice(1, 3), 16);
            const g = parseInt(hex.slice(3, 5), 16);
            const b = parseInt(hex.slice(5, 7), 16);
            return `rgba(${r}, ${g}, ${b}, ${alpha})`;
        };
        
        this.setSeriesStyle(1, {
            stroke: color,
            fill: hexToRgba(color, this.config.fillAlpha)
        });
    }
    
    // ========================================================================
    // ДАННЫЕ И СТАТИСТИКА
    // ========================================================================
    
    /**
     * Получить использование памяти
     */
    getMemoryUsage() {
        if (!this.data) {
            return { points: 0, series: 0, bytes: 0, kb: '0.00', mb: '0.00' };
        }
        
        const dataSize = this.data[0].length * this.data.length;
        const bytesPerPoint = 8; // Float64
        const totalBytes = dataSize * bytesPerPoint;
        const totalKB = totalBytes / 1024;
        const totalMB = totalKB / 1024;
        
        return {
            points: this.data[0].length,
            series: this.data.length,
            bytes: totalBytes,
            kb: totalKB.toFixed(2),
            mb: totalMB.toFixed(2)
        };
    }
    
    /**
     * Получить статистику
     */
    getStats() {
        const memory = this.getMemoryUsage();
        const uptime = this.stats.startTime ? (Date.now() - this.stats.startTime) / 1000 : 0;
        
        return {
            isRunning: this.isRunning,
            isPaused: this.isPaused,
            totalPoints: this.totalPoints,
            windowSize: this.config.windowSize,
            updateInterval: this.config.updateInterval,
            targetFPS: (1000 / this.config.updateInterval).toFixed(1),
            realFPS: this.realFPS.toFixed(1),
            avgFPS: this.stats.avgFPS.toFixed(1),
            totalUpdates: this.stats.totalUpdates,
            droppedFrames: this.stats.droppedFrames,
            uptime: uptime.toFixed(1),
            memory: memory
        };
    }
    
    /**
     * Получить реальный FPS
     */
    getRealFPS() {
        return this.realFPS;
    }
    
    /**
     * Обновить FPS
     * @private
     */
    updateFPS() {
        this.frameCount++;
        const now = Date.now();
        const elapsed = now - this.lastFPSTime;
        
        if (elapsed >= 1000) {
            this.realFPS = this.frameCount / (elapsed / 1000);
            this.fpsHistory.push(this.realFPS);
            
            // Ограничиваем историю FPS (последние 60 секунд)
            if (this.fpsHistory.length > 60) {
                this.fpsHistory.shift();
            }
            
            // Средний FPS
            this.stats.avgFPS = this.fpsHistory.reduce((a, b) => a + b, 0) / this.fpsHistory.length;
            
            // Пропущенные кадры
            const targetFPS = 1000 / this.config.updateInterval;
            if (this.realFPS < targetFPS * 0.9) {
                this.stats.droppedFrames++;
            }
            
            this.frameCount = 0;
            this.lastFPSTime = now;
        }
    }
    
    /**
     * Очистить старые данные
     */
    clearOldData() {
        if (!this.data) return;
        
        const keepSize = Math.floor(this.config.windowSize / 2);
        
        this.data[0] = this.data[0].slice(-keepSize);
        this.data[1] = this.data[1].slice(-keepSize);
        
        if (this.chart) {
            this.chart.setData(this.data);
        }
    }
    
    // ========================================================================
    // ИНИЦИАЛИЗАЦИЯ И ОЧИСТКА
    // ========================================================================
    
    /**
     * Инициализация с автозапуском
     */
    init() {
        this.generateInitialData();
        super.init();
        
        // Устанавливаем фиксированный диапазон X сразу после создания графика
        if (this.chart) {
            this.chart.setScale('x', { 
                min: 0, 
                max: this.config.windowSize - 1 
            });
        }
        
        // НЕ запускаем автоматически - это решает страница
    }
    
    /**
     * Очистка
     */
    destroy() {
        this.stop();
        super.destroy();
        
        this.currentIndex = 0;
        this.lastValue = 50;
        this.totalPoints = 0;
        this.frameCount = 0;
        this.fpsHistory = [];
        this.stats = {
            startTime: null,
            totalUpdates: 0,
            droppedFrames: 0,
            avgFPS: 0,
            memoryUsage: 0
        };
    }
}
