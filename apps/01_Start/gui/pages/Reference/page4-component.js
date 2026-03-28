// ===============================================================================
// page4-component.js - Страница Отчёты с живыми графиками uPlot
// ===============================================================================

class PageReports extends HTMLElement {
    constructor() {
        super();
        this.chart = null;
        this.updateInterval = null;
        this.data = null; // uPlot data format: [timestamps, series1, series2, series3]
        this.maxDataPoints = 50; // Максимум точек на графике
        this.lastValue1 = 50; // Начальное значение линии 1
        this.lastValue2 = 30; // Начальное значение линии 2
        this.lastValue3 = 70; // Начальное значение линии 3
        this.timeIndex = 0; // Индекс времени
        this.totalPoints = 0; // Общее количество точек (для статистики)
    }
    
    connectedCallback() {
        this.render();
        // Небольшая задержка для загрузки DOM
        setTimeout(() => {
            this.initChart();
        }, 100);
        console.log('Page4: Отчёты загружены (uPlot)');
    }
    
    disconnectedCallback() {
        // Очищаем интервал при удалении компонента
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
        // Очищаем данные
        this.data = null;
        console.log('Page4: График остановлен и очищен');
    }
    
    render() {
        this.innerHTML = /* html */`
            <div class="page-body">
                <div class="container-xl">
                    <div class="page-header d-print-none">
                        <div class="row g-2 align-items-center">
                            <div class="col">
                                <div class="page-pretitle">ОБЗОР</div>
                                <h2 class="page-title">Отчёты и графики</h2>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="page-body">
                    <div class="container-xl">
                        <!-- Живой график -->
                        <div class="row row-deck row-cards">
                            <div class="col-12">
                                <div class="card">
                                    <div class="card-header">
                                        <h3 class="card-title">Мониторинг в реальном времени (uPlot)</h3>
                                        <div class="ms-auto">
                                            <span class="badge bg-green-lt">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-activity" width="16" height="16" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none">
                                                    <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                                    <path d="M3 12h4l3 8l4 -16l3 8h4" />
                                                </svg>
                                                60 FPS
                                            </span>
                                        </div>
                                    </div>
                                    <div class="card-body">
                                        <div id="realtime-chart" style="height: 400px;"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
    
    initChart() {
        // Инициализируем данные в формате uPlot: [timestamps, series1, series2, series3]
        const timestamps = [];
        const series1 = [];
        const series2 = [];
        const series3 = [];
        
        for (let i = 0; i < this.maxDataPoints; i++) {
            // Генерируем начальные данные
            const change1 = (Math.random() - 0.5) * 1;
            this.lastValue1 = Math.max(0, Math.min(100, this.lastValue1 + change1));
            
            const change2 = (Math.random() - 0.5) * 1;
            this.lastValue2 = Math.max(0, Math.min(100, this.lastValue2 + change2));
            
            const change3 = (Math.random() - 0.5) * 1;
            this.lastValue3 = Math.max(0, Math.min(100, this.lastValue3 + change3));
            
            timestamps.push(this.timeIndex++);
            series1.push(parseFloat(this.lastValue1.toFixed(2)));
            series2.push(parseFloat(this.lastValue2.toFixed(2)));
            series3.push(parseFloat(this.lastValue3.toFixed(2)));
        }
        
        this.data = [timestamps, series1, series2, series3];
        
        // Определяем тему
        const isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark';
        
        // Получаем контейнер
        const container = document.getElementById('realtime-chart');
        if (!container) {
            console.error('❌ Контейнер #realtime-chart не найден!');
            return;
        }
        
        // Настройки uPlot
        const opts = {
            width: container.offsetWidth || 800,
            height: 400,
            series: [
                {
                    label: "Время"
                },
                {
                    label: "Датчик 1",
                    stroke: "#206bc4",
                    width: 2
                },
                {
                    label: "Датчик 2",
                    stroke: "#2fb344",
                    width: 2
                },
                {
                    label: "Датчик 3",
                    stroke: "#f59f00",
                    width: 2
                }
            ],
            axes: [
                {
                    stroke: isDark ? '#ffffff' : '#000000',
                    grid: {
                        stroke: isDark ? '#374151' : '#e5e7eb',
                        width: 1
                    }
                },
                {
                    stroke: isDark ? '#ffffff' : '#000000',
                    grid: {
                        stroke: isDark ? '#374151' : '#e5e7eb',
                        width: 1
                    }
                }
            ],
            legend: {
                show: true
            }
        };
        
        try {
            // Создаём график
            this.chart = new uPlot(opts, this.data, container);
            console.log('✅ uPlot график создан успешно');
            
            // Запускаем обновление
            this.startRealTimeUpdate();
            
            // Обработка изменения размера окна
            window.addEventListener('resize', () => {
                if (this.chart && container) {
                    this.chart.setSize({
                        width: container.offsetWidth || 800,
                        height: 400
                    });
                }
            });
        } catch (error) {
            console.error('❌ Ошибка создания uPlot:', error);
        }
    }
    
    startRealTimeUpdate() {
        this.updateInterval = setInterval(() => {
            // Генерируем новые значения
            const change1 = (Math.random() - 0.5) * 1;
            this.lastValue1 = Math.max(0, Math.min(100, this.lastValue1 + change1));
            
            const change2 = (Math.random() - 0.5) * 1;
            this.lastValue2 = Math.max(0, Math.min(100, this.lastValue2 + change2));
            
            const change3 = (Math.random() - 0.5) * 1;
            this.lastValue3 = Math.max(0, Math.min(100, this.lastValue3 + change3));
            
            this.totalPoints++;
            
            // Добавляем новые точки
            this.data[0].push(this.timeIndex++);
            this.data[1].push(parseFloat(this.lastValue1.toFixed(2)));
            this.data[2].push(parseFloat(this.lastValue2.toFixed(2)));
            this.data[3].push(parseFloat(this.lastValue3.toFixed(2)));
            
            // Удаляем старые точки если превышен лимит
            if (this.data[0].length > this.maxDataPoints) {
                this.data[0].shift();
                this.data[1].shift();
                this.data[2].shift();
                this.data[3].shift();
            }
            
            // Обновляем график (uPlot автоматически управляет памятью!)
            if (this.chart) {
                this.chart.setData(this.data);
            }
            
            // Логируем статистику каждые 1000 точек
            if (this.totalPoints % 1000 === 0) {
                console.log(`📊 uPlot: ${this.totalPoints} точек обработано, в памяти: ${this.data[0].length} x 3 линии`);
            }
        }, 16); // 60 FPS
    }
}

customElements.define('page-reports', PageReports);
