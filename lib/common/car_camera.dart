import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:webview_flutter/webview_flutter.dart';

final log = Logger('CarCameraView');

const String _html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Stream</title>
  <style>
    * {
      margin: 0;
    }
    img {
      width: 99%;
      margin: auto;
      display: block;
    }
  </style>
</head>
<body>
  <img src="/stream" />
  <script>
    const img = document.querySelector('img');
    let checkFrameSizeInterval;
    let lastWidth;
    let lastHeight;
    function sendFrameSize() {
      if (img.naturalWidth <= 0) return;
      App.postMessage(JSON.stringify({
        frameSize: {
          width: lastWidth = img.naturalWidth,
          height: lastHeight = img.naturalHeight,
        },
      }));
    }
    img.addEventListener('load', () => {
      clearInterval(checkFrameSizeInterval);
      checkFrameSizeInterval = setInterval(() => {
        if (lastWidth != img.naturalWidth || lastHeight != img.naturalHeight) {
          sendFrameSize();
        }
      }, 1000);
      sendFrameSize();
    });
  </script>
</body>
</html>
''';

class CarCameraView extends StatefulWidget {
  final Uri uri;

  const CarCameraView({Key? key, required this.uri}) : super(key: key);

  @override
  State<CarCameraView> createState() => _CarCameraViewState();
}

class _CarCameraViewState extends State<CarCameraView> {
  late final WebViewController _controller;
  double aspectRatio = 4 / 3;

  void _onJavascriptMessage(JavaScriptMessage message) {
    log.info(message.message);
    final o = jsonDecode(message.message);
    if (o['frameSize'] != null) {
      final size = o['frameSize'];
      setState(() {
        aspectRatio = size['width'] / size['height'];
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('App', onMessageReceived: _onJavascriptMessage)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_html, baseUrl: widget.uri.toString());
  }

  @override
  void dispose() {
    _controller.runJavaScript('window.stop();');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: WebViewWidget(controller: _controller),
    );
  }
}
