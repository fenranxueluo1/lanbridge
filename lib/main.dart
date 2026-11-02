import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/platform/app_platform.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugRepaintRainbowEnabled = false;

  if (AppPlatform.isMobile) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  runApp(const LanBridgeApp());
}
