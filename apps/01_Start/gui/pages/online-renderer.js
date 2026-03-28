// ===============================================================================
// Online Renderer - Рендеринг HTML структуры
// ===============================================================================

class OnlineRenderer {
    // Рендеринг главной структуры страницы
    renderPage() {
        return `
            <div class="page-header d-print-none">
                <div class="container-xl">
                    <div class="row g-2 align-items-center">
                        <div class="col">
                            <div class="page-pretitle">Мониторинг</div>
                            <h2 class="page-title">Онлайн</h2>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="page-body">
                <div class="container-xl">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Мониторинг счётчиков</h3>
                            <div class="card-actions">
                                <button id="btn-refresh-all" class="btn btn-primary btn-sm">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                        <path d="M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4" />
                                        <path d="M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4" />
                                    </svg>
                                    Обновить всё
                                </button>
                            </div>
                        </div>
                        <div class="card-body">
                            ${this.renderCountersGrid()}
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    // Рендеринг сетки счётчиков
    renderCountersGrid() {
        return `
            <div class="counters-grid">
                <!-- Заголовок -->
                <div class="grid-header">
                    <div class="grid-cell">№</div>
                    <div class="grid-cell">Название</div>
                    <div class="grid-cell">Статус данных</div>
                    <div class="grid-cell">Работа счётчика</div>
                    <div class="grid-cell">Последние данные</div>
                    <div class="grid-cell">Управление</div>
                </div>
                
                <!-- Строки счётчиков -->
                ${this.renderCounterRows()}
            </div>
            
            <!-- Отладочный блок для массивов данных -->
            <div id="debug-data" style="margin-top: 20px; padding: 20px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;">
                <h4 style="margin-bottom: 16px; color: #1e293b;">🔍 Отладка: Массивы данных счётчиков</h4>
                <div id="debug-arrays" style="font-family: monospace; font-size: 0.85rem; white-space: pre-wrap; color: #334155;"></div>
            </div>
        `;
    }

    // Рендеринг строк счётчиков
    renderCounterRows() {
        let html = '';
        for (let i = 1; i <= 7; i++) {
            html += this.renderCounterRow(i);
        }
        return html;
    }

    // Рендеринг одной строки счётчика
    renderCounterRow(counterId) {
        return `
            <div class="grid-row" data-counter-id="${counterId}">
                <div class="grid-cell cell-num">${counterId}</div>
                <div class="grid-cell cell-name">
                    <div class="counter-name" id="name-${counterId}">Counter ${counterId}</div>
                    <div class="counter-type" id="type-${counterId}">—</div>
                </div>
                <div class="grid-cell cell-status">
                    <span class="status-badge" id="status-${counterId}">⚪ Загрузка...</span>
                </div>
                <div class="grid-cell cell-working">
                    <div class="working-status" id="working-${counterId}">
                        <span class="working-badge">❌ Нет данных</span>
                        <div class="working-flow">—</div>
                    </div>
                </div>
                <div class="grid-cell cell-time">
                    <span id="time-${counterId}">—</span>
                </div>
                <div class="grid-cell cell-buttons">
                    <button class="btn-mini btn-parsing" data-counter-id="${counterId}" disabled>
                        <span class="btn-spinner"></span>
                    </button>
                    <button class="btn-mini btn-window" data-counter-id="${counterId}" disabled>
                        <span class="btn-spinner"></span>
                    </button>
                </div>
            </div>
        `;
    }
}
