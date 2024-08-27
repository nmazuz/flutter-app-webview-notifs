import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart'; // Import the package

import 'package:fapp_shell/navigation_controls.dart';
import 'package:fapp_shell/webview_stack.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(
    const MaterialApp(
      home: WebViewApp(),
    ),
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({Key? key}) : super(key: key);

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  final Completer<WebViewController> controller = Completer<WebViewController>();
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Replace with your ad unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Replace with your ad unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  void _onRefresh() async {
    final WebViewController webViewController = await controller.future;
    webViewController.reload();
    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _refreshController.dispose(); // Dispose of the RefreshController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Empty space with background color #198754
          Container(
            color: Color(0xFF198754), // Set the background color here
            height: kToolbarHeight, // Typically 56.0 pixels
          ),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              header: ClassicHeader(
                height: 60.0, // Set height to shorten the pull distance
                releaseText: 'Release to refresh',
                refreshingText: 'Refreshing...',
                completeText: 'Refresh complete',
                failedText: 'Refresh failed',
              ),
              child: WebViewStack(
                controller: controller,
                onUrlChange: (String url) {
                  print(url);
                  if (url.startsWith(appDomain)) {
                    _showInterstitialAd();
                  }
                },
              ),
            ),
          ),
          if (_bannerAd != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 75,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}
