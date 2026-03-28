// ===============================================================================
// footer-component.js - Web Component для подвала (Tabler)
// ===============================================================================

class FooterComponent extends HTMLElement {
    connectedCallback() {
        this.innerHTML = /* html */`
            <footer class="footer footer-transparent d-print-none">
                <div class="container-xl">
                    <div class="row align-items-center">
                        <!-- Левая часть: Эталонное приложение -->
                        <div class="col-lg-4 text-start">
                            <span class="badge bg-blue text-white">
                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler" width="16" height="16" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                    <rect x="4" y="4" width="16" height="4" rx="1" />
                                    <rect x="4" y="12" width="6" height="8" rx="1" />
                                    <line x1="14" y1="12" x2="20" y2="12" />
                                    <line x1="14" y1="16" x2="20" y2="16" />
                                    <line x1="14" y1="20" x2="20" y2="20" />
                                </svg>
                                Эталонное приложение
                            </span>
                        </div>
                        
                        <!-- Центр: Копирайт -->
                        <div class="col-lg-4 text-center">
                            <div class="text-muted">
                                © 2026 
                                <svg xmlns="http://www.w3.org/2000/svg" class="icon text-red icon-filled icon-inline" width="18" height="18" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                    <path d="M19.5 12.572l-7.5 7.428l-7.5 -7.428a5 5 0 1 1 7.5 -6.566a5 5 0 1 1 7.5 6.572" />
                                </svg>
                                <span class="fw-semibold">SDK Scada Team</span>
                            </div>
                        </div>
                        
                        <!-- Правая часть: Версия -->
                        <div class="col-lg-4 text-end">
                            <span class="badge bg-green text-white">Версия 2.0.0</span>
                        </div>
                    </div>
                    
                    <div class="row mt-3">
                        <div class="col-12">
                            <div class="alert alert-info mb-0" role="alert">
                                <div class="d-flex align-items-start">
                                    <div class="me-3">
                                        <img src="../../_tabler_engine/icons/outline/zoom-exclamation.svg" width="48" height="48" class="alert-logo-icon">
                                    </div>
                                    <div>
                                        <h4 class="alert-title">Эталонное приложение для копирования</h4>
                                        <div class="text-muted">
                                            Это приложение создано как шаблон для быстрого старта новых SCADA проектов. 
                                            Используйте <code class="text-primary">autoit.new_app</code> для создания копии с автоматическим переименованием. 
                                            Включает готовые компоненты на базе <span class="text-info">Tabler</span>: мониторинг, аналитику, настройки с плавной навигацией.
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </footer>
        `;
        
        console.log('Footer: Компонент загружен');
    }
}

// Регистрация компонента
customElements.define('app-footer', FooterComponent);
