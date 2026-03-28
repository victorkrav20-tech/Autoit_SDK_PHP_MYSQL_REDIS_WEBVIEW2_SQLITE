# 🔧 Инструкция по сборке NetWebView2Lib.dll

## 📋 Требования

### 1. Visual Studio 2019 или 2022
Скачать: https://visualstudio.microsoft.com/downloads/

**Необходимые компоненты при установке:**
- ✅ .NET desktop development
- ✅ .NET Framework 4.8 SDK
- ✅ NuGet package manager

### 2. .NET Framework 4.8
Уже установлен на вашей системе ✓

## 🚀 Пошаговая сборка

### Шаг 1: Применить патч для Win7

Открыть `WebViewManager.cs` и найти строку 456-464:

**ЗАМЕНИТЬ:**
```csharp
// UI Setup on the main UI thread
InvokeOnUiThread(() => {
    _webView.Location = new Point(x, y);
    _webView.Size = new Size(width, height);
    // Attach the WebView to the AutoIt window/container
    SetParent(_webView.Handle, _parentHandle);
    _webView.Visible = false;
});
```

**НА:**
```csharp
// UI Setup on the main UI thread
InvokeOnUiThread(() => {
    _webView.Location = new Point(x, y);
    _webView.Size = new Size(width, height);
    _webView.Visible = false;
    
    // Try to attach to parent window (may fail on Win7/VirtualBox)
    try
    {
        SetParent(_webView.Handle, _parentHandle);
        OnMessageReceived?.Invoke("DEBUG|SetParent succeeded");
    }
    catch (Exception ex)
    {
        OnMessageReceived?.Invoke("WARNING|SetParent failed: " + ex.Message);
        // Continue without parent attachment - WebView will be standalone
    }
});
```

### Шаг 2: Открыть проект

1. Запустить Visual Studio
2. File → Open → Project/Solution
3. Выбрать `libs\WebView2\src\NetWebView2Lib.sln`

### Шаг 3: Восстановить NuGet пакеты

В Visual Studio:
- Tools → NuGet Package Manager → Package Manager Console
- Выполнить: `Update-Package -reinstall`

Или:
- Solution Explorer → правый клик на Solution → Restore NuGet Packages

### Шаг 4: Выбрать конфигурацию

В верхней панели выбрать:
- **Configuration:** Release
- **Platform:** x64 (для 64-bit) или x86 (для 32-bit)

### Шаг 5: Собрать проект

- Build → Rebuild Solution (Ctrl+Shift+B)

Или через командную строку:
```cmd
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" NetWebView2Lib.sln /p:Configuration=Release /p:Platform=x64
```

### Шаг 6: Найти собранную DLL

После успешной сборки DLL будет в:
- `libs\WebView2\src\bin\x64\Release\NetWebView2Lib.dll` (для x64)
- `libs\WebView2\src\bin\x86\Release\NetWebView2Lib.dll` (для x86)

### Шаг 7: Скопировать и зарегистрировать

1. Скопировать DLL в `libs\WebView2\bin\`
2. Запустить `libs\WebView2\bin\Unregister.au3` (удалить старую)
3. Запустить `libs\WebView2\bin\Register_web2.au3` (зарегистрировать новую)

## 🧪 Тестирование

После регистрации запустить на Win7 VM:
```
libs\WebView2\examples\Win7_VirtualBox_Test.au3
```

Если патч сработал, вы увидите:
```
[EVENT] DEBUG|SetParent succeeded
```
или
```
[EVENT] WARNING|SetParent failed: ...
```

Но Initialize НЕ должен падать с ошибкой!

## ❌ Возможные ошибки

### Ошибка: "NuGet packages are missing"
**Решение:** Tools → NuGet Package Manager → Restore NuGet Packages

### Ошибка: "The type or namespace name 'WebView2' could not be found"
**Решение:** Установить пакет вручную:
```
Install-Package Microsoft.Web.WebView2 -Version 1.0.3650.58
```

### Ошибка: "MSB3073: The command regasm exited with code 1"
**Решение:** Запустить Visual Studio от администратора

## 📝 Примечания

- Патч делает SetParent() необязательным
- WebView2 будет работать как standalone окно если SetParent() упадёт
- Это может вызвать проблемы с позиционированием, но Initialize не упадёт
- Для полного решения нужен более сложный патч с альтернативным методом прикрепления

## 🆘 Если не получается собрать

Напиши мне и я помогу:
1. Какая ошибка при сборке?
2. Какая версия Visual Studio?
3. Скриншот ошибки
