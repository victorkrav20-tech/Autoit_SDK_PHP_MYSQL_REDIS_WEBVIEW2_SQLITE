// ===============================================================================
// Online Updater - Оптимизированное обновление DOM
// ===============================================================================

class OnlineUpdater {
    constructor() {
        // Кэш элементов DOM
        this.elements = new Map();
        
        // Кэш последних значений для проверки изменений
        this.lastValues = new Map();
    }

    // Инициализация кэша элементов
    initCache() {
        for (let i = 1; i <= 7; i++) {
            this.elements.set(i, {
                name: document.getElementById(`name-${i}`),
                status: document.getElementById(`status-${i}`),
                working: document.getElementById(`working-${i}`),
                time: document.getElementById(`time-${i}`),
                btnParsing: document.querySelector(`.btn-parsing[data-counter-id="${i}"]`),
                btnWindow: document.querySelector(`.btn-window[data-counter-id="${i}"]`)
            });
            
            this.lastValues.set(i, {
                name: null,
                dataStatus: null,
                workingStatus: null,
                time: null,
                enabled: null,
                windowVisible: null
            });
        }
    }

    // Обновление всех счётчиков
    updateAll(dataManager) {
        for (let i = 1; i <= 7; i++) {
            const counter = dataManager.getCounter(i);
            if (counter) {
                this.updateCounter(i, counter);
            }
        }
    }

    // Обновление одного счётчика
    updateCounter(counterId, counter) {
        const els = this.elements.get(counterId);
        const last = this.lastValues.get(counterId);
        
        if (!els || !last) return;

        // Обновляем название (только если изменилось)
        if (last.name !== counter.name) {
            if (els.name) {
                els.name.textContent = counter.name;
            }
            last.name = counter.name;
        }

        // Обновляем статус данных
        this.updateDataStatus(counterId, counter, els, last);

        // Обновляем статус работы
        this.updateWorkingStatus(counterId, counter, els, last);

        // Обновляем время
        this.updateTime(counterId, counter, els, last);

        // Обновляем кнопки
        this.updateButtons(counterId, counter, els, last);
    }

    // Обновление статуса данных
    updateDataStatus(counterId, counter, els, last) {
        if (!els.status) return;

        const now = Date.now();
        const elapsed = counter.lastDataTime ? 
            ((now - counter.lastDataTime) / 1000).toFixed(1) : '—';

        let text = '';
        let className = 'status-badge';

        switch (counter.dataStatus) {
            case 'fresh':
                text = `🟢 ${elapsed}с`;
                className += ' status-fresh';
                break;
            case 'stale':
                text = `🟡 ${elapsed}с`;
                className += ' status-stale';
                break;
            case 'timeout':
                text = `🔴 ${elapsed}с`;
                className += ' status-timeout';
                break;
            default:
                text = '⚪ Нет данных';
                className += ' status-none';
        }

        // Обновляем только если изменилось
        if (last.dataStatus !== counter.dataStatus || els.status.textContent !== text) {
            els.status.textContent = text;
            els.status.className = className;
            last.dataStatus = counter.dataStatus;
        }
    }

    // Обновление статуса работы
    updateWorkingStatus(counterId, counter, els, last) {
        if (!els.working) return;

        const status = counter.workingStatus;
        const flowText = status.flow !== undefined ? 
            `Расход: ${status.flow.toFixed(2)}` : '—';

        const statusKey = `${status.status}_${status.flow ? status.flow.toFixed(2) : 'null'}`;

        // Обновляем только если изменилось
        if (last.workingStatus !== statusKey) {
            const badge = els.working.querySelector('.working-badge');
            const flow = els.working.querySelector('.working-flow');

            if (badge) {
                badge.textContent = `${status.icon} ${status.text}`;
                badge.className = `working-badge working-${status.color}`;
            }

            if (flow) {
                flow.textContent = flowText;
            }

            last.workingStatus = statusKey;
        }
    }

    // Обновление времени
    updateTime(counterId, counter, els, last) {
        if (!els.time) return;

        if (counter.lastDataTime) {
            const date = new Date(counter.lastDataTime);
            const timeStr = date.toLocaleTimeString('ru-RU');

            if (last.time !== timeStr) {
                els.time.textContent = timeStr;
                els.time.className = 'time-active';
                last.time = timeStr;
            }
        } else {
            if (last.time !== null) {
                els.time.textContent = '—';
                els.time.className = 'time-inactive';
                last.time = null;
            }
        }
    }

    // Обновление кнопок
    updateButtons(counterId, counter, els, last) {
        // Кнопка парсинга
        if (els.btnParsing && last.enabled !== counter.enabled) {
            els.btnParsing.disabled = false;
            els.btnParsing.className = counter.enabled ? 
                'btn-mini btn-parsing btn-active' : 
                'btn-mini btn-parsing';
            els.btnParsing.textContent = counter.enabled ? '✓ ВКЛ' : 'ВЫКЛ';
            last.enabled = counter.enabled;
        }

        // Кнопка окна
        if (els.btnWindow && last.windowVisible !== counter.windowVisible) {
            els.btnWindow.disabled = false;
            els.btnWindow.className = counter.windowVisible ? 
                'btn-mini btn-window btn-visible' : 
                'btn-mini btn-window';
            els.btnWindow.textContent = counter.windowVisible ? 'ПОКАЗАНО' : 'СКРЫТО';
            last.windowVisible = counter.windowVisible;
        }
    }
}
