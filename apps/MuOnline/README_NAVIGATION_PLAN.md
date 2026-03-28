# 🗺️ MU Online Bot - План системы навигации и автопилота

## 🎯 Цель
Создать систему записи и выполнения маршрутов для автоматической навигации персонажа по игровому миру.

---

## 📋 Архитектура системы

### 🔹 Принцип работы
1. **Запись маршрута:** Пользователь телепортируется в город, проходит путь вручную, программа записывает контрольные точки
2. **Выполнение маршрута:** Программа автоматически телепортирует персонажа и проходит по записанным точкам
3. **Проверка достижения:** OCR координат для определения позиции персонажа
4. **Обход препятствий:** Если застряли - пробуем соседние точки, крайний случай - телепорт заново

### 🔹 Структура файлов маршрутов
```
data/routes/
  ├── Devias_Dungeon.json
  ├── Lorencia_Arena.json
  └── Noria_Boss_Run.json
```

**Формат файла маршрута:**
```json
{
  "name": "Devias → Dungeon",
  "description": "Маршрут от Девиаса до подземелья",
  "city_name": "Devias",
  "city_y": 533,
  "waypoints": [
    {
      "x": 400,
      "y": 300,
      "wait_coords": "145,230",
      "description": "Выход из города",
      "timeout": 10
    },
    {
      "x": 450,
      "y": 250,
      "wait_coords": "160,215",
      "description": "Поворот у моста",
      "timeout": 10
    }
  ],
  "markers_check": ["helper_active", "in_city"],
  "created": "2026-03-11 22:30:00",
  "version": "1.0"
}
```

---

## 🛠️ Новые функции для разработки

### Файл: `Mu_Online_Routes.au3` (новый)

#### 1. Инициализация и управление файлами
```autoit
Func _Routes_Init()
    ; Создание папки data/routes/ если её нет
    ; Инициализация глобальных переменных
EndFunc

Func _Routes_GetList()
    ; Возвращает массив всех файлов маршрутов из data/routes/
    ; Return: массив имён файлов ["Devias_Dungeon.json", ...]
EndFunc

Func _Routes_Load($sFileName)
    ; Загружает маршрут из JSON файла
    ; Param: $sFileName - имя файла (например "Devias_Dungeon.json")
    ; Return: структура маршрута или False при ошибке
EndFunc

Func _Routes_Save($sFileName, $aRoute)
    ; Сохраняет маршрут в JSON файл
    ; Param: $sFileName - имя файла
    ; Param: $aRoute - структура маршрута
    ; Return: True/False
EndFunc

Func _Routes_Delete($sFileName)
    ; Удаляет файл маршрута
    ; Param: $sFileName - имя файла
    ; Return: True/False
EndFunc
```

#### 2. Запись маршрута
```autoit
Func _Routes_StartRecording($sCityName, $iCityY, $sRouteName)
    ; Начинает запись нового маршрута
    ; 1. Телепортируется в город через _Send_TeleportToCity()
    ; 2. Ждёт 3 секунды
    ; 3. Делает OCR для получения первых координат
    ; 4. Создаёт структуру маршрута с первой точкой
    ; Param: $sCityName - название города
    ; Param: $iCityY - Y координата города для телепорта (533/551/569)
    ; Param: $sRouteName - имя маршрута
    ; Return: True/False
EndFunc

Func _Routes_AddWaypoint($sDescription = "")
    ; Добавляет новую контрольную точку в текущий маршрут
    ; 1. Делает скриншот и OCR
    ; 2. Получает текущие координаты персонажа
    ; 3. Получает позицию мыши относительно окна (куда кликнул пользователь)
    ; 4. Добавляет точку в массив waypoints
    ; Param: $sDescription - описание точки (опционально)
    ; Return: True/False
EndFunc

Func _Routes_StopRecording($sFileName)
    ; Завершает запись и сохраняет маршрут
    ; Param: $sFileName - имя файла для сохранения
    ; Return: True/False
EndFunc

Func _Routes_CancelRecording()
    ; Отменяет запись маршрута без сохранения
    ; Return: True/False
EndFunc
```

#### 3. Получение координат
```autoit
Func _Routes_GetCurrentCoords($hWnd)
    ; Получает текущие координаты персонажа через OCR
    ; 1. Делает фоновый скриншот
    ; 2. Вырезает область с координатами
    ; 3. Делает OCR
    ; 4. Парсит координаты (формат "123,456")
    ; Param: $hWnd - handle окна игры
    ; Return: строка "X,Y" или "" при ошибке
EndFunc

Func _Routes_GetMousePosInWindow($hWnd)
    ; Получает позицию мыши относительно окна
    ; Param: $hWnd - handle окна
    ; Return: массив [X, Y] или False
EndFunc

Func _Routes_IsNearCoords($sCoords1, $sCoords2, $iTolerance = 5)
    ; Проверяет близость двух координат
    ; Param: $sCoords1 - координаты "X1,Y1"
    ; Param: $sCoords2 - координаты "X2,Y2"
    ; Param: $iTolerance - допустимое отклонение (по умолчанию ±5)
    ; Return: True если координаты близки, False если нет
EndFunc
```

#### 4. Выполнение маршрута
```autoit
Func _Routes_Execute($sFileName, $hWnd)
    ; Выполняет маршрут из файла
    ; 1. Загружает маршрут из JSON
    ; 2. Проверяет маркеры (если указаны)
    ; 3. Телепортируется в город
    ; 4. Проходит по всем waypoints
    ; 5. Логирует прогресс
    ; Param: $sFileName - имя файла маршрута
    ; Param: $hWnd - handle окна игры
    ; Return: True если успешно, False при ошибке
EndFunc

Func _Routes_MoveTo($hWnd, $iTargetX, $iTargetY, $sWaitCoords, $iTimeout = 30)
    ; Движение к целевой точке с проверкой достижения
    ; 1. Кликает в целевую точку через _Send_Click()
    ; 2. Каждую секунду проверяет координаты через OCR
    ; 3. Если достигли (±5 пикселей) - возвращает True
    ; 4. Если таймаут - возвращает False
    ; Param: $hWnd - handle окна
    ; Param: $iTargetX, $iTargetY - координаты клика
    ; Param: $sWaitCoords - ожидаемые координаты "X,Y"
    ; Param: $iTimeout - максимальное время ожидания (секунды)
    ; Return: True/False
EndFunc

Func _Routes_CheckMovement($hWnd, $sOldCoords)
    ; Проверяет сдвинулся ли персонаж
    ; Param: $hWnd - handle окна
    ; Param: $sOldCoords - старые координаты "X,Y"
    ; Return: True если сдвинулся, False если нет
EndFunc
```

#### 5. Обход препятствий
```autoit
Func _Routes_TryAvoidObstacle($hWnd, $iTargetX, $iTargetY, $iAttempts = 8)
    ; Пробует обойти препятствие кликами в соседние точки
    ; 1. Получает текущие координаты
    ; 2. Пробует 8 направлений вокруг целевой точки (±30 пикселей)
    ; 3. После каждого клика проверяет сдвинулся ли персонаж
    ; 4. Если сдвинулся - возвращает True
    ; Param: $hWnd - handle окна
    ; Param: $iTargetX, $iTargetY - целевая точка
    ; Param: $iAttempts - количество попыток (по умолчанию 8)
    ; Return: True если обошли, False если застряли
EndFunc

Func _Routes_RetryFromStart($hWnd, $aRoute, $iRetryCount)
    ; Телепортируется заново и начинает маршрут сначала
    ; Param: $hWnd - handle окна
    ; Param: $aRoute - структура маршрута
    ; Param: $iRetryCount - текущий счётчик попыток
    ; Return: True если можно продолжать, False если превышен лимит (3 попытки)
EndFunc
```

---

## 🎨 Изменения в GUI (Mu_Online_Main.au3)

### Новая секция: "📝 Запись маршрута"
```autoit
; Dropdown выбора города
GUICtrlCreateLabel("Город:", ...)
$g_idCombo_City = GUICtrlCreateCombo("", ...)
GUICtrlSetData($g_idCombo_City, "Devias (533)|Lorencia (551)|Noria (569)", "Devias (533)")

; Input имени маршрута
GUICtrlCreateLabel("Имя маршрута:", ...)
$g_idInput_RouteName = GUICtrlCreateInput("", ...)

; Кнопки управления записью
$g_idButton_StartRecord = GUICtrlCreateButton("🔴 Начать запись", ...)
$g_idButton_AddPoint = GUICtrlCreateButton("➕ Добавить точку", ...)
$g_idButton_SaveRoute = GUICtrlCreateButton("💾 Сохранить маршрут", ...)
$g_idButton_CancelRecord = GUICtrlCreateButton("❌ Отменить", ...)

; Счётчик точек
$g_idLabel_PointsCount = GUICtrlCreateLabel("Точек: 0", ...)
```

### Новая секция: "🚀 Автопилот"
```autoit
; Dropdown выбора маршрута
GUICtrlCreateLabel("Маршрут:", ...)
$g_idCombo_Route = GUICtrlCreateCombo("", ...)
; Заполняется списком файлов из data/routes/

; Кнопки управления автопилотом
$g_idButton_StartAutopilot = GUICtrlCreateButton("▶️ Запустить", ...)
$g_idButton_StopAutopilot = GUICtrlCreateButton("⏹️ Остановить", ...)

; Checkbox проверки маркеров
$g_idCheckbox_CheckMarkers = GUICtrlCreateCheckbox("Проверять маркеры", ...)

; Прогресс выполнения
$g_idLabel_Progress = GUICtrlCreateLabel("Готов к запуску", ...)
$g_idProgress_Route = GUICtrlCreateProgress(...)
```

### Новые обработчики кнопок
```autoit
Func _Button_StartRecord()
    ; Обработчик кнопки "Начать запись"
EndFunc

Func _Button_AddPoint()
    ; Обработчик кнопки "Добавить точку"
EndFunc

Func _Button_SaveRoute()
    ; Обработчик кнопки "Сохранить маршрут"
EndFunc

Func _Button_CancelRecord()
    ; Обработчик кнопки "Отменить"
EndFunc

Func _Button_StartAutopilot()
    ; Обработчик кнопки "Запустить автопилот"
EndFunc

Func _Button_StopAutopilot()
    ; Обработчик кнопки "Остановить автопилот"
EndFunc

Func _Button_RefreshRoutes()
    ; Обновляет список маршрутов в Combo
EndFunc
```

---

## 🔄 Алгоритм работы

### Запись маршрута:
1. Пользователь выбирает город из списка
2. Вводит имя маршрута
3. Нажимает "Начать запись"
   - Программа телепортирует в город
   - Делает OCR и записывает первую точку (стартовая позиция)
4. Пользователь управляет персонажем вручную
5. Доходит до нужного места и нажимает "Добавить точку"
   - Программа делает OCR координат
   - Записывает координаты клика и ожидаемые координаты персонажа
6. Повторяет шаг 4-5 сколько нужно
7. Нажимает "Сохранить маршрут"
   - Программа сохраняет JSON файл в `data/routes/`

### Выполнение маршрута:
1. Пользователь выбирает маршрут из списка
2. Нажимает "Запустить автопилот"
3. Программа:
   - Загружает маршрут из JSON
   - Проверяет маркеры (если включено)
   - Телепортируется в город
   - Для каждой точки:
     - Кликает в координаты
     - Проверяет достижение через OCR (каждую секунду)
     - Если не дошли за 30 сек → пробует обойти препятствие
     - Если не помогло → телепорт заново (макс 3 попытки)
   - Логирует прогресс в GUI

---

## 📊 Глобальные переменные

```autoit
; Состояние записи маршрута
Global $g_bRecording = False
Global $g_aCurrentRoute = ""
Global $g_iWaypointsCount = 0

; Состояние автопилота
Global $g_bAutopilotRunning = False
Global $g_sCurrentRouteFile = ""
Global $g_iCurrentWaypoint = 0

; Настройки
Global $g_iMovementTimeout = 30        ; Таймаут ожидания движения (сек)
Global $g_iCoordsTolerance = 5         ; Допуск координат (пикселей)
Global $g_iObstacleOffset = 30         ; Смещение для обхода препятствий
Global $g_iMaxRetries = 3              ; Максимум попыток телепорта заново
```

---

## ✅ Этапы разработки

### Этап 1: Базовая инфраструктура
- [ ] Создать файл `Mu_Online_Routes.au3`
- [ ] Реализовать `_Routes_Init()`
- [ ] Реализовать `_Routes_GetList()`
- [ ] Реализовать `_Routes_Load()` и `_Routes_Save()`
- [ ] Создать папку `data/routes/`

### Этап 2: Получение координат
- [ ] Реализовать `_Routes_GetCurrentCoords()` (на базе существующего OCR)
- [ ] Реализовать `_Routes_GetMousePosInWindow()`
- [ ] Реализовать `_Routes_IsNearCoords()`
- [ ] Протестировать точность OCR координат

### Этап 3: Запись маршрута
- [ ] Реализовать `_Routes_StartRecording()`
- [ ] Реализовать `_Routes_AddWaypoint()`
- [ ] Реализовать `_Routes_StopRecording()`
- [ ] Добавить GUI элементы для записи
- [ ] Протестировать запись простого маршрута

### Этап 4: Выполнение маршрута
- [ ] Реализовать `_Routes_MoveTo()`
- [ ] Реализовать `_Routes_CheckMovement()`
- [ ] Реализовать `_Routes_Execute()`
- [ ] Добавить GUI элементы для автопилота
- [ ] Протестировать выполнение простого маршрута

### Этап 5: Обход препятствий
- [ ] Реализовать `_Routes_TryAvoidObstacle()`
- [ ] Реализовать `_Routes_RetryFromStart()`
- [ ] Протестировать на маршруте с препятствиями

### Этап 6: Интеграция с маркерами
- [ ] Добавить проверку маркеров перед выполнением
- [ ] Добавить проверку маркеров между точками
- [ ] Добавить остановку при критических маркерах

### Этап 7: Полировка
- [ ] Добавить подробное логирование
- [ ] Добавить визуализацию прогресса
- [ ] Добавить возможность паузы/возобновления
- [ ] Создать примеры маршрутов

---

## 🎯 Ожидаемый результат

После реализации пользователь сможет:
1. ✅ Записать любой маршрут в игре
2. ✅ Сохранить маршрут в файл
3. ✅ Выбрать маршрут из списка
4. ✅ Запустить автопилот
5. ✅ Персонаж автоматически пройдёт весь маршрут
6. ✅ Система обойдёт препятствия или переtelepортируется
7. ✅ Можно запустить несколько копий программы для разных окон

---

## 🔧 Технические требования

- Использовать существующие функции OCR из `Mu_Online_Main.au3`
- Использовать существующие функции телепорта и кликов из `Mu_Online_Send.au3`
- Использовать JSON библиотеку для сохранения маршрутов
- Все операции должны быть фоновыми (без активации окна)
- Логирование всех действий через `_Logger_Write()`

---

**Дата создания:** 2026-03-11
**Версия:** 1.0
**Статус:** План готов к реализации
