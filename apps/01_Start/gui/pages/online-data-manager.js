// ===============================================================================
// Online Data Manager - Управление данными счётчиков
// ===============================================================================

class OnlineDataManager {
    constructor() {
        this.counters = new Map();
        this.updateCount = 0;
        
        // Инициализация счётчиков
        for (let i = 1; i <= 7; i++) {
            this.counters.set(i, {
                id: i,
                name: `Counter ${i}`,
                enabled: false,
                windowVisible: false,
                lastDataTime: null,
                lastFlow: null,
                flowHistory: [],
                dataStatus: 'no_data',
                workingStatus: 'no_data'
            });
        }
    }

    // Загрузка начальных данных
    async loadInitialData() {
        try {
            // Загружаем статусы счётчиков
            const statuses = await window.RequestHub.send('get_counters_status');
            
            if (Array.isArray(statuses)) {
                statuses.forEach((counterData, index) => {
                    const counterId = index + 1;
                    this.updateCounterInfo(counterId, counterData);
                });
            }
            
            // Загружаем последние 10 записей для истории
            const lastData = await window.RequestHub.send('get_all_counters_last_data', { count: 10 });
            
            if (lastData) {
                this.initFlowHistory(lastData);
            }
            
            return true;
        } catch (error) {
            console.error('❌ [DataManager] Ошибка загрузки данных:', error);
            return false;
        }
    }

    // Обновление данных счётчика
    updateCounterInfo(counterId, data) {
        const counter = this.counters.get(counterId);
        if (!counter) return;

        counter.name = data.name || `Counter ${counterId}`;
        counter.enabled = data.enabled || false;
        counter.windowVisible = data.window_visible || false;
    }

    // Инициализация истории расхода
    initFlowHistory(bufferData) {
        for (let i = 1; i <= 7; i++) {
            const counterKey = `counter${i}`;
            const records = bufferData[counterKey];
            
            if (!records || !Array.isArray(records) || records.length === 0) continue;
            
            const counter = this.counters.get(i);
            if (!counter) continue;
            
            counter.flowHistory = [];
            
            records.forEach(record => {
                // Все счётчики используют main_flow для единообразия
                const flow = parseFloat(record.main_flow) || 0;
                const timestamp = this.parseTimestamp(record.timestamp);
                
                if (timestamp) {
                    counter.flowHistory.push({ flow, timestamp });
                }
            });
            
            if (counter.flowHistory.length > 0) {
                const lastRecord = counter.flowHistory[counter.flowHistory.length - 1];
                counter.lastFlow = lastRecord.flow;
                counter.lastDataTime = lastRecord.timestamp;
            }
        }
    }

    // Обновление данных из буфера
    async refreshData() {
        try {
            const lastData = await window.RequestHub.send('get_all_counters_last_data', { count: 1 });
            
            if (lastData) {
                this.updateFromBuffer(lastData);
                this.updateCount++;
                return true;
            }
            return false;
        } catch (error) {
            console.error('❌ [DataManager] Ошибка обновления:', error);
            return false;
        }
    }

    // Обновление из буфера
    updateFromBuffer(bufferData) {
        const now = Date.now();
        
        for (let i = 1; i <= 7; i++) {
            const counterKey = `counter${i}`;
            const records = bufferData[counterKey];
            
            if (!records || !Array.isArray(records) || records.length === 0) continue;
            
            const counter = this.counters.get(i);
            if (!counter) continue;
            
            const record = records[records.length - 1];
            
            // Все счётчики используют main_flow для единообразия
            const flow = parseFloat(record.main_flow) || 0;
            const timestamp = this.parseTimestamp(record.timestamp);
            
            if (timestamp) {
                counter.lastDataTime = timestamp;
            }
            
            counter.lastFlow = flow;
            
            // Добавляем в историю
            if (timestamp) {
                counter.flowHistory.push({ flow, timestamp });
            }
            
            // Удаляем старые значения (>5 сек)
            counter.flowHistory = counter.flowHistory.filter(
                item => (now - item.timestamp) < 5000
            );
            
            // Ограничиваем размер
            if (counter.flowHistory.length > 10) {
                counter.flowHistory.shift();
            }
        }
        
        // Обновляем статусы
        this.updateStatuses();
    }

    // Обновление статусов
    updateStatuses() {
        const now = Date.now();
        
        for (let i = 1; i <= 7; i++) {
            const counter = this.counters.get(i);
            if (!counter) continue;
            
            // Статус данных
            if (!counter.lastDataTime) {
                counter.dataStatus = 'no_data';
            } else {
                const elapsed = (now - counter.lastDataTime) / 1000;
                
                if (elapsed < 0.5) {
                    counter.dataStatus = 'fresh';
                } else if (elapsed < 3) {
                    counter.dataStatus = 'stale';
                } else {
                    counter.dataStatus = 'timeout';
                }
            }
            
            // Статус работы
            counter.workingStatus = this.calculateWorkingStatus(counter);
        }
    }

    // Вычисление статуса работы
    calculateWorkingStatus(counter) {
        if (counter.flowHistory.length < 2) {
            return { status: 'no_data', icon: '❌', text: 'Нет данных', color: 'secondary' };
        }
        
        const flows = counter.flowHistory.map(item => item.flow);
        const minFlow = Math.min(...flows);
        const maxFlow = Math.max(...flows);
        const delta = Math.abs(maxFlow - minFlow);
        
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

    // Парсинг timestamp
    parseTimestamp(timestampStr) {
        if (!timestampStr) return null;
        
        try {
            const parts = timestampStr.split(' ');
            if (parts.length !== 2) return null;
            
            const dateParts = parts[0].split('-');
            const timeParts = parts[1].split(':');
            
            if (dateParts.length !== 3 || timeParts.length !== 3) return null;
            
            const year = parseInt(dateParts[0]);
            const month = parseInt(dateParts[1]) - 1;
            const day = parseInt(dateParts[2]);
            const hour = parseInt(timeParts[0]);
            const minute = parseInt(timeParts[1]);
            const secondParts = timeParts[2].split('.');
            const second = parseInt(secondParts[0]);
            const millisecond = secondParts.length > 1 ? parseInt(secondParts[1]) : 0;
            
            return new Date(year, month, day, hour, minute, second, millisecond).getTime();
        } catch (error) {
            return null;
        }
    }

    // Получить данные счётчика
    getCounter(counterId) {
        return this.counters.get(counterId);
    }

    // Получить все счётчики
    getAllCounters() {
        return Array.from(this.counters.values());
    }
}
