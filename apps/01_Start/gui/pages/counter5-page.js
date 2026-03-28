// ===============================================================================
// counter5-page.js - Страница "Счётчик 5" (Tabler)
// ===============================================================================

class Counter5Page extends HTMLElement {
    connectedCallback() {
        this.innerHTML = /* html */`
            <div class="page-header d-print-none">
                <div class="container-xl">
                    <div class="row g-2 align-items-center">
                        <div class="col">
                            <div class="page-pretitle">Счётчики</div>
                            <h2 class="page-title">Счётчик 5</h2>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="page-body">
                <div class="container-xl">
                    <div class="row row-cards">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-header">
                                    <h3 class="card-title">Данные счётчика 5</h3>
                                </div>
                                <div class="card-body">
                                    <p class="text-muted">Здесь будут отображаться данные счётчика 5...</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        console.log('Page: Счётчик 5 загружена');
    }
}

customElements.define('page-counter5', Counter5Page);
