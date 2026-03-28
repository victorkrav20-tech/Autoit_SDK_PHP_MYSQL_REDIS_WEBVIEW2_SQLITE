// ===============================================================================
// scada-chart-base.js - Базовый класс для SCADA графиков (uPlot)
// ===============================================================================
// Версия: 1.0.0
// Дата: 02.03.2026
// Описание: Минимальный базовый класс для всех SCADA виджетов

class ScadaChartBase {
    constructor(container, options = {}) {
        this.container = container;
        this.options = options;
        this.chart = null;
        this.data = null;
    }
    
    /**
     * Инициализация uPlot графика
     */
    init() {
        if (!this.container) {
            console.error('❌ ScadaChartBase: Контейнер не найден');
            return;
        }
        
        if (!this.data) {
            console.error('❌ ScadaChartBase: Данные не установлены');
            return;
        }
        
        try {
            this.chart = new uPlot(this.options, this.data, this.container);
            console.log('✅ ScadaChartBase: График инициализирован');
        } catch (error) {
            console.error('❌ ScadaChartBase: Ошибка инициализации:', error);
        }
    }
    
    /**
     * Установка/обновление данных
     * @param {Array} newData - Данные в формате uPlot [[timestamps], [values1], [values2], ...]
     */
    setData(newData) {
        this.data = newData;
        
        if (this.chart) {
            this.chart.setData(newData);
        }
    }
    
    /**
     * Получение текущих данных
     * @returns {Array} Данные графика
     */
    getData() {
        return this.data;
    }
    
    /**
     * Изменение размера графика
     * @param {number} width - Ширина
     * @param {number} height - Высота
     */
    resize(width, height) {
        if (this.chart) {
            this.chart.setSize({ width, height });
        }
    }
    
    /**
     * Очистка и уничтожение графика
     */
    destroy() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
        
        this.data = null;
        console.log('✅ ScadaChartBase: График уничтожен');
    }
}
