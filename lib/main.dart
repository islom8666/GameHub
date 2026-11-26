import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'translations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GameHubApp());
}

class GameHubApp extends StatefulWidget {
  const GameHubApp({super.key});

  @override
  State<GameHubApp> createState() => _GameHubAppState();
}

class _GameHubAppState extends State<GameHubApp> {
  AppLanguage _currentLanguage = AppLanguage.uz;

  void _changeLanguage(AppLanguage lang) {
    setState(() {
      _currentLanguage = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Translations.get(_currentLanguage, 'app_name'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: GameHubHomePage(
        currentLanguage: _currentLanguage,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}

class GameHubHomePage extends StatefulWidget {
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const GameHubHomePage({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<GameHubHomePage> createState() => _GameHubHomePageState();
}

class _GameHubHomePageState extends State<GameHubHomePage> {
  InAppWebViewController? _webViewController;
  final TextEditingController _urlController =
  TextEditingController(text: 'https://example.com');
  double _progress = 0;
  bool _hasError = false;

  String _t(String key) => Translations.get(widget.currentLanguage, key);

  void _loadUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    _urlController.text = trimmed;
    setState(() {
      _hasError = false;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(trimmed)),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('app_name')),
        actions: [
          IconButton(
            tooltip: _t('back'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _webViewController?.canGoBack() ?? false) {
                await _webViewController?.goBack();
              }
            },
          ),
          IconButton(
            tooltip: _t('forward'),
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (await _webViewController?.canGoForward() ?? false) {
                await _webViewController?.goForward();
              }
            },
          ),
          IconButton(
            tooltip: _t('refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _hasError = false);
              _webViewController?.reload();
            },
          ),
          PopupMenuButton<AppLanguage>(
            tooltip: _t('language'),
            icon: const Icon(Icons.language),
            initialValue: widget.currentLanguage,
            onSelected: widget.onLanguageChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: AppLanguage.uz, child: Text("O'zbekcha")),
              PopupMenuItem(value: AppLanguage.ru, child: Text('Русский')),
              PopupMenuItem(value: AppLanguage.en, child: Text('English')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: _t('url_placeholder'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: _loadUrl,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _loadUrl(_urlController.text),
                  child: Text(_t('load_url')),
                ),
              ],
            ),
          ),
          if (_progress < 1.0 && !_hasError)
            LinearProgressIndicator(value: _progress),
          Expanded(
            child: _hasError
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_t('no_internet')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _loadUrl(_urlController.text),
                    child: Text(_t('retry')),
                  ),
                ],
              ),
            )
                : InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(_urlController.text),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _hasError = false;
                  if (url != null) {
                    _urlController.text = url.toString();
                  }
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _progress = 1.0;
                  if (url != null) {
                    _urlController.text = url.toString();
                  }
                });
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
        ],
      ),
    );
  }
}