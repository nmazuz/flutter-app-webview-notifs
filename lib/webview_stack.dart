import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewStack extends StatefulWidget {
  const WebViewStack({
    required this.controller,
    this.onUrlChange,
    Key? key,
  }) : super(key: key);

  final Completer<WebViewController> controller;
  final Function(String)? onUrlChange;

  @override
  State<WebViewStack> createState() => _WebViewStackState();
}

class _WebViewStackState extends State<WebViewStack> {
  var loadingPercentage = 0;
  String _currentUrl = 'https://snaplist.one';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebView(
          initialUrl: _currentUrl,
          userAgent: "random",
          javascriptMode: JavascriptMode.unrestricted,
          javascriptChannels: {
            _createJavascriptChannel(context),
          },
          onWebViewCreated: (webViewController) {
            widget.controller.complete(webViewController);
          },
          onPageStarted: (url) {
            setState(() {
              loadingPercentage = 0;
            });
            _handleUrlChange(url);
          },
          onProgress: (progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageFinished: (url) {
            setState(() {
              loadingPercentage = 100;
            });
            // Inject JavaScript to monitor page changes
            _injectJavascriptToDetectRouteChange(widget.controller.future);
          },
        ),
        if (loadingPercentage < 100)
          LinearProgressIndicator(
            value: loadingPercentage / 100.0,
          ),
      ],
    );
  }

  JavascriptChannel _createJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
      name: 'PageChangeDetection',
      onMessageReceived: (JavascriptMessage message) {
        final String newUrl = message.message;
        _handleUrlChange(newUrl);
      },
    );
  }

  void _handleUrlChange(String url) {
    if (url != _currentUrl) {
      setState(() {
        _currentUrl = url;
      });
      print("url changed");
      widget.onUrlChange?.call(url);
    }
  }

  void _injectJavascriptToDetectRouteChange(Future<WebViewController> controllerFuture) async {
    final WebViewController controller = await controllerFuture;
    final String js = """
      (function() {
        var currentUrl = window.location.href;
        setInterval(function() {
          if (currentUrl !== window.location.href) {
            currentUrl = window.location.href;
            PageChangeDetection.postMessage(currentUrl);
          }
        }, 1000);
      })();
    """;
    controller.runJavascript(js);
  }
}
