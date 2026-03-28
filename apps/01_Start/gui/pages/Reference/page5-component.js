// ===============================================================================
// page5-component.js - Страница Галерея карточек (тестовая)
// ===============================================================================

class PageGallery extends HTMLElement {
    connectedCallback() {
        this.render();
        this.initResizableColumns();
        console.log('Page5: Галерея карточек загружена');
    }
    
    initResizableColumns() {
        const table = this.querySelector('.table-fixed-width');
        if (!table) return;
        
        const headers = table.querySelectorAll('th');
        const storageKey = 'table-column-widths';
        
        // Загружаем сохранённые ширины из localStorage
        const savedWidths = JSON.parse(localStorage.getItem(storageKey) || '{}');
        
        headers.forEach((header, index) => {
            // Применяем сохранённую ширину
            if (savedWidths[index]) {
                header.style.width = savedWidths[index] + 'px';
            }
            
            let startX, startWidth;
            
            const onMouseDown = (e) => {
                // Проверяем, что клик в правой части заголовка (зона resize)
                const rect = header.getBoundingClientRect();
                if (e.clientX < rect.right - 10) return;
                
                startX = e.clientX;
                startWidth = header.offsetWidth;
                
                document.addEventListener('mousemove', onMouseMove);
                document.addEventListener('mouseup', onMouseUp);
                
                e.preventDefault();
            };
            
            const onMouseMove = (e) => {
                const width = startWidth + (e.clientX - startX);
                if (width > 50) { // Минимальная ширина 50px
                    header.style.width = width + 'px';
                }
            };
            
            const onMouseUp = () => {
                document.removeEventListener('mousemove', onMouseMove);
                document.removeEventListener('mouseup', onMouseUp);
                
                // Сохраняем ширины всех столбцов
                const widths = {};
                headers.forEach((h, i) => {
                    widths[i] = h.offsetWidth;
                });
                localStorage.setItem(storageKey, JSON.stringify(widths));
            };
            
            header.addEventListener('mousedown', onMouseDown);
        });
    }
    
    render() {
        this.innerHTML = /* html */`
            <div class="page-body">
                <div class="container-xl">
                    <div class="page-header d-print-none">
                        <div class="row g-2 align-items-center">
                            <div class="col">
                                <div class="page-pretitle">ДЕМОНСТРАЦИЯ</div>
                                <h2 class="page-title">Галерея карточек</h2>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="page-body">
                    <div class="container-xl">
                        <!-- Карточки с иконками -->
                        <div class="row row-deck row-cards mb-3">
                            <div class="col-sm-6 col-lg-3">
                                <div class="card card-sm">
                                    <div class="card-body">
                                        <div class="row align-items-center">
                                            <div class="col-auto">
                                                <span class="bg-primary text-white avatar">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                        <circle cx="12" cy="12" r="9" />
                                                        <line x1="12" y1="8" x2="12.01" y2="8" />
                                                        <polyline points="11 12 12 12 12 16 13 16" />
                                                    </svg>
                                                </span>
                                            </div>
                                            <div class="col">
                                                <div class="font-weight-medium">
                                                    132 Уведомлений
                                                </div>
                                                <div class="text-muted">
                                                    12 непрочитанных
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-3">
                                <div class="card card-sm">
                                    <div class="card-body">
                                        <div class="row align-items-center">
                                            <div class="col-auto">
                                                <span class="bg-green text-white avatar">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                        <path d="M5 12l5 5l10 -10" />
                                                    </svg>
                                                </span>
                                            </div>
                                            <div class="col">
                                                <div class="font-weight-medium">
                                                    98% Успешно
                                                </div>
                                                <div class="text-muted">
                                                    За последний час
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-3">
                                <div class="card card-sm">
                                    <div class="card-body">
                                        <div class="row align-items-center">
                                            <div class="col-auto">
                                                <span class="bg-twitter text-white avatar">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                        <rect x="4" y="13" rx="2" width="4" height="6" />
                                                        <rect x="16" y="13" rx="2" width="4" height="6" />
                                                        <path d="M4 15v-3a8 8 0 0 1 16 0v3" />
                                                    </svg>
                                                </span>
                                            </div>
                                            <div class="col">
                                                <div class="font-weight-medium">
                                                    43 Подключений
                                                </div>
                                                <div class="text-muted">
                                                    Активных сейчас
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-3">
                                <div class="card card-sm">
                                    <div class="card-body">
                                        <div class="row align-items-center">
                                            <div class="col-auto">
                                                <span class="bg-facebook text-white avatar">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                        <polyline points="12 3 20 7.5 20 16.5 12 21 4 16.5 4 7.5 12 3" />
                                                        <line x1="12" y1="12" x2="20" y2="7.5" />
                                                        <line x1="12" y1="12" x2="12" y2="21" />
                                                        <line x1="12" y1="12" x2="4" y2="7.5" />
                                                    </svg>
                                                </span>
                                            </div>
                                            <div class="col">
                                                <div class="font-weight-medium">
                                                    8 Модулей
                                                </div>
                                                <div class="text-muted">
                                                    Загружено
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Карточки с прогресс-барами -->
                        <div class="row row-deck row-cards mb-3">
                            <div class="col-12">
                                <div class="card">
                                    <div class="card-header">
                                        <h3 class="card-title">Использование ресурсов</h3>
                                    </div>
                                    <div class="card-body">
                                        <div class="mb-3">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span>Процессор</span>
                                                <span class="text-muted">45%</span>
                                            </div>
                                            <div class="progress">
                                                <div class="progress-bar bg-primary" style="width: 45%"></div>
                                            </div>
                                        </div>
                                        <div class="mb-3">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span>Память</span>
                                                <span class="text-muted">78%</span>
                                            </div>
                                            <div class="progress">
                                                <div class="progress-bar bg-yellow" style="width: 78%"></div>
                                            </div>
                                        </div>
                                        <div class="mb-3">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span>Диск</span>
                                                <span class="text-muted">62%</span>
                                            </div>
                                            <div class="progress">
                                                <div class="progress-bar bg-info" style="width: 62%"></div>
                                            </div>
                                        </div>
                                        <div>
                                            <div class="d-flex justify-content-between mb-1">
                                                <span>Сеть</span>
                                                <span class="text-muted">23%</span>
                                            </div>
                                            <div class="progress">
                                                <div class="progress-bar bg-success" style="width: 23%"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Карточки со статусами -->
                        <div class="row row-deck row-cards mb-3">
                            <div class="col-md-6 col-lg-4">
                                <div class="card">
                                    <div class="card-status-top bg-success"></div>
                                    <div class="card-body">
                                        <h3 class="card-title">Сервер #1</h3>
                                        <p class="text-muted">Работает нормально</p>
                                        <div class="d-flex align-items-center">
                                            <span class="badge bg-success-lt me-2">Онлайн</span>
                                            <span class="text-muted">Uptime: 45 дней</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6 col-lg-4">
                                <div class="card">
                                    <div class="card-status-top bg-warning"></div>
                                    <div class="card-body">
                                        <h3 class="card-title">Сервер #2</h3>
                                        <p class="text-muted">Высокая нагрузка</p>
                                        <div class="d-flex align-items-center">
                                            <span class="badge bg-warning-lt me-2">Предупреждение</span>
                                            <span class="text-muted">CPU: 89%</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6 col-lg-4">
                                <div class="card">
                                    <div class="card-status-top bg-danger"></div>
                                    <div class="card-body">
                                        <h3 class="card-title">Сервер #3</h3>
                                        <p class="text-muted">Недоступен</p>
                                        <div class="d-flex align-items-center">
                                            <span class="badge bg-danger-lt me-2">Офлайн</span>
                                            <span class="text-muted">Ошибка подключения</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Карточки с таблицами -->
                        <div class="row row-deck row-cards mb-3">
                            <div class="col-12">
                                <div class="card">
                                    <div class="card-header">
                                        <h3 class="card-title">Последние события - Демонстрация стилей</h3>
                                    </div>
                                    <div class="table-responsive">
                                        <table class="table table-vcenter card-table table-events">
                                            <thead>
                                                <tr>
                                                    <th>Время</th>
                                                    <th>Событие</th>
                                                    <th>Статус</th>
                                                    <th>Пользователь</th>
                                                    <th>Приоритет</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td class="text-muted"><strong>14:32</strong></td>
                                                    <td><span class="text-success fw-bold">Запуск системы</span></td>
                                                    <td><span class="badge bg-success">Успешно</span></td>
                                                    <td><code>admin</code></td>
                                                    <td><span class="badge bg-blue-lt">Высокий</span></td>
                                                </tr>
                                                <tr>
                                                    <td class="text-muted">14:28</td>
                                                    <td><em>Обновление конфигурации</em></td>
                                                    <td><span class="badge bg-info">Выполнено</span></td>
                                                    <td><span class="text-primary">operator1</span></td>
                                                    <td><span class="badge bg-green-lt">Средний</span></td>
                                                </tr>
                                                <tr class="table-warning">
                                                    <td class="text-muted">14:15</td>
                                                    <td><strong>Ошибка подключения</strong></td>
                                                    <td><span class="badge bg-warning">Предупреждение</span></td>
                                                    <td><small class="text-muted">system</small></td>
                                                    <td><span class="badge bg-yellow-lt">Средний</span></td>
                                                </tr>
                                                <tr>
                                                    <td class="text-muted">14:02</td>
                                                    <td>Резервное копирование</td>
                                                    <td><span class="badge bg-success">Успешно</span></td>
                                                    <td><span class="badge bg-secondary-lt">backup_service</span></td>
                                                    <td><span class="badge bg-gray-lt">Низкий</span></td>
                                                </tr>
                                                <tr class="table-danger">
                                                    <td class="text-muted"><strong>13:45</strong></td>
                                                    <td><span class="text-danger fw-bold">Критическая ошибка</span></td>
                                                    <td><span class="badge bg-danger">Ошибка</span></td>
                                                    <td><code class="text-danger">system</code></td>
                                                    <td><span class="badge bg-red-lt">Критический</span></td>
                                                </tr>
                                                <tr>
                                                    <td class="text-muted">13:30</td>
                                                    <td><span class="text-info">Синхронизация данных</span></td>
                                                    <td><span class="badge bg-cyan">В процессе</span></td>
                                                    <td><span class="text-info fw-semibold">sync_service</span></td>
                                                    <td><span class="badge bg-cyan-lt">Средний</span></td>
                                                </tr>
                                                <tr class="table-info">
                                                    <td class="text-muted">13:15</td>
                                                    <td><u>Проверка безопасности</u></td>
                                                    <td><span class="badge bg-primary">Запланировано</span></td>
                                                    <td><span class="badge bg-primary-lt">security_bot</span></td>
                                                    <td><span class="badge bg-blue-lt">Высокий</span></td>
                                                </tr>
                                                <tr>
                                                    <td class="text-muted">13:00</td>
                                                    <td><span class="text-secondary">Очистка кэша</span></td>
                                                    <td><span class="badge bg-secondary">Завершено</span></td>
                                                    <td><small>maintenance</small></td>
                                                    <td><span class="badge bg-gray-lt">Низкий</span></td>
                                                </tr>
                                                <tr class="table-success">
                                                    <td class="text-muted"><strong>12:45</strong></td>
                                                    <td><span class="text-success">Тестирование модулей</span></td>
                                                    <td><span class="badge bg-teal">Пройдено</span></td>
                                                    <td><code class="text-success">test_runner</code></td>
                                                    <td><span class="badge bg-teal-lt">Средний</span></td>
                                                </tr>
                                                <tr>
                                                    <td class="text-muted">12:30</td>
                                                    <td><span class="text-dark fw-semibold">Мониторинг производительности</span></td>
                                                    <td><span class="badge bg-purple">Активно</span></td>
                                                    <td><span class="text-purple fw-bold">monitor_agent</span></td>
                                                    <td><span class="badge bg-purple-lt">Высокий</span></td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Таблица с вертикальными разделителями и фиксированной шириной -->
                        <div class="row row-deck row-cards mb-3">
                            <div class="col-12">
                                <div class="card">
                                    <div class="card-header">
                                        <h3 class="card-title">Системные модули - Структурированная таблица</h3>
                                    </div>
                                    <div class="table-responsive">
                                        <table class="table table-vcenter table-bordered table-hover table-fixed-width">
                                            <thead>
                                                <tr>
                                                    <th class="w-icon">Иконка</th>
                                                    <th class="w-name">Название модуля</th>
                                                    <th class="w-status">Статус</th>
                                                    <th class="w-version">Версия</th>
                                                    <th class="w-load">Нагрузка</th>
                                                    <th class="w-actions">Действия</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td class="text-center">
                                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon text-blue" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                            <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                            <rect x="4" y="4" width="6" height="6" rx="1" />
                                                            <rect x="14" y="4" width="6" height="6" rx="1" />
                                                            <rect x="4" y="14" width="6" height="6" rx="1" />
                                                            <rect x="14" y="14" width="6" height="6" rx="1" />
                                                        </svg>
                                                    </td>
                                                    <td><strong>Core Engine</strong></td>
                                                    <td><span class="badge bg-success w-100">Активен</span></td>
                                                    <td class="text-center"><code>v2.1.0</code></td>
                                                    <td class="text-center"><span class="text-success">12%</span></td>
                                                    <td class="text-center">
                                                        <button class="btn btn-sm btn-primary">Настроить</button>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="text-center">
                                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon text-green" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                            <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                            <circle cx="12" cy="12" r="9" />
                                                            <line x1="3.6" y1="9" x2="20.4" y2="9" />
                                                            <line x1="3.6" y1="15" x2="20.4" y2="15" />
                                                            <path d="M11.5 3a17 17 0 0 0 0 18" />
                                                            <path d="M12.5 3a17 17 0 0 1 0 18" />
                                                        </svg>
                                                    </td>
                                                    <td><strong>Network Module</strong></td>
                                                    <td><span class="badge bg-success w-100">Активен</span></td>
                                                    <td class="text-center"><code>v1.8.5</code></td>
                                                    <td class="text-center"><span class="text-info">8%</span></td>
                                                    <td class="text-center">
                                                        <button class="btn btn-sm btn-primary">Настроить</button>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="text-center">
                                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon text-yellow" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                            <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                            <path d="M4 7a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12z" />
                                                            <path d="M8 3v4" />
                                                            <path d="M16 3v4" />
                                                            <path d="M4 11h16" />
                                                        </svg>
                                                    </td>
                                                    <td><strong>Scheduler</strong></td>
                                                    <td><span class="badge bg-warning w-100">Ожидание</span></td>
                                                    <td class="text-center"><code>v3.0.2</code></td>
                                                    <td class="text-center"><span class="text-warning">45%</span></td>
                                                    <td class="text-center">
                                                        <button class="btn btn-sm btn-warning">Проверить</button>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="text-center">
                                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon text-purple" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                            <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                            <rect x="3" y="5" width="18" height="14" rx="2" />
                                                            <polyline points="3 7 12 13 21 7" />
                                                        </svg>
                                                    </td>
                                                    <td><strong>Message Queue</strong></td>
                                                    <td><span class="badge bg-info w-100">Работает</span></td>
                                                    <td class="text-center"><code>v1.5.0</code></td>
                                                    <td class="text-center"><span class="text-primary">23%</span></td>
                                                    <td class="text-center">
                                                        <button class="btn btn-sm btn-info">Мониторинг</button>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="text-center">
                                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon text-red" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                            <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                            <path d="M12 3c7.2 0 9 1.8 9 9s-1.8 9 -9 9s-9 -1.8 -9 -9s1.8 -9 9 -9z" />
                                                            <path d="M10 10l4 4m0 -4l-4 4" />
                                                        </svg>
                                                    </td>
                                                    <td><strong>Security Guard</strong></td>
                                                    <td><span class="badge bg-danger w-100">Ошибка</span></td>
                                                    <td class="text-center"><code>v2.3.1</code></td>
                                                    <td class="text-center"><span class="text-danger">0%</span></td>
                                                    <td class="text-center">
                                                        <button class="btn btn-sm btn-danger">Перезапуск</button>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Карточки с формами -->
                        <div class="row row-deck row-cards">
                            <div class="col-md-6">
                                <div class="card">
                                    <div class="card-header">
                                        <h3 class="card-title">Быстрые настройки</h3>
                                    </div>
                                    <div class="card-body">
                                        <div class="mb-3">
                                            <label class="form-label">Режим работы</label>
                                            <select class="form-select">
                                                <option>Автоматический</option>
                                                <option>Ручной</option>
                                                <option>Тестовый</option>
                                            </select>
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
                                                <span class="form-check-label">Отладочный режим</span>
                                            </label>
                                        </div>
                                        <div class="mb-3">
                                            <label class="form-check form-switch">
                                                <input class="form-check-input" type="checkbox" checked>
                                                <span class="form-check-label">Уведомления</span>
                                            </label>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="card card-system-info">
                                    <div class="card-header bg-primary-lt">
                                        <h3 class="card-title">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler me-2" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                <circle cx="12" cy="12" r="9" />
                                                <line x1="12" y1="8" x2="12.01" y2="8" />
                                                <polyline points="11 12 12 12 12 16 13 16" />
                                            </svg>
                                            Информация о системе
                                        </h3>
                                    </div>
                                    <div class="card-body">
                                        <div class="row g-3">
                                            <div class="col-6">
                                                <div class="system-info-item">
                                                    <div class="system-info-label">Версия</div>
                                                    <div class="system-info-value">
                                                        <span class="badge bg-blue text-white fs-4">1.2.5</span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-6">
                                                <div class="system-info-item">
                                                    <div class="system-info-label">Платформа</div>
                                                    <div class="system-info-value">
                                                        <strong class="fs-3">Windows 10</strong>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-6">
                                                <div class="system-info-item">
                                                    <div class="system-info-label">Архитектура</div>
                                                    <div class="system-info-value">
                                                        <strong class="fs-3">x64</strong>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-6">
                                                <div class="system-info-item">
                                                    <div class="system-info-label">Время работы</div>
                                                    <div class="system-info-value">
                                                        <span class="text-success fs-3 fw-bold">45д 12ч 34м</span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-12">
                                                <div class="system-info-item text-center">
                                                    <div class="system-info-label">Последнее обновление</div>
                                                    <div class="system-info-value">
                                                        <strong class="fs-3">01.03.2026</strong>
                                                    </div>
                                                </div>
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
    }
}

customElements.define('page-gallery', PageGallery);
