import 'package:flutter/material.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorTheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            ExpressiveLoadingIndicator(
              activeSize: 48,
              color: colorTheme.primary,
            ),
            Text(
              'AntiMatter',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colorTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
