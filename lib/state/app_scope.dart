import 'package:flutter/widgets.dart';

import '../data/app_controller.dart';

/// Provides the single [AppController] instance to the widget tree and
/// rebuilds dependents whenever the controller notifies.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Subscribe to changes.
  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found above this context.');
    return scope!.notifier!;
  }

  /// Read without subscribing (for callbacks).
  static AppController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found above this context.');
    return scope!.notifier!;
  }
}
