import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'translations.dart';

const String kDefaultHubUrl = 'https://topgamehub.uz';
const String kGtaUrl = 'https://www.inxanitylabs.com/games/gta-v';
const String kNfsuUrl = 'https://nfsu.cc/launcher.html';
const Color kDarkBgColor = Color(0xFF12161F);

final ChromeSafariBrowser _chromeBrowser = ChromeSafariBrowser();

bool _isGtaLink(Uri? uri) {
  if (uri == null) return false;
  final s = uri.toString().toLowerCase();
  return s.contains('id=0') ||
      s.contains('gta-v') ||
      s.contains('gta-6') ||
      s.contains('gta5') ||
      s.contains('gta6') ||
      s.contains('fiveplay.lol') ||
      s.contains('inxanitylabs.com');
}

bool _isNfsuLink(Uri? uri) {
  if (uri == null) return false;
  final s = uri.toString().toLowerCase();
  return s.contains('id=4') ||
      s.contains('underground') ||
      s.contains('nfsu');
}

Future<void> _launchInChrome(String targetUrl) async {
  await _chromeBrowser.open(
    url: WebUri(targetUrl),
    settings: ChromeSafariBrowserSettings(
      shareState: CustomTabsShareState.SHARE_STATE_ON,
      instantAppsEnabled: true,
    ),
  );
}

const String _kGameClickBridgeJs = """
(function() {
  if (window.__tghGameBridgeInstalled) return;
  window.__tghGameBridgeInstalled = true;

  document.addEventListener('click', function(e) {
    const el = e.target.closest('a, button, div, article');
    if (!el) return;
    const text = (el.innerText || '').toUpperCase();
    if (text.length > 250) return;

    if (text.includes('GRAND THEFT AUTO V') || text.includes('GTA 6') || text.includes('GTA VI')) {
      e.preventDefault();
      e.stopPropagation();
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('openGameInChrome', '$kGtaUrl');
      }
      return;
    }

    if (text.includes('NEED FOR SPEED: UNDERGROUND') || text.includes('NFS UNDERGROUND')) {
      e.preventDefault();
      e.stopPropagation();
      window.location.href = '$kNfsuUrl';
    }
  }, true);
})();
""";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: kDarkBgColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const GameHubApp());
}

class GameHubApp extends StatefulWidget {
  const GameHubApp({super.key});

  @override
  State<GameHubApp> createState() => _GameHubAppState();
}

class _GameHubAppState extends State<GameHubApp> {
  final AppLanguage _currentLanguage = AppLanguage.uz;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Translations.get(_currentLanguage, 'app_name'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kDarkBgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameHubHomePage(),
    );
  }
}

class GameHubHomePage extends StatefulWidget {
  const GameHubHomePage({super.key});

  @override
  State<GameHubHomePage> createState() => _GameHubHomePageState();
}

class _GameHubHomePageState extends State<GameHubHomePage> {
  InAppWebViewController? _webViewController;
  bool _hasError = false;
  bool _isFullscreen = false;

  void _reloadHub() {
    setState(() {
      _hasError = false;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(kDefaultHubUrl)),
    );
  }

  Future<void> _handleBackPressed() async {
    if (_isFullscreen) {
      await _webViewController?.evaluateJavascript(
        source:
        'if (document.fullscreenElement) { document.exitFullscreen().catch(()=>{}); }',
      );
      if (mounted) {
        setState(() => _isFullscreen = false);
      }
      return;
    }
    if (await _webViewController?.canGoBack() ?? false) {
      await _webViewController?.goBack();
      return;
    }
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: kDarkBgColor,
        body: SafeArea(
          top: !_isFullscreen,
          bottom: !_isFullscreen,
          child: _hasError
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Internet aloqasini tekshiring',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _reloadHub,
                  child: const Text('Qayta urinish'),
                ),
              ],
            ),
          )
              : InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(kDefaultHubUrl),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              supportMultipleWindows: true,
              transparentBackground: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: 'openGameInChrome',
                callback: (args) async {
                  final target =
                  args.isNotEmpty && args.first is String
                      ? args.first as String
                      : kGtaUrl;
                  await _launchInChrome(target);
                  return true;
                },
              );
            },
            onEnterFullscreen: (controller) {
              setState(() => _isFullscreen = true);
            },
            onExitFullscreen: (controller) {
              setState(() => _isFullscreen = false);
            },
            onLoadStart: (controller, url) async {
              setState(() {
                _hasError = false;
              });
              await controller.evaluateJavascript(
                source: _kGameClickBridgeJs,
              );
            },
            onLoadStop: (controller, url) async {
              await controller.evaluateJavascript(
                source: _kGameClickBridgeJs,
              );
            },
            shouldOverrideUrlLoading:
                (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (_isGtaLink(uri)) {
                await _launchInChrome(kGtaUrl);
                return NavigationActionPolicy.CANCEL;
              }
              if (_isNfsuLink(uri)) {
                await controller.loadUrl(
                  urlRequest: URLRequest(url: WebUri(kNfsuUrl)),
                );
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onCreateWindow: (controller, createWindowAction) async {
              final uri = createWindowAction.request.url;
              if (_isGtaLink(uri)) {
                await _launchInChrome(kGtaUrl);
                return true;
              }
              if (_isNfsuLink(uri)) {
                await controller.loadUrl(
                  urlRequest: URLRequest(url: WebUri(kNfsuUrl)),
                );
                return true;
              }
              if (uri != null) {
                await controller.loadUrl(
                  urlRequest: createWindowAction.request,
                );
              }
              return true;
            },
            onReceivedError: (controller, request, error) {
              if (request.isForMainFrame ?? true) {
                setState(() {
                  _hasError = true;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}