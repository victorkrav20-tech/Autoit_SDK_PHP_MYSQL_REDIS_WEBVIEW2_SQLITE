// ===============================================================================
// Toast - Универсальные уведомления
// Версия: 1.0.0
// ===============================================================================

class Toast {
    constructor() {
        this.container = null;
        this.toasts = new Map();
        this.toastIdCounter = 0;
        this.defaultDuration = 3000; // 3 секунды
        
        this.init();
        console.log('📦 Toast инициализирован');
    }
    
    // ===============================================================================
    // Инициализация контейнера
    // ===============================================================================
    init() {
        // Создаём контейнер для toast'ов
        this.container = document.createElement('div');
        this.container.id = 'toast-container';
        this.container.className = 'toast-container';
        document.body.appendChild(this.container);
    }
    
    // ===============================================================================
    // Показать уведомление
    // ===============================================================================
    show(message, type = 'info', duration = this.defaultDuration) {
        const toastId = ++this.toastIdCounter;
        
        // Создаём элемент toast
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.dataset.toastId = toastId;
        
        // Иконка в зависимости от типа
        const icon = this.getIcon(type);
        
        // Содержимое
        toast.innerHTML = `
            <div class="toast-icon">${icon}</div>
            <div class="toast-message">${message}</div>
            <button class="toast-close" onclick="window.ToastInstance.close(${toastId})">×</button>
        `;
        
        // Добавляем в контейнер
        this.container.appendChild(toast);
        
        // Анимация появления
        setTimeout(() => {
            toast.classList.add('toast-show');
        }, 10);
        
        // Автоматическое скрытие
        if (duration > 0) {
            const timeoutId = setTimeout(() => {
                this.close(toastId);
            }, duration);
            
            this.toasts.set(toastId, { element: toast, timeoutId: timeoutId });
        } else {
            this.toasts.set(toastId, { element: toast, timeoutId: null });
        }
        
        console.log(`📢 Toast #${toastId} показан:`, type, message);
        
        return toastId;
    }
    
    // ===============================================================================
    // Закрыть уведомление
    // ===============================================================================
    close(toastId) {
        const toast = this.toasts.get(toastId);
        
        if (!toast) return;
        
        // Очищаем таймер
        if (toast.timeoutId) {
            clearTimeout(toast.timeoutId);
        }
        
        // Анимация скрытия
        toast.element.classList.remove('toast-show');
        toast.element.classList.add('toast-hide');
        
        // Удаляем из DOM
        setTimeout(() => {
            if (toast.element.parentNode) {
                toast.element.parentNode.removeChild(toast.element);
            }
            this.toasts.delete(toastId);
        }, 300);
        
        console.log(`📢 Toast #${toastId} закрыт`);
    }
    
    // ===============================================================================
    // Закрыть все уведомления
    // ===============================================================================
    closeAll() {
        this.toasts.forEach((toast, toastId) => {
            this.close(toastId);
        });
    }
    
    // ===============================================================================
    // Получить иконку по типу
    // ===============================================================================
    getIcon(type) {
        const icons = {
            success: '✓',
            error: '✕',
            warning: '⚠',
            info: 'ℹ'
        };
        
        return icons[type] || icons.info;
    }
    
    // ===============================================================================
    // Вспомогательные методы
    // ===============================================================================
    success(message, duration) {
        return this.show(message, 'success', duration);
    }
    
    error(message, duration) {
        return this.show(message, 'error', duration);
    }
    
    warning(message, duration) {
        return this.show(message, 'warning', duration);
    }
    
    info(message, duration) {
        return this.show(message, 'info', duration);
    }
}

// ===============================================================================
// Создание глобального экземпляра
// ===============================================================================
window.ToastInstance = new Toast();

// Удобные глобальные функции
window.showToast = (message, type, duration) => window.ToastInstance.show(message, type, duration);
window.toastSuccess = (message, duration) => window.ToastInstance.success(message, duration);
window.toastError = (message, duration) => window.ToastInstance.error(message, duration);
window.toastWarning = (message, duration) => window.ToastInstance.warning(message, duration);
window.toastInfo = (message, duration) => window.ToastInstance.info(message, duration);

console.log('📦 Toast готов к использованию');
