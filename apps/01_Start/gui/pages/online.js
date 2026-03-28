// ===============================================================================
// Online Page - Главный компонент (координатор)
// Использует модульную архитектуру для оптимальной производительности
// ===============================================================================

class OnlinePageTest extends HTMLElement {
    constructor() {
        super();
        
        // Модули
        this.dataManager = new OnlineDataManager();
        this.renderer = new OnlineRenderer();
        this.updater = new OnlineUpdater();
        
        // Состояние
        this.isActive = false;
        this.updateInterval = null;
        this.resizeObserver = null;
        this.lastCardWidth = 0;
    }

    connectedCallback() {
        this.render();
        this.attachEventListeners();
        this.setupResizeObserver();
        this.startMonitoring();
        console.log('✅ Online Page загружена');
    }

    disconnectedCallback() {
        this.stopMonitoring();
        this.cleanupResizeObserver();
        console.log('👋 Online Page выгружена');
    }

    render() {
        // Рендерим структуру
        this.innerHTML = this.renderer.renderPage();
        
        // Инициализируем кэш элементов
        this.updater.initCache();
        
        // Устанавливаем начальную ширину
        this.updateGridLayout();
    }

    setupResizeObserver() {
        // Находим карточку
        const card = this.querySelector('.card');
        if (!card) return;

        // Создаём ResizeObserver для отслеживания изменения размера
        this.resizeObserver = new ResizeObserver((entries) => {
            for (const entry of entries) {
                const newWidth = entry.contentRect.width;
                
                // Обновляем только если ширина изменилась значительно (>10px)
                if (Math.abs(newWidth - this.lastCardWidth) > 10) {
                    this.lastCardWidth = newWidth;
                    this.updateGridLayout();
                }
            }
        });

        // Начинаем наблюдение
        this.resizeObserver.observe(card);
        console.log('👁️ ResizeObserver установлен');
    }

    cleanupResizeObserver() {
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
            this.resizeObserver = null;
            console.log('🗑️ ResizeObserver отключён');
        }
    }

    updateGridLayout() {
        const grid = this.querySelector('.counters-grid');
        if (!grid) return;

        // CSS Grid автоматически пересчитает колонки благодаря minmax()
        // Принудительный reflow для применения изменений
        grid.style.display = 'none';
        grid.offsetHeight; // Trigger reflow
        grid.style.display = 'grid';
    }

    attachEventListeners() {
        // Кнопка "Обновить всё"
        const btnRefresh = document.getElementById('btn-refresh-all');
        if (btnRefresh) {
            btnRefresh.addEventListener('click', () => this.refreshAll());
        }

        // Кнопки управления счётчиками
        for (let i = 1; i <= 7; i++) {
            // Кнопка парсинга
            const btnParsing = document.querySelector(`.btn-parsing[data-counter-id="${i}"]`);
            if (btnParsing) {
                btnParsing.addEventListener('click', () => this.toggleParsing(i));
            }

            // Кнопка окна
            const btnWindow = document.querySelector(`.btn-window[data-counter-id="${i}"]`);
            if (btnWindow) {
                btnWindow.addEventListener('click', () => this.toggleWindow(i));
            }
        }
    }

    async startMonitoring() {
        this.isActive = true;
        
        // Загружаем начальные данные
        setTimeout(async () => {
            await this.dataManager.loadInitialData();
            this.updater.updateAll(this.dataManager);
        }, 500);
        
        // Через 3 секунды выводим отладочные данные
        setTimeout(async () => {
            await this.debugShowArrays();
        }, 3000);
        
        // Обновление данных каждые 100ms
        this.updateInterval = setInterval(async () => {
            if (this.isActive) {
                const success = await this.dataManager.refreshData();
                if (success) {
                    this.updater.updateAll(this.dataManager);
                }
            }
        }, 100);
        
        console.log('🔄 Мониторинг запущен (обновление каждые 100ms)');
    }

    async debugShowArrays() {
        console.log('🔍 [DEBUG] Загружаю данные для отладки...');
        
        try {
            // Запрашиваем последнюю запись от каждого счётчика
            const lastData = await window.RequestHub.send('get_all_counters_last_data', { count: 1 });
            
            if (!lastData) {
                console.error('❌ [DEBUG] Нет данных');
                return;
            }
            
            const debugEl = document.getElementById('debug-arrays');
            if (!debugEl) return;
            
            let output = '';
            
            for (let i = 1; i <= 7; i++) {
                const counterKey = `counter${i}`;
                const records = lastData[counterKey];
                
                output += `\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;
                output += `Счётчик #${i}\n`;
                output += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;
                
                if (!records || !Array.isArray(records) || records.length === 0) {
                    output += `❌ Нет данных\n`;
                    continue;
                }
                
                const record = records[0];
                
                // Выводим все поля
                output += `\nВсе поля записи:\n`;
                output += `─────────────────────────────────────────────────────────────\n`;
                
                const keys = Object.keys(record);
                keys.forEach((key, index) => {
                    output += `[${index}] ${key}: ${record[key]}\n`;
                });
                
                output += `\n`;
            }
            
            debugEl.textContent = output;
            console.log('✅ [DEBUG] Данные выведены');
            
        } catch (error) {
            console.error('❌ [DEBUG] Ошибка:', error);
        }
    }

    stopMonitoring() {
        this.isActive = false;
        
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
        
        console.log('⏸️ Мониторинг остановлен');
    }

    async refreshAll() {
        console.log('🔄 Обновление всех данных...');
        await this.dataManager.loadInitialData();
        this.updater.updateAll(this.dataManager);
    }

    async toggleParsing(counterId) {
        const btn = document.querySelector(`.btn-parsing[data-counter-id="${counterId}"]`);
        if (!btn) return;

        btn.disabled = true;
        btn.textContent = '⏳';

        try {
            const response = await window.RequestHub.sendReliable('toggle_counter_parsing', { 
                counterId: counterId 
            });
            
            if (response && response.enabled !== undefined) {
                const counter = this.dataManager.getCounter(counterId);
                if (counter) {
                    counter.enabled = response.enabled;
                    this.updater.updateCounter(counterId, counter);
                }
                
                if (window.notifySuccess) {
                    window.notifySuccess(`Парсинг счётчика ${counterId} ${response.enabled ? 'включен' : 'выключен'}`);
                }
            }
        } catch (error) {
            console.error(`❌ Ошибка переключения парсинга счётчика ${counterId}:`, error);
            if (window.notifyError) {
                window.notifyError('Ошибка: ' + error.message);
            }
            btn.disabled = false;
            btn.textContent = '⚠️';
        }
    }

    async toggleWindow(counterId) {
        const btn = document.querySelector(`.btn-window[data-counter-id="${counterId}"]`);
        if (!btn) return;

        btn.disabled = true;
        btn.textContent = '⏳';

        try {
            const response = await window.RequestHub.sendReliable('toggle_counter_window', { 
                counterId: counterId 
            });
            
            if (response && response.visible !== undefined) {
                const counter = this.dataManager.getCounter(counterId);
                if (counter) {
                    counter.windowVisible = response.visible;
                    this.updater.updateCounter(counterId, counter);
                }
                
                if (window.notifySuccess) {
                    window.notifySuccess(`Окно счётчика ${counterId} ${response.visible ? 'показано' : 'скрыто'}`);
                }
            }
        } catch (error) {
            console.error(`❌ Ошибка переключения окна счётчика ${counterId}:`, error);
            if (window.notifyError) {
                window.notifyError('Ошибка: ' + error.message);
            }
            btn.disabled = false;
            btn.textContent = '⚠️';
        }
    }
}

// Регистрация компонента
customElements.define('page-online-test', OnlinePageTest);

console.log('✅ Online Page компонент зарегистрирован');
