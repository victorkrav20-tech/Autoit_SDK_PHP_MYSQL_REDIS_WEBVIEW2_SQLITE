// ===============================================================================
// StatusIndicator - Индикатор статуса для кнопок и элементов
// Версия: 1.0.0
// ===============================================================================

class StatusIndicator {
    constructor(element) {
        this.element = element;
        this.indicator = null;
        this.currentState = 'idle';
        this.originalContent = null;
        
        this.init();
    }
    
    // ===============================================================================
    // Инициализация
    // ===============================================================================
    init() {
        // Сохраняем оригинальное содержимое
        this.originalContent = this.element.innerHTML;
        
        // Создаём контейнер для индикатора
        this.indicator = document.createElement('span');
        this.indicator.className = 'status-indicator';
        
        console.log('📦 StatusIndicator создан для элемента:', this.element);
    }
    
    // ===============================================================================
    // Состояние: Загрузка (спиннер)
    // ===============================================================================
    loading(message = 'Загрузка...') {
        this.currentState = 'loading';
        
        this.indicator.className = 'status-indicator status-loading';
        this.indicator.innerHTML = `
            <span class="spinner"></span>
            <span class="status-text">${message}</span>
        `;
        
        this.element.innerHTML = '';
        this.element.appendChild(this.indicator);
        this.element.disabled = true;
        
        console.log('⏳ StatusIndicator: loading');
    }
    
    // ===============================================================================
    // Состояние: Успех (зелёная галочка)
    // ===============================================================================
    success(message = 'Успешно', duration = 2000) {
        this.currentState = 'success';
        
        this.indicator.className = 'status-indicator status-success';
        this.indicator.innerHTML = `
            <span class="icon-success">✓</span>
            <span class="status-text">${message}</span>
        `;
        
        this.element.innerHTML = '';
        this.element.appendChild(this.indicator);
        this.element.disabled = false;
        
        console.log('✅ StatusIndicator: success');
        
        // Автоматический возврат к исходному состоянию
        if (duration > 0) {
            setTimeout(() => {
                this.reset();
            }, duration);
        }
    }
    
    // ===============================================================================
    // Состояние: Ошибка (красный крестик)
    // ===============================================================================
    error(message = 'Ошибка', duration = 3000) {
        this.currentState = 'error';
        
        this.indicator.className = 'status-indicator status-error';
        this.indicator.innerHTML = `
            <span class="icon-error">✕</span>
            <span class="status-text">${message}</span>
        `;
        
        this.element.innerHTML = '';
        this.element.appendChild(this.indicator);
        this.element.disabled = false;
        
        console.log('❌ StatusIndicator: error');
        
        // Автоматический возврат к исходному состоянию
        if (duration > 0) {
            setTimeout(() => {
                this.reset();
            }, duration);
        }
    }
    
    // ===============================================================================
    // Состояние: Предупреждение
    // ===============================================================================
    warning(message = 'Внимание', duration = 2000) {
        this.currentState = 'warning';
        
        this.indicator.className = 'status-indicator status-warning';
        this.indicator.innerHTML = `
            <span class="icon-warning">⚠</span>
            <span class="status-text">${message}</span>
        `;
        
        this.element.innerHTML = '';
        this.element.appendChild(this.indicator);
        this.element.disabled = false;
        
        console.log('⚠️ StatusIndicator: warning');
        
        // Автоматический возврат к исходному состоянию
        if (duration > 0) {
            setTimeout(() => {
                this.reset();
            }, duration);
        }
    }
    
    // ===============================================================================
    // Сброс к исходному состоянию
    // ===============================================================================
    reset() {
        this.currentState = 'idle';
        this.element.innerHTML = this.originalContent;
        this.element.disabled = false;
        
        console.log('🔄 StatusIndicator: reset');
    }
    
    // ===============================================================================
    // Получить текущее состояние
    // ===============================================================================
    getState() {
        return this.currentState;
    }
    
    // ===============================================================================
    // Проверка состояния
    // ===============================================================================
    isLoading() {
        return this.currentState === 'loading';
    }
    
    isSuccess() {
        return this.currentState === 'success';
    }
    
    isError() {
        return this.currentState === 'error';
    }
    
    isIdle() {
        return this.currentState === 'idle';
    }
}

// ===============================================================================
// Фабрика для создания индикаторов
// ===============================================================================
class StatusIndicatorFactory {
    constructor() {
        this.indicators = new Map();
    }
    
    // Создать индикатор для элемента
    create(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        
        if (!element) {
            console.error('❌ Элемент не найден');
            return null;
        }
        
        // Если индикатор уже существует - возвращаем его
        if (this.indicators.has(element)) {
            return this.indicators.get(element);
        }
        
        // Создаём новый индикатор
        const indicator = new StatusIndicator(element);
        this.indicators.set(element, indicator);
        
        return indicator;
    }
    
    // Получить существующий индикатор
    get(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        
        return this.indicators.get(element) || null;
    }
    
    // Удалить индикатор
    remove(element) {
        if (typeof element === 'string') {
            element = document.querySelector(element);
        }
        
        const indicator = this.indicators.get(element);
        if (indicator) {
            indicator.reset();
            this.indicators.delete(element);
        }
    }
    
    // Сбросить все индикаторы
    resetAll() {
        this.indicators.forEach(indicator => {
            indicator.reset();
        });
    }
}

// ===============================================================================
// Создание глобального экземпляра фабрики
// ===============================================================================
window.StatusIndicatorFactory = new StatusIndicatorFactory();

// Удобная глобальная функция
window.createStatusIndicator = (element) => window.StatusIndicatorFactory.create(element);

console.log('📦 StatusIndicator готов к использованию');
