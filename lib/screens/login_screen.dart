import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/preferences_helper.dart';
import '../utils/m3_motion.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Trigger Supabase OAuth sign-in. This will launch the system browser.
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.toString() : 'antimatter://login-callback',
        scopes: 'https://www.googleapis.com/auth/calendar',
      );
      
      // On desktop, the browser opens and the app continues running. 
      // The deep link handler in HomeScreen/main will capture the redirect and complete the login.
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBar('Google Sign-in failed: $e');
    }
  }

  Future<void> _continueOffline() async {
    setState(() {
      _isLoading = true;
    });

    await PreferencesHelper.setBool('offline_mode', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        M3Motion.sharedAxisRoute(const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainerLowest,
      body: Stack(
        children: [
          // Background decorative glowing circles (Premium aesthetics)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorTheme.primaryContainer.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorTheme.tertiaryContainer.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorTheme.surfaceContainerLow.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: colorTheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorTheme.primaryContainer,
                        ),
                        child: Icon(
                          Symbols.task_alt_rounded,
                          size: 40,
                          weight: 800,
                          color: colorTheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // App Name
                      Text(
                        'AntiMatter',
                        style: textTheme.headlineMedium?.copyWith(
                          fontFamily: 'GoogleSansFlex',
                          fontWeight: FontWeight.w900,
                          color: colorTheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Expressive Task & Session Manager',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        // Sign In with Google Button
                        SizedBox(
                          width: double.infinity,
                          child: ButtonM3E(
                            onPressed: _signInWithGoogle,
                            style: ButtonM3EStyle.filled,
                            size: ButtonM3ESize.lg,
                            shape: ButtonM3EShape.round,
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Symbols.login_rounded),
                                const SizedBox(width: 12),
                                Text(
                                  'Sign In with Google',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorTheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Continue Offline Option
                        SizedBox(
                          width: double.infinity,
                          child: ButtonM3E(
                            onPressed: _continueOffline,
                            style: ButtonM3EStyle.tonal,
                            size: ButtonM3ESize.lg,
                            shape: ButtonM3EShape.round,
                            label: Text(
                              'Continue Offline',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorTheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      
                      // Footer info
                      Text(
                        'Offline mode stores data locally on this device.\nSign in to enable cross-device synchronization.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorTheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
