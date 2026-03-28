// ===============================================================================
// page2-component.js - Страница аналитики (Tabler)
// ===============================================================================

class Page2Component extends HTMLElement {
    connectedCallback() {
        this.innerHTML = /* html */`
            <div class="page-header d-print-none">
                <div class="container-xl">
                    <div class="row g-2 align-items-center">
                        <div class="col">
                            <div class="page-pretitle">Данные</div>
                            <h2 class="page-title">Аналитика системы</h2>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="page-body">
                <div class="container-xl">
                    <!-- Статистика -->
                    <div class="row row-cards">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">Статистика за период</h3>
                                </div>
                                <div class="card-body">
                                    <div class="row g-3 stats-grid">
                                        <div class="col-sm-6 col-lg-3">
                                            <div class="stats-item">
                                                <div class="stats-label">Всего операций</div>
                                                <div class="stats-value text-primary">1,234</div>
                                            </div>
                                        </div>
                                        <div class="col-sm-6 col-lg-3">
                                            <div class="stats-item">
                                                <div class="stats-label">Успешность</div>
                                                <div class="stats-value">
                                                    <span class="badge bg-success text-white fs-3">98.5%</span>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-sm-6 col-lg-3">
                                            <div class="stats-item">
                                                <div class="stats-label">Предупреждений</div>
                                                <div class="stats-value">
                                                    <span class="badge bg-warning text-white fs-3">12</span>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-sm-6 col-lg-3">
                                            <div class="stats-item">
                                                <div class="stats-label">Среднее время</div>
                                                <div class="stats-value text-info">2.3s</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Производительность -->
                    <div class="row row-cards mt-3">
                        <div class="col-lg-6">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">Производительность</h3>
                                </div>
                                <div class="card-body">
                                    <div class="mb-3">
                                        <div class="d-flex mb-2">
                                            <div>Использовано памяти</div>
                                            <div class="ms-auto">256 MB / 512 MB</div>
                                        </div>
                                        <div class="progress">
                                            <div class="progress-bar" style="width: 50%" role="progressbar"></div>
                                        </div>
                                    </div>
                                    <div class="mb-3">
                                        <div class="d-flex mb-2">
                                            <div>CPU</div>
                                            <div class="ms-auto">23%</div>
                                        </div>
                                        <div class="progress">
                                            <div class="progress-bar bg-yellow" style="width: 23%" role="progressbar"></div>
                                        </div>
                                    </div>
                                    <div class="mb-3">
                                        <div class="d-flex mb-2">
                                            <div>Сеть</div>
                                            <div class="ms-auto">1.2 MB/s</div>
                                        </div>
                                        <div class="progress">
                                            <div class="progress-bar bg-green" style="width: 35%" role="progressbar"></div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-lg-6">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">Активность</h3>
                                </div>
                                <div class="list-group list-group-flush">
                                    <div class="list-group-item">
                                        <div class="row align-items-center">
                                            <div class="col-auto">
                                                <span class="status-dot bg-success d-block"></span>
                                            </div>
                                            <div class="col text-truncate">
                                                <div class="text-body">Система работает нормально</div>
                                                <div class="text-muted text-truncate mt-n1">Все сервисы активны</div>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="list-group-item">
                                        <div class="row align-items-center">
                                            <div class="col-auto">
                                                <span class="status-dot bg-warning d-block"></span>
                                            </div>
                                            <div class="col text-truncate">
                                                <div class="text-body">Высокая нагрузка</div>
                                                <div class="text-muted text-truncate mt-n1">Датчик #3 превысил порог</div>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="list-group-item">
                                        <div class="row align-items-center">
                                            <div class="col-auto">
                                                <span class="status-dot bg-info d-block"></span>
                                            </div>
                                            <div class="col text-truncate">
                                                <div class="text-body">Обновление доступно</div>
                                                <div class="text-muted text-truncate mt-n1">Версия 2.1.0</div>
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
        
        console.log('Page2: Аналитика загружена');
    }
}

customElements.define('page-analytics', Page2Component);
