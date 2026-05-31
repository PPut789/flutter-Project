import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubeEmbedView extends StatefulWidget {
  final String url;

  const YouTubeEmbedView({super.key, required this.url});

  @override
  State<YouTubeEmbedView> createState() => _YouTubeEmbedViewState();
}

class _YouTubeEmbedViewState extends State<YouTubeEmbedView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_buildHtml(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }

  String _buildHtml(String url) {
    final videoId = YoutubePlayerController.convertUrlToId(url);
    if (videoId == null) {
      return '<html><body style="margin:0;background:#000"></body></html>';
    }

    return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      html, body { margin: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
      iframe { width: 100%; height: 100%; border: 0; display: block; }
    </style>
  </head>
  <body>
    <iframe
      src="https://www.youtube.com/embed/$videoId?playsinline=1&rel=0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      allowfullscreen>
    </iframe>
  </body>
</html>
''';
  }
}
