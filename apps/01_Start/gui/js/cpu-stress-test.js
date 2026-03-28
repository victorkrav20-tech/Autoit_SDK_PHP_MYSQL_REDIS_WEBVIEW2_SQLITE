/**
 * CPU Stress Test - Нагрузка на процессор для тестирования
 * Создаёт интенсивные вычисления для проверки работы трэя
 */

class CPUStressTest {
    constructor() {
        this.isRunning = false;
        this.workers = [];
        this.intervalId = null;
        this.iterations = 0;
    }

    /**
     * Запуск нагрузки на CPU
     * @param {number} intensity - Интенсивность (1-10)
     */
    start(intensity = 5) {
        if (this.isRunning) {
            console.warn('⚠️ CPU Stress Test уже запущен');
            return;
        }

        this.isRunning = true;
        this.iterations = 0;
        console.log(`🔥 CPU Stress Test запущен (интенсивность: ${intensity}/10)`);

        // Запускаем МНОГО потоков вычислений для максимальной нагрузки
        const threads = intensity * 4; // Увеличено в 4 раза!
        
        for (let i = 0; i < threads; i++) {
            this.startWorkerThread(i, intensity);
        }

        // Логирование статистики каждую секунду
        this.intervalId = setInterval(() => {
            console.log(`📊 CPU Test: ${this.iterations} итераций/сек`);
            this.iterations = 0;
        }, 1000);
    }

    /**
     * Запуск рабочего потока
     */
    startWorkerThread(threadId, intensity) {
        const worker = () => {
            if (!this.isRunning) return;

            // МАКСИМАЛЬНЫЕ интенсивные математические вычисления
            const operations = intensity * 50000; // Увеличено в 5 раз!
            let result = 0;

            for (let i = 0; i < operations; i++) {
                // Тяжёлые математические операции
                result += Math.sqrt(i) * Math.sin(i) * Math.cos(i);
                result += Math.pow(i, 2) / (i + 1);
                result += Math.log(i + 1) * Math.exp(i / 1000);
                result += Math.tan(i) * Math.atan(i);
                result += Math.pow(Math.E, i / 10000);
                
                // Дополнительные операции для нагрузки
                if (i % 100 === 0) {
                    result += Math.random() * Math.PI;
                    result += Math.floor(Math.sqrt(i * Math.E));
                }
            }

            this.iterations++;

            // Продолжаем вычисления БЕЗ задержки
            requestAnimationFrame(worker);
        };

        worker();
    }

    /**
     * Остановка нагрузки
     */
    stop() {
        if (!this.isRunning) {
            console.warn('⚠️ CPU Stress Test не запущен');
            return;
        }

        this.isRunning = false;
        
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }

        console.log('✅ CPU Stress Test остановлен');
    }

    /**
     * Получить статус
     */
    getStatus() {
        return {
            isRunning: this.isRunning,
            iterations: this.iterations
        };
    }
}

// Создаём глобальный экземпляр
window.cpuStressTest = new CPUStressTest();

// Автозапуск при загрузке (для тестирования)
document.addEventListener('DOMContentLoaded', () => {
    console.log('🎯 CPU Stress Test готов к использованию');
    console.log('📝 Команды:');
    console.log('   cpuStressTest.start(5)  - Запустить (интенсивность 1-10)');
    console.log('   cpuStressTest.stop()    - Остановить');
    console.log('   cpuStressTest.getStatus() - Статус');
    
    // Автозапуск с МАКСИМАЛЬНОЙ интенсивностью 10 для тестирования трэя
    setTimeout(() => {
        window.cpuStressTest.start(10);
        console.log('🔥🔥🔥 МАКСИМАЛЬНАЯ CPU нагрузка для тестирования трэя!');
    }, 1000);
});
