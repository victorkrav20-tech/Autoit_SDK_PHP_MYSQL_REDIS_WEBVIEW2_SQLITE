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

// --- Version 1.4.2 ---

namespace NetWebView2Lib
{
    // --- 1. EVENTS INTERFACE (What C# sends to AutoIt) ---
    /// <summary>
    /// Events sent from C# to AutoIt.
    /// </summary>
    [Guid("B2C3D4E5-F6A7-4B6C-9D0E-1F2A3B4C5D6E")]
    [InterfaceType(ComInterfaceType.InterfaceIsIDispatch)]
    [ComVisible(true)]
    public interface IWebViewEvents
    {
        /// <summary>
        /// Triggered when a message is sent from the WebView.
        /// </summary>
        /// <param name="message">The message content.</param>
        [DispId(1)] void OnMessageReceived(string message);
        /// <summary>
        /// Triggered when navigation starts.
        /// </summary>
        /// <param name="url">The URL being navigated to.</param> 
        [DispId(2)] void OnNavigationStarting(string url);
        /// <summary>
        /// Triggered when navigation is completed.
        /// </summary>
        /// <param name="isSuccess">Indicates if navigation was successful.</param>  
        /// <param name="webErrorStatus">The web error status code.</param> 
        [DispId(3)] void OnNavigationCompleted(bool isSuccess, int webErrorStatus);
        /// <summary>
        /// Triggered when the document title changes.
        /// </summary>
        /// <param name="newTitle">The new document title.</param> 
        [DispId(4)] void OnTitleChanged(string newTitle);

        /// <summary>Triggered when a custom context menu is requested.</summary>
        /// <param name="menuData">JSON string containing context info (kind, link, selection).</param>
        [DispId(6)] void OnContextMenu(string menuData);

        /// <summary>Triggered when the zoom factor changes.</summary>
        [DispId(10)] void OnZoomChanged(double factor);
        /// <summary>Triggered when the browser gets focus.</summary>
        [DispId(11)] void OnBrowserGotFocus(int reason);
        /// <summary>Triggered when the browser loses focus.</summary>
        [DispId(12)] void OnBrowserLostFocus(int reason);
        /// <summary>
        /// Triggered when the URL changes.
        /// </summary>
        /// <param name="newUrl">The new URL.</param> 
        [DispId(13)] void OnURLChanged(string newUrl);

        /// <summary>Triggered when a context menu is requested (Simplified for AutoIt).</summary>
        /// <param name="linkUrl">The URL of the link under the cursor, if any.</param>
        /// <param name="x">The X coordinate.</param>
        /// <param name="y">The Y coordinate.</param>
        /// <param name="selectionText">The selected text under the cursor, if any.</param>
        [DispId(190)] void OnContextMenuRequested(string linkUrl, int x, int y, string selectionText);
    }

    /// <summary>
    /// Actions available to call from AutoIt.
    /// </summary>
    [Guid("CCB12345-6789-4ABC-DEF0-1234567890AB")]
    [InterfaceType(ComInterfaceType.InterfaceIsIDispatch)]
    [ComVisible(true)]
    public interface IWebViewActions
    {
        /// <summary>Initialize the WebView.</summary>
        [DispId(101)] void Initialize(object parentHandle, string userDataFolder, int x = 0, int y = 0, int width = 0, int height = 0);
        /// <summary>Navigate to a URL.</summary>
        [DispId(102)] void Navigate(string url);
        /// <summary>Navigate to HTML content.</summary>
        [DispId(103)] void NavigateToString(string htmlContent);
        /// <summary>Execute JavaScript.</summary>
        [DispId(104)] void ExecuteScript(string script);
        /// <summary>Resize the WebView.</summary>
        [DispId(105)] void Resize(int width, int height);
        /// <summary>Clean up resources.</summary>
        [DispId(106)] void Cleanup();
        /// <summary>Get the Bridge object.</summary>
        [DispId(107)] IBridgeActions GetBridge();
        /// <summary>Export to PDF.</summary>
        [DispId(108)] void ExportToPdf(string filePath);
        /// <summary>Check if ready.</summary>
        [DispId(109)] bool IsReady();
        /// <summary>Enable/Disable Context Menu.</summary>
        [DispId(110)] void SetContextMenuEnabled(bool enabled);
        /// <summary>Lock the WebView.</summary>
        [DispId(111)] void LockWebView();
        /// <summary>Disable browser features.</summary>
        [DispId(112)] void DisableBrowserFeatures();
        /// <summary>Go Back.</summary>
        [DispId(113)] void GoBack();
        /// <summary>Reset Zoom.</summary>
        [DispId(114)] void ResetZoom();
        /// <summary>Inject CSS.</summary>
        [DispId(115)] void InjectCss(string cssCode);
        /// <summary>Clear Injected CSS.</summary>
        [DispId(116)] void ClearInjectedCss();
        /// <summary>Toggle Audit Highlights.</summary>
        [DispId(117)] void ToggleAuditHighlights(bool enable);
        /// <summary>Set AdBlock active state.</summary>
        [DispId(118)] void SetAdBlock(bool active);
        /// <summary>Add a block rule.</summary>
        [DispId(119)] void AddBlockRule(string domain);
        /// <summary>Clear all block rules.</summary>
        [DispId(120)] void ClearBlockRules();
        /// <summary>Go Forward.</summary>
        [DispId(121)] void GoForward();
        /// <summary>Get HTML Source.</summary>
        [DispId(122)] void GetHtmlSource();
        /// <summary>Get Selected Text.</summary>
        [DispId(123)] void GetSelectedText();
        /// <summary>Set Zoom factor.</summary>
        [DispId(124)] void SetZoom(double factor);
        /// <summary>Parse JSON to internal storage.</summary>
        [DispId(125)] bool ParseJsonToInternal(string json);
        /// <summary>Get value from internal JSON.</summary>
        [DispId(126)] string GetInternalJsonValue(string path);
        /// <summary>Clear browsing data.</summary>
        [DispId(127)] void ClearBrowserData();
        /// <summary>Reload.</summary>
        [DispId(128)] void Reload();
        /// <summary>Stop loading.</summary>
        [DispId(129)] void Stop();
        /// <summary>Show Print UI.</summary>
        [DispId(130)] void ShowPrintUI();
        /// <summary>Set Muted state.</summary>
        [DispId(131)] void SetMuted(bool muted);
        /// <summary>Check if Muted.</summary>
        [DispId(132)] bool IsMuted();
        /// <summary>Set User Agent.</summary>
        [DispId(133)] void SetUserAgent(string userAgent);
        /// <summary>Get Document Title.</summary>
        [DispId(134)] string GetDocumentTitle();
        /// <summary>Get Source URL.</summary>
        [DispId(135)] string GetSource();
        /// <summary>Enable/Disable Script.</summary>
        [DispId(136)] void SetScriptEnabled(bool enabled);
        /// <summary>Enable/Disable Web Message.</summary>
        [DispId(137)] void SetWebMessageEnabled(bool enabled);
        /// <summary>Enable/Disable Status Bar.</summary>
        [DispId(138)] void SetStatusBarEnabled(bool enabled);
        /// <summary>Capture Preview.</summary>
        [DispId(139)] void CapturePreview(string filePath, string format);
        /// <summary>Call CDP Method.</summary>
        [DispId(140)] void CallDevToolsProtocolMethod(string methodName, string parametersJson);
        /// <summary>Get Cookies.</summary>
        [DispId(141)] void GetCookies(string channelId);
        /// <summary>Add a Cookie.</summary>
        [DispId(142)] void AddCookie(string name, string value, string domain, string path);
        /// <summary>Delete a Cookie.</summary>
        [DispId(143)] void DeleteCookie(string name, string domain, string path);
        /// <summary>Delete All Cookies.</summary>
        [DispId(144)] void DeleteAllCookies();

        /// <summary>Print.</summary>
        [DispId(145)] void Print();
        /// <summary>Add Extension.</summary>
        [DispId(150)] void AddExtension(string extensionPath);
        /// <summary>Remove Extension.</summary>
        [DispId(151)] void RemoveExtension(string extensionId);

        /// <summary>Check if can go back.</summary>
        [DispId(162)] bool GetCanGoBack();
        /// <summary>Check if can go forward.</summary>
        [DispId(163)] bool GetCanGoForward();
        /// <summary>Get Browser Process ID.</summary>
        [DispId(164)] uint GetBrowserProcessId();
        /// <summary>Encode a string for URL.</summary>
        [DispId(165)] string EncodeURI(string value);
        /// <summary>Decode a URL string.</summary>
        [DispId(166)] string DecodeURI(string value);
        /// <summary>Encode a string for Base64.</summary>
        [DispId(167)] string EncodeB64(string value);
        /// <summary>Decode a Base64 string.</summary>
        [DispId(168)] string DecodeB64(string value);

        // --- NEW UNIFIED SETTINGS (PROPERTIES) ---
        /// <summary>Check if DevTools are enabled.</summary>
        [DispId(170)] bool AreDevToolsEnabled { get; set; }
        /// <summary>Check if default context menus are enabled.</summary>
        [DispId(171)] bool AreDefaultContextMenusEnabled { get; set; }
        /// <summary>Check if default script dialogs are enabled.</summary>
        [DispId(172)] bool AreDefaultScriptDialogsEnabled { get; set; }
        /// <summary>Check if browser accelerator keys are enabled.</summary>
        [DispId(173)] bool AreBrowserAcceleratorKeysEnabled { get; set; }
        /// <summary>Check if status bar is enabled.</summary>
        [DispId(174)] bool IsStatusBarEnabled { get; set; }
        /// <summary>Get/Set Zoom Factor.</summary>
        [DispId(175)] double ZoomFactor { get; set; }
        /// <summary>Set Background Color (Hex string).</summary>
        [DispId(176)] string BackColor { get; set; }
        /// <summary>Check if host objects are allowed.</summary>
        [DispId(177)] bool AreHostObjectsAllowed { get; set; }
        /// <summary>Get/Set Anchor (Resizing).</summary>
        [DispId(178)] int Anchor { get; set; }
        /// <summary>Get/Set Border Style.</summary>
        [DispId(179)] int BorderStyle { get; set; }

        // --- NEW UNIFIED METHODS ---
        /// <summary>Set Zoom Factor (Wrapper).</summary>
        [DispId(180)] void SetZoomFactor(double factor);
        /// <summary>Open DevTools Window.</summary>
        [DispId(181)] void OpenDevToolsWindow();
        /// <summary>Focus the WebView.</summary>
        [DispId(182)] void WebViewSetFocus();
        /// <summary>Check if browser popups are allowed or redirected to the same window.</summary>
        [DispId(183)] bool AreBrowserPopupsAllowed { get; set; }
        /// <summary>Add a script that executes on every page load (Permanent Injection).</summary>
        [DispId(184)] void AddInitializationScript(string script);
        /// <summary>Binds the internal JSON data to a browser variable.</summary>
        [DispId(185)] bool BindJsonToBrowser(string variableName);
        /// <summary>Syncs JSON data to internal parser and optionally binds it to a browser variable.</summary>
        [DispId(186)] void SyncInternalData(string json, string bindToVariableName = "");

        /// <summary>Execute JavaScript and return result synchronously (Blocking wait).</summary>
        [DispId(188)] void ExecuteScriptWithResult(string script);
        /// <summary>Enables or disables automatic resizing of the WebView to fill its parent.</summary>
        [DispId(189)] void SetAutoResize(bool enabled);

        /// <summary>Execute JavaScript on the current page immediately.</summary>
        [DispId(191)] void ExecuteScriptOnPage(string script);

        /// <summary>Clears the browser cache (DiskCache and LocalStorage).</summary>
        [DispId(193)] void ClearCache();
        /// <summary>Enables or disables custom context menu handling.</summary>
        [DispId(194)] bool CustomMenuEnabled { get; set; }


        // --- DATA EXTRACTION & SCRAPING ---

        /// <summary>Get the inner text of the entire document.</summary>
        [DispId(200)] void GetInnerText();
    }

    // --- 3. THE MANAGER CLASS ---
    /// <summary>
    /// The Main Manager Class for WebView2 Interaction.
    /// </summary>
    [Guid("A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D")]
    [ComSourceInterfaces(typeof(IWebViewEvents))]
    [ClassInterface(ClassInterfaceType.None)] 
    [ComVisible(true)]
    [ProgId("NetWebView2.Manager")]
    public class WebViewManager : IWebViewActions
    {
        // --- PRIVATE FIELDS ---

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
        
        // STA thread for WebView2 COM objects (Win7 compatibility)
        private Thread _staThread = null;
        private System.Threading.SynchronizationContext _staSyncContext = null;

        // --- DELEGATES ---

        /// <summary>
        /// Delegate for detecting when messages are received.
        /// </summary>
        /// <param name="message">The message content.</param>
        public delegate void OnMessageReceivedDelegate(string message);

        /// <summary>
        /// Delegate for navigation starting event.
        /// </summary>
        /// <param name="url">The URL being navigated to.</param> 
        public delegate void OnNavigationStartingDelegate(string url);

        /// <summary>
        /// Delegate for navigation completed event.
        /// </summary> 
        /// <param name="isSuccess">Indicates if navigation was successful.</param>
        /// <param name="webErrorStatus">The web error status code.</param> 
        public delegate void OnNavigationCompletedDelegate(bool isSuccess, int webErrorStatus);

        /// <summary>
        /// Delegate for title changed event.
        /// </summary>
        /// <param name="newTitle">The new document title.</param> 
        public delegate void OnTitleChangedDelegate(string newTitle);

        /// <summary>
        /// Delegate for URL changed event.
        /// </summary>
        /// <param name="newUrl">The new URL.</param> 
        public delegate void OnURLChangedDelegate(string newUrl);

        /// <summary>Delegate for custom context menu event.</summary>
        /// <param name="menuData">JSON string with context info.</param>
        public delegate void OnContextMenuDelegate(string menuData);

        /// <summary>Delegate for simplified context menu event.</summary>
        public delegate void OnContextMenuRequestedDelegate(string linkUrl, int x, int y, string selectionText);

        /// <summary>Delegate for Zoom Changed.</summary>
        public delegate void OnZoomChangedDelegate(double factor);
        /// <summary>Delegate for Got Focus.</summary>
        public delegate void OnBrowserGotFocusDelegate(int reason);
        /// <summary>Delegate for Lost Focus.</summary>
        public delegate void OnBrowserLostFocusDelegate(int reason);


        // --- EVENTS ---

        /// <summary>
        /// Event fired when a message is received.
        /// </summary>
        public event OnMessageReceivedDelegate OnMessageReceived;

        /// <summary>
        /// Event fired when navigation starts.
        /// </summary> 
        public event OnNavigationStartingDelegate OnNavigationStarting;

        /// <summary>
        /// Event fired when navigation is completed.
        /// </summary>
        public event OnNavigationCompletedDelegate OnNavigationCompleted;

        /// <summary>
        /// Event fired when the document title changes.
        /// </summary> 
        public event OnTitleChangedDelegate OnTitleChanged;

        /// <summary>
        /// Event fired when the URL changes.
        /// </summary> 
        public event OnURLChangedDelegate OnURLChanged;

        /// <summary>Event fired when a custom context menu is requested.</summary>
        public event OnContextMenuDelegate OnContextMenu;

        /// <summary>Event fired when a simplified context menu is requested.</summary>
        public event OnContextMenuRequestedDelegate OnContextMenuRequested;

        /// <summary>Event fired when zoom factor changes.</summary>
#pragma warning disable CS0067 // Event is declared but never used
        public event OnZoomChangedDelegate OnZoomChanged;
#pragma warning restore CS0067
        /// <summary>Event fired when browser gets focus.</summary>
        public event OnBrowserGotFocusDelegate OnBrowserGotFocus;
        /// <summary>Event fired when browser loses focus.</summary>
        public event OnBrowserLostFocusDelegate OnBrowserLostFocus;

        // --- NATIVE METHODS ---

        [DllImport("user32.dll")]
        private static extern bool GetClientRect(IntPtr hWnd, out Rect lpRect);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);

        [DllImport("user32.dll")]
        private static extern IntPtr GetFocus();

        [DllImport("user32.dll")]
        private static extern bool IsChild(IntPtr hWndParent, IntPtr hWnd);

        /// <summary>
        /// A simple Rectangle struct.
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct Rect { 
            /// <summary>Left position</summary>
            public int Left;
            /// <summary>Top position</summary>
            public int Top; 
            /// <summary>Right position</summary>
            public int Right; 
            /// <summary>Bottom position</summary>
            public int Bottom; 
        }

        // --- CONSTRUCTOR ---

        /// <summary>
        /// Initializes a new instance of the WebViewManager class.
        /// </summary>
        public WebViewManager()
        {
            // WebView2 will be created in STA thread during Initialize (Win7 compatibility)
            _webView = null;
            _bridge = new WebViewBridge();
        }

        // --- PROPERTIES ---

        /// <summary>
        /// Get the Bridge object for AutoIt interaction.
        /// </summary>
        public IBridgeActions GetBridge()
        {
            return _bridge;
        }

        /// <summary>
        /// Check if WebView2 is initialized and ready.
        /// </summary>
        public bool IsReady()
        {
            try
            {
                // Safe check without accessing CoreWebView2 from wrong thread
                return _webView != null && !_webView.IsDisposed && _webView.IsHandleCreated;
            }
            catch
            {
                return false;
            }
        }


        // --- INITIALIZATION ---

        /// <summary>
        /// Initializes the WebView2 control within the specified parent window handle.
        /// Win7 compatible version - uses STA thread with async/await to avoid COM deadlocks.
        /// </summary>
        public void Initialize(object parentHandle, string userDataFolder, int x = 0, int y = 0, int width = 0, int height = 0)
        {
            // Create thread and EXPLICITLY set it to STA
            _staThread = new Thread(async () => // Make lambda async
            {
                try
                {
                    // CRITICAL: Create WebView2 in STA thread for proper COM apartment threading
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

                    // Safe options handling via reflection
                    CoreWebView2EnvironmentOptions options = new CoreWebView2EnvironmentOptions();
                    
                    // ========================================
                    // PERFORMANCE BOOST: SCADA Mode Flags
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

                    // USE await INSTEAD OF .Wait()
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
                    OnMessageReceived?.Invoke("ERROR|INIT_FAILED|" + ex.Message);
                    
                    // Log inner exceptions for AggregateException
                    if (ex is AggregateException aggEx)
                    {
                        foreach (var innerEx in aggEx.InnerExceptions)
                        {
                            OnMessageReceived?.Invoke("ERROR|INNER|" + innerEx.GetType().Name + ": " + innerEx.Message);
                        }
                    }
                    else if (ex.InnerException != null)
                    {
                        OnMessageReceived?.Invoke("ERROR|INNER|" + ex.InnerException.Message);
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
            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2 != null)
                {
                    var settings = _webView.CoreWebView2.Settings;
                    settings.AreDevToolsEnabled = false;   // Disable DevTools
                    settings.IsStatusBarEnabled = false;   // Disable Status Bar
                    settings.IsZoomControlEnabled = false; // Disable Zoom Control
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
                        OnContextMenuRequested?.Invoke(lnk, args.Location.X, args.Location.Y, sel);
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
                        OnContextMenu?.Invoke("JSON:" + json);
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
            };
			
            _webView.CoreWebView2.NewWindowRequested += (s, e) => 
            {
                if (!_areBrowserPopupsAllowed) {
                    e.Handled = true;
                    if (!string.IsNullOrEmpty(e.Uri))
                    {
                        string targetUri = e.Uri;
                        _webView.BeginInvoke(new Action(() => {
                            if (_webView?.CoreWebView2 != null)
                            {
                                _webView.CoreWebView2.Navigate(targetUri);
                            }
                        }));
                    }
                }
            };

            // --- END RESTORED LOGIC ---

            // Navigation & Content Events
            _webView.CoreWebView2.NavigationStarting += (s, e) => { 
                OnNavigationStarting?.Invoke(e.Uri); 
				
				string url = e.Uri;
				
				// Notify AutoIt about navigation start
                OnMessageReceived?.Invoke("NAV_STARTING|" + url);
            };

            _webView.CoreWebView2.NavigationCompleted += (s, e) => { 
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
            };

            _webView.CoreWebView2.SourceChanged += (s, e) => { 
                OnURLChanged?.Invoke(_webView.CoreWebView2.Source); 
            };
			
			// Source Changed Event
            _webView.CoreWebView2.SourceChanged += (s, e) => OnMessageReceived?.Invoke("URL_CHANGED|" + _webView.Source);

            _webView.CoreWebView2.DocumentTitleChanged += (s, e) => { 
                OnTitleChanged?.Invoke(_webView.CoreWebView2.DocumentTitle); 
            };

            // Communication Event <---> AutoIt <---> JavaScript
            //_webView.CoreWebView2.WebMessageReceived += (s, e) => {
            //    OnMessageReceived?.Invoke(e.TryGetWebMessageAsString());
            //};
			
			// --- THE FIX IS HERE ---
            // Instead of sending the WebMessage to OnMessageReceived (Manager),
            // we send it to Bridge so that Bridge_OnMessageReceived in AutoIt can catch it.
            _webView.CoreWebView2.WebMessageReceived += (s, e) =>
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
                        
                        _webView.BeginInvoke(new Action(() => {
                            OnContextMenuRequested?.Invoke(lnk, x, y, sel);
                        }));
                        return; // Handled
                    }
                }

                _bridge.RaiseMessage(message); // Send message to the correct channel
            };

            // Focus Events (Native Bridge) 
            _webView.GotFocus += (s, e) => { OnBrowserGotFocus?.Invoke(0); };
            
            _webView.LostFocus += (s, e) => {
                _webView.BeginInvoke(new Action(() => {
                    // Use Native API to see which HWND REALLY has the focus
                    IntPtr focusedHandle = GetFocus(); 
                    
                    // If focusedHandle is NOT _webView.Handle 
                    // AND is NOT a child (IsChild) of _webView.Handle, then we truly lost focus.
                    if (focusedHandle != _webView.Handle && !IsChild(_webView.Handle, focusedHandle)) {
                        OnBrowserLostFocus?.Invoke(0);
                    }
                }));
            };
			
			// Communication Event <---> AutoIt <---> JavaScript
			_webView.CoreWebView2.AddHostObjectToScript("autoit", _bridge);
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
            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2 != null)
                {
                    var s = _webView.CoreWebView2.Settings;
                    s.AreDefaultContextMenusEnabled = false; // Disable context menus
                    s.AreDevToolsEnabled = false;            // Disable DevTools    
                    s.IsZoomControlEnabled = false;          // Disable Zoom Control
                    s.IsBuiltInErrorPageEnabled = false;     // Disable built-in error pages
                }
            });
        }

        /// <summary>
        /// Stops any ongoing navigation or loading.
        /// </summary>
        public void Stop()
        {
            _webView?.CoreWebView2.Stop();
        }

        /// <summary>
        /// Shows the print UI dialog.
        /// </summary>
        public void ShowPrintUI()
        {
            _webView?.CoreWebView2.ShowPrintUI();
        }

        /// <summary>
        /// Sets the mute status for audio.
        /// </summary>
        public void SetMuted(bool muted)
        {
            if (_webView?.CoreWebView2 != null)
                _webView.CoreWebView2.IsMuted = muted;
        }

        /// <summary>
        /// Gets the current mute status.
        /// </summary>
        public bool IsMuted()
        {
            return _webView?.CoreWebView2?.IsMuted ?? false;
        }

        /// <summary>
        /// Reload the current page.
        /// </summary>
        public void Reload()
        {
            // Check if CoreWebView2 is initialized to avoid null reference exceptions
            if (_webView != null && _webView.CoreWebView2 != null)
            {
                _webView.CoreWebView2.Reload();
            }
        }

        /// <summary>
        /// Navigate back in history.
        /// </summary>
        public void GoBack() => InvokeOnUiThread(() => {
            if (_webView?.CoreWebView2 != null && _webView.CoreWebView2.CanGoBack)
                _webView.CoreWebView2.GoBack();
        });

        /// <summary>
        /// Navigate forward in history.
        /// </summary>
        public void GoForward() => InvokeOnUiThread(() => {
            if (_webView?.CoreWebView2 != null && _webView.CoreWebView2.CanGoForward)
                _webView.CoreWebView2.GoForward();
        });

        /// <summary>
        /// Reset zoom to default (100%).
        /// </summary>
        public void ResetZoom() => SetZoom(1.0);

        /// <summary>
        /// Clear all ad block rules.
        /// </summary>
        public void ClearBlockRules() => _blockList.Clear();

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

            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2 != null)
                {
                    // IMPORTANT: We keep this ALWAYS true. 
                    // If we set it to false, the 'ContextMenuRequested' event will never fire.
                    _webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
                }
            });
        }


        /// <summary>
        /// Navigate to a specified URL.
        /// </summary>
        public void Navigate(string url)
        {
            InvokeOnUiThread(() => {
                _webView.CoreWebView2?.Navigate(url);
            });
        }

        /// <summary>
        /// Navigate to a string containing HTML content.
        /// </summary>
        public void NavigateToString(string htmlContent)
        {
            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2 != null)
                {
                    _webView.CoreWebView2.NavigateToString(htmlContent);
                }
            });
        }

        /// <summary>
        /// Execute arbitrary JavaScript code (fire-and-forget, non-blocking).
        /// </summary>
        public void ExecuteScript(string script)
        {
            if (_webView == null || !_webView.IsHandleCreated) return;

            InvokeOnUiThread(() =>
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
                    _bridge.RaiseMessage("ERROR|ExecuteScript exception: " + ex.Message);
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
            // Subtraction from the future (Stops automatic injection)
            if (!string.IsNullOrEmpty(_lastCssRegistrationId))
            {
                _webView.CoreWebView2.RemoveScriptToExecuteOnDocumentCreated(_lastCssRegistrationId);
                _lastCssRegistrationId = "";
            }

            // Subtraction from now
            ExecuteScript($"(function() {{ let style = document.getElementById('{StyleId}'); if (style) style.remove(); }})();");
        }


        /// <summary>
        /// Toggle audit highlights on/off.
        /// </summary>
        public void ToggleAuditHighlights(bool enable)
        {
            if (enable) InjectCss("img, h1, h2, h3, table, a { outline: 3px solid #FF6A00 !important; outline-offset: -3px !important; }");
            else ClearInjectedCss();
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
            string decoded = System.Text.RegularExpressions.Regex.Unescape(input);
            if (decoded.StartsWith("\"") && decoded.EndsWith("\"") && decoded.Length >= 2)
                decoded = decoded.Substring(1, decoded.Length - 2);
            return decoded;
        }

        /// <summary>
        /// Resize the WebView control.
        /// </summary>
        public void Resize(int w, int h) => InvokeOnUiThread(() => _webView.Size = new Size(w, h));
        
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
                    
                    // Wait for thread to finish (with shorter timeout)
                    if (!_staThread.Join(1000))
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
        public void SetZoom(double factor) => InvokeOnUiThread(() => _webView.ZoomFactor = factor);

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
        public void SetAdBlock(bool active) => _isAdBlockActive = active;

        /// <summary>
        /// Add a domain to the block list.
        /// </summary>
        public void AddBlockRule(string domain) { if (!string.IsNullOrEmpty(domain)) _blockList.Add(domain.ToLower()); }

        /// <summary>
        /// Parse JSON into the internal parser.
        /// </summary>
        public bool ParseJsonToInternal(string json) => _internalParser.Parse(json?.Trim());

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
            if (ParseJsonToInternal(json))
            {
                if (!string.IsNullOrEmpty(bindToVariableName))
                {
                    BindJsonToBrowser(bindToVariableName);
                }
            }
        }

        /// <summary>
        /// Get a value from the internal JSON parser.
        /// </summary>
        public string GetInternalJsonValue(string path) => _internalParser.GetTokenValue(path);

        // --- NEW ENRICHED METHODS ---

        /// <summary>
        /// Set a custom User Agent.
        /// </summary>
        public void SetUserAgent(string userAgent)
        {
            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2?.Settings != null)
                    _webView.CoreWebView2.Settings.UserAgent = userAgent;
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
            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2?.Settings != null)
                    _webView.CoreWebView2.Settings.IsScriptEnabled = enabled;
            });
        }

        /// <summary>
        /// Enable or Disable Web Messages (Communication).
        /// </summary>
        public void SetWebMessageEnabled(bool enabled)
        {
            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2?.Settings != null)
                    _webView.CoreWebView2.Settings.IsWebMessageEnabled = enabled;
            });
        }

        /// <summary>
        /// Enable or Disable the Status Bar.
        /// </summary>
        public void SetStatusBarEnabled(bool enabled)
        {
            InvokeOnUiThread(() => {
                if (_webView?.CoreWebView2?.Settings != null)
                    _webView.CoreWebView2.Settings.IsStatusBarEnabled = enabled;
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
            var cookie = _webView.CoreWebView2.CookieManager.CreateCookie(name, "", domain, path);
            _webView.CoreWebView2.CookieManager.DeleteCookie(cookie);
        }

        /// <summary>
        /// Delete All Cookies.
        /// </summary>
        public void DeleteAllCookies()
        {
            _webView?.CoreWebView2?.CookieManager?.DeleteAllCookies();
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
            InvokeOnUiThread(() => {
                result = _webView?.CoreWebView2?.CanGoBack ?? false;
            });
            return result;
        }

        /// <summary>
        /// Check if navigation forward is possible.
        /// </summary> 
        public bool GetCanGoForward()
        {
            bool result = false;
            InvokeOnUiThread(() => {
                result = _webView?.CoreWebView2?.CanGoForward ?? false;
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
            set => InvokeOnUiThread(() => { if (_webView?.CoreWebView2?.Settings != null) _webView.CoreWebView2.Settings.AreDevToolsEnabled = value; });
        }
		
        /// <summary>
        /// Check if browser popups are allowed or redirected to the same window.
        /// </summary>
        public bool AreBrowserPopupsAllowed
        {
            get => _areBrowserPopupsAllowed;
            set => InvokeOnUiThread(() => _areBrowserPopupsAllowed = value);
        }

        public bool AreDefaultContextMenusEnabled
        {
            get => _contextMenuEnabled;
            set => SetContextMenuEnabled(value); // Reuse existing logic
        }

        public bool AreDefaultScriptDialogsEnabled
        {
            get => RunOnUiThread(() => _webView?.CoreWebView2?.Settings?.AreDefaultScriptDialogsEnabled ?? true);
            set => InvokeOnUiThread(() => { if (_webView?.CoreWebView2?.Settings != null) _webView.CoreWebView2.Settings.AreDefaultScriptDialogsEnabled = value; });
        }

        public bool AreBrowserAcceleratorKeysEnabled
        {
            get => RunOnUiThread(() => _webView?.CoreWebView2?.Settings?.AreBrowserAcceleratorKeysEnabled ?? true);
            set => InvokeOnUiThread(() => { if (_webView?.CoreWebView2?.Settings != null) _webView.CoreWebView2.Settings.AreBrowserAcceleratorKeysEnabled = value; });
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
            set => InvokeOnUiThread(() => { if (_webView?.CoreWebView2?.Settings != null) _webView.CoreWebView2.Settings.AreHostObjectsAllowed = value; });
        }

        public int Anchor
        {
            get => RunOnUiThread(() => (int)_webView.Anchor);
            set => InvokeOnUiThread(() => _webView.Anchor = (AnchorStyles)value);
        }

        public int BorderStyle
        {
            get => 0; // WebView2 control does not support BorderStyle property natively.
            set { /* No-op: WebView2 does not support BorderStyle directly */ }
        }

        // --- NEW METHODS ---

        public void SetZoomFactor(double factor)
        {
            if (factor < 0.1 || factor > 5.0) return; // Basic validation
            InvokeOnUiThread(() => _webView.ZoomFactor = factor);
        }

        public void OpenDevToolsWindow() => InvokeOnUiThread(() => _webView?.CoreWebView2?.OpenDevToolsWindow());

        public void WebViewSetFocus() => InvokeOnUiThread(() => _webView?.Focus());

        // --- HELPER METHODS ---

        private T RunOnUiThread<T>(Func<T> func)
        {
            if (_webView == null || _webView.IsDisposed) return default(T);
            if (_webView.InvokeRequired) return (T)_webView.Invoke(func);
            else return func();
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

        /// Invoke actions on the UI thread
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


