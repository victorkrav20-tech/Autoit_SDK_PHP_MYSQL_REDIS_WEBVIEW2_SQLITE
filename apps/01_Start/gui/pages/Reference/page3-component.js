// ===============================================================================
// page3-component.js - Страница настроек (Tabler)
// ===============================================================================

class Page3Component extends HTMLElement {
    connectedCallback() {
        this.innerHTML = /* html */`
            <div class="page-header d-print-none">
                <div class="container-xl">
                    <div class="row g-2 align-items-center">
                        <div class="col">
                            <div class="page-pretitle">Конфигурация</div>
                            <h2 class="page-title">Настройки системы</h2>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="page-body">
                <div class="container-xl">
                    <div class="row row-cards">
                        <!-- Основные настройки -->
                        <div class="col-lg-6">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">Основные параметры</h3>
                                </div>
                                <div class="card-body">
                                    <div class="mb-3">
                                        <label class="form-label">Режим работы</label>
                                        <select class="form-select">
                                            <option value="auto" selected>Автоматический</option>
                                            <option value="manual">Ручной</option>
                                            <option value="debug">Отладка</option>
                                        </select>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Интервал обновления (мс)</label>
                                        <input type="number" class="form-control" value="500">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label">Порог предупреждения</label>
                                        <input type="number" class="form-control" value="150">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-check form-switch">
                                            <input class="form-check-input" type="checkbox" checked>
                                            <span class="form-check-label">Автосохранение</span>
                                        </label>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-check form-switch">
                                            <input class="form-check-input" type="checkbox">
                                            <span class="form-check-label">Режим отладки</span>
                                        </label>
                                    </div>
                                </div>
                                <div class="card-footer">
                                    <div class="btn-list">
                                        <button class="btn btn-primary">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 4h10l4 4v10a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2" /><circle cx="12" cy="14" r="2" /><polyline points="14 4 14 8 8 8 8 4" /></svg>
                                            Сохранить
                                        </button>
                                        <button class="btn">
                                            Сбросить
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Параметры подключения -->
                        <div class="col-lg-6">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">Параметры подключения</h3>
                                </div>
                                <div class="card-body">
                                    <div class="datagrid">
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <circle cx="12" cy="12" r="9" />
                                                    <line x1="3.6" y1="9" x2="20.4" y2="9" />
                                                    <line x1="3.6" y1="15" x2="20.4" y2="15" />
                                                    <path d="M11.5 3a17 17 0 0 0 0 18" />
                                                    <path d="M12.5 3a17 17 0 0 1 0 18" />
                                                </svg>
                                                IP адрес
                                            </div>
                                            <div class="datagrid-content">
                                                <span class="badge bg-blue-lt">localhost</span>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <circle cx="12" cy="13" r="2" />
                                                    <line x1="13.45" y1="11.55" x2="15.5" y2="9.5" />
                                                    <path d="M6.4 20a9 9 0 1 1 11.2 0z" />
                                                </svg>
                                                Порт
                                            </div>
                                            <div class="datagrid-content">
                                                <strong>8080</strong>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <circle cx="12" cy="12" r="9" />
                                                    <polyline points="12 7 12 12 15 15" />
                                                </svg>
                                                Таймаут
                                            </div>
                                            <div class="datagrid-content">
                                                <strong>5s</strong>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <path d="M4.05 11a8 8 0 1 1 .5 4m-.5 5v-5h5" />
                                                </svg>
                                                Повторы
                                            </div>
                                            <div class="datagrid-content">
                                                <strong>3</strong>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" />
                                                    <path d="M9 12l2 2l4 -4" />
                                                </svg>
                                                Статус
                                            </div>
                                            <div class="datagrid-content">
                                                <span class="status status-success">
                                                    <span class="status-dot"></span>
                                                    Подключено
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Информация о системе -->
                            <div class="card mt-3">
                                <div class="card-header">
                                    <h3 class="card-title">Информация о системе</h3>
                                </div>
                                <div class="card-body">
                                    <div class="datagrid">
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" />
                                                    <rect x="9" y="3" width="6" height="4" rx="2" />
                                                    <line x1="9" y1="12" x2="9.01" y2="12" />
                                                    <line x1="13" y1="12" x2="15" y2="12" />
                                                    <line x1="9" y1="16" x2="9.01" y2="16" />
                                                    <line x1="13" y1="16" x2="15" y2="16" />
                                                </svg>
                                                Версия
                                            </div>
                                            <div class="datagrid-content">
                                                <span class="badge bg-blue-lt">1.2.5</span>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <rect x="3" y="5" width="18" height="14" rx="2" />
                                                    <line x1="7" y1="15" x2="7" y2="15.01" />
                                                    <line x1="11" y1="15" x2="11" y2="15.01" />
                                                    <line x1="15" y1="15" x2="15" y2="15.01" />
                                                    <line x1="17" y1="15" x2="17" y2="15.01" />
                                                </svg>
                                                Платформа
                                            </div>
                                            <div class="datagrid-content">
                                                <strong>Windows 10</strong>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <rect x="4" y="4" width="6" height="6" rx="1" />
                                                    <rect x="14" y="4" width="6" height="6" rx="1" />
                                                    <rect x="4" y="14" width="6" height="6" rx="1" />
                                                    <rect x="14" y="14" width="6" height="6" rx="1" />
                                                </svg>
                                                Архитектура
                                            </div>
                                            <div class="datagrid-content">
                                                <strong>x64</strong>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <circle cx="12" cy="12" r="9" />
                                                    <polyline points="12 7 12 12 15 15" />
                                                </svg>
                                                Время работы
                                            </div>
                                            <div class="datagrid-content">
                                                <span class="text-primary">45д 12ч 34м</span>
                                            </div>
                                        </div>
                                        <div class="datagrid-item">
                                            <div class="datagrid-title">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-1" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <rect x="4" y="5" width="16" height="16" rx="2" />
                                                    <line x1="16" y1="3" x2="16" y2="7" />
                                                    <line x1="8" y1="3" x2="8" y2="7" />
                                                    <line x1="4" y1="11" x2="20" y2="11" />
                                                    <line x1="10" y1="16" x2="14" y2="16" />
                                                </svg>
                                                Последнее обновление
                                            </div>
                                            <div class="datagrid-content">
                                                <strong>01.03.2026</strong>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        console.log('Page3: Настройки загружены');
    }
}

customElements.define('page-settings', Page3Component);
