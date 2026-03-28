# ⚛️ ИНСТРУМЕНТЫ AI - SDK Universal MCP

**Назначение:** Краткая справка по единому MCP серверу для работы с AutoIt SDK  
**Когда читать:** Только по явному указанию пользователя  
**Версия:** 5.0 | **Дата:** 23.02.2026

---

## 🎯 ГЛАВНОЕ ПРАВИЛО

**При работе с .au3 файлами ВСЕГДА используй MCP функции вместо встроенных инструментов Kiro!**

❌ НЕ используй: `readCode`, `strReplace`, `grepSearch` для AutoIt
✅ Используй: MCP функции `sdk-universal`

**Преимущества:**
- Специальный парсер для AutoIt (понимает структуру Func/EndFunc)
- Кеш в памяти (поиск < 1мс, 604 функции)
- Безопасность (проверка дубликатов, автодобавление EndFunc)
- Экономия токенов (только нужное)
- Автоматическая валидация

---

## 📦 SDK UNIVERSAL MCP

**Единый сервер с двумя процессами:**
- `sdk_autoit` - специализированные функции для AutoIt
- `sdk_universal` - универсальные функции для любых языков

---

## 🔧 AUTOIT ПРОЦЕСС (sdk_autoit)

### 📖 Чтение файлов

**Обзор:**
- `read_structure(file_path)` - структурный обзор (~50 строк: header, includes, globals count, preload, loop, функции)
- `read_file(file_path)` - детальный обзор (globals с usage, preload код, loop код, функции)
- `read_file_full(file_path, stage=1)` - постраничное чтение без комментариев (600 строк/stage, умная обрезка по EndFunc)

**Модульное чтение:**
- `read_header(file_path)` - шапка до #include
- `read_includes(file_path)` - блок #include директив
- `read_globals(file_path)` - блок Global переменных
- `read_preload(file_path)` - инициализация после globals до Func/While
- `read_loop(file_path)` - While цикл

**Функции:**
- `read_function(function_name, detail_level="medium", file_path=null)` - чтение из кэша
  - `minimal` - код, файл, строки, usages_count
  - `medium` - + usages, complexity, params_count
  - `full` - + signature, calls_functions, код вызывающих
  - `file_path` - опционально при дубликатах

### ✏️ Редактирование

**Модульная запись (требует чтения, timeout 30 сек):**
- `write_header(file_path, new_code)`
- `write_includes(file_path, new_code)`
- `write_globals(file_path, new_code)` - ⚠️ заменяет ВСЕ globals
- `write_preload(file_path, new_code)`
- `write_loop(file_path, new_code)`

**Функции:**
- `write_function(function_name, new_code, file_path=null)` - замена функции
  - ✨ Автоматически добавляет EndFunc если отсутствует
  - ⚠️ Требует чтения (timeout 30 сек)
  - `file_path` - опционально при дубликатах
  
- `add_function(file_path, function_code, position="end", target_function=null, add_separator=true)`
  - Позиции: `end`, `after`, `before`
  
- `add_global_var(file_path, global_code)` - добавление после последней Global

- `delete_function(function_name, file_path=null)` - удаление с шапкой
  - ⚠️ Требует чтения (timeout 30 сек)
  - `file_path` - опционально при дубликатах
  
- `move_function(file_path, function_name, position, target_function)` - перемещение

### ✅ Проверка и запуск

- `validate_syntax(file_path, detailed=false, check_standards=true, check_structure=true)`
  - Au3Check + стандарты (префиксы, венгерская нотация, header, документация)
  - `detailed=true` - + проверка соседних файлов в папке
  
- `autoit.run_script(file_path, timeout=10, kill_on_timeout=true)` - запуск с перехватом ConsoleWrite

- `fast_terminal(command, cwd=null, timeout=3)` - быстрое выполнение команд (гарантированный ответ за 3 сек)

### 📊 Аналитика проекта

**Базовая:**
- `analyze_project(scope, folder_class, folder_name, detail_level)` - статистика (файлы, строки, функции, сложность)
- `analyze_quality(scope, folder_class, folder_name)` - оценка качества 0-100
- `analyze_complexity(scope, folder_class, folder_name, threshold=10)` - анализ сложности функций
- `analyze_dependencies(scope, folder_class, folder_name, target=null)` - зависимости между функциями
- `analyze_issues(scope, folder_class, folder_name, severity="all")` - детальный анализ проблем

**Полная:**
- `analyze_full_summary(scope, folder_class, folder_name)` - полная сводка (объединяет все 5 аналитик + рекомендации, экспорт в MD)
- `batch_analyze(mode, scope, folder_class, folder_name)` - массовый анализ
  - `mode: full` - весь проект (workspace + libs + apps + подпапки 1 уровня)
  - `mode: single` - одна папка

**Scope:** `workspace`, `folder_class`, `folder_name`  
**Folder class:** `libs`, `apps`

---

## 🌐 UNIVERSAL ПРОЦЕСС (sdk_universal)

**Работает для ЛЮБЫХ языков (AutoIt, Python, PHP, C#, JS, HTML и т.д.)**

### 🔍 find_usages

Поиск использований строк/переменных/функций в проекте.

**Параметры:**
- `search_strings` (обязательный) - список строк для поиска
- `paths` (опционально) - папки для поиска (default: весь проект)
- `detail_level` (опционально) - summary | detailed | full (default: summary)
- `case_sensitive` (опционально) - true | false (default: true)
- `whole_word` (опционально) - true | false (default: false)
- `file_pattern` (опционально) - фильтр файлов "*.au3" (default: все)
- `use_regex` (опционально) - true | false (default: false)

**Режимы:**
- `summary` - общий счёт + разбивка по файлам
- `detailed` - файлы с номерами строк
- `full` - файлы с номерами строк + контекст кода

**Примеры:**
```python
# Простой поиск
SDK_Mcp_Tool("sdk.find_usages", '{"search_strings": ["$g_MySQL"], "detail_level": "summary"}')

# Множественный поиск
SDK_Mcp_Tool("sdk.find_usages", '{"search_strings": ["$g_MySQL", "$g_Redis"], "detail_level": "detailed", "paths": ["libs/"]}')

# Regex - все глобальные переменные
SDK_Mcp_Tool("sdk.find_usages", '{"search_strings": ["\\\\$g_\\\\w+"], "use_regex": true}')

# Regex - все функции с префиксом
SDK_Mcp_Tool("sdk.find_usages", '{"search_strings": ["_MySQL\\\\w+"], "use_regex": true, "file_pattern": "*.au3"}')
```

### 📁 file_search

Поиск файлов по glob паттерну с фильтрацией и группировкой.

**Параметры:**
- `pattern` (обязательный) - glob паттерн "*.au3", "test_*.py", "**/*.json"
- `paths` (опционально) - папки для поиска
- `recursive` (опционально) - глубина: 0=папка, 1=+1 уровень, 2=+2 уровня, -1=все (default: 2)
- `case_sensitive` (опционально) - чувствительность к регистру (default: false)
- `include_hidden` (опционально) - включить скрытые файлы (default: false)
- `extensions` (опционально) - фильтр по расширениям [".au3", ".py"]
- `exclude_folders` (опционально) - исключить папки ["node_modules", ".git"]
- `max_results` (опционально) - макс результатов (default: 1000)
- `min_size`, `max_size` (опционально) - размер файла в байтах
- `detail_level` (опционально) - summary | detailed | full (default: summary)
- `sort_by` (опционально) - name | size | date (default: name)
- `group_by` (опционально) - extension | folder | none (default: none)

**Примеры:**
```python
# Простой поиск
SDK_Mcp_Tool("sdk.file_search", '{"pattern": "*.au3"}')

# С группировкой
SDK_Mcp_Tool("sdk.file_search", '{"pattern": "*.au3", "detail_level": "detailed", "group_by": "folder"}')

# Найти большие файлы
SDK_Mcp_Tool("sdk.file_search", '{"pattern": "*", "min_size": 1048576, "sort_by": "size"}')
```



### ⏰ find_last

Поиск последних изменённых файлов (для отладки и мониторинга).

**Параметры:**
- `count` (опционально) - количество файлов (default: 10)
- `time_window` (опционально) - временное окно "5m", "30m", "2h", "1d", "7d"
- `paths` (опционально) - папки для поиска
- `pattern` (опционально) - glob паттерн (default: "*")
- `extensions` (опционально) - фильтр по расширениям
- `exclude_folders` (опционально) - исключить папки
- `detail_level` (опционально) - summary | detailed | full (default: summary)

**Примеры:**
```python
# Последние 5 файлов
SDK_Mcp_Tool("sdk.find_last", '{"count": 5}')

# Что я только что редактировал?
SDK_Mcp_Tool("sdk.find_last", '{"count": 5, "time_window": "5m", "extensions": [".au3"]}')

# Изменения за последний час в libs/
SDK_Mcp_Tool("sdk.find_last", '{"count": 20, "paths": ["libs/"], "time_window": "1h"}')
```

---

## ⚡ ТИПОВЫЕ СЦЕНАРИИ

### 1. Изучить файл
```
read_structure → read_file → read_function (для конкретных)
```

### 2. Изменить функцию
```
read_function → write_function → validate_syntax
```

### 3. Добавить функцию
```
add_function → validate_syntax
```

### 4. Удалить функцию
```
read_function → delete_function → validate_syntax
```

### 5. Найти использования
```
find_usages (sdk_universal) → анализ результатов
```

### 6. Протестировать
```
validate_syntax → run_script → анализ output
```

### 7. Анализ проекта
```
analyze_full_summary → экспорт в MD → рекомендации
```

### 8. Найти последние изменения
```
find_last (sdk_universal) → анализ изменений
```

---

## ⚠️ ВАЖНЫЕ ПРАВИЛА

### Безопасность при дубликатах
- `read_function`, `write_function`, `delete_function` проверяют дубликаты
- Если найдено >1 функции с одинаковым именем → требуется `file_path`
- Всегда указывай `file_path` при работе с функциями, которые могут дублироваться

### Автоматизация
- `write_function` автоматически добавляет `EndFunc` если отсутствует
- Поддерживает любой регистр: `EndFunc`, `endfunc`, `ENDFUNC`
- Не дублирует `EndFunc` если уже есть

### Защита записи
- Все `write_*` команды требуют предварительного чтения (timeout 30 сек)
- Это защита от случайных изменений
- Сначала `read_*`, потом `write_*`

### Валидация
- После редактирования → `validate_syntax`
- `validate_syntax` проверяет: Au3Check + стандарты + структуру
- `detailed=true` → + проверка соседних файлов

### Область применения
- MCP работает только с .au3 файлами в `libs/` и `apps/`
- Для других файлов (.md, .json, .php) используй встроенные инструменты Kiro
- Universal функции работают для ВСЕХ языков

---

## 📚 СПРАВКА

**Быстрая справка:**
- `SDK_Mcp_Tool("help.autoit", "{}")` - AutoIt функции
- `SDK_Mcp_Tool("help.sdk", "{}")` - Universal функции

**Полная документация:**
- `SDK_Mcp_Tool("help.autoit.full", "{}")` - AutoIt полная
- `SDK_Mcp_Tool("help.sdk.full", "{}")` - Universal полная

---

**Версия:** 5.0 | **Дата:** 23.02.2026  
**Статус:** Справочный документ (читать только по указанию)
