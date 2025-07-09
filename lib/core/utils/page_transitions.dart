import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 300),
        );
}

class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 350),
          reverseTransitionDuration: Duration(milliseconds: 350),
        );
}

/// Route khusus untuk membuka pesan notifikasi dengan efek zoom dramatis.
/// Scale dari 0.75 → 1.0 dengan easeOutBack (sedikit bounce) + fade in.
class ZoomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ZoomPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );
            final fadeCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(
              opacity: fadeCurve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.75, end: 1.0).animate(scaleCurve),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}
