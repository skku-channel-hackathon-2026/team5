import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

/// 채널톡 도우미(상담 봇) 화면이 들어 있는 파일이에요.
///
/// 채널톡 웹 플러그인을 웹뷰에 띄우는 방식이에요. 봇의 질문·답변은 채널톡 관리자 화면에서 만들어요.
/// 플러그인 키(Plugin Key)는 채널톡이 웹사이트 소스에도 그대로 넣게 하는 "공개용" 값이라 기본값으로 넣어 뒀어요.
/// 다른 채널로 바꾸고 싶으면 실행할 때 덮어쓸 수 있어요:
///   flutter run -d <기기> --dart-define=CHANNEL_PLUGIN_KEY=다른_키
/// (Access Secret 은 서버용 비밀값이라 앱·저장소에 절대 넣지 않아요.)
const String kChannelPluginKey = String.fromEnvironment(
  'CHANNEL_PLUGIN_KEY',
  defaultValue: 'a7d6086d-46c8-4593-8532-296829c7af40',
);

const String _baseUrl = 'https://mate.example.com/';

/// 도우미 채팅 화면을 위로 띄워요. [message]가 있으면 입력창에 미리 채워져요.
Future<void> openChannelChat(BuildContext context, {String? message}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ChannelChatScreen(message: message),
    ),
  );
}

String _js(String s) => jsonEncode(s).replaceAll('</', r'<\/');

/// 웹뷰에 넣을 HTML. 채널톡 공식 설치 스크립트 + boot 입니다.
String channelHtml({required String pluginKey, required String name, String? message}) {
  final open = (message == null || message.isEmpty)
      ? "ChannelIO('openChat');"
      : "ChannelIO('openChat', undefined, ${_js(message)});";
  return '''<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<style>html,body{margin:0;height:100%;background:#fff;}</style>
</head>
<body>
<script>
  (function() {
    var w = window;
    if (w.ChannelIO) { return; }
    var ch = function() { ch.c(arguments); };
    ch.q = [];
    ch.c = function(args) { ch.q.push(args); };
    w.ChannelIO = ch;
    function l() {
      if (w.ChannelIOInitialized) { return; }
      w.ChannelIOInitialized = true;
      var s = document.createElement('script');
      s.type = 'text/javascript';
      s.async = true;
      s.src = 'https://cdn.channel.io/plugin/ch-plugin-web.js';
      s.charset = 'UTF-8';
      var x = document.getElementsByTagName('script')[0];
      x.parentNode.insertBefore(s, x);
    }
    if (document.readyState === 'complete') { l(); }
    else {
      w.addEventListener('DOMContentLoaded', l, false);
      w.addEventListener('load', l, false);
    }
  })();
</script>
<script>
  function send(m) { try { MateBridge.postMessage(m); } catch (e) {} }
  window.addEventListener('error', function(e) { send('js-error: ' + (e && e.message ? e.message : 'unknown') + (e && e.target && e.target.src ? ' src=' + e.target.src : '')); }, true);
  window.addEventListener('unhandledrejection', function(e) { send('js-reject: ' + (e && e.reason ? e.reason : 'unknown')); });
  setTimeout(function() {
    send('status: ChannelIO=' + (typeof window.ChannelIO) + ', queue=' + (window.ChannelIO && window.ChannelIO.q ? 'still-queued' : 'none') + ', bridge=ok');
  }, 4000);
  ChannelIO('onHideMessenger', function() { send('close'); });
  ChannelIO('boot', {
    pluginKey: ${_js(pluginKey)},
    hideChannelButtonOnBoot: true,
    language: 'ko',
    profile: { name: ${_js(name)} }
  }, function(error, user) {
    if (error) { send('boot-error: ' + (error && error.message ? error.message : JSON.stringify(error))); send('error'); return; }
    $open
    send('ready');
  });
</script>
</body>
</html>''';
}

class ChannelChatScreen extends StatefulWidget {
  final String? message;
  const ChannelChatScreen({super.key, this.message});

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  WebViewController? _c;
  bool _loading = true;
  bool _failed = false;
  final List<String> _logs = [];
  Timer? _timeout;

  bool get _hasKey => kChannelPluginKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasKey) return;
    // 10초가 지나도 채팅창이 안 뜨면 원인을 화면에 보여줘요.
    _timeout = Timer(const Duration(seconds: 10), () {
      if (mounted && _loading) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    });
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('MateBridge', onMessageReceived: _onBridge)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNav,
        onPageFinished: (u) => _log('page-finished: $u'),
        onWebResourceError: (e) {
          _log('resource-error(${e.errorCode}, main=${e.isForMainFrame}): ${e.description}');
          if ((e.isForMainFrame ?? true) && mounted) setState(() => _failed = true);
        },
      ))
      ..loadHtmlString(
        channelHtml(pluginKey: kChannelPluginKey, name: app.userName, message: widget.message),
        baseUrl: _baseUrl,
      );
  }

  void _log(String m) {
    debugPrint('[Channel] $m');
    if (!mounted) return;
    setState(() {
      _logs.add(m);
      if (_logs.length > 8) _logs.removeAt(0);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  void _onBridge(JavaScriptMessage m) {
    if (!mounted) return;
    switch (m.message) {
      case 'ready':
        _timeout?.cancel();
        setState(() => _loading = false);
      case 'error':
        _timeout?.cancel();
        setState(() {
          _loading = false;
          _failed = true;
        });
      case 'close':
        Navigator.of(context).maybePop();
      default:
        _log(m.message);
    }
  }

  NavigationDecision _onNav(NavigationRequest r) {
    final u = r.url;
    if (!r.isMainFrame || u.startsWith('about:') || u.startsWith(_baseUrl)) {
      return NavigationDecision.navigate;
    }
    // 채팅 안에서 누른 링크는 밖(브라우저)에서 열어요.
    final uri = Uri.tryParse(u);
    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(children: [
          if (_c != null) Positioned.fill(child: WebViewWidget(controller: _c!)),
          if (!_hasKey)
            _Notice(
              title: '채널톡 키가 아직 없어요',
              body: '앱을 실행할 때 플러그인 키를 함께 넘겨 주세요.\nflutter run --dart-define=CHANNEL_PLUGIN_KEY=키',
              onClose: () => Navigator.of(context).maybePop(),
            )
          else if (_failed)
            _Notice(
              title: '도우미를 불러오지 못했어요',
              body: '인터넷 연결이나 플러그인 키를 확인하고 다시 열어 주세요.${_logs.isEmpty ? '' : '\n\n[진단]\n${_logs.join('\n')}'}',
              onClose: () => Navigator.of(context).maybePop(),
            )
          else if (_loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator(color: p.pri)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String title, body;
  final VoidCallback onClose;
  const _Notice({required this.title, required this.body, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return Positioned.fill(
      child: ColoredBox(
        color: p.paper,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title, textAlign: TextAlign.center, style: disp(22, p.ink, height: 1.3)),
              const SizedBox(height: 10),
              Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.6, color: p.mut)),
              const SizedBox(height: 20),
              FilledButton(onPressed: onClose, child: const Text('닫기')),
            ]),
          ),
        ),
      ),
    );
  }
}
