; For those who would fear the license - don't. I tried to license it as liberal as possible.
; It really means you can do what ever you want with this.
; Donations are wellcome And will be accepted via PayPal address: trancexx at yahoo dot com
; Thank you for the shiny stuff :kiss:

#comments-start
	Copyright 2013 Dragana R. <trancexx at yahoo dot com>

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
#comments-end

#include-once
#include "WinHttpConstants.au3"

; #INDEX# ===================================================================================
; Title ...............: WinHttp
; File Name............: WinHttp.au3
; File Version.........: 1.6.4.1
; Min. AutoIt Version..: v3.3.7.20
; Description .........: AutoIt wrapper for WinHTTP functions
; Author... ...........: trancexx, ProgAndy
; Dll .................: winhttp.dll, kernel32.dll
; ===========================================================================================

; #CONSTANTS# ===============================================================================
Global Const $hWINHTTPDLL__WINHTTP = DllOpen("winhttp.dll")
DllOpen("winhttp.dll") ; making sure reference count never reaches 0
;============================================================================================

; #CURRENT# =================================================================================
;_WinHttpAddRequestHeaders
;_WinHttpCheckPlatform
;_WinHttpCloseHandle
;_WinHttpConnect
;_WinHttpCrackUrl
;_WinHttpCreateUrl
;_WinHttpDetectAutoProxyConfigUrl
;_WinHttpGetDefaultProxyConfiguration
;_WinHttpGetIEProxyConfigForCurrentUser
;_WinHttpOpen
;_WinHttpOpenRequest
;_WinHttpQueryAuthSchemes
;_WinHttpQueryDataAvailable
;_WinHttpQueryHeaders
;_WinHttpQueryOption
;_WinHttpReadData
;_WinHttpReceiveResponse
;_WinHttpSendRequest
;_WinHttpSetCredentials
;_WinHttpSetDefaultProxyConfiguration
;_WinHttpSetOption
;_WinHttpSetStatusCallback
;_WinHttpSetTimeouts
;_WinHttpSimpleBinaryConcat
;_WinHttpSimpleFormFill
;_WinHttpSimpleFormFill_SetUploadCallback
;_WinHttpSimpleReadData
;_WinHttpSimpleReadDataAsync
;_WinHttpSimpleRequest
;_WinHttpSimpleSendRequest
;_WinHttpSimpleSendSSLRequest
;_WinHttpSimpleSSLRequest
;_WinHttpTimeFromSystemTime
;_WinHttpTimeToSystemTime
;_WinHttpWriteData
; ===========================================================================================

; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpAddRequestHeaders
; Description ...: Adds one or more HTTP request headers to the HTTP request handle.
; Syntax.........: _WinHttpAddRequestHeaders ($hRequest, $sHeaders [, $iModifiers = Default ])
; Parameters ....: $hRequest - Handle returned by _WinHttpOpenRequest function.
;                  $sHeader - [optional] Header(s) to append to the request.
;                  $iModifier - [optional] Contains the flags used to modify the semantics of this function. Default is $WINHTTP_ADDREQ_FLAG_ADD_IF_NEW.
; Return values .: Success - Returns 1
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: In case of multiple additions at once use [[@CRLF]] to separate each [[$hRequest]] and responded [[$sHeaders]] and [[$iModifiers]].
; Related .......: _WinHttpOpenRequest, _WinHttpQueryHeaders
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384087.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpCheckPlatform
; Description ...: Determines whether the current platform is supported by this version of Microsoft Windows HTTP Services (WinHTTP).
; Syntax.........: _WinHttpCheckPlatform()
; Parameters ....: None
; Return values .: Success - Returns 1 if current platform is supported
;                          - Returns 0 if current platform is not supported
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384089.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpCloseHandle
; Description ...: Closes a single handle.
; Syntax.........: _WinHttpCloseHandle($hInternet)
; Parameters ....: $hInternet - Valid handle to be closed.
; Return values .: Success - Returns 1
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Related .......: _WinHttpConnect, _WinHttpOpen, _WinHttpOpenRequest
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384090.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpConnect
; Description ...: Specifies the initial target server of an HTTP request and returns connection handle to an HTTP session for that initial target.
; Syntax.........: _WinHttpConnect($hSession, $sServerName [, $iServerPort = Default ])
; Parameters ....: $hSession - Valid WinHttp session handle returned by a previous call to _WinHttpOpen().
;                  $sServerName - Host name of an HTTP server. In case URI scheme (http://, https://, ...) is specified $iServerPort is ignored.
;                  $iServerPort - [optional] TCP/IP port on the server to which a connection is made (default is $INTERNET_DEFAULT_PORT)
; Return values .: Success - Returns a valid connection handle to the HTTP session
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: [[$iServerPort]] can be defined via global constants [[$INTERNET_DEFAULT_PORT]], [[$INTERNET_DEFAULT_HTTP_PORT]] or [[$INTERNET_DEFAULT_HTTPS_PORT]]
; Related .......: _WinHttpOpen
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384091.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpCrackUrl
; Description ...: Separates a URL into its component parts such as host name and path.
; Syntax.........: _WinHttpCrackUrl($sURL [, $iFlag = Default ])
; Parameters ....: $sURL - String. Canonical URL to separate.
;                  $iFlag - [optional] Flag that control the operation. Default is $ICU_ESCAPE
; Return values .: Success - Returns array with 8 elements:
;                  |$array[0] - scheme name
;                  |$array[1] - internet protocol scheme
;                  |$array[2] - host name
;                  |$array[3] - port number
;                  |$array[4] - user name
;                  |$array[5] - password
;                  |$array[6] - URL path
;                  |$array[7] - extra information
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: ProgAndy
; Modified.......: trancexx
; Remarks .......: [[$iFlag]] is defined in WinHttpConstants.au3 and can be:
;                  |[[$ICU_DECODE]] - Converts characters that are "escape encoded" (%xx) to their non-escaped form.
;                  |[[$ICU_ESCAPE]] - Escapes certain characters to their escape sequences (%xx).
; Related .......: _WinHttpCreateUrl
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384092.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpCreateUrl
; Description ...: Creates a URL from array of components such as the host name and path.
; Syntax.........: _WinHttpCreateUrl($aURLArray)
; Parameters ....: $aURLArray - Array of URL data.
; Return values .: Success - Returns created URL
;                  Failure - Returns empty string and sets @error:
;                  |1 - Invalid input.
;                  |2 - Initial DllCall failed
;                  |3 - Main DllCall failed
; Author ........: ProgAndy
; Modified.......: trancexx
; Remarks .......: Input is one dimensional 8 elements in size array:
;                  |- first element [0] scheme name
;                  |- second element [1] internet protocol scheme
;                  |- third element [2] host name
;                  |- fourth element [3] port number
;                  |- fifth element [4] user name
;                  |- sixth element [5] password
;                  |- seventh element [6] URL path
;                  |- eighth element [7] extra information
; Related .......: _WinHttpCrackUrl
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384093.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpDetectAutoProxyConfigUrl
; Description ...: Finds the URL for the Proxy Auto-Configuration (PAC) file.
; Syntax.........: _WinHttpDetectAutoProxyConfigUrl($iAutoDetectFlags)
; Parameters ....: $iAutoDetectFlags - Specifies what protocols to use to locate the PAC file.
; Return values .: Success - Returns URL for the PAC file.
;                  Failure - Returns empty string and sets @error:
;                  |1 - DllCall failed
;                  |2 - Internal failure.
; Author ........: trancexx
; Remarks .......: [[$iAutoDetectFlags]] values are defined in WinHttpconstants.au3
; Related .......: _WinHttpGetDefaultProxyConfiguration, _WinHttpGetIEProxyConfigForCurrentUser, _WinHttpSetDefaultProxyConfiguration
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384094.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpGetDefaultProxyConfiguration
; Description ...: Retrieves the default WinHttp proxy configuration.
; Syntax.........: _WinHttpGetDefaultProxyConfiguration()
; Parameters ....: None.
; Return values .: Success - Returns array with 3 elements:
;                  |$array[0] - Integer. Access type.
;                  |$array[1] - String. Proxy server list.
;                  |$array[2] - String. Proxy bypass list.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: Access types are defined in WinHttpconstants.au3:
;                  |[[$WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0]]
;                  |[[$WINHTTP_ACCESS_TYPE_NO_PROXY = 1]]
;                  |[[$WINHTTP_ACCESS_TYPE_NAMED_PROXY = 3]]
; Related .......: _WinHttpDetectAutoProxyConfigUrl, _WinHttpGetIEProxyConfigForCurrentUser, _WinHttpSetDefaultProxyConfiguration
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384095.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpGetIEProxyConfigForCurrentUser
; Description ...: Retrieves the Internet Explorer proxy configuration for the current user.
; Syntax.........: _WinHttpGetIEProxyConfigForCurrentUser()
; Parameters ....: None.
; Return values .: Success - Returns array with 4 elements:
;                  |$array[0] - if 1 indicates that the IE proxy configuration for the current user specifies "automatically detect settings",
;                  |$array[1] - auto-configuration URL if the IE proxy configuration for the current user specifies "Use automatic proxy configuration",
;                  |$array[2] - proxy URL if the IE proxy configuration for the current user specifies "use a proxy server",
;                  |$array[3] - optional proxy by-pass server list.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
;                  |2 - Internal failure.
; Author ........: trancexx
; Related .......: _WinHttpDetectAutoProxyConfigUrl, _WinHttpGetDefaultProxyConfiguration, _WinHttpSetDefaultProxyConfiguration
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384096.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpOpen
; Description ...: Initializes the use of WinHttp functions and returns a WinHttp-session handle.
; Syntax.........: _WinHttpOpen([$sUserAgent = Default [, $iAccessType = Default [, $sProxyName = Default [, $sProxyBypass = Default [, $iFlag = Default ]]]]])
; Parameters ....: $sUserAgent - [optional] The name of the application or entity calling the WinHttp functions.
;                  $iAccessType - [optional] Type of access required. Default is $WINHTTP_ACCESS_TYPE_NO_PROXY.
;                  $sProxyName - [optional] The name of the proxy server to use when proxy access is specified by setting $iAccessType to $WINHTTP_ACCESS_TYPE_NAMED_PROXY. Default is $WINHTTP_NO_PROXY_NAME.
;                  $sProxyBypass - [optional] An optional list of host names or IP addresses, or both, that should not be routed through the proxy when $iAccessType is set to $WINHTTP_ACCESS_TYPE_NAMED_PROXY. Default is $WINHTTP_NO_PROXY_BYPASS.
;                  $iFlag - [optional] Integer containing the flags that indicate various options affecting the behavior of this function. Default is 0.
; Return values .: Success - Returns valid session handle.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: <b>You are strongly discouraged to use WinHTTP in asynchronous mode with AutoIt. AutoIt's callback implementation can't handle reentrancy properly.</b>
;                  +For asynchronous mode set [[$iFlag]] to [[$WINHTTP_FLAG_ASYNC]]. In that case [[$WINHTTP_OPTION_CONTEXT_VALUE]] for the handle will inernally be set to [[$WINHTTP_FLAG_ASYNC]] also.
; Related .......: _WinHttpCloseHandle, _WinHttpConnect
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384098.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpOpenRequest
; Description ...: Creates an HTTP request handle.
; Syntax.........: _WinHttpOpenRequest($hConnect [, $sVerb = Default [, $sObjectName = Default [, $sVersion = Default [, $sReferrer = Default [, $sAcceptTypes = Default [, $iFlags = Default ]]]]]])
; Parameters ....: $hConnect - Handle to an HTTP session returned by _WinHttpConnect().
;                  $sVerb - [optional] HTTP verb to use in the request. Default is "GET".
;                  $sObjectName - [optional] The name of the target resource of the specified HTTP verb.
;                  $sVersion - [optional] HTTP version. Default is "HTTP/1.1"
;                  $sReferrer - [optional] URL of the document from which the URL in the request $sObjectName was obtained. Default is $WINHTTP_NO_REFERER.
;                  $sAcceptTypes - [optional] Media types accepted by the client. Default is $WINHTTP_DEFAULT_ACCEPT_TYPES
;                  $iFlags - [optional] Integer specifying the Internet flag values. Default is $WINHTTP_FLAG_ESCAPE_DISABLE
; Return values .: Success - Returns valid session handle.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Related .......: _WinHttpCloseHandle, _WinHttpConnect, _WinHttpSendRequest
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384099.aspx
;============================================================================================
; #FUNCTION# ====================================================================================================================
; Name ..........: _WinHttpQueryAuthSchemes
; Description ...: Returns the authorization schemes that are supported by the server.
; Syntax ........: _WinHttpQueryAuthSchemes($hRequest, Byref $iSupportedSchemes, Byref $iFirstScheme, Byref $iAuthTarget)
; Parameters ....: $hRequest - Valid handle returned by _WinHttpSendRequest().
;                  $iSupportedSchemes - [out] Supported authentication schemes. See remarks.
;                  $iFirstScheme - [out] First authentication scheme listed by the server. See remarks.
;                  $iAuthTarget - [out] A flag that contains the authentication target. See remarks.
; Return values .: Success - Returns 1
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: _WinHttpQueryAuthSchemes() is called after _WinHttpQueryHeaders().
;                  +Arguments are accepted ByRef.
;                  +Both [[$iSupportedSchemes]] and [[$iFirstScheme]] is set to combination of any of [[$WINHTTP_AUTH_SCHEME_]] flags.
;                  +[[$iAuthTarget]] parameter is set to one or more [[$WINHTTP_AUTH_TARGET_]] constants values.
; Related .......: _WinHttpSetCredentials, _WinHttpQueryHeaders, _WinHttpOpenRequest
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384100.aspx
; ===============================================================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpQueryDataAvailable
; Description ...: Returns the availability to be read with _WinHttpReadData().
; Syntax.........: _WinHttpQueryDataAvailable($hRequest)
; Parameters ....: $hRequest - handle returned by _WinHttpOpenRequest().
; Return values .: Success - Returns 1 if data is available.
;                          - Returns 0 if no data is available.
;                          - @extended receives the number of available bytes.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: _WinHttpReceiveResponse must have been called for this handle and completed before _WinHttpQueryDataAvailable is called.
; Related .......: _WinHttpOpenRequest, _WinHttpReadData, _WinHttpReceiveResponse
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384101.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpQueryHeaders
; Description ...: Retrieves header information associated with an HTTP request.
; Syntax.........: _WinHttpQueryHeaders($hRequest [, $iInfoLevel = Default [, $sName = Default [, $iIndex = Default ]]])
; Parameters ....: $hRequest - Handle returned by _WinHttpOpenRequest().
;                  $iInfoLevel - [optional] A combination of attribute and modifier flags. Default is $WINHTTP_QUERY_RAW_HEADERS_CRLF.
;                  $sName - [optional] Header name string. Default is $WINHTTP_HEADER_NAME_BY_INDEX.
;                  $iIndex - [optional] Index used to enumerate multiple headers with the same name
; Return values .: Success - Returns string that contains header.
;                          - @extended is set to the index of the next header
;                  Failure - Returns empty string and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Related .......: _WinHttpAddRequestHeaders, _WinHttpOpenRequest
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384102.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpQueryOption
; Description ...: Queries an Internet option on the specified handle.
; Syntax.........: _WinHttpQueryOption($hInternet, $iOption)
; Parameters ....: $hInternet - Handle on which to query information.
;                  $iOption - Internet option to query.
; Return values .: Success - Returns data containing requested information.
;                  Failure - Returns empty string and sets @error:
;                  |1 - Initial DllCall failed
;                  |2 - Main DllCall failed
; Author ........: trancexx
; Remarks .......: Type of the returned data varies on request.
; Related .......: _WinHttpSetOption
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384103.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpReadData
; Description ...: Reads data from a handle opened by the _WinHttpOpenRequest() function.
; Syntax.........: _WinHttpReadData($hRequest [, $iMode = Default [, $iNumberOfBytesToRead = Default ]])
; Parameters ....: $hRequest - Valid handle returned from a previous call to _WinHttpOpenRequest().
;                  $iMode - [optional] Integer representing reading mode. Default is 0 (charset is decoded as it is ANSI).
;                  $iNumberOfBytesToRead - [optional] The number of bytes to read. Default is 8192 bytes.
; Return values .: Success - Returns data read.
;                          - @extended receives the number of bytes read.
;                  Special: Sets @error to -1 if no more data to read (end reached).
;                  Failure - Returns empty string and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx, ProgAndy
; Remarks .......: [[$iMode]] can have these values:
;                  |[[0]] - ANSI
;                  |[[1]] - UTF8
;                  |[[2]] - Binary
; Related .......: _WinHttpOpenRequest, _WinHttpWriteData
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384104.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpReceiveResponse
; Description ...: Waits to receive the response to an HTTP request initiated by WinHttpSendRequest().
; Syntax.........: _WinHttpReceiveResponse($hRequest)
; Parameters ....: $hRequest - Handle returned by _WinHttpOpenRequest() and sent by _WinHttpSendRequest().
; Return values .: Success - Returns 1.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: Call to _WinHttpReceiveResponse() must be done before _WinHttpQueryDataAvailable() and _WinHttpReadData().
; Related .......: _WinHttpOpenRequest, _WinHttpSetTimeouts
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384105.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSendRequest
; Description ...: Sends the specified request to the HTTP server.
; Syntax.........: _WinHttpSendRequest($hRequest [, $sHeaders = Default [, $sOptional = Default [, $iTotalLength = Default [, $iContext = Default ]]]])
; Parameters ....: $hRequest - Handle returned by _WinHttpOpenRequest().
;                  $sHeaders - [optional] Additional headers to append to the request. Default is $WINHTTP_NO_ADDITIONAL_HEADERS.
;                  $vOptional - [optional] Optional data to send immediately after the request headers. Default is $WINHTTP_NO_REQUEST_DATA.
;                  $iTotalLength - [optional] Length, in bytes, of the total optional data sent. Default is 0.
;                  $iContext - [optional] Application-defined value that is passed, with the request handle, to any callback functions. Default is 0.
; Return values .: Success - Returns 1.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: Specifying optional data [[$vOptional]] will cause [[$iTotalLength]] to receive the size of that data if left default value.
; Related .......: _WinHttpOpenRequest
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384110.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSetCredentials
; Description ...: Passes the required authorization credentials to the server.
; Syntax.........: _WinHttpSetCredentials($hRequest, $iAuthTargets, $iAuthScheme, $sUserName, $sPassword)
; Parameters ....: $hRequest - Valid handle returned by _WinHttpOpenRequest().
;                  $iAuthTargets - Authentication target.
;                  $iAuthScheme - Authentication scheme.
;                  $sUserName - Valid user name.
;                  $sPassword - Valid password.
; Return values .: Success - Returns 1.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Related .......: _WinHttpOpenRequest
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384112.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSetDefaultProxyConfiguration
; Description ...: Sets the default WinHttp proxy configuration.
; Syntax.........: _WinHttpSetDefaultProxyConfiguration($iAccessType [, $sProxy = "" [, $sProxyBypass = ""])
; Parameters ....: $iAccessType - Integer. Access type.
;                  $sProxy - [optional] String. Proxy server list.
;                  $sProxyBypass - [optional] String. Proxy bypass list.
; Return values .: Success - Returns 1.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Related .......: _WinHttpDetectAutoProxyConfigUrl, _WinHttpGetDefaultProxyConfiguration, _WinHttpGetIEProxyConfigForCurrentUser
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384113.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSetOption
; Description ...: Sets an Internet option.
; Syntax.........: _WinHttpSetOption($hInternet, $iOption, $vSetting [, $iSize = Default ])
; Parameters ....: $hInternet - Handle on which to set data.
;                  $iOption - Integer value that contains the Internet option to set.
;                  $vSetting - Value of setting
;                  $iSize    - [optional] Size of $vSetting, required if $vSetting is pointer to memory block
; Return values .: Success - Returns 1.
;                  Failure - Returns 0 and sets @error:
;                  |1 - Invalid Internet option
;                  |2 - Size required
;                  |3 - Datatype of value does not fit to option
;                  |4 - DllCall failed
; Author ........: ProgAndy, trancexx
; Related .......: _WinHttpQueryOption
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384114.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSetStatusCallback
; Description ...: Sets up a callback function that WinHttp can call as progress is made during an operation.
; Syntax.........: _WinHttpSetStatusCallback($hInternet, $hInternetCallback [, $iNotificationFlags = Default ])
; Parameters ....: $hInternet - Handle for which the callback is to be set.
;                  $hInternetCallback - Callback function to call when progress is made.
;                  $iNotificationFlags - [optional] Flags to indicate which events activate the callback function. Default is $WINHTTP_CALLBACK_FLAG_ALL_NOTIFICATIONS.
; Return values .: Success - Returns a pointer to the previously defined status callback function or NULL if there was no previously defined status callback function.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: ProgAndy
; Modified.......: trancexx
; Related .......: _WinHttpOpen
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384115.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSetTimeouts
; Description ...: Sets time-outs involved with HTTP transactions.
; Syntax.........: _WinHttpSetTimeouts($hInternet [, $iResolveTimeout = Default [, $iConnectTimeout = Default [, $iSendTimeout = Default [, $iReceiveTimeout = Default ]]]])
; Parameters ....: $hInternet - Handle returned by _WinHttpOpen() or _WinHttpOpenRequest().
;                  $iResolveTimeout - [optional] Time-out value, in milliseconds, to use for name resolution. Default is 0 ms.
;                  $iConnectTimeout - [optional] Time-out value, in milliseconds, to use for server connection requests. Default is 60000 ms.
;                  $iSendTimeout - [optional] Time-out value, in milliseconds, to use for sending requests. Default is 30000 ms.
;                  $iReceiveTimeout - [optional] Time-out value, in milliseconds, to receive a response to a request. Default is 30000 ms.
; Return values .: Success - Returns 1.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Remarks .......: Initial values are:
;                  |- $iResolveTimeout = 0
;                  |- $iConnectTimeout = 60000
;                  |- $iSendTimeout = 30000
;                  |- $iReceiveTimeout = 30000
; Related .......: _WinHttpReceiveResponse
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384116.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSimpleBinaryConcat
; Description ...: Concatenates two binary data returned by _WinHttpReadData() in binary mode.
; Syntax.........: _WinHttpSimpleBinaryConcat(ByRef $bBinary1, ByRef $bBinary2)
; Parameters ....: $bBinary1 - Binary data that is to be concatenated.
;                  $bBinary2 - Binary data to concatenate.
; Return values .: Success - Returns concatenated binary data.
;                  Failure - Returns empty binary and sets @error:
;                  |1 - Invalid input.
; Author ........: ProgAndy
; Modified.......: trancexx
; Related .......: _WinHttpReadData
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpSimpleFormFill
; Description ...: Fills web form.
; Syntax.........: _WinHttpSimpleFormFill(ByRef $hInternet [, $sActionPage = Default [, $sFormId = Default [, $sFldId1 = Default [, $sDta1 = Default [, (...) [, $sAdditionalData]]]]]])
; Parameters ....: $hInternet - Handle returned by _WinHttpConnect() or string variable with form.
;                  $sActionPage -  [optional] path to the page with form or session handle if $hInternet is string (default: "" - empty string; meaning 'default' page on the server in former).
;                  $sFormId - [optional] Id of the form. Can be name or zero-based index too (read Remarks section).
;                  $sFldId1 - [optional] Id of the input.
;                  $sDta1 - [optional] Data to set to coresponding field.
;                  (...) - [optional] Other pairs of Id/Data. Overall number of fields is 40.
;                  $sAdditionalData - [optional] Additional data (read Remarks section).
; Return values .: Success - Returns HTML source of the page returned by the server on submited form. @extended is set to HTTP status code.
;                  Failure - Returns empty string and sets @error:
;                  |1 - No forms on the page
;                  |2 - Invalid form
;                  |3 - No forms with specified attributes on the page
;                  |4 - Connection problems
;                  |5 - form's "action" is invalid
;                  |6 - invalid session handle passed
; Author ........: trancexx
; Remarks .......: In case form requires redirection and [[$hInternet]] is internet handle, this handle will be closed and replaced with new and required one.
;                  +When [[$hInternet]] is form string, form's "action" must specify URL and [[$sActionPage]] parameter must be session handle. On succesful call this variable will be changed to connection handle of the internally made connection.
;                  Don't forget to close this handle after the function returns and when no longer needed.
;                  +[[$sFormId]] specifies Id of the form same as [[.getElementById(FormId)]]. Aditionally you can use [["index:FormIndex"]] to
;                  identify form by its zero-based index number (in case of e.g. three forms on some page first one will have index=0, second index=1, third index=2).
;                  Use [["name:FormName"]] to identify form by its name like with [[.getElementsByName(FormName)]]. FormName will be taken to be what's right of colon mark.
;                  In that case first form with that name is filled.
;                  +As for fields, If [["name:FieldName"]] option is used all the fields except last with that name are removed from the form. Last one is filled with specified [[$sDta]] data.
;                  +This function can be used to fill forms with up to 40 fields at once.
;                  +"Submit" control you want to keep (click) set to True. If no such control is set then the first one found in the form is "clicked". You can also use [["type:submit", zero_based_index_of_the_submit]] to "click" if no id or name is available.
;                  +All other "submit" controls are removed from the submited form (including images).
;                  +If form is submitted by clicking an image then pass click coordinates [["name:image_name", "Xcoord,Ycoord"]] or [["image_id", "Xcoord,Ycoord"]]. If the image has no name or id then you can use its index of appearance [["type:image", "zero_based_index_of_the_image Xcoord,Ycoord"]].
;                  +"Checkbox" and "Button" input types are removed from the submitted form unless explicitly set. Same goes for "Radio" with exception that
;                  only one such control can be set, the rest are removed. These controls are set by their values. Wrong value makes them invalid and therefore not part of the submited data.
;                  +All other non-set fields are left default.
;                  +Last (superfluous) [[$sAdditionalData]] argument can be used to pass authorization credentials in form [["[CRED:username:password]"]], magic string to ignore certificate errors in form [["[IGNORE_CERT_ERRORS]"]], change output type to extended array with [["[RETURN_ARRAY]"]] moniker, and/or HTTP request header data to add.
;                  If array is returned then [[array[0]]] is the response header, [[array[1]]] is returned data and [[array[2]]] is URL of the final request.
;                  +
;                  +If this function is used to upload multiple files then there are two available ways. Default would be to submit the form following RFC2388 specification.
;                  In that case every file is represented as multipart/mixed part embedded within the multipart/form-data.
;                  +If you want to upload using alternative way (to avoid certain PHP bug that could exist on server side) then prefix the file string with [["PHP#50338:"]] string.
;                  +For example: [[..."name:files[]", "PHP#50338:" & $sFile1 & "|" & $sFile2 ...]]
;                  +Muliple files are always separated with vertical line ASCII character when filling the form.
; Related .......: _WinHttpConnect, _WinHttpSimpleFormFill_SetUploadCallback
;============================================================================================
; #FUNCTION# ====================================================================================================================
; Name...........: _WinHttpSimpleFormFill_SetUploadCallback
; Description ...: Sets user defined function as callback function for _WinHttpSimpleFormFill
; Syntax.........: _WinHttpSimpleFormFill_SetUploadCallback($vCallback [, $iNumChunks = 100 ])
; Parameters ....: $vCallback - UDF's name
;                  $iNumChunks - [optional] number of chunks to send during form submitting. Default is 100.
; Return values .: Undefined.
; Author ........: trancexx
; Remarks .......: Unregistering is done by passing [[0]] as first argument.
; Related .......: _WinHttpSimpleFormFill
; ===============================================================================================================================
; #FUNCTION# ====================================================================================================================
; Name...........: _WinHttpSimpleReadData
; Description ...: Reads data from a request
; Syntax.........: _WinHttpSimpleReadData($hRequest [, $iMode = Default ])
; Parameters ....: $hRequest - request handle after _WinHttpReceiveResponse
;                  $iMode         - [optional] type of data returned
;                  |0 - ASCII-String
;                  |1 - UTF-8-String
;                  |2 - binary data
; Return values .: Success      - String or binary depending on $iMode
;                  Failure      - empty string or empty binary (mode 2) and set @error
;                  |1 - invalid mode
;                  |2 - no data available
; Author ........: ProgAndy
; Modified.......: trancexx
; Remarks .......: In case of default reading mode, if the server specifies utf-8 content type, function will force UTF-8 string.
; Related .......: _WinHttpReadData, _WinHttpSimpleRequest, _WinHttpSimpleSSLRequest
; ===============================================================================================================================
; #FUNCTION# ====================================================================================================================
; Name...........: _WinHttpSimpleReadDataAsync
; Description ...: Reads data from a request in asynchronous mode
; Syntax.........: _WinHttpSimpleReadDataAsync($hInternet, Byref $pBuffer [, $iNumberOfBytesToRead = Default ])
; Parameters ....: $hInternet - Request handle (first parameter while in callback function).
;                  $pBuffer - Pointer to memory buffer to which to read.
;                  $iNumberOfBytesToRead - [optional] The number of bytes to read. Default is 8192 bytes.
;                  |0 - ASCII-String
;                  |1 - UTF-8-String
;                  |2 - binary data
; Return values .: Same as for _WinHttpReadData. Due to async nature here it has no meaning except in case of possible error.
; Author ........: trancexx
; Remarks .......: <b>You are strongly discouraged to use WinHTTP in asynchronous mode with AutoIt. AutoIt's callback implementation can't handle reentrancy properly.</b>
;                  +WinHttp is rentrant during asynchronous completion callback. Make sure you have only one callback running and only one request handled though it at time.
;                  +Also make sure memory buffer is at least 8192 bytes in size if [[$iNumberOfBytesToRead]] is left default.
; Related .......: _WinHttpSimpleReadData, _WinHttpReadData
; ===============================================================================================================================
; #FUNCTION# ====================================================================================================================
; Name...........: _WinHttpSimpleRequest
; Description ...: A function to send a request in a simpler form
; Syntax.........: _WinHttpSimpleRequest($hConnect, $sType, $sPath [, $sReferrer = Default [, $sDta = Default [, $sHeader = Default [, $fGetHeaders = Default [, $iMode = Default ]]]]])
; Parameters ....: $hConnect  - Handle from _WinHttpConnect
;                  $sType       - [optional] GET or POST (default: GET)
;                  $sPath       - [optional] request path (default: "" - empty string; meaning 'default' page on the server)
;                  $sReferrer   - [optional] referrer (default: $WINHTTP_NO_REFERER)
;                  $sDta        - [optional] POST-Data (default: $WINHTTP_NO_REQUEST_DATA)
;                  $sHeader     - [optional] additional Headers (default: $WINHTTP_NO_ADDITIONAL_HEADERS)
;                  $fGetHeaders - [optional] return response headers (default: False)
;                  $iMode       - [optional] reading mode of result
;                  |0 - ASCII-text
;                  |1 - UTF-8 text
;                  |2 - binary data
; Return values .: Success      - response data if $fGetHeaders = False (default)
;                  |Array if $fGetHeaders = True
;                  | [0] - response headers
;                  | [1] - response data
;                  Failure      - 0 and set @error
;                  |1 - could not open request
;                  |2 - could not send request
;                  |3 - could not receive response
;                  |4 - $iMode is not valid
; Author ........: ProgAndy
; Modified.......: trancexx
; Related .......: _WinHttpSimpleSSLRequest, _WinHttpSimpleSendRequest, _WinHttpSimpleSendSSLRequest, _WinHttpQueryHeaders, _WinHttpSimpleReadData
; ===============================================================================================================================
; #FUNCTION# ====================================================================================================================
; Name...........: _WinHttpSimpleSendRequest
; Description ...: A function to send a request in a simpler form, but not read the data
; Syntax.........: _WinHttpSimpleSendRequest($hConnect, $sType, $sPath [, $sReferrer = Default [, $sDta = Default [, $sHeader = Default ]]])
; Parameters ....: $hConnect  - Handle from _WinHttpConnect
;                  $sType       - [optional] GET or POST (default: GET)
;                  $sPath       - [optional] request path (default: "" - empty string; meaning 'default' page on the server)
;                  $sReferrer   - [optional] referrer (default: $WINHTTP_NO_REFERER)
;                  $sDta        - [optional] POST-Data (default: $WINHTTP_NO_REQUEST_DATA)
;                  $sHeader     - [optional] additional Headers (default: $WINHTTP_NO_ADDITIONAL_HEADERS)
; Return values .: Success      - handle of request after _WinHttpReceiveResponse.
;                  Failure      - 0 and set @error
;                  |1 - could not open request
;                  |2 - could not send request
;                  |3 - could not receive response
; Author ........: ProgAndy
; Related .......: _WinHttpSimpleRequest, _WinHttpSimpleSendSSLRequest, _WinHttpSimpleReadData
; ===============================================================================================================================
; #FUNCTION# ====================================================================================================================
; Name...........: _WinHttpSimpleSendSSLRequest
; Description ...: A function to send a SSL request in a simpler form, but not read the data
; Syntax.........: _WinHttpSimpleSendSSLRequest($hConnect [, $sType [, $sPath [, $sReferrer = Default [, $sDta = Default [, $sHeader = Default ]]]]])
; Parameters ....: $hConnect  - Handle from _WinHttpConnect
;                  $sType       - [optional] GET or POST (default: GET)
;                  $sPath       - [optional] request path (default: "" - empty string; meaning 'default' page on the server)
;                  $sReferrer   - [optional] referrer (default: $WINHTTP_NO_REFERER)
;                  $sDta        - [optional] POST-Data (default: $WINHTTP_NO_REQUEST_DATA)
;                  $sHeader     - [optional] additional Headers (default: $WINHTTP_NO_ADDITIONAL_HEADERS)
; Return values .: Success      - handle of request after _WinHttpReceiveResponse.
;                  Failure      - 0 and set @error
;                  |1 - could not open request
;                  |2 - could not send request
;                  |3 - could not receive response
; Author ........: ProgAndy
; Related .......: _WinHttpSimpleSSLRequest, _WinHttpSimpleSendRequest, _WinHttpSimpleReadData
; ===============================================================================================================================
; #FUNCTION# ====================================================================================================================
; Name...........: _WinHttpSimpleSSLRequest
; Description ...: A function to send a SSL request in a simpler form
; Syntax.........: _WinHttpSimpleSSLRequest($hConnect [, $sType [, $sPath [, $sReferrer = Default [, $sDta = Default [, $sHeader = Default [, $fGetHeaders = Default [, $iMode = Default ]]]]]]])
; Parameters ....: $hConnect  - Handle from _WinHttpConnect
;                  $sType       - [optional] GET or POST (default: GET)
;                  $sPath       - [optional] request path (default: "" - empty string; meaning 'default' page on the server)
;                  $sReferrer   - [optional] referrer (default: $WINHTTP_NO_REFERER)
;                  $sDta        - [optional] POST-Data (default: $WINHTTP_NO_REQUEST_DATA)
;                  $sHeader     - [optional] additional Headers (default: $WINHTTP_NO_ADDITIONAL_HEADERS)
;                  $fGetHeaders - [optional] return response headers (default: False)
;                  $iMode       - [optional] reading mode of result
;                  |0 - ASCII-text
;                  |1 - UTF-8 text
;                  |2 - binary data
; Return values .: Success      - response data if $fGetHeaders = False (default)
;                  |Array if $fGetHeaders = True
;                  | [0] - response headers
;                  | [1] - response data
;                  Failure      - 0 and set @error
;                  |1 - could not open request
;                  |2 - could not send request
;                  |3 - could not receive response
;                  |4 - $iMode is not valid
; Author ........: ProgAndy
; Modified.......: trancexx
; Related .......: _WinHttpSimpleRequest, _WinHttpSimpleSendSSLRequest, _WinHttpSimpleSendRequest, _WinHttpQueryHeaders, _WinHttpSimpleReadData
; ===============================================================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpTimeFromSystemTime
; Description ...: Formats a system date and time according to the HTTP version 1.0 specification.
; Syntax.........: _WinHttpTimeFromSystemTime()
; Parameters ....: None.
; Return values .: Success - Returns time string.
;                  Failure - Returns empty string and sets @error:
;                  |1 - Initial DllCall failed
;                  |2 - Main DllCall failed
; Author ........: trancexx
; Related .......: _WinHttpTimeToSystemTime
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384117.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpTimeToSystemTime
; Description ...: Takes an HTTP time/date string and converts it to array (SYSTEMTIME structure values).
; Syntax.........: _WinHttpTimeToSystemTime($sHttpTime)
; Parameters ....: $sHttpTime - Date/time string to convert.
; Return values .: Success - Returns array with 8 elements:
;                  |$array[0] - Year,
;                  |$array[1] - Month,
;                  |$array[2] - DayOfWeek,
;                  |$array[3] - Day,
;                  |$array[4] - Hour,
;                  |$array[5] - Minute,
;                  |$array[6] - Second.,
;                  |$array[7] - Milliseconds.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx
; Related .......: _WinHttpTimeFromSystemTime
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384118.aspx
;============================================================================================
; #FUNCTION# ;===============================================================================
; Name...........: _WinHttpWriteData
; Description ...: Writes request data to an HTTP server.
; Syntax.........: _WinHttpWriteData($hRequest, $vData [, $iMode = Default ])
; Parameters ....: $hRequest - Valid handle returned by _WinHttpSendRequest().
;                  $vData - Data to write.
;                  $iMode - [optional] Integer representing writing mode. Default is 0 - write ANSI string.
; Return values .: Success - Returns 1
;                          - @extended receives the number of bytes written.
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
; Author ........: trancexx, ProgAndy
; Remarks .......: [[$vData]] variable is either string or binary data to write.
;                  [[$iMode]] can have these values:
;                  |[[0]] - to write ANSI string
;                  |[[1]] - to write binary data
; Related .......: _WinHttpSendRequest, _WinHttpReadData
; Link ..........: http://msdn.microsoft.com/en-us/library/aa384120.aspx
;============================================================================================

; #INTERNAL FUNCTIONS# ;=====================================================================

Func __WinHttpFileContent($sAccept, $sName, $sFileString, $sBoundaryMain = "")
Func __WinHttpMIMEType($sFileName)
Func __WinHttpMIMEAssocString()
Func __WinHttpCharSet($sContentType)
Func __WinHttpURLEncode($vData, $sEncType = "")
Func __WinHttpHTMLDecode($vData)
Func __WinHttpNormalizeActionURL($sActionPage, ByRef $sAction, ByRef $iScheme, ByRef $sNewURL, ByRef $sEnctype, ByRef $sMethod, $sURL = "")
Func __WinHttpHTML5FormAttribs(ByRef $aDtas, ByRef $aFlds, ByRef $iNumParams, ByRef $aInput, ByRef $sAction, ByRef $sEnctype, ByRef $sMethod)
Func __WinHttpNormalizeForm(ByRef $sForm, $sSpr1, $sSpr2)
Func __WinHttpFinalizeCtrls($sSubmit, $sRadio, $sCheckBox, $sButton, ByRef $sAddData, $sGrSep, $sBound = "")
Func __WinHttpTrimBounds(ByRef $sDta, $sBound)
Func __WinHttpFormAttrib(ByRef $aAttrib, $i, $sElement)
Func __WinHttpAttribVal($sIn, $sAttrib)
Func __WinHttpFormSend($hInternet, $sMethod, $sAction, $fMultiPart, $sBoundary, $sAddData, $fSecure = False, $sAdditionalHeaders = "", $sCredName = "", $sCredPass = "", $iIgnoreAllCertErrors = 0)
Func __WinHttpSetCredentials($hRequest, $sHeaders = "", $sOptional = "", $sCredName = "", $sCredPass = "", $iFormFill = 0)
Func __WinHttpFormUpload($hRequest, $sHeaders, $sData)
Func __WinHttpDefault(ByRef $vInput, $vOutput)
Func __WinHttpMemGlobalFree($pMem)
Func __WinHttpPtrStringLenW($pStr)
Func __WinHttpUA()
Func __WinHttpSysInfo()
Func __WinHttpVer()
Func _WinHttpBinaryConcat(ByRef $bBinary1, ByRef $bBinary2)
