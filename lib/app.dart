import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/platform/app_platform.dart';
import 'core/theme/app_theme.dart';
import 'data/app_controller.dart';
import 'l10n/app_localizations.dart';
import 'state/app_scope.dart';
import 'ui/shell/app_shell.dart';

class LanBridgeApp extends StatefulWidget {
  const LanBridgeApp({super.key, this.enableEngine = true});

  final bool enableEngine;

  @override
  State<LanBridgeApp> createState() => _LanBridgeAppState();
}

class _LanBridgeAppState extends State<LanBridgeApp> {
  static const MethodChannel _windowChannel =
      MethodChannel('lanbridge/window');

  late final AppController _controller =
      AppController(enableEngine: widget.enableEngine);
  late ThemeMode _themeMode = _controller.settings.themeMode;
  late Locale _locale = _controller.settings.locale;
  bool? _darkChrome;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncAppearance);
  }

  void _syncAppearance() {
    final settings = _controller.settings;
    if (settings.themeMode != _themeMode || settings.locale != _locale) {
      setState(() {
        _themeMode = settings.themeMode;
        _locale = settings.locale;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncAppearance);
    _controller.dispose();
    super.dispose();
  }

  void _scheduleWindowChrome(bool dark) {
    if (_darkChrome == dark) return;
    _darkChrome = dark;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _windowChannel.invokeMethod<void>('setBrightness', dark);
      } on MissingPluginException {
        // Only Windows implements native window chrome.
      } on PlatformException {
        // Non-fatal: the app theme still updates.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          _scheduleWindowChrome(isDark);
          final overlay =
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AppShell(),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (AppPlatform.isIOS || AppPlatform.isMacOS) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
