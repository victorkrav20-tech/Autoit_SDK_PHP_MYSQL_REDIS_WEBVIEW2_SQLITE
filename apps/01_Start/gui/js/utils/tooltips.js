// ===============================================================================
// Tooltips - Обёртка для Tippy.js
// Версия: 1.0.0
// ===============================================================================

class Tooltips {
    constructor() {
        this.instances = new Map();
        console.log('📦 Tooltips (Tippy.js) инициализирован');
    }
    
    // ===============================================================================
    // Создать tooltip для элемента
    // ===============================================================================
    create(selector, options = {}) {
        const elements = typeof selector === 'string' 
            ? document.querySelectorAll(selector)
            : [selector];
        
        if (elements.length === 0) {
            console.warn('⚠️ Элементы не найдены:', selector);
            return null;
        }
        
        const config = {
            content: options.content || 'Tooltip',
            placement: options.placement || 'top',
            theme: options.theme || 'light',
            animation: options.animation || 'fade',
            arrow: options.arrow !== undefined ? options.arrow : true,
            delay: options.delay || [0, 0],
            duration: options.duration || [300, 250],
            interactive: options.interactive || false,
            trigger: options.trigger || 'mouseenter focus',
            maxWidth: options.maxWidth || 350,
            offset: options.offset || [0, 10],
            allowHTML: options.allowHTML || false,
            appendTo: options.appendTo || document.body,
            hideOnClick: options.hideOnClick !== undefined ? options.hideOnClick : true,
            ...options
        };
        
        const instances = tippy(elements, config);
        
        // Сохраняем инстансы
        if (Array.isArray(instances)) {
            instances.forEach(instance => {
                this.instances.set(instance.reference, instance);
            });
        } else {
            this.instances.set(instances.reference, instances);
        }
        
        return instances;
    }
    
    // ===============================================================================
    // Удалить tooltip
    // ===============================================================================
    destroy(selector) {
        const element = typeof selector === 'string' 
            ? document.querySelector(selector)
            : selector;
        
        if (!element) return;
        
        const instance = this.instances.get(element);
        if (instance) {
            instance.destroy();
            this.instances.delete(element);
        }
    }
    
    // ===============================================================================
    // Удалить все tooltips
    // ===============================================================================
    destroyAll() {
        this.instances.forEach(instance => instance.destroy());
        this.instances.clear();
    }
    
    // ===============================================================================
    // Показать tooltip программно
    // ===============================================================================
    show(selector) {
        const element = typeof selector === 'string' 
            ? document.querySelector(selector)
            : selector;
        
        const instance = this.instances.get(element);
        if (instance) instance.show();
    }
    
    // ===============================================================================
    // Скрыть tooltip программно
    // ===============================================================================
    hide(selector) {
        const element = typeof selector === 'string' 
            ? document.querySelector(selector)
            : selector;
        
        const instance = this.instances.get(element);
        if (instance) instance.hide();
    }
    
    // ===============================================================================
    // Обновить контент tooltip
    // ===============================================================================
    setContent(selector, content) {
        const element = typeof selector === 'string' 
            ? document.querySelector(selector)
            : selector;
        
        const instance = this.instances.get(element);
        if (instance) instance.setContent(content);
    }
    
    // ===============================================================================
    // Автоматическая инициализация по data-атрибутам
    // ===============================================================================
    autoInit() {
        // Ищем все элементы с data-tooltip
        const elements = document.querySelectorAll('[data-tooltip]');
        
        elements.forEach(element => {
            const content = element.getAttribute('data-tooltip');
            const placement = element.getAttribute('data-tooltip-placement') || 'top';
            const theme = element.getAttribute('data-tooltip-theme') || 'light';
            
            this.create(element, {
                content: content,
                placement: placement,
                theme: theme
            });
        });
        
        console.log(`✅ Автоинициализация: ${elements.length} tooltips`);
    }
}

// ===============================================================================
// Создание глобального экземпляра
// ===============================================================================
window.Tooltips = new Tooltips();

// Удобные глобальные функции
window.createTooltip = (selector, options) => window.Tooltips.create(selector, options);
window.destroyTooltip = (selector) => window.Tooltips.destroy(selector);
window.showTooltip = (selector) => window.Tooltips.show(selector);
window.hideTooltip = (selector) => window.Tooltips.hide(selector);

// Автоинициализация при загрузке DOM
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.Tooltips.autoInit();
    });
} else {
    window.Tooltips.autoInit();
}

console.log('📦 Tooltips готов к использованию');
