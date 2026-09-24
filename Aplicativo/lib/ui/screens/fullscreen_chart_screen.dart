import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../responsive_chart.dart';

class FullscreenChartScreen extends StatefulWidget {
  const FullscreenChartScreen({
    super.key,
    required this.content,
    required this.semitones,
    required this.fontSize,
  });
  final String content;
  final int semitones;
  final double fontSize;
  @override
  State<FullscreenChartScreen> createState() => _FullscreenChartScreenState();
}

class _FullscreenChartScreenState extends State<FullscreenChartScreen>
    with WidgetsBindingObserver {
  static const channel = MethodChannel('cifrasanta/fullscreen');
  Future<void> setFullscreen(bool enabled) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await channel.invokeMethod<void>('setFullscreen', enabled);
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        );
      }
    } on PlatformException {
      // A cifra continua em tela inteira mesmo se o sistema mantiver suas barras.
    } on MissingPluginException {
      // Permite visualizar a tela em plataformas sem integração nativa.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(setFullscreen(true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(setFullscreen(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(setFullscreen(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              tooltip: 'Voltar à cifra',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              child: ResponsiveChart(
                content: widget.content,
                semitones: widget.semitones,
                fontSize: widget.fontSize,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
