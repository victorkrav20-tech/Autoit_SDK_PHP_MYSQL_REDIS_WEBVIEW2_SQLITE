using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

// --- Версия 1.1.0 - SCADA Edition с усиленной защитой ---

namespace NetWebView2Lib
{
    // --- 1. ИНТЕРФЕЙС СОБЫТИЙ (Что C# отправляет в AutoIt) ---
    /// <summary>
    /// События, отправляемые из C# в AutoIt.
    /// </summary>
    [Guid("B2C3D4E5-F6A7-4B6C-9D0E-1F2A3B4C5D6E")]
    [InterfaceType(ComInterfaceType.InterfaceIsIDispatch)]
    [ComVisible(true)]
    public interface IWebViewEvents
    {
        /// <summary>
        /// Срабатывает при получении сообщения от WebView.
        /// </summary>
        /// <param name="message">Содержимое сообщения.</param>
        [DispId(1)] void OnMessageReceived(string message);
        /// <summary>
        /// Срабатывает при начале навигации.
        /// </summary>
        /// <param name="url">URL, на который происходит переход.</param> 
        [DispId(2)] void OnNavigationStarting(string url);
        /// <summary>
        /// Срабатывает при завершении навигации.
        /// </summary>
        /// <param name="isSuccess">Указывает, была ли навигация успешной.</param>  
        /// <param name="webErrorStatus">Код статуса веб-ошибки.</param> 
        [DispId(3)] void OnNavigationCompleted(bool isSuccess, int webErrorStatus);
        /// <summary>
        /// Срабатывает при изменении заголовка документа.
        /// </summary>
        /// <param name="newTitle">Новый заголовок документа.</param> 
        [DispId(4)] void OnTitleChanged(string newTitle);

        /// <summary>Срабатывает при запросе пользовательского контекстного меню.</summary>
        /// <param name="menuData">JSON строка с контекстной информацией (тип, ссылка, выделение).</param>
        [DispId(6)] void OnContextMenu(string menuData);

        /// <summary>Срабатывает при изменении масштаба.</summary>
        [DispId(10)] void OnZoomChanged(double factor);
        /// <summary>Срабатывает когда браузер получает фокус.</summary>
        [DispId(11)] void OnBrowserGotFocus(int reason);
        /// <summary>Срабатывает когда браузер теряет фокус.</summary>
        [DispId(12)] void OnBrowserLostFocus(int reason);
        /// <summary>
        /// Срабатывает при изменении URL.
        /// </summary>
        /// <param name="newUrl">Новый URL.</param> 
        [DispId(13)] void OnURLChanged(string newUrl);

        /// <summary>Срабатывает при запросе контекстного меню (упрощённая версия для AutoIt).</summary>
        /// <param name="linkUrl">URL ссылки под курсором, если есть.</param>
        /// <param name="x">Координата X.</param>
        /// <param name="y">Координата Y.</param>
        /// <param name="selectionText">Выделенный текст под курсором, если есть.</param>
        [DispId(190)] void OnContextMenuRequested(string linkUrl, int x, int y, string selectionText);
    }

    /// <summary>
    /// Действия, доступные для вызова из AutoIt.
    /// </summary>
    [Guid("CCB12345-6789-4ABC-DEF0-1234567890AB")]
    [InterfaceType(ComInterfaceType.InterfaceIsIDispatch)]
    [ComVisible(true)]
    public interface IWebViewActions
    {
        /// <summary>Инициализировать WebView.</summary>
        [DispId(101)] void Initialize(object parentHandle, string userDataFolder, int x = 0, int y = 0, int width = 0, int height = 0);
        /// <summary>Перейти по URL.</summary>
        [DispId(102)] void Navigate(string url);
        /// <summary>Перейти к HTML контенту.</summary>
        [DispId(103)] void NavigateToString(string htmlContent);
        /// <summary>Выполнить JavaScript.</summary>
        [DispId(104)] void ExecuteScript(string script);
        /// <summary>Изменить размер WebView.</summary>
        [DispId(105)] void Resize(int width, int height);
        /// <summary>Очистить ресурсы.</summary>
        [DispId(106)] void Cleanup();
        /// <summary>Получить объект Bridge.</summary>
        [DispId(107)] IBridgeActions GetBridge();
        /// <summary>Тест DevTools событий (отправляет тестовые сообщения).</summary>
        [DispId(120)] void TestDevToolsEvents();
        /// <summary>Экспортировать в PDF.</summary>
        [DispId(108)] void ExportToPdf(string filePath);
        /// <summary>Проверить готовность.</summary>
        [DispId(109)] bool IsReady();
        /// <summary>Включить/Отключить контекстное меню.</summary>
        [DispId(110)] void SetContextMenuEnabled(bool enabled);
        /// <summary>Заблокировать WebView.</summary>
        [DispId(111)] void LockWebView();
        /// <summary>Отключить функции браузера.</summary>
        [DispId(112)] void DisableBrowserFeatures();
        /// <summary>Назад.</summary>
        [DispId(113)] void GoBack();
        /// <summary>Сбросить масштаб.</summary>
        [DispId(114)] void ResetZoom();
        /// <summary>Внедрить CSS.</summary>
        [DispId(115)] void InjectCss(string cssCode);
        /// <summary>Очистить внедрённый CSS.</summary>
        [DispId(116)] void ClearInjectedCss();
        /// <summary>Переключить подсветку аудита.</summary>
        [DispId(117)] void ToggleAuditHighlights(bool enable);
        /// <summary>Установить состояние AdBlock.</summary>
        [DispId(118)] void SetAdBlock(bool active);
        /// <summary>Добавить правило блокировки.</summary>
        [DispId(119)] void AddBlockRule(string domain);
        /// <summary>Очистить все правила блокировки.</summary>
        [DispId(120)] void ClearBlockRules();
        /// <summary>Вперёд.</summary>
        [DispId(121)] void GoForward();
        /// <summary>Получить HTML исходник.</summary>
        [DispId(122)] void GetHtmlSource();
        /// <summary>Получить выделенный текст.</summary>
        [DispId(123)] void GetSelectedText();
        /// <summary>Установить масштаб.</summary>
        [DispId(124)] void SetZoom(double factor);
        /// <summary>Разобрать JSON во внутреннее хранилище.</summary>
        [DispId(125)] bool ParseJsonToInternal(string json);
        /// <summary>Получить значение из внутреннего JSON.</summary>
        [DispId(126)] string GetInternalJsonValue(string path);
        /// <summary>Очистить данные браузера.</summary>
        [DispId(127)] void ClearBrowserData();
        /// <summary>Перезагрузить.</summary>
        [DispId(128)] void Reload();
        /// <summary>Остановить загрузку.</summary>
        [DispId(129)] void Stop();
        /// <summary>Показать интерфейс печати.</summary>
        [DispId(130)] void ShowPrintUI();
        /// <summary>Установить состояние звука.</summary>
        [DispId(131)] void SetMuted(bool muted);
        /// <summary>Проверить отключён ли звук.</summary>
        [DispId(132)] bool IsMuted();
        /// <summary>Установить User Agent.</summary>
        [DispId(133)] void SetUserAgent(string userAgent);
        /// <summary>Получить заголовок документа.</summary>
        [DispId(134)] string GetDocumentTitle();
        /// <summary>Получить исходный URL.</summary>
        [DispId(135)] string GetSource();
        /// <summary>Включить/Отключить скрипты.</summary>
        [DispId(136)] void SetScriptEnabled(bool enabled);
        /// <summary>Включить/Отключить веб-сообщения.</summary>
        [DispId(137)] void SetWebMessageEnabled(bool enabled);
        /// <summary>Включить/Отключить строку состояния.</summary>
        [DispId(138)] void SetStatusBarEnabled(bool enabled);
        /// <summary>Захватить превью.</summary>
        [DispId(139)] void CapturePreview(string filePath, string format);
        /// <summary>Вызвать метод CDP.</summary>
        [DispId(140)] void CallDevToolsProtocolMethod(string methodName, string parametersJson);
        /// <summary>Получить cookies.</summary>
        [DispId(141)] void GetCookies(string channelId);
        /// <summary>Добавить cookie.</summary>
        [DispId(142)] void AddCookie(string name, string value, string domain, string path);
        /// <summary>Удалить cookie.</summary>
        [DispId(143)] void DeleteCookie(string name, string domain, string path);
        /// <summary>Удалить все cookies.</summary>
        [DispId(144)] void DeleteAllCookies();

        /// <summary>Печать.</summary>
        [DispId(145)] void Print();
        /// <summary>Добавить расширение.</summary>
        [DispId(150)] void AddExtension(string extensionPath);
        /// <summary>Удалить расширение.</summary>
        [DispId(151)] void RemoveExtension(string extensionId);

        /// <summary>Проверить можно ли вернуться назад.</summary>
        [DispId(162)] bool GetCanGoBack();
        /// <summary>Проверить можно ли перейти вперёд.</summary>
        [DispId(163)] bool GetCanGoForward();
        /// <summary>Получить ID процесса браузера.</summary>
        [DispId(164)] uint GetBrowserProcessId();
        /// <summary>Закодировать строку для URL.</summary>
        [DispId(165)] string EncodeURI(string value);
        /// <summary>Декодировать URL строку.</summary>
        [DispId(166)] string DecodeURI(string value);
        /// <summary>Закодировать строку в Base64.</summary>
        [DispId(167)] string EncodeB64(string value);
        /// <summary>Декодировать Base64 строку.</summary>
        [DispId(168)] string DecodeB64(string value);

        // --- НОВЫЕ УНИФИЦИРОВАННЫЕ НАСТРОЙКИ (СВОЙСТВА) ---
        /// <summary>Проверить включены ли DevTools.</summary>
        [DispId(170)] bool AreDevToolsEnabled { get; set; }
        /// <summary>Проверить включены ли стандартные контекстные меню.</summary>
        [DispId(171)] bool AreDefaultContextMenusEnabled { get; set; }
        /// <summary>Проверить включены ли стандартные диалоги скриптов.</summary>
        [DispId(172)] bool AreDefaultScriptDialogsEnabled { get; set; }
        /// <summary>Проверить включены ли клавиши ускорения браузера.</summary>
        [DispId(173)] bool AreBrowserAcceleratorKeysEnabled { get; set; }
        /// <summary>Проверить включена ли строка состояния.</summary>
        [DispId(174)] bool IsStatusBarEnabled { get; set; }
        /// <summary>Получить/Установить масштаб.</summary>
        [DispId(175)] double ZoomFactor { get; set; }
        /// <summary>Установить цвет фона (Hex строка).</summary>
        [DispId(176)] string BackColor { get; set; }
        /// <summary>Проверить разрешены ли host объекты.</summary>
        [DispId(177)] bool AreHostObjectsAllowed { get; set; }
        /// <summary>Получить/Установить привязку (изменение размера).</summary>
        [DispId(178)] int Anchor { get; set; }
        /// <summary>Получить/Установить стиль границы.</summary>
        [DispId(179)] int BorderStyle { get; set; }

        // --- НОВЫЕ УНИФИЦИРОВАННЫЕ МЕТОДЫ ---
        /// <summary>Установить масштаб (обёртка).</summary>
        [DispId(180)] void SetZoomFactor(double factor);
        /// <summary>Открыть окно DevTools.</summary>
        [DispId(181)] void OpenDevToolsWindow();
        /// <summary>Установить фокус на WebView.</summary>
        [DispId(182)] void WebViewSetFocus();
        /// <summary>Проверить разрешены ли всплывающие окна браузера или перенаправлены в то же окно.</summary>
        [DispId(183)] bool AreBrowserPopupsAllowed { get; set; }
        /// <summary>Добавить скрипт, который выполняется при каждой загрузке страницы (постоянное внедрение).</summary>
        [DispId(184)] void AddInitializationScript(string script);
        /// <summary>Привязывает внутренние JSON данные к переменной браузера.</summary>
        [DispId(185)] bool BindJsonToBrowser(string variableName);
        /// <summary>Синхронизирует JSON данные с внутренним парсером и опционально привязывает к переменной браузера.</summary>
        [DispId(186)] void SyncInternalData(string json, string bindToVariableName = "");

        /// <summary>Выполнить JavaScript и вернуть результат синхронно (блокирующее ожидание).</summary>
        [DispId(188)] void ExecuteScriptWithResult(string script);
        /// <summary>Включает или отключает автоматическое изменение размера WebView для заполнения родителя.</summary>
        [DispId(189)] void SetAutoResize(bool enabled);

        /// <summary>Выполнить JavaScript на текущей странице немедленно.</summary>
        [DispId(191)] void ExecuteScriptOnPage(string script);

        /// <summary>Очищает кеш браузера (DiskCache и LocalStorage).</summary>
        [DispId(193)] void ClearCache();
        /// <summary>Включает или отключает обработку пользовательского контекстного меню.</summary>
        [DispId(194)] bool CustomMenuEnabled { get; set; }


        // --- ИЗВЛЕЧЕНИЕ ДАННЫХ И СКРАПИНГ ---

        /// <summary>Получить внутренний текст всего документа.</summary>
        [DispId(200)] void GetInnerText();
    }

    // --- 3. КЛАСС МЕНЕДЖЕРА ---
    /// <summary>
    /// Главный класс менеджера для взаимодействия с WebView2.
    /// </summary>
    [Guid("A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D")]
    [ComSourceInterfaces(typeof(IWebViewEvents))]
    [ClassInterface(ClassInterfaceType.None)] 
    [ComVisible(true)]
    [ProgId("NetWebView2Lib.Manager")]
    public class WebViewManager : IWebViewActions
    {
        // --- ПРИВАТНЫЕ ПОЛЯ ---

        private WebView2 _webView;
        private readonly WebViewBridge _bridge;
        private readonly JsonParser _internalParser = new JsonParser();

        private bool _isAdBlockActive = false;
        private List<string> _blockList = new List<string>();
        private const string StyleId = "autoit-injected-style";
        private bool _areBrowserPopupsAllowed = false;
        private bool _contextMenuEnabled = true;
        private bool _autoResizeEnabled = false;
        private bool _customMenuEnabled = false;

        private int _offsetX = 0;
        private int _offsetY = 0;
        private IntPtr _parentHandle = IntPtr.Zero;
        private ParentWindowSubclass _parentSubclass;

        private string _lastCssRegistrationId = "";
        
        // STA поток для COM объектов WebView2 (совместимость с Win7)
        private Thread _staThread = null;
        private System.Threading.SynchronizationContext _staSyncContext = null;

        // --- ДЕЛЕГАТЫ ---

        /// <summary>
        /// Делегат для обнаружения получения сообщений.
        /// </summary>
        /// <param name="message">Содержимое сообщения.</param>
        public delegate void OnMessageReceivedDelegate(string message);

        /// <summary>
        /// Делегат для события начала навигации.
        /// </summary>
        /// <param name="url">URL, на который происходит переход.</param> 
        public delegate void OnNavigationStartingDelegate(string url);

        /// <summary>
        /// Делегат для события завершения навигации.
        /// </summary> 
        /// <param name="isSuccess">Указывает, была ли навигация успешной.</param>
        /// <param name="webErrorStatus">Код статуса веб-ошибки.</param> 
        public delegate void OnNavigationCompletedDelegate(bool isSuccess, int webErrorStatus);

        /// <summary>
        /// Делегат для события изменения заголовка.
        /// </summary>
        /// <param name="newTitle">Новый заголовок документа.</param> 
        public delegate void OnTitleChangedDelegate(string newTitle);

        /// <summary>
        /// Делегат для события изменения URL.
        /// </summary>
        /// <param name="newUrl">Новый URL.</param> 
        public delegate void OnURLChangedDelegate(string newUrl);

        /// <summary>Делегат для события пользовательского контекстного меню.</summary>
        /// <param name="menuData">JSON строка с контекстной информацией.</param>
        public delegate void OnContextMenuDelegate(string menuData);

        /// <summary>Делегат для упрощённого события контекстного меню.</summary>
        public delegate void OnContextMenuRequestedDelegate(string linkUrl, int x, int y, string selectionText);

        /// <summary>Делегат для изменения масштаба.</summary>
        public delegate void OnZoomChangedDelegate(double factor);
        /// <summary>Делегат для получения фокуса.</summary>
        public delegate void OnBrowserGotFocusDelegate(int reason);
        /// <summary>Делегат для потери фокуса.</summary>
        public delegate void OnBrowserLostFocusDelegate(int reason);


        // --- СОБЫТИЯ ---

        /// <summary>
        /// Событие, срабатывающее при получении сообщения.
        /// </summary>
        public event OnMessageReceivedDelegate OnMessageReceived;

        /// <summary>
        /// Событие, срабатывающее при начале навигации.
        /// </summary> 
        public event OnNavigationStartingDelegate OnNavigationStarting;

        /// <summary>
        /// Событие, срабатывающее при завершении навигации.
        /// </summary>
        public event OnNavigationCompletedDelegate OnNavigationCompleted;

        /// <summary>
        /// Событие, срабатывающее при изменении заголовка документа.
        /// </summary> 
        public event OnTitleChangedDelegate OnTitleChanged;

        /// <summary>
        /// Событие, срабатывающее при изменении URL.
        /// </summary> 
        public event OnURLChangedDelegate OnURLChanged;

        /// <summary>Событие, срабатывающее при запросе пользовательского контекстного меню.</summary>
        public event OnContextMenuDelegate OnContextMenu;

        /// <summary>Событие, срабатывающее при запросе упрощённого контекстного меню.</summary>
        public event OnContextMenuRequestedDelegate OnContextMenuRequested;

        /// <summary>Событие, срабатывающее при изменении масштаба.</summary>
#pragma warning disable CS0067 // Событие объявлено, но не используется
        public event OnZoomChangedDelegate OnZoomChanged;
#pragma warning restore CS0067
        /// <summary>Событие, срабатывающее когда браузер получает фокус.</summary>
        public event OnBrowserGotFocusDelegate OnBrowserGotFocus;
        /// <summary>Событие, срабатывающее когда браузер теряет фокус.</summary>
        public event OnBrowserLostFocusDelegate OnBrowserLostFocus;

        // --- НАТИВНЫЕ МЕТОДЫ ---

        [DllImport("user32.dll")]
        private static extern bool GetClientRect(IntPtr hWnd, out Rect lpRect);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);

        [DllImport("user32.dll")]
        private static extern IntPtr GetFocus();

        [DllImport("user32.dll")]
        private static extern bool IsChild(IntPtr hWndParent, IntPtr hWnd);

        /// <summary>
        /// Простая структура прямоугольника.
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct Rect { 
            /// <summary>Левая позиция</summary>
            public int Left;
            /// <summary>Верхняя позиция</summary>
            public int Top; 
            /// <summary>Правая позиция</summary>
            public int Right; 
            /// <summary>Нижняя позиция</summary>
            public int Bottom; 
        }

        // --- КОНСТРУКТОР ---

        /// <summary>
        /// Статический конструктор для диагностики загрузки класса.
        /// </summary>
        static WebViewManager()
        {
            try
            {
                // Этот код выполняется ДО создания первого экземпляра класса
                System.IO.File.AppendAllText(@"C:\webview2_debug.log", 
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " DEBUG|STATIC_CONSTRUCTOR_START" + Environment.NewLine);
                
                // Проверяем доступность основных типов
                var testWebView = typeof(Microsoft.Web.WebView2.WinForms.WebView2);
                var testBridge = typeof(WebViewBridge);
                
                System.IO.File.AppendAllText(@"C:\webview2_debug.log", 
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " DEBUG|TYPES_LOADED|WebView2=" + (testWebView != null) + "|Bridge=" + (testBridge != null) + Environment.NewLine);
                
                System.IO.File.AppendAllText(@"C:\webview2_debug.log", 
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " DEBUG|STATIC_CONSTRUCTOR_SUCCESS" + Environment.NewLine);
            }
            catch (Exception ex)
            {
                System.IO.File.AppendAllText(@"C:\webview2_debug.log", 
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " DEBUG|STATIC_CONSTRUCTOR_ERROR|" + ex.GetType().Name + ": " + ex.Message + Environment.NewLine);
                if (ex.InnerException != null)
                {
                    System.IO.File.AppendAllText(@"C:\webview2_debug.log", 
                        DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " DEBUG|INNER_ERROR|" + ex.InnerException.Message + Environment.NewLine);
                }
                throw;
            }
        }

        /// <summary>
        /// Инициализирует новый экземпляр класса WebViewManager.
        /// </summary>
        public WebViewManager()
        {
            try
            {
                // WebView2 будет создан в STA потоке во время Initialize (совместимость с Win7)
                _webView = null;
                _bridge = new WebViewBridge();
            }
            catch (Exception ex)
            {
                string errorMsg = "DEBUG|CONSTRUCTOR_ERROR|" + ex.GetType().Name + ": " + ex.Message;
                System.IO.File.AppendAllText(@"C:\webview2_debug.log", 
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " " + errorMsg + Environment.NewLine);
                OnMessageReceived?.Invoke(errorMsg);
                throw;
            }
        }

        // --- СВОЙСТВА ---

        /// <summary>
        /// Получить объект Bridge для взаимодействия с AutoIt.
        /// </summary>
        public IBridgeActions GetBridge()
        {
            return _bridge;
        }

        /// <summary>
        /// Тест DevTools событий - отправляет тестовые сообщения через Bridge.
        /// Вызывается из AutoIt ПОСЛЕ регистрации Bridge событий.
        /// </summary>
        public void TestDevToolsEvents()
        {
            Debug.WriteLine(">>> TestDevToolsEvents() CALLED <<<");
            
            // Send test message through RaiseMessage
            Debug.WriteLine(">>> Sending GETBRIDGE_CALLED through RaiseMessage <<<");
            _bridge.RaiseMessage("GETBRIDGE_CALLED");
            
            // Test DevTools console message (JSON)
            Debug.WriteLine(">>> Sending test DEVTOOLS_CONSOLE (JSON) <<<");
            _bridge.RaiseMessage("{\"type\":\"DEVTOOLS_CONSOLE\",\"level\":\"log\",\"message\":\"TEST MESSAGE FROM DEVTOOLS\",\"source\":\"test.js\",\"line\":123,\"column\":45}");
            
            // Test DevTools exception (JSON)
            Debug.WriteLine(">>> Sending test DEVTOOLS_EXCEPTION (JSON) <<<");
            _bridge.RaiseMessage("{\"type\":\"DEVTOOLS_EXCEPTION\",\"message\":\"TEST EXCEPTION FROM DEVTOOLS\",\"source\":\"test.js\",\"line\":456,\"column\":78,\"stackTrace\":\"test stack trace\"}");
            
            Debug.WriteLine(">>> TestDevToolsEvents() completed <<<");
        }

        /// <summary>
        /// Проверить инициализирован ли WebView2 и готов к работе.
        /// </summary>
        public bool IsReady()
        {
            try
            {
                // Безопасная проверка без доступа к CoreWebView2 из неправильного потока
                return _webView != null && !_webView.IsDisposed && _webView.IsHandleCreated;
            }
            catch
            {
                return false;
            }
        }


        // --- ИНИЦИАЛИЗАЦИЯ ---

        /// <summary>
        /// Инициализирует контрол WebView2 внутри указанного дескриптора родительского окна.
        /// Версия совместимая с Win7 - использует STA поток с async/await для избежания COM блокировок.
        /// </summary>
        public void Initialize(object parentHandle, string userDataFolder, int x = 0, int y = 0, int width = 0, int height = 0)
        {
            // Создаём поток и ЯВНО устанавливаем его в STA
            _staThread = new Thread(async () => // ВЕРНУЛИ async для совместимости с Win7
            {
                try
                {
                    // КРИТИЧНО: Создаём WebView2 в STA потоке для правильной COM apartment threading
                    _webView = new WebView2();
                    
                    long rawHandleValue = Convert.ToInt64(parentHandle);
                    _parentHandle = new IntPtr(rawHandleValue);

                    _offsetX = x;
                    _offsetY = y;

                    _parentSubclass = new ParentWindowSubclass(() => PerformSmartResize());

                    if (string.IsNullOrEmpty(userDataFolder))
                    {
                        userDataFolder = Path.Combine(
                            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                            "AutoIt_WebView2_Profile"
                        );
                    }

                    if (!Directory.Exists(userDataFolder))
                    {
                        Directory.CreateDirectory(userDataFolder);
                    }

                    // Безопасная обработка опций через рефлексию
                    CoreWebView2EnvironmentOptions options = new CoreWebView2EnvironmentOptions();
                    
                    // ========================================
                    // ПОВЫШЕНИЕ ПРОИЗВОДИТЕЛЬНОСТИ: Флаги режима SCADA
                    // ========================================
                    string performanceFlags = 
                        // === Отключение троттлинга (главное!) ===
                        "--disable-background-timer-throttling " +        // НЕ замедлять таймеры в фоне
                        "--disable-renderer-backgrounding " +             // НЕ замедлять рендеринг в фоне
                        "--disable-backgrounding-occluded-windows " +     // НЕ замедлять скрытые окна
                        
                        // === GPU ускорение (работает и на встроенной GPU) ===
                        "--enable-gpu-rasterization " +                   // GPU растеризация
                        "--enable-zero-copy " +                           // Zero-copy для GPU
                        "--enable-accelerated-2d-canvas " +               // Ускорение 2D canvas
                        "--enable-accelerated-video-decode " +            // Ускорение видео
                        
                        // === Многопоточность ===
                        "--num-raster-threads=4 " +                       // 4 потока для растеризации
                        
                        // === Отключение лишнего ===
                        "--disable-features=msWebOOUI,msPdfOOUI " +       // Отключить PDF/Office UI
                        "--disable-ipc-flooding-protection " +            // Убрать защиту от флуда (для SCADA)
                        "--disable-hang-monitor " +                       // Убрать мониторинг зависаний
                        "--disable-breakpad " +                           // Отключить crash reporter
                        "--disable-component-update " +                   // Отключить обновления компонентов
                        
                        // === Максимальный FPS ===
                        "--disable-frame-rate-limit " +                   // Убрать ограничение FPS
                        "--disable-gpu-vsync";                            // Отключить VSync
                    
                    options.AdditionalBrowserArguments = performanceFlags;
                    
                    try
                    {
                        var prop = options.GetType().GetProperty("AreBrowserExtensionsEnabled");
                        if (prop != null)
                        {
                            prop.SetValue(options, true);
                        }
                    }
                    catch
                    {
                        // Extensions not available on Win7
                    }

                    // USE await INSTEAD OF .Result for proper async handling in STA thread
                    // This prevents thread from blocking COM messages
                    var env = await CoreWebView2Environment.CreateAsync(null, userDataFolder, options);

                    // WebView control was created in STA thread
                    // We are already in the correct thread, no marshaling needed
                    
                    // Access Handle to force creation
                    var tempHandle = _webView.Handle;
                    
                    // Setup WebView
                    _webView.Location = new Point(x, y);
                    _webView.Size = new Size(width, height);

                    SetParent(_webView.Handle, _parentHandle);

                    _webView.Visible = true;

                    var initTask = _webView.EnsureCoreWebView2Async(env);
                    
                    int waitCount = 0;
                    int maxWait = 300;
                    
                    while (!initTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        System.Threading.Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (initTask.IsFaulted)
                    {
                        throw initTask.Exception.InnerException ?? initTask.Exception;
                    }
                    
                    if (!initTask.IsCompleted)
                    {
                        throw new TimeoutException("EnsureCoreWebView2Async timeout");
                    }
                    
                    initTask.Wait();

                    ConfigureSettings();
                    RegisterEvents();

                    var scriptTask = _webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(@"
                        window.dispatchEventToAutoIt = function(lnk, x, y, sel) {
                            window.chrome.webview.postMessage('CONTEXT_MENU_REQUEST|' + (lnk||'') + '|' + (x||0) + '|' + (y||0) + '|' + (sel||''));
                        };
                    ");
                    
                    // Wait with DoEvents
                    int scriptWait = 0;
                    while (!scriptTask.IsCompleted && scriptWait < 50)
                    {
                        Application.DoEvents();
                        System.Threading.Thread.Sleep(1);
                        scriptWait++;
                    }
                    
                    if (scriptTask.IsCompleted)
                    {
                        scriptTask.Wait();
                    }

                    // ========================================
                    // PERFORMANCE BOOST: High Priority
                    // ========================================
                    try
                    {
                        uint browserPid = _webView.CoreWebView2.BrowserProcessId;
                        if (browserPid > 0)
                        {
                            var browserProcess = Process.GetProcessById((int)browserPid);
                            browserProcess.PriorityClass = ProcessPriorityClass.High;
                        }
                    }
                    catch (Exception ex)
                    {
                        OnMessageReceived?.Invoke("ERROR|PRIORITY_FAILED|" + ex.Message);
                    }
                    
                    OnMessageReceived?.Invoke("INIT_READY");
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("DEBUG|EXCEPTION_TYPE|" + ex.GetType().FullName);
                    OnMessageReceived?.Invoke("DEBUG|EXCEPTION_SOURCE|" + (ex.Source ?? "null"));
                    OnMessageReceived?.Invoke("DEBUG|STACK_TRACE|" + (ex.StackTrace ?? "null"));
                    OnMessageReceived?.Invoke("ERROR|INIT_FAILED|" + ex.Message);
                    
                    // Log inner exceptions for AggregateException
                    if (ex is AggregateException aggEx)
                    {
                        OnMessageReceived?.Invoke("DEBUG|AGGREGATE_EXCEPTION_COUNT|" + aggEx.InnerExceptions.Count);
                        foreach (var innerEx in aggEx.InnerExceptions)
                        {
                            OnMessageReceived?.Invoke("ERROR|INNER|" + innerEx.GetType().Name + ": " + innerEx.Message);
                            OnMessageReceived?.Invoke("DEBUG|INNER_STACK|" + (innerEx.StackTrace ?? "null"));
                        }
                    }
                    else if (ex.InnerException != null)
                    {
                        OnMessageReceived?.Invoke("ERROR|INNER|" + ex.InnerException.Message);
                        OnMessageReceived?.Invoke("DEBUG|INNER_TYPE|" + ex.InnerException.GetType().FullName);
                        OnMessageReceived?.Invoke("DEBUG|INNER_STACK|" + (ex.InnerException.StackTrace ?? "null"));
                    }
                }
                
                // CRITICAL: Ensure WindowsFormsSynchronizationContext is set before Application.Run
                if (System.Threading.SynchronizationContext.Current == null)
                {
                    System.Threading.SynchronizationContext.SetSynchronizationContext(
                        new System.Windows.Forms.WindowsFormsSynchronizationContext()
                    );
                }
                
                _staSyncContext = System.Threading.SynchronizationContext.Current;
                
                // CRITICAL: Keep STA thread alive with message loop
                Application.Run();
            });

            // CRITICAL: Set STA BEFORE starting the thread
            _staThread.SetApartmentState(ApartmentState.STA);
            _staThread.IsBackground = true;
            _staThread.Start();
        }

        /// <summary>
        /// Adds a browser extension from an unpacked folder (containing manifest.json).
        /// NOT SUPPORTED on WebView2 Runtime 109 (Win7). Method disabled for compatibility.
        /// </summary>
        /// <param name="extensionPath">The full path to the unpacked extension folder.</param>
        public void AddExtension(string extensionPath)
        {
            OnMessageReceived?.Invoke("ERROR|EXTENSION|Extensions not supported on WebView2 Runtime 109 (Win7)");
            // Extension support requires WebView2 SDK 1.0.1661.34+ and Runtime 110+
            // Win7 is limited to Runtime 109, so extensions are not available
        }

        /// <summary>
        /// Removes a browser extension by its ID.
        /// NOT SUPPORTED on WebView2 Runtime 109 (Win7). Method disabled for compatibility.
        /// </summary>
        /// <param name="extensionId">The ID of the extension to remove.</param> 
        public void RemoveExtension(string extensionId)
        {
            OnMessageReceived?.Invoke("ERROR|EXTENSION|Extensions not supported on WebView2 Runtime 109 (Win7)");
            // Extension support requires WebView2 SDK 1.0.1661.34+ and Runtime 110+
            // Win7 is limited to Runtime 109, so extensions are not available
        }


        // --- CONFIGURATION ---

        /// <summary>
        /// Configure WebView2 settings.
        /// </summary>
        private void ConfigureSettings()
        {
            var settings = _webView.CoreWebView2.Settings;
            settings.IsWebMessageEnabled = true;            // Enable Web Messages
            settings.AreDevToolsEnabled = true;             // Enable DevTools by default
            settings.AreDefaultContextMenusEnabled = true;  // Keep TRUE to ensure the event fires
            
            // DefaultBackgroundColor not supported in SDK 1.0.1518.46 (Win7)
            try
            {
                _webView.DefaultBackgroundColor = Color.Transparent;
            }
            catch
            {
                // Ignore - not supported in older SDK versions
            }
        }

        /// <summary>
        /// Disable certain browser features for a controlled environment.
        /// </summary>
        public void DisableBrowserFeatures()
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2 != null)
                    {
                        var settings = _webView.CoreWebView2.Settings;
                        settings.AreDevToolsEnabled = false;   // Disable DevTools
                        settings.IsStatusBarEnabled = false;   // Disable Status Bar
                        settings.IsZoomControlEnabled = false; // Disable Zoom Control
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"DISABLE_BROWSER_FEATURES_ERROR|{ex.Message}");
                }
            });
        }

        // --- EVENT REGISTRATION ---

        /// <summary>
        /// Register event handlers for WebView2 events.
        /// </summary>
        private void RegisterEvents()
        {
            if (_webView?.CoreWebView2 == null) return;

            // --- RESTORED LOGIC ---

            // Context Menu Event
            _webView.CoreWebView2.ContextMenuRequested += async (sender, args) =>
            {
                // 1. Browser Default Menu Strategy
                // Handled=true means we block the browser's menu. 
                // Handled=false means we let the browser show its own menu.
                args.Handled = !_contextMenuEnabled;

                try
                {
                    // 2. Data Retrieval (Async parts first)
                    // Check if the element or any of its parents is TABLE
                    string script = "document.elementFromPoint(" + args.Location.X + "," + args.Location.Y + ").closest('table') ? 'TABLE' : document.elementFromPoint(" + args.Location.X + "," + args.Location.Y + ").tagName";
                    string tagName = await _webView.CoreWebView2.ExecuteScriptAsync(script);
                    tagName = tagName?.Trim('\"') ?? "UNKNOWN";

                    // Extraction of Context info
                    string k = args.ContextMenuTarget.Kind.ToString();
                    string src = args.ContextMenuTarget.HasSourceUri ? args.ContextMenuTarget.SourceUri : "";
                    string lnk = args.ContextMenuTarget.HasLinkUri ? args.ContextMenuTarget.LinkUri : "";
                    string sel = args.ContextMenuTarget.HasSelection ? args.ContextMenuTarget.SelectionText : "";

                    // --- CASE A: Parameter-based Event (v1.4.2 Priority) ---
                    // This is DispId 190 for AutoIt compatibility
                    _webView.BeginInvoke(new Action(() => {
                        try
                        {
                            OnContextMenuRequested?.Invoke(lnk, args.Location.X, args.Location.Y, sel);
                        }
                        catch (Exception ex)
                        {
                            Debug.WriteLine("ContextMenuRequested Invoke Error: " + ex.Message);
                        }
                    }));

                    // --- CASE B: Legacy JSON-based Event (v1.4.1 compatibility) ---
                    // Build JSON - Escaping for safety
                    string cleanSrc = src.Replace("\"", "\\\"");
                    string cleanLnk = lnk.Replace("\"", "\\\"");
                    string cleanSel = sel.Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");

                    string json = "{" +
                        "\"x\":" + args.Location.X + "," +
                        "\"y\":" + args.Location.Y + "," +
                        "\"kind\":\"" + k + "\"," +
                        "\"tagName\":\"" + tagName + "\"," +
                        "\"src\":\"" + cleanSrc + "\"," +
                        "\"link\":\"" + cleanLnk + "\"," +
                        "\"selection\":\"" + cleanSel + "\"" +
                        "}";

                    _webView.BeginInvoke(new Action(() => {
                        try
                        {
                            OnContextMenu?.Invoke("JSON:" + json);
                        }
                        catch (Exception ex)
                        {
                            Debug.WriteLine("ContextMenu JSON Invoke Error: " + ex.Message);
                        }
                    }));
                }
                catch (Exception ex) 
                { 
                    Debug.WriteLine("ContextMenu Error: " + ex.Message); 
                }
            };

            // Ad Blocking
            _webView.CoreWebView2.AddWebResourceRequestedFilter("*", CoreWebView2WebResourceContext.All);
            _webView.CoreWebView2.WebResourceRequested += (s, e) =>
            {
                try
                {
                    if (!_isAdBlockActive) return;
                    
                    string uri = e.Request.Uri.ToLower();
                    foreach (var domain in _blockList)
                    {
                        if (uri.Contains(domain))
                        {
                            e.Response = _webView.CoreWebView2.Environment.CreateWebResourceResponse(null, 403, "Forbidden", "");
                            OnMessageReceived?.Invoke($"BLOCKED_AD|{uri}");
                            return;
                        }
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("WebResourceRequested Error: " + ex.Message);
                }
            };
			
            _webView.CoreWebView2.NewWindowRequested += (s, e) => 
            {
                try
                {
                    if (!_areBrowserPopupsAllowed)
                    {
                        e.Handled = true;
                        if (!string.IsNullOrEmpty(e.Uri))
                        {
                            string targetUri = e.Uri;
                            _webView.BeginInvoke(new Action(() => {
                                try
                                {
                                    if (_webView?.CoreWebView2 != null)
                                    {
                                        _webView.CoreWebView2.Navigate(targetUri);
                                    }
                                }
                                catch (Exception ex)
                                {
                                    Debug.WriteLine("NewWindow Navigate Error: " + ex.Message);
                                }
                            }));
                        }
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("NewWindowRequested Error: " + ex.Message);
                }
            };

            // --- END RESTORED LOGIC ---

            // Navigation & Content Events
            _webView.CoreWebView2.NavigationStarting += (s, e) => 
            { 
                try
                {
                    OnNavigationStarting?.Invoke(e.Uri);
                    
                    string url = e.Uri;
                    
                    // Notify AutoIt about navigation start
                    OnMessageReceived?.Invoke("NAV_STARTING|" + url);
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("NavigationStarting Error: " + ex.Message);
                }
            };

            _webView.CoreWebView2.NavigationCompleted += (s, e) => 
            { 
                try
                {
                    OnNavigationCompleted?.Invoke(e.IsSuccess, (int)e.WebErrorStatus);
                    
                    // Keep the old OnMessageReceived for compatibility (optional)
                    if (e.IsSuccess)
                    {
                        OnMessageReceived?.Invoke("NAV_COMPLETED");
                        OnMessageReceived?.Invoke("TITLE_CHANGED|" + _webView.CoreWebView2.DocumentTitle);
                    }
                    else
                    {
                        OnMessageReceived?.Invoke("NAV_ERROR|" + e.WebErrorStatus);
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("NavigationCompleted Error: " + ex.Message);
                }
            };

            _webView.CoreWebView2.SourceChanged += (s, e) => 
            { 
                try
                {
                    OnURLChanged?.Invoke(_webView.CoreWebView2.Source);
                    OnMessageReceived?.Invoke("URL_CHANGED|" + _webView.Source);
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("SourceChanged Error: " + ex.Message);
                }
            };

            _webView.CoreWebView2.DocumentTitleChanged += (s, e) => 
            { 
                try
                {
                    OnTitleChanged?.Invoke(_webView.CoreWebView2.DocumentTitle);
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("DocumentTitleChanged Error: " + ex.Message);
                }
            };

            // Communication Event <---> AutoIt <---> JavaScript
            //_webView.CoreWebView2.WebMessageReceived += (s, e) => {
            //    OnMessageReceived?.Invoke(e.TryGetWebMessageAsString());
            //};
			
			// --- SCADA CRITICAL: Non-blocking message handling with try-catch ---
            // This handles 1000+ messages/sec from 100 sensors @ 10Hz
            // BeginInvoke ensures non-blocking operation for real-time SCADA systems
            _webView.CoreWebView2.WebMessageReceived += (s, e) =>
            {
                try
                {
                    string message = e.TryGetWebMessageAsString();
                    
                    // Routing: Check if this is a JS-triggered context menu request
                    if (message != null && message.StartsWith("CONTEXT_MENU_REQUEST|"))
                    {
                        var parts = message.Split('|');
                        if (parts.Length >= 5)
                        {
                            string lnk = parts[1];
                            int x = int.TryParse(parts[2], out int px) ? px : 0;
                            int y = int.TryParse(parts[3], out int py) ? py : 0;
                            string sel = parts[4];
                            
                            // NON-BLOCKING: Use BeginInvokeOnUiThread for async event
                            BeginInvokeOnUiThread(() => {
                                try
                                {
                                    OnContextMenuRequested?.Invoke(lnk, x, y, sel);
                                }
                                catch (Exception ex)
                                {
                                    Debug.WriteLine("ContextMenuRequested Invoke Error: " + ex.Message);
                                }
                            });
                            return; // Handled
                        }
                    }

                    // SCADA CRITICAL: Non-blocking message delivery to Bridge
                    // BeginInvokeOnUiThread queues the action and returns immediately
                    // This prevents blocking the WebView2 message pump at high frequency
                    BeginInvokeOnUiThread(() => {
                        try
                        {
                            _bridge.RaiseMessage(message);
                        }
                        catch (Exception ex)
                        {
                            Debug.WriteLine("Bridge.RaiseMessage Error: " + ex.Message);
                            // Don't propagate - SCADA must continue working
                        }
                    });
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("WebMessageReceived Error: " + ex.Message);
                    // SCADA CRITICAL: Never throw - system must stay operational
                }
            };

            // Focus Events (Native Bridge) 
            // Focus Events (Native Bridge) 
            _webView.GotFocus += (s, e) => {
                try
                {
                    // Пытаемся отправить событие в AutoIt
                    OnBrowserGotFocus?.Invoke(0);
                }
                catch (System.Reflection.TargetException)
                {
                    // Игнорируем ошибку рассинхрона COM на Windows 7
                    // Целевой объект AutoIt временно недоступен
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("GotFocus Event Error: " + ex.Message);
                }
            };

            _webView.LostFocus += (s, e) => {
                _webView.BeginInvoke(new Action(() => {
                    try
                    {
                        IntPtr focusedHandle = GetFocus();
                        if (focusedHandle != _webView.Handle && !IsChild(_webView.Handle, focusedHandle))
                        {
                            OnBrowserLostFocus?.Invoke(0);
                        }
                    }
                    catch (System.Reflection.TargetException)
                    {
                        // Игнорируем ошибку рассинхрона COM
                    }
                    catch (Exception ex)
                    {
                        Debug.WriteLine("LostFocus Event Error: " + ex.Message);
                    }
                }));
            };

            // TEST: Send message BEFORE DevTools Protocol
            Debug.WriteLine(">>> TEST: Sending message BEFORE DevTools Protocol <<<");
            _bridge.RaiseMessage("BEFORE_DEVTOOLS_INIT");

            // --- DEVTOOLS PROTOCOL: Console & Exception Tracking ---
            try
            {
                Debug.WriteLine("=== DevTools Protocol Initialization START ===");
                
                // Enable Runtime domain for exception tracking
                Debug.WriteLine("DevTools: Enabling Runtime domain...");
                _webView.CoreWebView2.CallDevToolsProtocolMethodAsync("Runtime.enable", "{}");
                Debug.WriteLine("DevTools: Runtime domain enabled");
                
                // Enable Console domain for console messages
                Debug.WriteLine("DevTools: Enabling Console domain...");
                _webView.CoreWebView2.CallDevToolsProtocolMethodAsync("Console.enable", "{}");
                Debug.WriteLine("DevTools: Console domain enabled");
                
                // Subscribe to Runtime.exceptionThrown event
                Debug.WriteLine("DevTools: Subscribing to Runtime.exceptionThrown...");
                _webView.CoreWebView2.GetDevToolsProtocolEventReceiver("Runtime.exceptionThrown")
                    .DevToolsProtocolEventReceived += OnRuntimeExceptionThrown;
                Debug.WriteLine("DevTools: Runtime.exceptionThrown subscribed");
                
                // Subscribe to Runtime.consoleAPICalled event
                Debug.WriteLine("DevTools: Subscribing to Runtime.consoleAPICalled...");
                _webView.CoreWebView2.GetDevToolsProtocolEventReceiver("Runtime.consoleAPICalled")
                    .DevToolsProtocolEventReceived += OnConsoleAPICalled;
                Debug.WriteLine("DevTools: Runtime.consoleAPICalled subscribed");
                
                Debug.WriteLine("=== DevTools Protocol Initialization SUCCESS ===");
                
                // TEST: Send test message to verify Bridge is working
                Debug.WriteLine(">>> Sending test message through Bridge <<<");
                _bridge.RaiseMessage("DEVTOOLS_PROTOCOL_INITIALIZED");
            }
            catch (Exception ex)
            {
                Debug.WriteLine("!!! DevTools Protocol Initialization FAILED !!!");
                Debug.WriteLine("DevTools Protocol Error: " + ex.Message);
                Debug.WriteLine("Stack Trace: " + ex.StackTrace);
                // Non-critical - continue without DevTools tracking
            }

            // Communication Event <---> AutoIt <---> JavaScript
            _webView.CoreWebView2.AddHostObjectToScript("autoit", _bridge);
        }

        // --- DEVTOOLS PROTOCOL EVENT HANDLERS ---

        /// <summary>
        /// Handler for Runtime.exceptionThrown event from DevTools Protocol.
        /// Captures all JavaScript exceptions with full stack traces.
        /// </summary>
        private void OnRuntimeExceptionThrown(object sender, CoreWebView2DevToolsProtocolEventReceivedEventArgs e)
        {
            Debug.WriteLine(">>> OnRuntimeExceptionThrown CALLED <<<");
            try
            {
                string json = e.ParameterObjectAsJson;
                Debug.WriteLine("Raw JSON: " + json);
                
                string message = "";
                string fileName = "";
                int line = 0;
                int column = 0;
                string stackTrace = "";
                
                try
                {
                    // Parse exceptionDetails object
                    int exceptionDetailsIndex = json.IndexOf("\"exceptionDetails\"");
                    if (exceptionDetailsIndex > 0)
                    {
                        // Extract exception object
                        int exceptionIndex = json.IndexOf("\"exception\"", exceptionDetailsIndex);
                        if (exceptionIndex > 0)
                        {
                            int descIndex = json.IndexOf("\"description\"", exceptionIndex);
                            if (descIndex > 0)
                            {
                                // Extract full error description
                                int startQuote = json.IndexOf("\"", descIndex + 13);
                                int endQuote = json.IndexOf("\"", startQuote + 1);
                                if (startQuote > 0 && endQuote > startQuote)
                                {
                                    message = json.Substring(startQuote + 1, endQuote - startQuote - 1);
                                }
                            }
                        }
                        
                        // Extract URL, line, column from exceptionDetails
                        string url = ExtractJsonValue(json.Substring(exceptionDetailsIndex), "url");
                        string lineStr = ExtractJsonValue(json.Substring(exceptionDetailsIndex), "lineNumber");
                        string columnStr = ExtractJsonValue(json.Substring(exceptionDetailsIndex), "columnNumber");
                        
                        int.TryParse(lineStr, out line);
                        int.TryParse(columnStr, out column);
                        
                        // Extract filename from URL
                        if (!string.IsNullOrEmpty(url))
                        {
                            int lastSlash = url.LastIndexOf('/');
                            if (lastSlash >= 0 && lastSlash < url.Length - 1)
                            {
                                fileName = url.Substring(lastSlash + 1);
                            }
                            else
                            {
                                fileName = url;
                            }
                        }
                        
                        // Extract stack trace
                        int stackIndex = json.IndexOf("\"stackTrace\"", exceptionDetailsIndex);
                        if (stackIndex > 0)
                        {
                            int startBrace = json.IndexOf("{", stackIndex);
                            int endBrace = FindMatchingBrace(json, startBrace);
                            if (startBrace > 0 && endBrace > startBrace)
                            {
                                stackTrace = json.Substring(startBrace, endBrace - startBrace + 1);
                            }
                        }
                    }
                    
                    Debug.WriteLine($"Parsed: message={message}, file={fileName}, line={line}, column={column}");
                }
                catch (Exception parseEx)
                {
                    Debug.WriteLine("!!! Parsing error: " + parseEx.Message);
                    _bridge.RaiseMessage($"DEBUG: Exception parsing failed - {parseEx.Message}");
                    // Fallback - send raw JSON
                    message = "Parse error - see raw JSON";
                    fileName = "unknown";
                }
                
                Debug.WriteLine($">>> Sending via RaiseMessage: DEVTOOLS_EXCEPTION (JSON) <<<");
                
                // Send to AutoIt via RaiseMessage as JSON
                // Escape special characters for JSON
                string escapedMessage = message.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r");
                string escapedFileName = fileName.Replace("\\", "\\\\").Replace("\"", "\\\"");
                string escapedStack = stackTrace.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r");
                
                string devToolsJson = $"{{\"type\":\"DEVTOOLS_EXCEPTION\",\"message\":\"{escapedMessage}\",\"source\":\"{escapedFileName}\",\"line\":{line},\"column\":{column},\"stackTrace\":\"{escapedStack}\"}}";
                _bridge.RaiseMessage(devToolsJson);
                
                Debug.WriteLine($">>> RaiseMessage completed <<<");
            }
            catch (Exception ex)
            {
                Debug.WriteLine("!!! OnRuntimeExceptionThrown Error: " + ex.Message);
                Debug.WriteLine("Stack Trace: " + ex.StackTrace);
                _bridge.RaiseMessage($"DEBUG: OnRuntimeExceptionThrown failed - {ex.Message}");
            }
        }

        /// <summary>
        /// Handler for Runtime.consoleAPICalled event from DevTools Protocol.
        /// Captures all console.log, console.error, console.warn, console.info calls.
        /// </summary>
        private void OnConsoleAPICalled(object sender, CoreWebView2DevToolsProtocolEventReceivedEventArgs e)
        {
            Debug.WriteLine(">>> OnConsoleAPICalled CALLED <<<");
            try
            {
                string json = e.ParameterObjectAsJson;
                Debug.WriteLine("Raw JSON: " + json);
                
                string type = "log";
                string message = "";
                string fileName = "";
                int line = 0;
                int column = 0;
                
                try
                {
                    // Use JsonParser for reliable parsing
                    JsonParser parser = new JsonParser();
                    if (!parser.Parse(json))
                    {
                        throw new Exception("Failed to parse JSON");
                    }
                    
                    // Extract console API type (log, error, warn, info, debug)
                    type = parser.GetTokenValue("type");
                    if (string.IsNullOrEmpty(type)) type = "log";
                    
                    // Extract first argument value from args array
                    message = parser.GetTokenValue("args[0].value");
                    
                    // Extract stack trace for source location
                    string url = parser.GetTokenValue("stackTrace.callFrames[0].url");
                    string lineStr = parser.GetTokenValue("stackTrace.callFrames[0].lineNumber");
                    string columnStr = parser.GetTokenValue("stackTrace.callFrames[0].columnNumber");
                    
                    int.TryParse(lineStr, out line);
                    int.TryParse(columnStr, out column);
                    
                    // Extract filename from URL
                    if (!string.IsNullOrEmpty(url))
                    {
                        int lastSlash = url.LastIndexOf('/');
                        if (lastSlash >= 0 && lastSlash < url.Length - 1)
                        {
                            fileName = url.Substring(lastSlash + 1);
                        }
                        else
                        {
                            fileName = url;
                        }
                    }
                    
                    Debug.WriteLine($"Parsed: type={type}, message={message}, file={fileName}, line={line}, column={column}");
                
                // Send raw JSON for debugging (only first 500 chars)
                string rawJsonPreview = json.Length > 500 ? json.Substring(0, 500) + "..." : json;
                _bridge.RaiseMessage($"DEBUG_RAW_CONSOLE: {rawJsonPreview}");
                }
                catch (Exception parseEx)
                {
                    Debug.WriteLine("!!! Parsing error: " + parseEx.Message);
                    _bridge.RaiseMessage($"DEBUG: Console parsing failed - {parseEx.Message}");
                    // Fallback
                    message = "Parse error - see raw JSON";
                    fileName = "unknown";
                }
                
                Debug.WriteLine($">>> Sending via RaiseMessage: DEVTOOLS_CONSOLE (JSON) <<<");
                
                // Send to AutoIt via RaiseMessage as JSON
                // Escape special characters for JSON
                string escapedMessage = message.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r");
                string escapedFileName = fileName.Replace("\\", "\\\\").Replace("\"", "\\\"");
                
                string devToolsJson = $"{{\"type\":\"DEVTOOLS_CONSOLE\",\"level\":\"{type}\",\"message\":\"{escapedMessage}\",\"source\":\"{escapedFileName}\",\"line\":{line},\"column\":{column}}}";
                _bridge.RaiseMessage(devToolsJson);
                
                Debug.WriteLine($">>> RaiseMessage completed <<<");
            }
            catch (Exception ex)
            {
                Debug.WriteLine("!!! OnConsoleAPICalled Error: " + ex.Message);
                Debug.WriteLine("Stack Trace: " + ex.StackTrace);
            }
        }

        /// <summary>
        /// Extract a JSON value by key (simple parser for performance).
        /// </summary>
        private string ExtractJsonValue(string json, string key)
        {
            try
            {
                string searchKey = "\"" + key + "\"";
                int keyIndex = json.IndexOf(searchKey);
                if (keyIndex < 0) return "";
                
                int colonIndex = json.IndexOf(":", keyIndex);
                if (colonIndex < 0) return "";
                
                int valueStart = colonIndex + 1;
                while (valueStart < json.Length && (json[valueStart] == ' ' || json[valueStart] == '\t'))
                    valueStart++;
                
                if (valueStart >= json.Length) return "";
                
                // Check if value is a string (starts with ")
                if (json[valueStart] == '"')
                {
                    valueStart++;
                    int valueEnd = json.IndexOf('"', valueStart);
                    if (valueEnd < 0) return "";
                    return json.Substring(valueStart, valueEnd - valueStart);
                }
                else
                {
                    // Number or boolean
                    int valueEnd = valueStart;
                    while (valueEnd < json.Length && 
                           json[valueEnd] != ',' && 
                           json[valueEnd] != '}' && 
                           json[valueEnd] != ']' &&
                           json[valueEnd] != '\r' &&
                           json[valueEnd] != '\n')
                    {
                        valueEnd++;
                    }
                    return json.Substring(valueStart, valueEnd - valueStart).Trim();
                }
            }
            catch
            {
                return "";
            }
        }

        /// <summary>
        /// Find matching closing brace for JSON object.
        /// </summary>
        private int FindMatchingBrace(string json, int startIndex)
        {
            try
            {
                if (startIndex < 0 || startIndex >= json.Length || json[startIndex] != '{')
                    return -1;
                
                int depth = 0;
                for (int i = startIndex; i < json.Length; i++)
                {
                    if (json[i] == '{') depth++;
                    else if (json[i] == '}')
                    {
                        depth--;
                        if (depth == 0) return i;
                    }
                }
                return -1;
            }
            catch
            {
                return -1;
            }
        }

        /// <summary>
        /// Find matching closing bracket for JSON array.
        /// </summary>
        private int FindMatchingBracket(string json, int startIndex)
        {
            try
            {
                if (startIndex < 0 || startIndex >= json.Length || json[startIndex] != '[')
                    return -1;
                
                int depth = 0;
                for (int i = startIndex; i < json.Length; i++)
                {
                    if (json[i] == '[') depth++;
                    else if (json[i] == ']')
                    {
                        depth--;
                        if (depth == 0) return i;
                    }
                }
                return -1;
            }
            catch
            {
                return -1;
            }
        }


        // --- PUBLIC API METHODS ---

        /// <summary>
        /// Adds a script that executes on every page load (Permanent Injection).
        /// </summary>
        /// <param name="script">The JavaScript code to be injected.</param>
        public void AddInitializationScript(string script)
        {
            // CRITICAL: Safe check without CoreWebView2 access
            if (_webView == null || _webView.IsDisposed || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                // NOW safe to check CoreWebView2 (in UI thread)
                if (_webView?.CoreWebView2 == null) return;
                
                try
                {
                    // Start async operation
                    var addScriptTask = _webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(script);
                    
                    // Wait with DoEvents (same pattern as Initialize)
                    int waitCount = 0;
                    int maxWait = 50; // 5 seconds max
                    
                    while (!addScriptTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (addScriptTask.IsCompleted)
                    {
                        addScriptTask.Wait(); // Safe to wait now
                    }
                    
                    // Also execute immediately for already loaded pages
                    var execTask = _webView.CoreWebView2.ExecuteScriptAsync(script);
                    
                    waitCount = 0;
                    while (!execTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (execTask.IsCompleted)
                    {
                        execTask.Wait();
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|AddInitializationScript: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Clear browser data (cookies, cache, history, etc.).
        /// </summary>
        public void ClearBrowserData()
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                try
                {
                    // Ensure CoreWebView2 is ready
                    var ensureTask = _webView.EnsureCoreWebView2Async();
                    
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!ensureTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (!ensureTask.IsCompleted) return;
                    
                    // Clears cookies, history, cache, etc.
                    var clearTask = _webView.CoreWebView2.Profile.ClearBrowsingDataAsync();
                    
                    waitCount = 0;
                    while (!clearTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (clearTask.IsCompleted)
                    {
                        clearTask.Wait();
                        OnMessageReceived?.Invoke("DATA_CLEARED");
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|ClearBrowserData: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Lock down the WebView by disabling certain features.
        /// </summary>
        public void LockWebView()
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2 != null)
                    {
                        var s = _webView.CoreWebView2.Settings;
                        s.AreDefaultContextMenusEnabled = false; // Disable context menus
                        s.AreDevToolsEnabled = false;            // Disable DevTools    
                        s.IsZoomControlEnabled = false;          // Disable Zoom Control
                        s.IsBuiltInErrorPageEnabled = false;     // Disable built-in error pages
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"LOCK_WEBVIEW_ERROR|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Stops any ongoing navigation or loading.
        /// </summary>
        public void Stop()
        {
            try
            {
                _webView?.CoreWebView2?.Stop();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"STOP_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Shows the print UI dialog.
        /// </summary>
        public void ShowPrintUI()
        {
            try
            {
                _webView?.CoreWebView2?.ShowPrintUI();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"PRINT_UI_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Sets the mute status for audio.
        /// </summary>
        public void SetMuted(bool muted)
        {
            try
            {
                if (_webView?.CoreWebView2 != null)
                    _webView.CoreWebView2.IsMuted = muted;
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"SET_MUTED_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Gets the current mute status.
        /// </summary>
        public bool IsMuted()
        {
            try
            {
                return _webView?.CoreWebView2?.IsMuted ?? false;
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"IS_MUTED_ERROR|{ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Reload the current page.
        /// </summary>
        public void Reload()
        {
            try
            {
                // Check if CoreWebView2 is initialized to avoid null reference exceptions
                if (_webView != null && _webView.CoreWebView2 != null)
                {
                    _webView.CoreWebView2.Reload();
                }
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"RELOAD_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Navigate back in history.
        /// </summary>
        public void GoBack() => InvokeOnUiThread(() => 
        {
            try
            {
                if (_webView?.CoreWebView2 != null && _webView.CoreWebView2.CanGoBack)
                    _webView.CoreWebView2.GoBack();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"GO_BACK_ERROR|{ex.Message}");
            }
        });

        /// <summary>
        /// Navigate forward in history.
        /// </summary>
        public void GoForward() => InvokeOnUiThread(() => 
        {
            try
            {
                if (_webView?.CoreWebView2 != null && _webView.CoreWebView2.CanGoForward)
                    _webView.CoreWebView2.GoForward();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"GO_FORWARD_ERROR|{ex.Message}");
            }
        });

        /// <summary>
        /// Reset zoom to default (100%).
        /// </summary>
        public void ResetZoom() => SetZoom(1.0);

        /// <summary>
        /// Clear all ad block rules.
        /// </summary>
        public void ClearBlockRules()
        {
            try
            {
                _blockList.Clear();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"CLEAR_BLOCK_RULES_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Controls the context menu behavior.
        /// If true, the native browser menu is displayed.
        /// If false, the native menu is blocked and the OnContextMenu event is sent to AutoIt.
        /// </summary>
        /// <param name="enabled">Boolean to toggle between Native (true) and Custom (false) modes.</param>
        public void SetContextMenuEnabled(bool enabled)
        {
            // Update our internal tracking variable
            _contextMenuEnabled = enabled;

            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2 != null)
                    {
                        // IMPORTANT: We keep this ALWAYS true. 
                        // If we set it to false, the 'ContextMenuRequested' event will never fire.
                        _webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"SET_CONTEXT_MENU_ERROR|{ex.Message}");
                }
            });
        }


        /// <summary>
        /// Navigate to a specified URL.
        /// </summary>
        public void Navigate(string url)
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    _webView.CoreWebView2?.Navigate(url);
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"NAVIGATE_ERROR|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Navigate to a string containing HTML content.
        /// </summary>
        public void NavigateToString(string htmlContent)
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2 != null)
                    {
                        _webView.CoreWebView2.NavigateToString(htmlContent);
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"NAVIGATE_TO_STRING_ERROR|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Execute arbitrary JavaScript code (fire-and-forget, non-blocking).
        /// OPTIMIZED: Uses BeginInvoke for high-frequency calls (1000+ msg/sec).
        /// </summary>
        public void ExecuteScript(string script)
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            BeginInvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    // Simply fire the script - don't wait for result
                    // This is non-blocking and works reliably on Win7/Win10
                    _webView.CoreWebView2.ExecuteScriptAsync(script);
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|ExecuteScript: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Inject CSS code into the current page.
        /// </summary>
        /// <param name="cssCode"></param>
        public void InjectCss(string cssCode)
        {
            // CRITICAL: Safe check without CoreWebView2 access
            if (_webView == null || _webView.IsDisposed || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                // NOW safe to check CoreWebView2 (in UI thread)
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    // The JS wrapper you already have
                    string js = $"(function() {{ let style = document.getElementById('{StyleId}'); if (!style) {{ style = document.createElement('style'); style.id = '{StyleId}'; document.head.appendChild(style); }} style.innerHTML = `{cssCode.Replace("`", "\\` text-decoration")}`; }})();";

                    // Execute NOW (for the current page)
                    ExecuteScript(js);

                    // Persistence
                    // If there was a previous persistent CSS, we remove it to avoid filling up memory
                    if (!string.IsNullOrEmpty(_lastCssRegistrationId))
                    {
                        _webView.CoreWebView2.RemoveScriptToExecuteOnDocumentCreated(_lastCssRegistrationId);
                    }

                    // Register the new CSS to run on every refresh
                    var addScriptTask = _webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(js);
                    
                    // Wait with DoEvents (same pattern as Initialize)
                    int waitCount = 0;
                    int maxWait = 50; // 5 seconds max
                    
                    while (!addScriptTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (addScriptTask.IsCompleted)
                    {
                        _lastCssRegistrationId = addScriptTask.Result;
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|InjectCss: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Remove previously injected CSS.
        /// </summary>
        public void ClearInjectedCss()
        {
            try
            {
                // Subtraction from the future (Stops automatic injection)
                if (!string.IsNullOrEmpty(_lastCssRegistrationId))
                {
                    _webView.CoreWebView2.RemoveScriptToExecuteOnDocumentCreated(_lastCssRegistrationId);
                    _lastCssRegistrationId = "";
                }

                // Subtraction from now
                ExecuteScript($"(function() {{ let style = document.getElementById('{StyleId}'); if (style) style.remove(); }})();");
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"CLEAR_CSS_ERROR|{ex.Message}");
            }
        }


        /// <summary>
        /// Toggle audit highlights on/off.
        /// </summary>
        public void ToggleAuditHighlights(bool enable)
        {
            try
            {
                if (enable) 
                    InjectCss("img, h1, h2, h3, table, a { outline: 3px solid #FF6A00 !important; outline-offset: -3px !important; }");
                else 
                    ClearInjectedCss();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"TOGGLE_AUDIT_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Retrieve the full HTML source of the current page.
        /// </summary>
        public void GetHtmlSource()
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    var scriptTask = _webView.CoreWebView2.ExecuteScriptAsync("document.documentElement.outerHTML");
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!scriptTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (scriptTask.IsCompleted)
                    {
                        string html = scriptTask.Result;
                        OnMessageReceived?.Invoke("HTML_SOURCE|" + CleanJsString(html));
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|GetHtmlSource: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Retrieve the currently selected text on the page.
        /// </summary>
        public void GetSelectedText()
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    var scriptTask = _webView.CoreWebView2.ExecuteScriptAsync("window.getSelection().toString()");
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!scriptTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (scriptTask.IsCompleted)
                    {
                        string selectedText = scriptTask.Result;
                        OnMessageReceived?.Invoke("SELECTED_TEXT|" + CleanJsString(selectedText));
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|GetSelectedText: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Clean up JavaScript string results.
        /// </summary>
        private string CleanJsString(string input)
        {
            try
            {
                if (string.IsNullOrEmpty(input)) return "";
                
                string decoded = System.Text.RegularExpressions.Regex.Unescape(input);
                if (decoded.StartsWith("\"") && decoded.EndsWith("\"") && decoded.Length >= 2)
                    decoded = decoded.Substring(1, decoded.Length - 2);
                return decoded;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("CleanJsString Error: " + ex.Message);
                return input ?? ""; // Return original or empty on error
            }
        }

        /// <summary>
        /// Resize the WebView control.
        /// </summary>
        public void Resize(int w, int h) => InvokeOnUiThread(() => 
        {
            try
            {
                if (_webView != null)
                {
                    _webView.Size = new Size(w, h);
                }
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"RESIZE_ERROR|{ex.Message}");
            }
        });
        
        /// <summary>
        /// Clean up resources.
        /// </summary>
        public void Cleanup()
        {
            try
            {
                // Stop STA thread message loop if running
                if (_staThread != null && _staThread.IsAlive)
                {
                    // Check if we're being called from STA thread itself
                    if (Thread.CurrentThread.ManagedThreadId == _staThread.ManagedThreadId)
                    {
                        // Already in STA thread, just exit
                        _webView?.Dispose();
                        Application.ExitThread();
                        return;
                    }
                    
                    // Signal the message loop to exit from another thread
                    if (_staSyncContext != null)
                    {
                        // Use Post (async) to avoid deadlock
                        _staSyncContext.Post(_ => {
                            try
                            {
                                _webView?.Dispose();
                                Application.ExitThread();
                            }
                            catch { }
                        }, null);
                    }
                    
                    // Wait for thread to finish (with very short timeout for fast cleanup)
                    if (!_staThread.Join(10))
                    {
                        // Force abort as last resort
                        try { _staThread.Abort(); } catch { }
                    }
                }
                else
                {
                    // STA thread not running, just dispose
                    _webView?.Dispose();
                }
            }
            catch
            {
                // Suppress all errors during cleanup
            }
        }

        /// <summary>
        /// Set the zoom factor.
        /// </summary>
        public void SetZoom(double factor) => InvokeOnUiThread(() => 
        {
            try
            {
                if (_webView != null)
                {
                    _webView.ZoomFactor = factor;
                }
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"ZOOM_ERROR|{ex.Message}");
            }
        });

        /// <summary>
        /// Export the current page to a PDF file.
        /// </summary>
        public void ExportToPdf(string filePath)
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    var pdfTask = _webView.CoreWebView2.PrintToPdfAsync(filePath, null);
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 100; // 10 seconds for PDF generation
                    
                    while (!pdfTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (pdfTask.IsCompleted)
                    {
                        pdfTask.Wait();
                        OnMessageReceived?.Invoke("PDF_SUCCESS|" + filePath);
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("PDF_ERROR|" + ex.Message);
                }
            });
        }

        /// <summary>
        /// Ad Block Methods. set AdBlock active state.
        /// </summary>
        public void SetAdBlock(bool active)
        {
            try
            {
                _isAdBlockActive = active;
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"SET_ADBLOCK_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Add a domain to the block list.
        /// </summary>
        public void AddBlockRule(string domain)
        {
            try
            {
                if (!string.IsNullOrEmpty(domain))
                    _blockList.Add(domain.ToLower());
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"ADD_BLOCK_RULE_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Parse JSON into the internal parser.
        /// </summary>
        public bool ParseJsonToInternal(string json)
        {
            try
            {
                return _internalParser.Parse(json?.Trim());
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"PARSE_JSON_ERROR|{ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Binds the internal JSON data to a browser variable.
        /// </summary>
        public bool BindJsonToBrowser(string variableName)
        {
            try
            {
                if (_webView?.CoreWebView2 == null) return false;

                // 2. Get minified JSON from internal parser
                string jsonData = _internalParser.GetMinifiedJson();
                if (string.IsNullOrEmpty(jsonData))
                {
                    jsonData = "{}"; // Fallback to empty object
                }

                // 3. Escape for JS safety
                string safeJson = jsonData.Replace("\\", "\\\\").Replace("'", "\\'");

                // 3. Build script with JS try-catch and console logging
                string script = $@"
                    try {{
                        window.{variableName} = JSON.parse('{safeJson}');
                        console.log('NetWebView2Lib: Data bound to window.{variableName}');
                        true;
                    }} catch (e) {{
                        console.error('NetWebView2Lib Bind Error:', e);
                        false;
                    }}";

                // 4. Execute script
                _webView.CoreWebView2.ExecuteScriptAsync(script);
                return true;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("BindJsonToBrowser Error: " + ex.Message);
                return false;
            }
        }

        /// <summary>
        /// Syncs JSON data to internal parser and optionally binds it to a browser variable.
        /// </summary>
        public void SyncInternalData(string json, string bindToVariableName = "")
        {
            try
            {
                if (ParseJsonToInternal(json))
                {
                    if (!string.IsNullOrEmpty(bindToVariableName))
                    {
                        BindJsonToBrowser(bindToVariableName);
                    }
                }
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"SYNC_INTERNAL_DATA_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Get a value from the internal JSON parser.
        /// </summary>
        public string GetInternalJsonValue(string path)
        {
            try
            {
                return _internalParser.GetTokenValue(path);
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"GET_INTERNAL_JSON_VALUE_ERROR|{ex.Message}");
                return "";
            }
        }

        // --- NEW ENRICHED METHODS ---

        /// <summary>
        /// Set a custom User Agent.
        /// </summary>
        public void SetUserAgent(string userAgent)
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null)
                        _webView.CoreWebView2.Settings.UserAgent = userAgent;
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"SET_USER_AGENT_ERROR|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Get the Document Title.
        /// </summary>
        public string GetDocumentTitle()
        {
            string title = "";
            
            // CRITICAL: Safe check without CoreWebView2 access
            if (_webView == null || _webView.IsDisposed || !_webView.IsHandleCreated)
                return "";
            
            try
            {
                InvokeOnUiThread(() =>
                {
                    // NOW safe to access CoreWebView2 (in UI thread)
                    if (_webView?.CoreWebView2 != null)
                    {
                        title = _webView.CoreWebView2.DocumentTitle ?? "";
                    }
                });
            }
            catch
            {
                // Return empty string on error
            }
            
            return title;
        }

        /// <summary>
        /// Get the Current Source URL.
        /// </summary>
        public string GetSource()
        {
            return _webView?.Source?.ToString() ?? "";
        }

        /// <summary>
        /// Enables or disables automatic resizing of the WebView to fill its parent.
        /// </summary>
        /// <param name="enabled">True to enable auto-resize, False to disable.</param>
        public void SetAutoResize(bool enabled)
        {
            if (_parentHandle == IntPtr.Zero || _parentSubclass == null) return;

            _autoResizeEnabled = enabled;

            if (_autoResizeEnabled)
            {
                // Assign the handle to start intercepting WM_SIZE
                _parentSubclass.AssignHandle(_parentHandle);
                // Immediately perform a resize
                PerformSmartResize();
            }
            else
            {
                // Release the handle to stop intercepting
                _parentSubclass.ReleaseHandle();
            }
        }

        private void PerformSmartResize()
        {
            if (_webView == null || _parentHandle == IntPtr.Zero) return;

            if (_webView.InvokeRequired)
            {
                _webView.Invoke(new Action(PerformSmartResize));
                return;
            }

            // Get the parent window client dimensions using Win32 API
            if (GetClientRect(_parentHandle, out Rect rect))
            {
                int parentWidth = rect.Right - rect.Left;
                int parentHeight = rect.Bottom - rect.Top;

                int newWidth = parentWidth - _offsetX;
                int newHeight = parentHeight - _offsetY;

                _webView.Left = _offsetX;
                _webView.Top = _offsetY;
                _webView.Width = Math.Max(10, newWidth);
                _webView.Height = Math.Max(10, newHeight);

                // Notify AutoIt that the resizing is finished
                OnMessageReceived?.Invoke("WINDOW_RESIZED|" + _webView.Width + "|" + _webView.Height);
            }
        }

        /// <summary>
        /// NativeWindow implementation to intercept WM_SIZE from non-.NET parent windows.
        /// </summary>
        private class ParentWindowSubclass : NativeWindow
        {
            private readonly Action _onResize;
            private const int WM_SIZE = 0x0005;

            public ParentWindowSubclass(Action onResize)
            {
                _onResize = onResize;
            }

            protected override void WndProc(ref Message m)
            {
                base.WndProc(ref m);
                if (m.Msg == WM_SIZE)
                {
                    _onResize?.Invoke();
                }
            }
        }

        /// <summary>Enable/Disable Custom Context Menu.</summary>
        public bool CustomMenuEnabled
        {
            get => _customMenuEnabled;
            set => _customMenuEnabled = value;
        }

        /// <summary>
        /// Execute JavaScript on the current page immediately.
        /// </summary>
        /// <param name="script">The JavaScript code to be executed.</param>
        public void ExecuteScriptOnPage(string script)
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    var scriptTask = _webView.CoreWebView2.ExecuteScriptAsync(script);
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!scriptTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (scriptTask.IsCompleted)
                    {
                        scriptTask.Wait();
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|ExecuteScriptOnPage: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Clears the browser cache (DiskCache and LocalStorage).
        /// </summary>
        public void ClearCache()
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    // Clears browser cache (disk cache, shaders, local storage, etc.)
                    var clearTask = _webView.CoreWebView2.Profile.ClearBrowsingDataAsync(
                        CoreWebView2BrowsingDataKinds.DiskCache |
                        CoreWebView2BrowsingDataKinds.LocalStorage
                    );
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!clearTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (clearTask.IsCompleted)
                    {
                        clearTask.Wait();
                        Debug.WriteLine("NetWebView2Lib: Cache cleared successfully.");
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("ERROR|ClearCache: " + ex.Message);
                }
            });
        }

        /// <summary>
        /// Execute JavaScript and return result asynchronously via OnMessageReceived event.
        /// Result is sent as "SCRIPT_RESULT|result" or "SCRIPT_ERROR|error" event.
        /// NON-BLOCKING IMPLEMENTATION - returns immediately, result comes via event.
        /// </summary>
        public void ExecuteScriptWithResult(string script)
        {
            // CRITICAL: Don't check CoreWebView2 here - it causes "UI thread" error!
            // Check only _webView (safe from any thread)
            if (_webView == null || _webView.IsDisposed || !_webView.IsHandleCreated)
            {
                OnMessageReceived?.Invoke("SCRIPT_ERROR|WebView not initialized");
                return;
            }

            // Fire-and-forget: Invoke returns immediately, async task runs in background
            InvokeOnUiThread(async () =>
            {
                try
                {
                    // NOW it's safe to check CoreWebView2 (we're in UI thread)
                    if (_webView?.CoreWebView2 == null)
                    {
                        OnMessageReceived?.Invoke("SCRIPT_ERROR|CoreWebView2 not initialized");
                        return;
                    }
                    
                    // Asynchronous wait (doesn't block UI thread or message loop)
                    string result = await _webView.CoreWebView2.ExecuteScriptAsync(script);
                    
                    // Clean the result using existing helper
                    string cleanedResult = CleanJsString(result);

                    // At this point AutoIt is already in its While loop and ready to receive events
                    OnMessageReceived?.Invoke("SCRIPT_RESULT|" + cleanedResult);
                    
                    // Force message processing
                    Application.DoEvents();
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("SCRIPT_ERROR|" + ex.Message);
                }
            });
        }

        /// <summary>
        /// Enable or Disable JavaScript execution.
        /// </summary>
        public void SetScriptEnabled(bool enabled)
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null)
                        _webView.CoreWebView2.Settings.IsScriptEnabled = enabled;
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"SET_SCRIPT_ENABLED_ERROR|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Enable or Disable Web Messages (Communication).
        /// </summary>
        public void SetWebMessageEnabled(bool enabled)
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null)
                        _webView.CoreWebView2.Settings.IsWebMessageEnabled = enabled;
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"SET_WEB_MESSAGE_ENABLED_ERROR|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Enable or Disable the Status Bar.
        /// </summary>
        public void SetStatusBarEnabled(bool enabled)
        {
            InvokeOnUiThread(() => 
            {
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null)
                        _webView.CoreWebView2.Settings.IsStatusBarEnabled = enabled;
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"SET_STATUS_BAR_ENABLED_ERROR|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Capture a screenshot (preview) of the current view.
        /// </summary>
        /// <param name="filePath">The destination file path.</param>
        /// <param name="format">The format (png or jpg).</param>
        public void CapturePreview(string filePath, string format)
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;
                
                CoreWebView2CapturePreviewImageFormat imageFormat = CoreWebView2CapturePreviewImageFormat.Png;
                if (format.ToLower().Contains("jpg") || format.ToLower().Contains("jpeg"))
                    imageFormat = CoreWebView2CapturePreviewImageFormat.Jpeg;

                try
                {
                    using (var fileStream = File.Create(filePath))
                    {
                        var captureTask = _webView.CoreWebView2.CapturePreviewAsync(imageFormat, fileStream);
                        
                        // Wait with DoEvents
                        int waitCount = 0;
                        int maxWait = 100; // 10 seconds for screenshot
                        
                        while (!captureTask.IsCompleted && waitCount < maxWait)
                        {
                            Application.DoEvents();
                            Thread.Sleep(1);
                            waitCount++;
                        }
                        
                        if (captureTask.IsCompleted)
                        {
                            captureTask.Wait(); // Safe to wait now
                        }
                    }
                    OnMessageReceived?.Invoke("CAPTURE_SUCCESS|" + filePath);
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("CAPTURE_ERROR|" + ex.Message);
                }
            });
        }

        /// <summary>
        /// Call a DevTools Protocol (CDP) method directly.
        /// </summary>
        public void CallDevToolsProtocolMethod(string methodName, string parametersJson)
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    var cdpTask = _webView.CoreWebView2.CallDevToolsProtocolMethodAsync(methodName, parametersJson);
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 100; // 10 seconds for DevTools operations
                    
                    while (!cdpTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (cdpTask.IsCompleted)
                    {
                        string result = cdpTask.Result;
                        OnMessageReceived?.Invoke($"CDP_RESULT|{methodName}|{result}");
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"CDP_ERROR|{methodName}|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Get Cookies asynchronously. Results are sent via the COOKIES_RECEIVED event.
        /// </summary>
        public void GetCookies(string channelId)
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2?.CookieManager == null) return;

                try
                {
                    var cookiesTask = _webView.CoreWebView2.CookieManager.GetCookiesAsync(null);
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!cookiesTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (cookiesTask.IsCompleted)
                    {
                        var cookieList = cookiesTask.Result;
                        
                        // Build JSON manually since we don't depend on external JSON serializers for this simple array
                        var sb = new System.Text.StringBuilder("[");
                        for(int i=0; i<cookieList.Count; i++)
                        {
                            var c = cookieList[i];
                            sb.Append($"{{\"name\":\"{c.Name}\",\"value\":\"{c.Value}\",\"domain\":\"{c.Domain}\",\"path\":\"{c.Path}\"}}");
                            if (i < cookieList.Count - 1) sb.Append(",");
                        }
                        sb.Append("]");

                        // Build the JSON string as before
                        string jsonRaw = sb.ToString();

                        // Convert to Base64 to ensure safe transport of large data
                        var plainTextBytes = System.Text.Encoding.UTF8.GetBytes(jsonRaw);
                        string base64Json = Convert.ToBase64String(plainTextBytes);

                        OnMessageReceived?.Invoke($"COOKIES_B64|{channelId}|{base64Json}");
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke($"COOKIES_ERROR|{channelId}|{ex.Message}");
                }
            });
        }

        /// <summary>
        /// Add or Update a Cookie.
        /// </summary>
        public void AddCookie(string name, string value, string domain, string path)
        {
            if (_webView?.CoreWebView2?.CookieManager == null) return;
            try
            {
                var cookie = _webView.CoreWebView2.CookieManager.CreateCookie(name, value, domain, path);
                _webView.CoreWebView2.CookieManager.AddOrUpdateCookie(cookie);
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"COOKIE_ADD_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Delete a specific Cookie.
        /// </summary>
        public void DeleteCookie(string name, string domain, string path)
        {
            if (_webView?.CoreWebView2?.CookieManager == null) return;
            
            try
            {
                var cookie = _webView.CoreWebView2.CookieManager.CreateCookie(name, "", domain, path);
                _webView.CoreWebView2.CookieManager.DeleteCookie(cookie);
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"COOKIE_DELETE_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Delete All Cookies.
        /// </summary>
        public void DeleteAllCookies()
        {
            try
            {
                _webView?.CoreWebView2?.CookieManager?.DeleteAllCookies();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"COOKIE_DELETE_ALL_ERROR|{ex.Message}");
            }
        }

        /// <summary>
        /// Initiate the native Print dialog.
        /// </summary>
        public void Print()
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    var printTask = _webView.CoreWebView2.ExecuteScriptAsync("window.print();");
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!printTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (printTask.IsCompleted)
                    {
                        printTask.Wait();
                    }
                }
                catch (Exception ex)
                {
                    OnMessageReceived?.Invoke("PRINT_ERROR|" + ex.Message);
                }
            });
        }

        /// <summary>
        /// Check if navigation back is possible.
        /// </summary> 
        public bool GetCanGoBack()
        {
            bool result = false;
            InvokeOnUiThread(() => 
            {
                try
                {
                    result = _webView?.CoreWebView2?.CanGoBack ?? false;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("GetCanGoBack Error: " + ex.Message);
                }
            });
            return result;
        }

        /// <summary>
        /// Check if navigation forward is possible.
        /// </summary> 
        public bool GetCanGoForward()
        {
            bool result = false;
            InvokeOnUiThread(() => 
            {
                try
                {
                    result = _webView?.CoreWebView2?.CanGoForward ?? false;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("GetCanGoForward Error: " + ex.Message);
                }
            });
            return result;
        }

        /// <summary>
        /// Get the Browser Process ID.
        /// </summary> 
        public uint GetBrowserProcessId()
        {
            try { return _webView?.CoreWebView2?.BrowserProcessId ?? 0; }
            catch { return 0; }
        }

        // --- UNIFIED SETTINGS IMPLEMENTATION ---

        public bool AreDevToolsEnabled
        {
            get => RunOnUiThread(() => _webView?.CoreWebView2?.Settings?.AreDevToolsEnabled ?? false);
            set => InvokeOnUiThread(() => 
            { 
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null) 
                        _webView.CoreWebView2.Settings.AreDevToolsEnabled = value;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("AreDevToolsEnabled Set Error: " + ex.Message);
                }
            });
        }
		
        /// <summary>
        /// Check if browser popups are allowed or redirected to the same window.
        /// </summary>
        public bool AreBrowserPopupsAllowed
        {
            get => _areBrowserPopupsAllowed;
            set => InvokeOnUiThread(() => 
            {
                try
                {
                    _areBrowserPopupsAllowed = value;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("AreBrowserPopupsAllowed Set Error: " + ex.Message);
                }
            });
        }

        public bool AreDefaultContextMenusEnabled
        {
            get => _contextMenuEnabled;
            set => SetContextMenuEnabled(value); // Reuse existing logic
        }

        public bool AreDefaultScriptDialogsEnabled
        {
            get => RunOnUiThread(() => _webView?.CoreWebView2?.Settings?.AreDefaultScriptDialogsEnabled ?? true);
            set => InvokeOnUiThread(() => 
            { 
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null) 
                        _webView.CoreWebView2.Settings.AreDefaultScriptDialogsEnabled = value;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("AreDefaultScriptDialogsEnabled Set Error: " + ex.Message);
                }
            });
        }

        public bool AreBrowserAcceleratorKeysEnabled
        {
            get => RunOnUiThread(() => _webView?.CoreWebView2?.Settings?.AreBrowserAcceleratorKeysEnabled ?? true);
            set => InvokeOnUiThread(() => 
            { 
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null) 
                        _webView.CoreWebView2.Settings.AreBrowserAcceleratorKeysEnabled = value;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("AreBrowserAcceleratorKeysEnabled Set Error: " + ex.Message);
                }
            });
        }

        public bool IsStatusBarEnabled
        {
            get => RunOnUiThread(() => _webView?.CoreWebView2?.Settings?.IsStatusBarEnabled ?? true);
            set => SetStatusBarEnabled(value); // Reuse existing logic
        }

        public double ZoomFactor
        {
            get => RunOnUiThread(() => _webView?.ZoomFactor ?? 1.0);
            set => SetZoomFactor(value);
        }

        public string BackColor
        {
            get => RunOnUiThread(() => ColorTranslator.ToHtml(_webView.DefaultBackgroundColor));
            set => InvokeOnUiThread(() => {
                try {
                    // Fix 0x prefix for AutoIt
                    string hex = value.Replace("0x", "#");
                    _webView.DefaultBackgroundColor = ColorTranslator.FromHtml(hex);
                } catch { _webView.DefaultBackgroundColor = Color.White; }
            });
        }

        public bool AreHostObjectsAllowed
        {
            get => RunOnUiThread(() => _webView?.CoreWebView2?.Settings?.AreHostObjectsAllowed ?? true);
            set => InvokeOnUiThread(() => 
            { 
                try
                {
                    if (_webView?.CoreWebView2?.Settings != null) 
                        _webView.CoreWebView2.Settings.AreHostObjectsAllowed = value;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("AreHostObjectsAllowed Set Error: " + ex.Message);
                }
            });
        }

        public int Anchor
        {
            get => RunOnUiThread(() => (int)_webView.Anchor);
            set => InvokeOnUiThread(() => 
            {
                try
                {
                    _webView.Anchor = (AnchorStyles)value;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("Anchor Set Error: " + ex.Message);
                }
            });
        }

        public int BorderStyle
        {
            get => 0; // WebView2 control does not support BorderStyle property natively.
            set { /* No-op: WebView2 does not support BorderStyle directly */ }
        }

        // --- NEW METHODS ---

        public void SetZoomFactor(double factor)
        {
            try
            {
                if (factor < 0.1 || factor > 5.0) return; // Basic validation
                InvokeOnUiThread(() => 
                {
                    if (_webView != null)
                    {
                        _webView.ZoomFactor = factor;
                    }
                });
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"ZOOM_FACTOR_ERROR|{ex.Message}");
            }
        }

        public void OpenDevToolsWindow() => InvokeOnUiThread(() => 
        {
            try
            {
                _webView?.CoreWebView2?.OpenDevToolsWindow();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"OPEN_DEVTOOLS_ERROR|{ex.Message}");
            }
        });

        public void WebViewSetFocus() => InvokeOnUiThread(() => 
        {
            try
            {
                _webView?.Focus();
            }
            catch (Exception ex)
            {
                OnMessageReceived?.Invoke($"FOCUS_ERROR|{ex.Message}");
            }
        });

        // --- HELPER METHODS ---

        private T RunOnUiThread<T>(Func<T> func)
        {
            if (_webView == null || _webView.IsDisposed) return default(T);
            
            try
            {
                if (_webView.InvokeRequired) 
                    return (T)_webView.Invoke(func);
                else 
                    return func();
            }
            catch (Exception ex)
            {
                Debug.WriteLine("RunOnUiThread Error: " + ex.Message);
                return default(T);
            }
        }

        /// <summary>
        /// Encodes a string for safe use in a URL.
        /// </summary>
        public string EncodeURI(string value)
        {
            if (string.IsNullOrEmpty(value)) return "";
            return System.Net.WebUtility.UrlEncode(value);
        }

        /// <summary>
        /// Decodes a URL-encoded string.
        /// </summary>
        public string DecodeURI(string value)
        {
            if (string.IsNullOrEmpty(value)) return "";
            return System.Net.WebUtility.UrlDecode(value);
        }

        /// <summary>
        /// Encodes a string to Base64 (UTF-8).
        /// </summary>
        public string EncodeB64(string value)
        {
            if (string.IsNullOrEmpty(value)) return "";
            var bytes = System.Text.Encoding.UTF8.GetBytes(value);
            return Convert.ToBase64String(bytes);
        }

        /// <summary>
        /// Decodes a Base64 string to plain text (UTF-8).
        /// </summary>
        public string DecodeB64(string value)
        {
            if (string.IsNullOrEmpty(value)) return "";
            try {
                var bytes = Convert.FromBase64String(value);
                return System.Text.Encoding.UTF8.GetString(bytes);
            } catch { return ""; } // Fail safe
        }

        /// Invoke actions on the UI thread (BLOCKING - for synchronous operations)
        private void InvokeOnUiThread(Action action)
        {
            if (_webView == null || _webView.IsDisposed) return;
            
            try
            {
                // Check if we're already on the correct thread
                if (_webView.InvokeRequired)
                {
                    // We're on a different thread, need to marshal to WebView's thread
                    // Check if handle is still valid
                    if (!_webView.IsHandleCreated) return;
                    
                    _webView.Invoke(action);
                }
                else
                {
                    // Already on correct thread, execute directly
                    action();
                }
            }
            catch
            {
                // Suppress errors during shutdown
            }
        }

        /// Begin invoke actions on the UI thread (NON-BLOCKING - for async events)
        /// SCADA CRITICAL: Use for high-frequency events (1000+ msg/sec)
        private void BeginInvokeOnUiThread(Action action)
        {
            if (_webView == null || _webView.IsDisposed) return;
            
            try
            {
                // Check if we're already on the correct thread
                if (_webView.InvokeRequired)
                {
                    // We're on a different thread, need to marshal to WebView's thread
                    // Check if handle is still valid
                    if (!_webView.IsHandleCreated) return;
                    
                    // NON-BLOCKING: Queue the action and return immediately
                    _webView.BeginInvoke(action);
                }
                else
                {
                    // Already on correct thread, execute directly
                    action();
                }
            }
            catch
            {
                // Suppress errors during shutdown
            }
        }

        /// Invoke async actions on the UI thread (for async/await support)
        private void InvokeOnUiThread(Func<Task> asyncAction)
        {
            if (_webView == null || _webView.IsDisposed) return;
            
            // Wrap async action in synchronous Action for Invoke
            Action wrapper = async () =>
            {
                try
                {
                    await asyncAction();
                }
                catch
                {
                    // Suppress errors during shutdown
                }
            };
            
            try
            {
                // Check if we're already on the correct thread
                if (_webView.InvokeRequired)
                {
                    if (!_webView.IsHandleCreated) return;
                    _webView.Invoke(wrapper);
                }
                else
                {
                    // Already on correct thread, execute directly
                    wrapper();
                }
            }
            catch
            {
                // Suppress errors during shutdown
            }
        }

        // --- NEW SECTION: DATA EXTRACTION ---

        /// <summary>
        /// Retrieves the entire text content (innerText) of the document and sends it back to AutoIt.
        /// </summary>
        public void GetInnerText()
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
            {
                if (_webView?.CoreWebView2 == null) return;

                try
                {
                    // ExecuteScriptAsync returns the result as a JSON-encoded string (including quotes)
                    var scriptTask = _webView.CoreWebView2.ExecuteScriptAsync("document.documentElement.innerText");
                    
                    // Wait with DoEvents
                    int waitCount = 0;
                    int maxWait = 50;
                    
                    while (!scriptTask.IsCompleted && waitCount < maxWait)
                    {
                        Application.DoEvents();
                        Thread.Sleep(1);
                        waitCount++;
                    }
                    
                    if (scriptTask.IsCompleted)
                    {
                        string html = scriptTask.Result;
                        
                        // Use CleanJsString to handle escape characters and remove surrounding quotes
                        string cleanedText = CleanJsString(html);

                        // Send the result to AutoIt with the "INNER_TEXT|" prefix
                        OnMessageReceived?.Invoke("INNER_TEXT|" + cleanedText);
                    }
                }
                catch (Exception ex)
                {
                    // Notify AutoIt in case of an execution error
                    OnMessageReceived?.Invoke("ERROR|INNER_TEXT_FAILED: " + ex.Message);
                }
            });
        }

    }

}


