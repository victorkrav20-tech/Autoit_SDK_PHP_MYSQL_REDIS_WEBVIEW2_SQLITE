// ===============================================================================
// Notifications - Обёртка для Toastify JS
// Версия: 2.0.0 (Toastify)
// ===============================================================================

class Notifications {
    constructor() {
        this.defaultDuration = 3000;
        this.defaultGravity = "top";      // "top" или "bottom"
        this.defaultPosition = "right";   // "left", "center", "right"
        console.log('📦 Notifications (Toastify) инициализирован');
    }
    
    // ===============================================================================
    // Базовый метод показа уведомления
    // ===============================================================================
    show(message, type = 'info', options = {}) {
        const config = {
            text: message,
            duration: options.duration || this.defaultDuration,
            close: options.close !== undefined ? options.close : true,
            gravity: options.gravity || this.defaultGravity,
            position: options.position || this.defaultPosition,
            stopOnFocus: options.stopOnFocus !== undefined ? options.stopOnFocus : true,
            className: options.className || `toast-${type}`,
            avatar: options.avatar || null,
            destination: options.destination || null,
            newWindow: options.newWindow || false,
            onClick: options.onClick || null,
            offset: options.offset || { x: 0, y: 0 },
            style: options.style || this.getStyle(type)
        };
        
        return Toastify(config).showToast();
    }
    
    // ===============================================================================
    // Стили для разных типов
    // ===============================================================================
    getStyle(type) {
        const styles = {
            success: {
                background: "linear-gradient(to right, #10b981, #059669)",
            },
            error: {
                background: "linear-gradient(to right, #ef4444, #dc2626)",
            },
            warning: {
                background: "linear-gradient(to right, #f59e0b, #d97706)",
            },
            info: {
                background: "linear-gradient(to right, #3b82f6, #2563eb)",
            }
        };
        
        return styles[type] || styles.info;
    }
    
    // ===============================================================================
    // Вспомогательные методы
    // ===============================================================================
    success(message, options = {}) {
        return this.show(message, 'success', options);
    }
    
    error(message, options = {}) {
        return this.show(message, 'error', options);
    }
    
    warning(message, options = {}) {
        return this.show(message, 'warning', options);
    }
    
    info(message, options = {}) {
        return this.show(message, 'info', options);
    }
    
    // ===============================================================================
    // Настройка глобальных параметров
    // ===============================================================================
    configure(options = {}) {
        if (options.duration !== undefined) this.defaultDuration = options.duration;
        if (options.gravity !== undefined) this.defaultGravity = options.gravity;
        if (options.position !== undefined) this.defaultPosition = options.position;
    }

    // ===============================================================================
    // Специальное уведомление для автокликера (справа, кастомные цвета)
    // ===============================================================================
    autoClicker(enabled) {
        const message = enabled ? 'Автокликер включен' : 'Автокликер выключен';
        
        return this.show(message, enabled ? 'success' : 'info', {
            duration: 2000,
            gravity: 'top',
            position: 'right',
            className: `toast-autoclicker`,
            style: {
                background: enabled 
                    ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'  // Фиолетовый градиент для ВКЛ
                    : 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)', // Розовый градиент для ВЫКЛ
                color: '#ffffff',
                borderRadius: '8px',
                padding: '16px 24px',
                fontSize: '14px',
                fontWeight: '500',
                boxShadow: '0 4px 12px rgba(0,0,0,0.15)'
            }
        });
    }
}

// ===============================================================================
// Создание глобального экземпляра
// ===============================================================================
window.Notifications = new Notifications();

// Удобные глобальные функции
window.showNotification = (message, type, options) => window.Notifications.show(message, type, options);
window.notifySuccess = (message, options) => window.Notifications.success(message, options);
window.notifyError = (message, options) => window.Notifications.error(message, options);
window.notifyWarning = (message, options) => window.Notifications.warning(message, options);
window.notifyInfo = (message, options) => window.Notifications.info(message, options);
window.notifyAutoClicker = (enabled) => window.Notifications.autoClicker(enabled);

console.log('📦 Notifications готов к использованию');
