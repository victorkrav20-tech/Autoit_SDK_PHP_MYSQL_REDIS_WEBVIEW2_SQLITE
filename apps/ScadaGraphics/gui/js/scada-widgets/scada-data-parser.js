// ===============================================================================
// scada-data-parser.js - Универсальный парсер данных для SCADA графиков
// ===============================================================================
// Версия: 1.0.0
// Дата: 02.03.2026
// Описание: Преобразование различных форматов данных в uPlot колоночный формат

class ScadaDataParser {
    
    // ========================================================================
    // 1. CSV/TSV/DSV ПАРСИНГ (через uDSV)
    // ========================================================================
    
    /**
     * Парсинг CSV/TSV/DSV в uPlot формат
     * @param {string} csvString - CSV строка
     * @param {Object} options - Опции парсинга
     * @param {string} options.delimiter - Разделитель (auto, ',', '\t', '|', ';')
     * @param {boolean} options.hasHeader - Есть ли заголовок (default: true)
     * @param {boolean} options.trim - Обрезать пробелы (default: true)
     * @returns {Array} uPlot колоночный формат [[x], [y1], [y2], ...]
     */
    static parseCSV(csvString, options = {}) {
        try {
            if (!csvString || typeof csvString !== 'string') {
                throw new Error('CSV строка пуста или некорректна');
            }
            
            // Проверяем что uDSV загружен
            if (typeof uDSV === 'undefined') {
                throw new Error('uDSV библиотека не загружена');
            }
            
            const config = {
                delimiter: options.delimiter || undefined, // auto-detect
                hasHeader: options.hasHeader !== false,
                trim: options.trim !== false
            };
            
            // Инференс схемы
            const schema = uDSV.inferSchema(csvString, {
                col: config.delimiter,
                trim: config.trim
            });
            
            // Создаём парсер
            const parser = uDSV.initParser(schema);
            
            // Парсим в колоночный формат (идеально для uPlot!)
            const data = parser.typedCols(csvString);
            
            console.log('✅ ScadaDataParser.parseCSV: Успешно распарсено', data[0].length, 'точек');
            
            return data;
            
        } catch (error) {
            console.error('❌ ScadaDataParser.parseCSV: Ошибка парсинга:', error);
            return null;
        }
    }
    
    // ========================================================================
    // 2. JSON ПАРСИНГ
    // ========================================================================
    
    /**
     * Парсинг JSON в uPlot формат
     * @param {*} jsonData - JSON данные
     * @param {string} format - Формат: 'array', 'object', 'columnar', 'auto'
     * @returns {Array} uPlot колоночный формат [[x], [y1], [y2], ...]
     */
    static parseJSON(jsonData, format = 'auto') {
        try {
            if (!jsonData) {
                throw new Error('JSON данные пусты');
            }
            
            // Если строка - парсим
            if (typeof jsonData === 'string') {
                jsonData = JSON.parse(jsonData);
            }
            
            // Автоопределение формата
            if (format === 'auto') {
                format = this._detectJSONFormat(jsonData);
            }
            
            let result = null;
            
            switch (format) {
                case 'array':
                    // [{x:1,y:2}, {x:2,y:3}] → [[1,2],[2,3]]
                    result = this._parseJSONArray(jsonData);
                    break;
                    
                case 'object':
                    // {x:[1,2], y:[2,3]} → [[1,2],[2,3]]
                    result = this._parseJSONObject(jsonData);
                    break;
                    
                case 'columnar':
                    // [[1,2],[2,3]] → как есть
                    result = jsonData;
                    break;
                    
                default:
                    throw new Error(`Неизвестный формат JSON: ${format}`);
            }
            
            console.log('✅ ScadaDataParser.parseJSON: Успешно распарсено', result[0].length, 'точек');
            
            return result;
            
        } catch (error) {
            console.error('❌ ScadaDataParser.parseJSON: Ошибка парсинга:', error);
            return null;
        }
    }
    
    /**
     * Парсинг JSON массива объектов
     * @private
     */
    static _parseJSONArray(data) {
        if (!Array.isArray(data) || data.length === 0) {
            throw new Error('JSON array пуст или некорректен');
        }
        
        const keys = Object.keys(data[0]);
        const columns = keys.map(() => []);
        
        data.forEach(row => {
            keys.forEach((key, i) => {
                columns[i].push(row[key]);
            });
        });
        
        return columns;
    }
    
    /**
     * Парсинг JSON объекта с массивами
     * @private
     */
    static _parseJSONObject(data) {
        if (typeof data !== 'object' || Array.isArray(data)) {
            throw new Error('JSON object некорректен');
        }
        
        const keys = Object.keys(data);
        const columns = keys.map(key => data[key]);
        
        return columns;
    }
    
    /**
     * Автоопределение формата JSON
     * @private
     */
    static _detectJSONFormat(data) {
        if (Array.isArray(data)) {
            if (data.length > 0 && Array.isArray(data[0])) {
                return 'columnar';
            }
            return 'array';
        }
        return 'object';
    }
    
    // ========================================================================
    // 3. REDIS ПАРСИНГ (из PHP API)
    // ========================================================================
    
    /**
     * Парсинг Redis ответа в uPlot формат
     * @param {Object|string} redisResponse - Ответ от Redis API
     * @returns {Array} uPlot колоночный формат [[timestamps], [values], ...]
     */
    static parseRedis(redisResponse) {
        try {
            // Если строка - парсим JSON
            if (typeof redisResponse === 'string') {
                redisResponse = JSON.parse(redisResponse);
            }
            
            // Проверяем структуру ответа
            if (!redisResponse || !redisResponse.success) {
                throw new Error('Redis ответ некорректен или содержит ошибку');
            }
            
            const data = redisResponse.data;
            
            if (!Array.isArray(data) || data.length === 0) {
                throw new Error('Redis data пуст или некорректен');
            }
            
            // Извлекаем ключи из первого элемента
            const keys = Object.keys(data[0]);
            
            // Создаём колонки
            const columns = keys.map(() => []);
            
            // Заполняем колонки
            data.forEach(row => {
                keys.forEach((key, i) => {
                    const value = row[key];
                    // Преобразуем строки в числа где возможно
                    columns[i].push(
                        typeof value === 'string' && !isNaN(value) 
                            ? parseFloat(value) 
                            : value
                    );
                });
            });
            
            console.log('✅ ScadaDataParser.parseRedis: Успешно распарсено', columns[0].length, 'точек');
            
            return columns;
            
        } catch (error) {
            console.error('❌ ScadaDataParser.parseRedis: Ошибка парсинга:', error);
            return null;
        }
    }
    
    // ========================================================================
    // 4. МАССИВЫ ПАРСИНГ
    // ========================================================================
    
    /**
     * Парсинг массивов в uPlot формат
     * @param {Array} arrayData - Массив данных
     * @param {string} format - Формат: 'rows' или 'columns'
     * @returns {Array} uPlot колоночный формат [[x], [y1], [y2], ...]
     */
    static parseArray(arrayData, format = 'rows') {
        try {
            if (!Array.isArray(arrayData) || arrayData.length === 0) {
                throw new Error('Массив пуст или некорректен');
            }
            
            let result = null;
            
            if (format === 'rows') {
                // [[1,2],[3,4]] → [[1,3],[2,4]]
                result = this.transposeArray(arrayData);
            } else if (format === 'columns') {
                // [[1,3],[2,4]] → как есть
                result = arrayData;
            } else {
                throw new Error(`Неизвестный формат массива: ${format}`);
            }
            
            console.log('✅ ScadaDataParser.parseArray: Успешно распарсено', result[0].length, 'точек');
            
            return result;
            
        } catch (error) {
            console.error('❌ ScadaDataParser.parseArray: Ошибка парсинга:', error);
            return null;
        }
    }
    
    // ========================================================================
    // 5. ВАЛИДАЦИЯ ДАННЫХ
    // ========================================================================
    
    /**
     * Валидация данных для uPlot
     * @param {Array} data - Данные в формате uPlot
     * @returns {Object} {valid: boolean, errors: Array}
     */
    static validateUPlotData(data) {
        const errors = [];
        
        try {
            // Проверка что это массив
            if (!Array.isArray(data)) {
                errors.push('Данные должны быть массивом');
                return { valid: false, errors };
            }
            
            // Проверка что не пустой
            if (data.length === 0) {
                errors.push('Данные пусты');
                return { valid: false, errors };
            }
            
            // Проверка что минимум 2 серии (X + Y)
            if (data.length < 2) {
                errors.push('Должно быть минимум 2 серии (X и Y)');
                return { valid: false, errors };
            }
            
            // Проверка что все серии - массивы
            for (let i = 0; i < data.length; i++) {
                if (!Array.isArray(data[i])) {
                    errors.push(`Серия ${i} не является массивом`);
                }
            }
            
            if (errors.length > 0) {
                return { valid: false, errors };
            }
            
            // Проверка что все серии одинаковой длины
            const length = data[0].length;
            for (let i = 1; i < data.length; i++) {
                if (data[i].length !== length) {
                    errors.push(`Серия ${i} имеет длину ${data[i].length}, ожидалось ${length}`);
                }
            }
            
            if (errors.length > 0) {
                return { valid: false, errors };
            }
            
            // Проверка что есть данные
            if (length === 0) {
                errors.push('Серии пусты');
                return { valid: false, errors };
            }
            
            console.log('✅ ScadaDataParser.validateUPlotData: Данные валидны');
            
            return { valid: true, errors: [] };
            
        } catch (error) {
            errors.push(`Ошибка валидации: ${error.message}`);
            return { valid: false, errors };
        }
    }
    
    // ========================================================================
    // УТИЛИТЫ
    // ========================================================================
    
    /**
     * Транспонирование массива (rows ↔ columns)
     * @param {Array} array - Массив для транспонирования
     * @returns {Array} Транспонированный массив
     */
    static transposeArray(array) {
        if (!Array.isArray(array) || array.length === 0) {
            return array;
        }
        
        const rows = array.length;
        const cols = array[0].length;
        const result = [];
        
        for (let j = 0; j < cols; j++) {
            result[j] = [];
            for (let i = 0; i < rows; i++) {
                result[j][i] = array[i][j];
            }
        }
        
        return result;
    }
}
