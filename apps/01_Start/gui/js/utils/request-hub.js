// ===============================================================================
// RequestHub - Система запросов с таймаутами и Promise API
// Версия: 1.0.0
// ===============================================================================

class RequestHub {
    constructor() {
        this.pendingRequests = new Map();
        this.requestIdCounter = 0;
        this.defaultTimeout = 3000; // 3 секунды
        this.stats = {
            total: 0,
            success: 0,
            timeout: 0,
            error: 0
        };
        
        // Хранение последнего запроса для отладки
        this.lastRequest = null;
        
        // Подписываемся на ответы от AutoIt через engine
        this.initResponseHandler();
    }
    
    // ===============================================================================
    // Инициализация обработчика ответов
    // ===============================================================================
    initResponseHandler() {
        // Регистрируем обработчик для всех ответов от AutoIt
        if (window.WebView2Engine) {
            WebView2Engine.on('response', (data) => {
                this.handleResponse(data);
            });
        } else {
            console.error('❌ WebView2Engine не найден!');
        }
    }
    
    // ===============================================================================
    // Отправка запроса (возвращает Promise)
    // ===============================================================================
    send(type, payload = null, timeout = this.defaultTimeout) {
        return new Promise((resolve, reject) => {
            // Генерируем уникальный ID запроса
            const requestId = ++this.requestIdCounter;
            
            // Создаём таймер
            const timeoutId = setTimeout(() => {
                this.handleTimeout(requestId);
                reject(new Error(`Timeout: AutoIt не ответил за ${timeout}ms`));
            }, timeout);
            
            // Сохраняем запрос
            this.pendingRequests.set(requestId, {
                type: type,
                payload: payload,
                resolve: resolve,
                reject: reject,
                timeoutId: timeoutId,
                timestamp: Date.now()
            });
            
            // ВАЖНО: WebView2Engine.sendToAutoIt(type, data) формирует:
            // { type: type, payload: data, windowId: X, timestamp: Y }
            // Поэтому передаём данные плоско, они попадут в payload
            const requestData = {
                requestId: requestId,
                requestType: type,       // Тип запроса (test_request, get_app_info и т.д.)
                requestPayload: payload  // Данные запроса
            };
            
            // Сохраняем последний запрос для отладки
            this.lastRequest = {
                requestId: requestId,
                type: type,
                payload: payload,
                timestamp: Date.now(),
                timestampFormatted: new Date().toLocaleString('ru-RU'),
                status: 'pending',
                response: null,
                error: null
            };
            
            if (window.WebView2Engine && window.WebView2Engine.isReady) {
                // Отправляем с типом "response" чтобы попасть в зарегистрированный обработчик
                // engine.js обернёт это в { type: 'response', payload: requestData, ... }
                window.WebView2Engine.sendToAutoIt('response', requestData);
                this.stats.total++;
            } else {
                clearTimeout(timeoutId);
                this.pendingRequests.delete(requestId);
                this.lastRequest.status = 'error';
                this.lastRequest.error = 'WebView2Engine не готов';
                reject(new Error('WebView2Engine не готов'));
            }
        });
    }
    
    // ===============================================================================
    // Надёжная отправка запроса (5 копий параллельно + retry до 3 раз)
    // ===============================================================================
    async sendReliable(type, payload = null, options = {}) {
        const copies = options.copies || 5;           // 5 копий по умолчанию
        const timeout = options.timeout || 300;       // 300мс таймаут
        const maxRetries = options.maxRetries || 3;   // До 3 переотправок
        const retryDelay = options.retryDelay || 50;  // 50мс между переотправками
        
        let attempt = 0;
        let lastError = null;
        
        // Пытаемся до maxRetries раз
        while (attempt < maxRetries) {
            attempt++;
            
            try {
                // Отправляем 5 копий одновременно
                const copyPromises = Array.from({ length: copies }, (_, copyIndex) => {
                    return this.send(type, payload, timeout)
                        .then(response => ({
                            status: 'success',
                            copyIndex: copyIndex + 1,
                            response
                        }))
                        .catch(error => ({
                            status: 'failed',
                            copyIndex: copyIndex + 1,
                            error: error.message
                        }));
                });
                
                // Ждём первую успешную копию (не дожидаясь остальных!)
                const result = await new Promise((resolve, reject) => {
                    let completed = 0;
                    let hasSuccess = false;
                    
                    copyPromises.forEach((copyPromise) => {
                        copyPromise.then(copyResult => {
                            // Если это первая успешная - сразу резолвим
                            if (copyResult.status === 'success' && !hasSuccess) {
                                hasSuccess = true;
                                resolve({
                                    success: true,
                                    response: copyResult.response,
                                    copyIndex: copyResult.copyIndex,
                                    attempt: attempt
                                });
                            }
                            
                            completed++;
                            
                            // Если все завершились и нет успешных - reject
                            if (completed === copies && !hasSuccess) {
                                reject({
                                    success: false,
                                    attempt: attempt,
                                    message: `All ${copies} copies failed`
                                });
                            }
                        });
                    });
                });
                
                // Успех! Возвращаем результат
                return result.response;
                
            } catch (error) {
                lastError = error;
                
                // Если не последняя попытка - ждём и пробуем снова
                if (attempt < maxRetries) {
                    console.warn(`⚠️ [RequestHub.sendReliable] Попытка ${attempt}/${maxRetries} провалилась, переотправка через ${retryDelay}мс...`);
                    await new Promise(resolve => setTimeout(resolve, retryDelay));
                }
            }
        }
        
        // Все попытки провалились
        console.error(`❌ [RequestHub.sendReliable] Все ${maxRetries} попытки провалились`);
        throw new Error(`Reliable request failed after ${maxRetries} attempts: ${lastError.message}`);
    }
    
    // ===============================================================================
    // Обработка ответа от AutoIt
    // ===============================================================================
    handleResponse(data) {
        const requestId = data.requestId;
        
        if (!requestId) {
            console.error('⚠️ [RequestHub] Ответ без requestId:', data);
            return;
        }
        
        const request = this.pendingRequests.get(requestId);
        
        if (!request) {
            // Запрос не найден - возможно таймаут уже сработал
            return;
        }
        
        // Очищаем таймер
        clearTimeout(request.timeoutId);
        
        // Удаляем из очереди
        this.pendingRequests.delete(requestId);
        
        // Обновляем последний запрос если это он
        if (this.lastRequest && this.lastRequest.requestId === requestId) {
            this.lastRequest.status = (data.status === 'success' || data.success === true) ? 'success' : 'error';
            this.lastRequest.response = data.payload || data;
            this.lastRequest.responseTime = Date.now() - this.lastRequest.timestamp;
        }
        
        // Проверяем статус ответа
        if (data.status === 'success' || data.success === true) {
            this.stats.success++;
            request.resolve(data.payload || data);
        } else {
            this.stats.error++;
            request.reject(new Error(data.error || data.message || 'Unknown error'));
        }
    }
    
    // ===============================================================================
    // Обработка таймаута
    // ===============================================================================
    handleTimeout(requestId) {
        const request = this.pendingRequests.get(requestId);
        
        if (request) {
            this.pendingRequests.delete(requestId);
            this.stats.timeout++;
            
            // Обновляем последний запрос если это он
            if (this.lastRequest && this.lastRequest.requestId === requestId) {
                this.lastRequest.status = 'timeout';
                this.lastRequest.error = 'Request timeout';
                this.lastRequest.responseTime = Date.now() - this.lastRequest.timestamp;
            }
            
            // Детальное логирование таймаутов для диагностики
            console.error(`⏱️ [RequestHub] TIMEOUT #${requestId}:`, {
                type: request.type,
                age: Date.now() - request.timestamp,
                pendingCount: this.pendingRequests.size
            });
        }
    }
    
    // ===============================================================================
    // Отмена запроса
    // ===============================================================================
    cancel(requestId) {
        const request = this.pendingRequests.get(requestId);
        
        if (request) {
            clearTimeout(request.timeoutId);
            this.pendingRequests.delete(requestId);
            request.reject(new Error('Request cancelled'));
            return true;
        }
        
        return false;
    }
    
    // ===============================================================================
    // Отмена всех запросов
    // ===============================================================================
    cancelAll() {
        const count = this.pendingRequests.size;
        
        this.pendingRequests.forEach((request, requestId) => {
            clearTimeout(request.timeoutId);
            request.reject(new Error('All requests cancelled'));
        });
        
        this.pendingRequests.clear();
        
        return count;
    }
    
    // ===============================================================================
    // Получение статистики
    // ===============================================================================
    getStats() {
        return {
            ...this.stats,
            pending: this.pendingRequests.size,
            successRate: this.stats.total > 0 
                ? ((this.stats.success / this.stats.total) * 100).toFixed(2) + '%'
                : '0%'
        };
    }
    
    // ===============================================================================
    // Сброс статистики
    // ===============================================================================
    resetStats() {
        this.stats = {
            total: 0,
            success: 0,
            timeout: 0,
            error: 0
        };
    }
    
    // ===============================================================================
    // Получение информации о последнем запросе
    // ===============================================================================
    getLastRequest() {
        if (!this.lastRequest) {
            return {
                message: 'Запросов ещё не было'
            };
        }
        
        return {
            requestId: this.lastRequest.requestId,
            type: this.lastRequest.type,
            status: this.lastRequest.status,
            timestamp: this.lastRequest.timestampFormatted,
            responseTime: this.lastRequest.responseTime ? `${this.lastRequest.responseTime}ms` : 'N/A',
            request: {
                type: this.lastRequest.type,
                payload: this.lastRequest.payload
            },
            response: this.lastRequest.response,
            error: this.lastRequest.error
        };
    }
    
    // ===============================================================================
    // Получение списка ожидающих запросов
    // ===============================================================================
    getPendingRequests() {
        const pending = [];
        
        this.pendingRequests.forEach((request, requestId) => {
            pending.push({
                id: requestId,
                type: request.type,
                age: Date.now() - request.timestamp
            });
        });
        
        return pending;
    }
}

// ===============================================================================
// Создание глобального экземпляра
// ===============================================================================
window.RequestHub = new RequestHub();
