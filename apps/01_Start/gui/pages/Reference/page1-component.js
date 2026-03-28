// ===============================================================================
// page1-component.js - Страница мониторинга (Tabler)
// ===============================================================================

class Page1Component extends HTMLElement {
    connectedCallback() {
        this.innerHTML = /* html */`
            <div class="page-header d-print-none">
                <div class="container-xl">
                    <div class="row g-2 align-items-center">
                        <div class="col">
                            <div class="page-pretitle">Обзор</div>
                            <h2 class="page-title">Мониторинг системы</h2>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="page-body">
                <div class="container-xl">
                    <!-- Карточки статистики -->
                    <div class="row row-deck row-cards">
                        <div class="col-sm-6 col-lg-3">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="subheader">Датчики</div>
                                        <div class="ms-auto lh-1">
                                            <div class="dropdown">
                                                <a class="dropdown-toggle text-muted" href="#" data-bs-toggle="dropdown">Последний час</a>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="h1 mb-3">24</div>
                                    <div class="d-flex mb-2">
                                        <div>Активных</div>
                                        <div class="ms-auto">
                                            <span class="text-green d-inline-flex align-items-center lh-1">
                                                8% <svg xmlns="http://www.w3.org/2000/svg" class="icon ms-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><polyline points="3 17 9 11 13 15 21 7" /><polyline points="14 7 21 7 21 14" /></svg>
                                            </span>
                                        </div>
                                    </div>
                                    <div class="progress progress-sm">
                                        <div class="progress-bar bg-primary" style="width: 75%" role="progressbar"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-sm-6 col-lg-3">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="subheader">Температура</div>
                                    </div>
                                    <div class="h1 mb-3">42°C</div>
                                    <div class="d-flex mb-2">
                                        <div>Средняя</div>
                                        <div class="ms-auto">
                                            <span class="text-yellow d-inline-flex align-items-center lh-1">
                                                Норма
                                            </span>
                                        </div>
                                    </div>
                                    <div class="progress progress-sm">
                                        <div class="progress-bar bg-yellow" style="width: 60%" role="progressbar"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-sm-6 col-lg-3">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="subheader">Давление</div>
                                    </div>
                                    <div class="h1 mb-3">1.2 bar</div>
                                    <div class="d-flex mb-2">
                                        <div>Текущее</div>
                                        <div class="ms-auto">
                                            <span class="text-green d-inline-flex align-items-center lh-1">
                                                Стабильно
                                            </span>
                                        </div>
                                    </div>
                                    <div class="progress progress-sm">
                                        <div class="progress-bar bg-green" style="width: 45%" role="progressbar"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="col-sm-6 col-lg-3">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="subheader">Уровень</div>
                                    </div>
                                    <div class="h1 mb-3">87%</div>
                                    <div class="d-flex mb-2">
                                        <div>Заполнение</div>
                                        <div class="ms-auto">
                                            <span class="text-red d-inline-flex align-items-center lh-1">
                                                Высокий
                                            </span>
                                        </div>
                                    </div>
                                    <div class="progress progress-sm">
                                        <div class="progress-bar bg-red" style="width: 87%" role="progressbar"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Таблица датчиков -->
                    <div class="row row-cards mt-3">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">Список датчиков</h3>
                                </div>
                                <div class="table-responsive">
                                    <table class="table table-vcenter card-table">
                                        <thead>
                                            <tr>
                                                <th>Датчик</th>
                                                <th>Значение</th>
                                                <th>Статус</th>
                                                <th>Обновлено</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr>
                                                <td>Температура #1</td>
                                                <td class="text-muted">42.5°C</td>
                                                <td><span class="badge bg-success">Активен</span></td>
                                                <td class="text-muted">2 мин назад</td>
                                            </tr>
                                            <tr>
                                                <td>Давление #1</td>
                                                <td class="text-muted">1.2 bar</td>
                                                <td><span class="badge bg-success">Активен</span></td>
                                                <td class="text-muted">1 мин назад</td>
                                            </tr>
                                            <tr>
                                                <td>Уровень #1</td>
                                                <td class="text-muted">87%</td>
                                                <td><span class="badge bg-warning">Предупреждение</span></td>
                                                <td class="text-muted">30 сек назад</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        console.log('Page1: Мониторинг загружен');
    }
}

customElements.define('page-monitoring', Page1Component);
