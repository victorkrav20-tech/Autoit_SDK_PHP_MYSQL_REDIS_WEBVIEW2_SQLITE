// ===============================================================================
// header-component.js - Web Component для шапки с навигацией (Tabler)
// ===============================================================================

class HeaderComponent extends HTMLElement {
    connectedCallback() {
        this.render();
        this.attachNavigationListeners();
        this.attachThemeHandlers();
        console.log('Header: Компонент загружен');
    }
    
    render() {
        // Определяем текущую тему ДО рендера
        const currentTheme = document.documentElement.getAttribute('data-bs-theme') || 'light';
        const dropdownContent = this.getDropdownContent(currentTheme);
        
        // Определяем активную страницу из localStorage
        const activePage = localStorage.getItem('current-page') || 'online';
        
        this.innerHTML = /* html */`
            <header class="navbar navbar-expand-md navbar-light d-print-none">
                <div class="container-xl">
                    <!-- Кнопка-гамбургер для мобильных (слева) -->
                    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbar-menu" aria-controls="navbar-menu" aria-expanded="false" aria-label="Toggle navigation">
                        <span class="navbar-toggler-icon"></span>
                    </button>
                    
                    <h1 class="navbar-brand navbar-brand-autodark d-none-navbar-horizontal pe-0 pe-md-3">
                        <a href="#">
                            <img src="../../_tabler_engine/icons/outline/brand-meta.svg" width="48" height="48" class="icon logo-icon">
                            NewScada1
                        </a>
                    </h1>
                    
                    <div class="navbar-nav flex-row order-md-last">
                        <div class="nav-item d-none d-md-flex me-3">
                            <div class="btn-list">
                                <span class="badge bg-green-lt">Система активна</span>
                            </div>
                        </div>
                        <div class="nav-item dropdown">
                            <a href="#" class="nav-link d-flex lh-1 text-reset p-0" data-bs-toggle="dropdown" aria-label="Выбор темы">
                                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                    <circle cx="12" cy="12" r="4" />
                                    <path d="M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7" />
                                </svg>
                            </a>
                            <div class="dropdown-menu dropdown-menu-end dropdown-menu-arrow" id="theme-dropdown">
                                ${dropdownContent}
                            </div>
                        </div>
                    </div>
                    <div class="collapse navbar-collapse" id="navbar-menu">
                        <div class="d-flex flex-column flex-md-row align-items-stretch align-items-md-center">
                            <ul class="navbar-nav">
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'online' ? 'active' : ''}" href="#" data-page="online">
                                        <span class="nav-link-icon d-md-none d-lg-inline-block">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                <polyline points="5 12 3 12 12 3 21 12 19 12" />
                                                <path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7" />
                                            </svg>
                                        </span>
                                        <span class="nav-link-title">Онлайн</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'counter1' ? 'active' : ''}" href="#" data-page="counter1">
                                        <span class="nav-link-title">Счётчик 1</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'counter2' ? 'active' : ''}" href="#" data-page="counter2">
                                        <span class="nav-link-title">Счётчик 2</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'counter3' ? 'active' : ''}" href="#" data-page="counter3">
                                        <span class="nav-link-title">Счётчик 3</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'counter4' ? 'active' : ''}" href="#" data-page="counter4">
                                        <span class="nav-link-title">Счётчик 4</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'counter5' ? 'active' : ''}" href="#" data-page="counter5">
                                        <span class="nav-link-title">Счётчик 5</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'counter6' ? 'active' : ''}" href="#" data-page="counter6">
                                        <span class="nav-link-title">Счётчик 6</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'counter7' ? 'active' : ''}" href="#" data-page="counter7">
                                        <span class="nav-link-title">Счётчик 7</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link ${activePage === 'test-utils' ? 'active' : ''}" href="#" data-page="test-utils">
                                        <span class="nav-link-icon d-md-none d-lg-inline-block">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                <path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" />
                                                <rect x="9" y="3" width="6" height="4" rx="2" />
                                                <path d="M9 14l2 2l4 -4" />
                                            </svg>
                                        </span>
                                        <span class="nav-link-title">Тест утилит</span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </header>
        `;
    }
    
    getDropdownContent(currentTheme) {
        if (currentTheme === 'dark') {
            // Для тёмной темы показываем все опции
            return /* html */`
                <h6 class="dropdown-header">Тема оформления</h6>
                <a href="javascript:void(0)" class="dropdown-item theme-option" data-theme="light">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon me-2" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                        <circle cx="12" cy="12" r="4" />
                        <path d="M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7" />
                    </svg>
                    Светлая
                </a>
                <a href="javascript:void(0)" class="dropdown-item theme-option active" data-theme="dark">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon me-2" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                        <path d="M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1 -8.313 -12.454z" />
                    </svg>
                    Тёмная ✓
                </a>
                <div class="dropdown-divider"></div>
                <h6 class="dropdown-header">Варианты тёмной темы</h6>
                <a href="javascript:void(0)" class="dropdown-item theme-base-option" data-base="gray">
                    <span class="badge bg-gray me-2" style="width: 20px; height: 20px;"></span>
                    Gray (стандарт)
                </a>
                <a href="javascript:void(0)" class="dropdown-item theme-base-option" data-base="slate">
                    <span class="badge bg-blue me-2" style="width: 20px; height: 20px;"></span>
                    Slate
                </a>
                <a href="javascript:void(0)" class="dropdown-item theme-base-option" data-base="zinc">
                    <span class="badge bg-secondary me-2" style="width: 20px; height: 20px;"></span>
                    Zinc
                </a>
                <a href="javascript:void(0)" class="dropdown-item theme-base-option" data-base="neutral">
                    <span class="badge bg-dark me-2" style="width: 20px; height: 20px;"></span>
                    Neutral
                </a>
                <a href="javascript:void(0)" class="dropdown-item theme-base-option" data-base="stone">
                    <span class="badge" style="width: 20px; height: 20px; background: #78716c;"></span>
                    Stone
                </a>
            `;
        } else {
            // Для светлой темы только переключение
            return /* html */`
                <h6 class="dropdown-header">Тема оформления</h6>
                <a href="javascript:void(0)" class="dropdown-item theme-option active" data-theme="light">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon me-2" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                        <circle cx="12" cy="12" r="4" />
                        <path d="M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7" />
                    </svg>
                    Светлая ✓
                </a>
                <a href="javascript:void(0)" class="dropdown-item theme-option" data-theme="dark">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon me-2" width="20" height="20" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                        <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                        <path d="M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1 -8.313 -12.454z" />
                    </svg>
                    Тёмная
                </a>
            `;
        }
    }
    
    updateDropdown() {
        const currentTheme = document.documentElement.getAttribute('data-bs-theme') || 'light';
        const dropdown = this.querySelector('#theme-dropdown');
        dropdown.innerHTML = this.getDropdownContent(currentTheme);
        
        // Перенавешиваем обработчики после обновления
        this.attachThemeHandlers();
    }
    
    attachNavigationListeners() {
        // Навешиваем обработчики на навигацию
        this.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                if (link.dataset.page) {
                    this.switchPage(link.dataset.page);
                }
            });
        });
    }
    
    attachThemeHandlers() {
        // Обработчики для переключения тем
        this.querySelectorAll('.theme-option').forEach(option => {
            option.addEventListener('click', (e) => {
                e.preventDefault();
                const theme = option.dataset.theme;
                document.documentElement.setAttribute('data-bs-theme', theme);
                localStorage.setItem('tabler-theme', theme);
                console.log(`Тема изменена на: ${theme}`);
                
                // Обновляем dropdown после смены темы
                this.updateDropdown();
            });
        });
        
        // Обработчики для цветовой схемы (только для тёмной темы)
        this.querySelectorAll('.theme-base-option').forEach(option => {
            option.addEventListener('click', (e) => {
                e.preventDefault();
                const base = option.dataset.base;
                document.documentElement.setAttribute('data-bs-theme-base', base);
                localStorage.setItem('tabler-theme-base', base);
                console.log(`Цветовая схема изменена на: ${base}`);
            });
        });
    }
    
    switchPage(pageId) {
        // Убираем active со всех страниц
        document.querySelectorAll('.page-content').forEach(page => {
            page.classList.remove('active');
        });
        
        // Добавляем active к выбранной странице
        const targetPage = document.getElementById(pageId);
        if (targetPage) {
            targetPage.classList.add('active');
        }
        
        // Обновляем активную ссылку в навигации
        this.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
            if (link.dataset.page === pageId) {
                link.classList.add('active');
            }
        });
        
        // Сохраняем текущую страницу в localStorage
        localStorage.setItem('current-page', pageId);
        
        console.log(`Header: Переключено на ${pageId}`);
    }
    
    // Загрузка последней открытой страницы при старте
    loadLastPage() {
        const lastPage = localStorage.getItem('current-page');
        if (lastPage) {
            // Проверяем, существует ли такая страница
            const pageElement = document.getElementById(lastPage);
            if (pageElement) {
                this.switchPage(lastPage);
                console.log(`Header: Загружена последняя страница ${lastPage}`);
                return;
            }
        }
        // Если нет сохранённой страницы или она не существует - загружаем online
        this.switchPage('online');
    }
}

// Регистрация компонента
customElements.define('app-header', HeaderComponent);
