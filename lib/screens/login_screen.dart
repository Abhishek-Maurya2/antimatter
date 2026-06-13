import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/preferences_helper.dart';
import '../utils/m3_motion.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[Auth] App resumed. Checking session...');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted &&
            _isLoading &&
            Supabase.instance.client.auth.currentSession == null) {
          debugPrint(
            '[Auth] No session found after resume. Resetting loading state.',
          );
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

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
    debugPrint('[Auth] Sign In with Google button clicked.');
    setState(() {
      _isLoading = true;
    });

    try {
      final redirectUrl = kIsWeb
          ? Uri.base.toString()
          : 'antimatter://login-callback';

      debugPrint(
        '[Auth] Triggering signInWithOAuth. Redirect URL: $redirectUrl',
      );

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        scopes: 'https://www.googleapis.com/auth/calendar',
      );

      debugPrint(
        '[Auth] signInWithOAuth call completed successfully (returned).',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[Auth] Exception caught in signInWithGoogle: $e\n$stackTrace',
      );
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
      Navigator.of(
        context,
      ).pushReplacement(M3Motion.sharedAxisRoute(const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Title: RichText with cursive/serif italic + sans-serif mix
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Bring ',
                            style: GoogleFonts.instrumentSerif(
                              fontSize: 44,
                              fontStyle: FontStyle.italic,
                              color: isLight
                                  ? const Color(0xFF6D28D9)
                                  : const Color(0xFFDDD6FE),
                            ),
                          ),
                          TextSpan(
                            text: 'your tasks to\n',
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                              height: 1.1,
                              color: isLight ? Colors.black : Colors.white,
                              fontVariations: const [
                                FontVariation('wght', 900),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'Life',
                            style: GoogleFonts.instrumentSerif(
                              fontSize: 52,
                              fontStyle: FontStyle.italic,
                              color: isLight
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFA78BFA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Transform your daily workflow into a work of art and bring your productivity to life with Style.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: isLight ? Colors.black54 : Colors.white70,
                        ),
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
                      // Primary action: Sign In with Google
                      AnimatedPillButton(
                        onPressed: _signInWithGoogle,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            if (!isLight)
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                          ],
                          gradient: isLight
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6366F1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: isLight ? Colors.white : null,
                          border: isLight
                              ? Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgIcon(
                              path: _googlePath,
                              color: isLight ? Colors.black : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sign In with Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider "or continue with"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isLight
                                  ? Colors.black.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isLight
                                    ? Colors.black38
                                    : Colors.white38,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isLight
                                  ? Colors.black.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Secondary action: Continue Offline
                      AnimatedPillButton(
                        onPressed: _continueOffline,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: isLight
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.cloud_off_rounded,
                              color: isLight ? Colors.black : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue Offline',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isLight ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mesh Background for Light Mode ──────────────────────────────
class MeshBackground extends StatelessWidget {
  final Widget child;
  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (!isLight) {
      return Container(color: Colors.black, child: child);
    }

    final colorTheme = Theme.of(context).colorScheme;
    return Container(
      color: const Color(0xFFF2EDFF), // soft lavender mesh base
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorTheme.primaryContainer.withValues(alpha: 0.45),
                    colorTheme.primaryContainer.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorTheme.tertiaryContainer.withValues(alpha: 0.4),
                    colorTheme.tertiaryContainer.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: 80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                    const Color(0xFFE2E8F0).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: const SizedBox(),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: MeshWavePainter(
                color: colorTheme.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

// ─── Custom Painter for Soft Flowing Mesh Waves ──────────────────
class MeshWavePainter extends CustomPainter {
  final Color color;
  const MeshWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.cubicTo(
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.6,
      size.height * 0.35,
      size.width,
      size.height * 0.25,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.45);
    path2.cubicTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.7,
      size.height * 0.3,
      size.width,
      size.height * 0.48,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Tactile Animated Spring Button ──────────────────────────────
class AnimatedPillButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final BoxDecoration decoration;
  const AnimatedPillButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.decoration,
  });

  @override
  State<AnimatedPillButton> createState() => _AnimatedPillButtonState();
}

class _AnimatedPillButtonState extends State<AnimatedPillButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: widget.decoration,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── SVG Vector Paths for Monochromatic Brand Icons ────────────────
const String _googlePath =
    "M15.545 6.558a9.4 9.4 0 0 1 .139 1.626c0 2.434-.87 4.492-2.384 5.885h.002C11.978 15.292 10.158 16 8 16A8 8 0 1 1 8 0a7.7 7.7 0 0 1 5.352 2.082l-2.284 2.284A4.35 4.35 0 0 0 8 3.166c-2.087 0-3.86 1.408-4.492 3.304a4.8 4.8 0 0 0 0 3.063h.003c.635 1.893 2.405 3.301 4.492 3.301 1.078 0 2.004-.276 2.722-.764h-.003a3.7 3.7 0 0 0 1.599-2.431H8v-3.08z";

// ─── SVG Monochromatic Icon Widget ─────────────────────────────────
class SvgIcon extends StatelessWidget {
  final String path;
  final Color color;
  final double size;

  const SvgIcon({
    super.key,
    required this.path,
    required this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: SvgPathPainter(svgPath: path, color: color),
    );
  }
}

class SvgPathPainter extends CustomPainter {
  final String svgPath;
  final Color color;
  final double originalWidth;
  final double originalHeight;

  const SvgPathPainter({
    required this.svgPath,
    required this.color,
    this.originalWidth = 16.0,
    this.originalHeight = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = parseSvgPath(svgPath);

    // Scale path to fit the actual widget size
    final scaleX = size.width / originalWidth;
    final scaleY = size.height / originalHeight;
    final matrix = Matrix4.diagonal3Values(scaleX, scaleY, 1.0);
    final scaledPath = path.transform(matrix.storage);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(scaledPath, paint);
  }

  @override
  bool shouldRepaint(covariant SvgPathPainter oldDelegate) {
    return oldDelegate.svgPath != svgPath || oldDelegate.color != color;
  }
}

// ─── SVG Path Parser ──────────────────────────────────────────────
Path parseSvgPath(String svgPath) {
  final path = Path();
  final RegExp regExp = RegExp(
    r'([MmLlHhVvCcSsQqTtAaZz])|(-?\d*\.?\d+(?:[eE][-+]?\d+)?)',
  );
  final matches = regExp.allMatches(svgPath).toList();

  int i = 0;
  String currentCommand = '';
  double lastX = 0;
  double lastY = 0;
  double lastControlX = 0;
  double lastControlY = 0;

  double getNextArg() {
    if (i >= matches.length) return 0.0;
    final val = double.tryParse(matches[i].group(0)!) ?? 0.0;
    i++;
    return val;
  }

  while (i < matches.length) {
    final token = matches[i].group(0)!;
    if (RegExp(r'[MmLlHhVvCcSsQqTtAaZz]').hasMatch(token)) {
      currentCommand = token;
      i++;
    }

    if (currentCommand == 'M') {
      final x = getNextArg();
      final y = getNextArg();
      path.moveTo(x, y);
      lastX = x;
      lastY = y;
      lastControlX = x;
      lastControlY = y;
      currentCommand = 'L';
    } else if (currentCommand == 'm') {
      final x = getNextArg() + lastX;
      final y = getNextArg() + lastY;
      path.moveTo(x, y);
      lastX = x;
      lastY = y;
      lastControlX = x;
      lastControlY = y;
      currentCommand = 'l';
    } else if (currentCommand == 'L') {
      final x = getNextArg();
      final y = getNextArg();
      path.lineTo(x, y);
      lastX = x;
      lastY = y;
      lastControlX = x;
      lastControlY = y;
    } else if (currentCommand == 'l') {
      final x = getNextArg() + lastX;
      final y = getNextArg() + lastY;
      path.lineTo(x, y);
      lastX = x;
      lastY = y;
      lastControlX = x;
      lastControlY = y;
    } else if (currentCommand == 'H') {
      final x = getNextArg();
      path.lineTo(x, lastY);
      lastX = x;
      lastControlX = x;
      lastControlY = lastY;
    } else if (currentCommand == 'h') {
      final x = getNextArg() + lastX;
      path.lineTo(x, lastY);
      lastX = x;
      lastControlX = x;
      lastControlY = lastY;
    } else if (currentCommand == 'V') {
      final y = getNextArg();
      path.lineTo(lastX, y);
      lastY = y;
      lastControlX = lastX;
      lastControlY = y;
    } else if (currentCommand == 'v') {
      final y = getNextArg() + lastY;
      path.lineTo(lastX, y);
      lastY = y;
      lastControlX = lastX;
      lastControlY = y;
    } else if (currentCommand == 'C') {
      final x1 = getNextArg();
      final y1 = getNextArg();
      final x2 = getNextArg();
      final y2 = getNextArg();
      final x = getNextArg();
      final y = getNextArg();
      path.cubicTo(x1, y1, x2, y2, x, y);
      lastX = x;
      lastY = y;
      lastControlX = x2;
      lastControlY = y2;
    } else if (currentCommand == 'c') {
      final x1 = getNextArg() + lastX;
      final y1 = getNextArg() + lastY;
      final x2 = getNextArg() + lastX;
      final y2 = getNextArg() + lastY;
      final x = getNextArg() + lastX;
      final y = getNextArg() + lastY;
      path.cubicTo(x1, y1, x2, y2, x, y);
      lastControlX = x2;
      lastControlY = y2;
      lastX = x;
      lastY = y;
    } else if (currentCommand == 's') {
      final x2 = getNextArg() + lastX;
      final y2 = getNextArg() + lastY;
      final x = getNextArg() + lastX;
      final y = getNextArg() + lastY;
      final x1 = 2 * lastX - lastControlX;
      final y1 = 2 * lastY - lastControlY;
      path.cubicTo(x1, y1, x2, y2, x, y);
      lastControlX = x2;
      lastControlY = y2;
      lastX = x;
      lastY = y;
    } else if (currentCommand == 'q') {
      final x1 = getNextArg() + lastX;
      final y1 = getNextArg() + lastY;
      final x = getNextArg() + lastX;
      final y = getNextArg() + lastY;
      path.quadraticBezierTo(x1, y1, x, y);
      lastX = x;
      lastY = y;
    } else if (currentCommand == 'A') {
      final rx = getNextArg();
      final ry = getNextArg();
      final rot = getNextArg();
      final largeArc = getNextArg();
      final sweep = getNextArg();
      final x = getNextArg();
      final y = getNextArg();
      path.arcToPoint(
        Offset(x, y),
        radius: Radius.elliptical(rx, ry),
        rotation: rot,
        largeArc: largeArc == 1.0,
        clockwise: sweep == 1.0,
      );
      lastX = x;
      lastY = y;
      lastControlX = x;
      lastControlY = y;
    } else if (currentCommand == 'a') {
      final rx = getNextArg();
      final ry = getNextArg();
      final rot = getNextArg();
      final largeArc = getNextArg();
      final sweep = getNextArg();
      final x = getNextArg() + lastX;
      final y = getNextArg() + lastY;
      path.arcToPoint(
        Offset(x, y),
        radius: Radius.elliptical(rx, ry),
        rotation: rot,
        largeArc: largeArc == 1.0,
        clockwise: sweep == 1.0,
      );
      lastX = x;
      lastY = y;
      lastControlX = x;
      lastControlY = y;
    } else if (currentCommand == 'Z' || currentCommand == 'z') {
      path.close();
    } else {
      if (i < matches.length) i++;
    }
  }
  return path;
}
