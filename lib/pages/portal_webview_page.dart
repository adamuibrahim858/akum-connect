import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PortalWebViewPage extends StatefulWidget {
  final String initialUrl;
  final String title;

  const PortalWebViewPage({
    super.key,
    this.initialUrl = 'https://students.akum.edu.ng/student/login',
    this.title = 'School Portal',
  });

  @override
  State<PortalWebViewPage> createState() => _PortalWebViewPageState();
}

class _PortalWebViewPageState extends State<PortalWebViewPage> {
  WebViewController? _controller;
  bool _isPlatformSupported = false;
  double _loadingProgress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _currentUrl = '';
  String _pageTitle = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _pageTitle = widget.title;

    // Determine if webview_flutter platform implementation is available
    // (Available on Android & iOS; not available on Linux/Windows desktop by default)
    _isPlatformSupported = !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS) &&
        WebViewPlatform.instance != null;

    if (_isPlatformSupported) {
      _initWebView();
    } else {
      _isLoading = false;
      // On desktop platforms, automatically open in user's default browser
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInExternalBrowser();
      });
    }
  }

  void _initWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress / 100.0;
                  if (progress >= 100) {
                    _isLoading = false;
                  }
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _currentUrl = url;
                });
              }
            },
            onPageFinished: (String url) async {
              if (_controller == null) return;
              final canGoBack = await _controller!.canGoBack();
              final canGoForward = await _controller!.canGoForward();
              final title = await _controller!.getTitle();
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _canGoBack = canGoBack;
                  _canGoForward = canGoForward;
                  _currentUrl = url;
                  if (title != null && title.trim().isNotEmpty) {
                    _pageTitle = title.trim();
                  }
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (error.isForMainFrame ?? true) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                    _errorMessage = error.description.isNotEmpty
                        ? error.description
                        : 'Unable to connect to the portal server.';
                  });
                }
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final uri = Uri.tryParse(request.url);
              if (uri != null) {
                final scheme = uri.scheme.toLowerCase();
                if (scheme == 'tel' ||
                  scheme == 'mailto' ||
                  scheme == 'sms' ||
                  scheme == 'whatsapp') {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationDecision.prevent;
                }
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.initialUrl));

      _controller = controller;
    } catch (e) {
      debugPrint("Error initializing WebViewController: $e");
      if (mounted) {
        setState(() {
          _isPlatformSupported = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateNavState() async {
    if (_controller == null) return;
    final canGoBack = await _controller!.canGoBack();
    final canGoForward = await _controller!.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  Future<void> _reload() async {
    if (!_isPlatformSupported || _controller == null) {
      _openInExternalBrowser();
      return;
    }
    setState(() {
      _hasError = false;
      _isLoading = true;
      _loadingProgress = 0.05;
    });
    await _controller!.reload();
  }

  Future<void> _openInExternalBrowser() async {
    final urlToOpen = _currentUrl.isNotEmpty ? _currentUrl : widget.initialUrl;
    final uri = Uri.tryParse(urlToOpen);
    if (uri != null) {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open in external browser"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _copyUrlToClipboard() async {
    final urlToCopy = _currentUrl.isNotEmpty ? _currentUrl : widget.initialUrl;
    await Clipboard.setData(ClipboardData(text: urlToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text("Portal link copied to clipboard")),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearCookiesAndCache() async {
    if (_controller != null) {
      await _controller!.clearCache();
    }
    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cache and cookies cleared successfully"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      _reload();
    }
  }

  String _getHostName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : 'students.akum.edu.ng';
    } catch (_) {
      return 'students.akum.edu.ng';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPlatformSupported || !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isPlatformSupported && _controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
          await _updateNavState();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 68,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            tooltip: 'Back',
            onPressed: () async {
              if (_isPlatformSupported &&
                  _controller != null &&
                  await _controller!.canGoBack()) {
                await _controller!.goBack();
                await _updateNavState();
              } else {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _pageTitle.isNotEmpty ? _pageTitle : widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 11,
                          color: Colors.lightGreenAccent,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            _getHostName(_currentUrl),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (_isPlatformSupported)
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Reload',
                onPressed: _reload,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'browser':
                    _openInExternalBrowser();
                    break;
                  case 'copy':
                    _copyUrlToClipboard();
                    break;
                  case 'home':
                    if (_isPlatformSupported && _controller != null) {
                      _controller!.loadRequest(Uri.parse(widget.initialUrl));
                    } else {
                      _openInExternalBrowser();
                    }
                    break;
                  case 'clear':
                    _clearCookiesAndCache();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'home',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.home_outlined, color: Colors.green),
                    title: Text('Portal Login Home'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'browser',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.open_in_browser_rounded, color: Colors.blue),
                    title: Text('Open in Browser'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.copy_rounded, color: Colors.orange),
                    title: Text('Copy Portal Link'),
                  ),
                ),
                if (_isPlatformSupported) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.cleaning_services_outlined, color: Colors.redAccent),
                      title: Text('Clear Cache & Cookies'),
                    ),
                  ),
                ],
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _isLoading && _isPlatformSupported
                ? LinearProgressIndicator(
                    value: _loadingProgress > 0 ? _loadingProgress : null,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    minHeight: 3,
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: _buildBody(),
        bottomNavigationBar: _isPlatformSupported ? _buildBottomBar() : null,
      ),
    );
  }

  Widget _buildBody() {
    // If running on Desktop (Linux/Windows) or platforms without webview_flutter backend
    if (!_isPlatformSupported) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "AKUM Student Portal",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      _getHostName(widget.initialUrl),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Access course registrations, semester results, payment receipts, and profile records securely on the official university portal.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openInExternalBrowser,
                    icon: const Icon(Icons.open_in_browser_rounded, size: 22),
                    label: const Text(
                      "Open Portal in Browser",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copyUrlToClipboard,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text("Copy Portal URL"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "In-app embedded WebView activates on Android & iOS mobile devices.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Supported platform (Android/iOS)
    return Stack(
      children: [
        if (!_hasError && _controller != null)
          WebViewWidget(controller: _controller!),

        if (_isLoading && _loadingProgress < 0.6 && !_hasError)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 48,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Connecting to School Portal...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "students.akum.edu.ng",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _loadingProgress > 0 ? _loadingProgress : null,
                        backgroundColor: Colors.green.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade700,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_hasError)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Unable to Connect to Portal",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage.isNotEmpty
                        ? _errorMessage
                        : "Please check your internet connection and try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text("Try Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openInExternalBrowser,
                    icon: const Icon(Icons.open_in_browser_rounded, size: 20),
                    label: const Text("Open in External Browser"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              iconSize: 20,
              color: _canGoBack ? Colors.green.shade800 : Colors.grey.shade300,
              tooltip: 'Go Back',
              onPressed: _canGoBack
                  ? () async {
                      if (_controller != null) {
                        await _controller!.goBack();
                        await _updateNavState();
                      }
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              iconSize: 20,
              color: _canGoForward ? Colors.green.shade800 : Colors.grey.shade300,
              tooltip: 'Go Forward',
              onPressed: _canGoForward
                  ? () async {
                      if (_controller != null) {
                        await _controller!.goForward();
                        await _updateNavState();
                      }
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.home_rounded),
              iconSize: 24,
              color: Colors.green.shade800,
              tooltip: 'Portal Login',
              onPressed: () {
                if (_controller != null) {
                  _controller!.loadRequest(Uri.parse(widget.initialUrl));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              iconSize: 22,
              color: Colors.grey.shade700,
              tooltip: 'Copy Link',
              onPressed: _copyUrlToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              iconSize: 22,
              color: Colors.grey.shade700,
              tooltip: 'External Browser',
              onPressed: _openInExternalBrowser,
            ),
          ],
        ),
      ),
    );
  }
}
