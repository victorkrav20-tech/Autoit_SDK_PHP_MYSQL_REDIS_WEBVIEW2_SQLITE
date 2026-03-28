// ===============================================================================
// test12.js - Тесты пушинга с подтверждением получения
// ===============================================================================

// Лог для отображения событий
function addToLog(message) {
    const log = document.getElementById('push_log');
    const entry = document.createElement('div');
    entry.textContent = `[${new Date().toLocaleTimeString()}] ${message}`;
    log.appendChild(entry);
    
    // Автоскролл вниз
    log.scrollTop = log.scrollHeight;
    
    console.log(message);
}

// Обработчик подтверждений пушинга (отправляем обратно в AutoIt)
WebView2Engine.on('push_confirmed', function(data) {
    // Этот обработчик уже зарегистрирован в engine.js
    // Здесь мы просто логируем
    addToLog(`✅ Push confirmed: ${data.type}`);
});

// Наблюдатель за изменениями DOM (MutationObserver)
const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
        if (mutation.type === 'childList' || mutation.type === 'characterData') {
            const target = mutation.target;
            const elementId = target.id || target.parentElement?.id;
            
            if (elementId && elementId !== 'push_log') {
                addToLog(`🔄 DOM changed: ${elementId}`);
            }
        }
        
        if (mutation.type === 'attributes') {
            const target = mutation.target;
            const elementId = target.id;
            const attrName = mutation.attributeName;
            
            if (elementId && elementId !== 'push_log') {
                addToLog(`🎨 Attribute changed: ${elementId}.${attrName}`);
            }
        }
    });
});

// Запускаем наблюдатель после загрузки DOM
document.addEventListener('DOMContentLoaded', function() {
    // Наблюдаем за всеми элементами с value-display
    const elements = document.querySelectorAll('.value-display');
    elements.forEach(function(element) {
        observer.observe(element, {
            childList: true,
            characterData: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['class', 'style']
        });
    });
    
    addToLog('📦 MutationObserver started');
    addToLog('✅ Ready for push events');
});

// Тестовая функция для вызова из AutoIt
function testFunction(param1, param2) {
    addToLog(`🎯 testFunction called: ${param1}, ${param2}`);
    console.log('testFunction executed with params:', param1, param2);
}

console.log('test12.js loaded');
