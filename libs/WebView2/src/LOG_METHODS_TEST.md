# DLL Log Methods Test

## Version: 21:10 - 20.02.2026

## Test Methods Added:

### Method 1: DEBUG prefix
```csharp
OnMessageReceived?.Invoke("DEBUG|DLL_REBUILT_21_10_METHOD_1");
```

### Method 2: No prefix
```csharp
OnMessageReceived?.Invoke("DLL_REBUILT_21_10_METHOD_2");
```

### Method 3: INIT_READY style
```csharp
OnMessageReceived?.Invoke("DLL_LOG_TEST_METHOD_3");
```

### Method 4: Pipe separator
```csharp
OnMessageReceived?.Invoke("DEBUG|TEST|DLL_REBUILT_21_10_METHOD_4");
```

### Method 5: Simple text
```csharp
OnMessageReceived?.Invoke("DLL version 21:10 - Method 5");
```

### Method 6: After flags
```csharp
OnMessageReceived?.Invoke("DEBUG|Performance_flags_applied_METHOD_6");
OnMessageReceived?.Invoke("PERF_FLAGS_APPLIED");
```

### Method 7: Environment creation
```csharp
OnMessageReceived?.Invoke("DEBUG|Creating_WebView2_Environment_METHOD_7");
OnMessageReceived?.Invoke("ENV_CREATING");
OnMessageReceived?.Invoke("ENV_CREATED|" + version);
```

### Method 8: Priority setting
```csharp
OnMessageReceived?.Invoke("DEBUG|Setting_browser_priority_HIGH_METHOD_8");
OnMessageReceived?.Invoke("PRIORITY_SETTING");
OnMessageReceived?.Invoke("PRIORITY_SET|" + pid);
OnMessageReceived?.Invoke("PROCESS_NAME|" + name);
```

### Method 9: Final complete
```csharp
OnMessageReceived?.Invoke("DEBUG|All_initialization_complete_METHOD_9");
OnMessageReceived?.Invoke("INIT_COMPLETE");
```

## Expected in AutoIt Console:

All messages should appear in AutoIt console output.
Check which formats are visible and which are filtered.

## Test Command:

```
Debug_Log_Test.au3
```

Look for messages containing:
- DLL_REBUILT_21_10
- METHOD_1 through METHOD_9
- ENV_CREATING, ENV_CREATED
- PERF_FLAGS_APPLIED
- PRIORITY_SET
- INIT_COMPLETE
