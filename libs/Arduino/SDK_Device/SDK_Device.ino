// ============================================================
// SDK_Device.ino — Arduino Mega 2560 Modbus RTU Slave
// Тестовый набор регистров для автотеста библиотеки Rs485
// ------------------------------------------------------------
// Serial1 (TX1/RX1) — RS-485 модуль
// DE/RE пин: 13
// Baudrate: 19200
// Slave ID: 1
// ------------------------------------------------------------
// РЕГИСТРЫ ДЛЯ ЧТЕНИЯ (0–9):
//   [0]  INT16   temp_int16       -150 (0xFF6A) = -15.0°C x10
//   [1]  UINT16  status_uint16    0x00A5 = 165 (битовые флаги)
//   [2]  UINT16  counter_uint16   1000
//   [3]  FLOAT32 pressure ABCD hi 0x4048 (3.14159)
//   [4]  FLOAT32 pressure ABCD lo 0xF5C3
//   [5]  FLOAT32 weight CDAB hi   0x4461 (897.5)
//   [6]  FLOAT32 weight CDAB lo   0xC000
//   [7]  INT32   long_int32 hi    0x0001 (100000)
//   [8]  INT32   long_int32 lo    0x86A0
//   [9]  UINT32  uint32 hi        0x000F (1000000)
// РЕГИСТРЫ ДЛЯ ЗАПИСИ (10–19):
//   [10] UINT32  uint32 lo        0x4240 (1000000)
//   [11] rw_int16    — master пишет INT16,   отражается в [0]
//   [12] rw_uint16   — master пишет UINT16,  отражается в [1]
//   [13] rw_f32_abcd_hi — Float ABCD hi,     отражается в [3]
//   [14] rw_f32_abcd_lo — Float ABCD lo,     отражается в [4]
//   [15] rw_f32_cdab_hi — Float CDAB hi,     отражается в [5]
//   [16] rw_f32_cdab_lo — Float CDAB lo,     отражается в [6]
//   [17] rw_int32_hi    — INT32 hi,           отражается в [7]
//   [18] rw_int32_lo    — INT32 lo,           отражается в [8]
//   [19] rw_uint32_hi   — UINT32 hi,          отражается в [9]
// ============================================================

#include <ModbusRtu.h>

// --- Параметры Modbus ---
const int SLAVE_ID   = 1;
const int BAUD_RATE  = 19200;
const int ENABLE_PIN = 13;   // DE/RE пин RS-485 модуля
const int LED_PIN    = 12;   // Индикатор активности (опционально)

// --- Modbus объект: (slaveID, serial port number, enable pin) ---
// Serial1 = порт 1 на Mega 2560 (TX1=18, RX1=19)
Modbus bus(SLAVE_ID, 1, ENABLE_PIN);

// --- Массив регистров 20 x uint16_t ---
uint16_t modbus_regs[20];

// --- Флаг: была ли запись от мастера ---
bool writeReceived = false;

// ============================================================
// Вспомогательные функции конвертации
// ============================================================

// Float → два uint16_t в порядке ABCD (Big Endian, стандарт Modbus)
// Старший word в hi, младший в lo
void floatToRegsABCD(float val, uint16_t &hi, uint16_t &lo) {
  union { float f; uint32_t u; } conv;
  conv.f = val;
  hi = (uint16_t)(conv.u >> 16);
  lo = (uint16_t)(conv.u & 0xFFFF);
}

// Float → два uint16_t в порядке CDAB (Mid-Big, часто у ПЛК)
// Байты: C D A B → word0 = CD, word1 = AB
void floatToRegsCDAB(float val, uint16_t &hi, uint16_t &lo) {
  union { float f; uint32_t u; } conv;
  conv.f = val;
  // ABCD исходный: A=byte3, B=byte2, C=byte1, D=byte0
  // CDAB: word0 = C(byte1) D(byte0), word1 = A(byte3) B(byte2)
  uint8_t a = (conv.u >> 24) & 0xFF;
  uint8_t b = (conv.u >> 16) & 0xFF;
  uint8_t c = (conv.u >>  8) & 0xFF;
  uint8_t d = (conv.u      ) & 0xFF;
  hi = ((uint16_t)c << 8) | d;  // word0 = CD
  lo = ((uint16_t)a << 8) | b;  // word1 = AB
}

// INT32 → два uint16_t Big Endian
void int32ToRegs(int32_t val, uint16_t &hi, uint16_t &lo) {
  hi = (uint16_t)((uint32_t)val >> 16);
  lo = (uint16_t)((uint32_t)val & 0xFFFF);
}

// UINT32 → два uint16_t Big Endian
void uint32ToRegs(uint32_t val, uint16_t &hi, uint16_t &lo) {
  hi = (uint16_t)(val >> 16);
  lo = (uint16_t)(val & 0xFFFF);
}

// ============================================================
// Инициализация тестовых значений в регистрах 0–10
// ============================================================
void initTestValues() {
  // [0] INT16 = -150 (0xFF6A) — температура ×10 = -15.0°C
  modbus_regs[0] = (uint16_t)(-150);  // 0xFF6A

  // [1] UINT16 = 0x00A5 = 165 — битовые флаги
  modbus_regs[1] = 0x00A5;

  // [2] UINT16 = 1000 — счётчик
  modbus_regs[2] = 1000;

  // [3][4] FLOAT32 ABCD = 3.14159
  floatToRegsABCD(3.14159f, modbus_regs[3], modbus_regs[4]);

  // [5][6] FLOAT32 CDAB = 897.5
  floatToRegsCDAB(897.5f, modbus_regs[5], modbus_regs[6]);

  // [7][8] INT32 = 100000
  int32ToRegs(100000L, modbus_regs[7], modbus_regs[8]);

  // [9][10] UINT32 = 1000000
  uint32ToRegs(1000000UL, modbus_regs[9], modbus_regs[10]);

  // [11–19] Регистры записи — инициализируем нулями
  for (int i = 11; i < 20; i++) {
    modbus_regs[i] = 0;
  }
}

// ============================================================
// Применение записанных мастером значений
// Мастер пишет в [11–19], arduino отражает в [0–9]
// Специальный флаг сброса: если reg[11]=0xFFFF — сброс всех в начальные значения
// ============================================================
void applyWrittenValues() {
  // Флаг сброса: если reg[11]=0xFFFF — восстанавливаем начальные значения
  if (modbus_regs[11] == 0xFFFF) {
    initTestValues();
    // Сбрасываем флаг
    modbus_regs[11] = 0;
    return;
  }

  // [11] → [0]: rw_int16 → temp_int16 (применяем всегда если reg[11] изменился)
  modbus_regs[0] = modbus_regs[11];

  // [12] → [1]: rw_uint16 → status_uint16
  modbus_regs[1] = modbus_regs[12];

  // [13][14] → [3][4]: rw_f32_abcd → pressure ABCD
  modbus_regs[3] = modbus_regs[13];
  modbus_regs[4] = modbus_regs[14];

  // [15][16] → [5][6]: rw_f32_cdab → weight CDAB
  modbus_regs[5] = modbus_regs[15];
  modbus_regs[6] = modbus_regs[16];

  // [17][18] → [7][8]: rw_int32 → long_int32
  modbus_regs[7] = modbus_regs[17];
  modbus_regs[8] = modbus_regs[18];

  // [19] → [9]: rw_uint32_hi → uint32 hi
  modbus_regs[9] = modbus_regs[19];
}

// ============================================================
// setup
// ============================================================
void setup() {
  pinMode(ENABLE_PIN, OUTPUT);
  digitalWrite(ENABLE_PIN, LOW);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // Инициализируем тестовые значения
  initTestValues();

  // Запускаем Modbus на Serial1, 19200 бод
  bus.begin(BAUD_RATE);
}

// ============================================================
// loop
// ============================================================
void loop() {
  // Обрабатываем Modbus запросы
  // bus.poll возвращает true если была активность (чтение или запись)
  bool activity = bus.poll(modbus_regs, 20);

  if (activity) {
    // Мигаем LED при активности
    digitalWrite(LED_PIN, HIGH);

    // Применяем записанные мастером значения
    applyWrittenValues();

    // Небольшая задержка для LED
    delay(5);
    digitalWrite(LED_PIN, LOW);
  }
}
