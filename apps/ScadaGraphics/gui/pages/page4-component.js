// ===============================================================================
// page4-component.js - Страница Отчёты (заглушка)
// ===============================================================================

class PageReports extends HTMLElement {
    constructor() {
        super();
    }
    
    connectedCallback() {
        this.render();
        console.log('Page4: Отчёты загружены');
    }
    
    render() {
        this.innerHTML = /* html */`
            <div class="page-body">
                <div class="container-xl">
                    <div class="page-header d-print-none">
                        <div class="row g-2 align-items-center">
                            <div class="col">
                                <div class="page-pretitle">ОБЗОР</div>
                                <h2 class="page-title">📊 Отчёты</h2>
                            </div>
                        </div>
                    </div>
                    
                    <div class="row row-cards mt-3">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-body text-center py-5">
                                    <h3 class="text-muted">Страница в разработке</h3>
                                    <p class="text-muted">Здесь будут отчёты и аналитика</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
}

customElements.define('page-reports', PageReports);
