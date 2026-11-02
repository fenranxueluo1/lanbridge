import 'package:flutter/material.dart';

import 'ambient_background.dart';

/// Full-screen scaffold painted with the ambient background.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.child,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: child,
      ),
    );
  }
}
