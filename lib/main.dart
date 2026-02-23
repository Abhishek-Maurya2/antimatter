import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'utils/theme_controller.dart';
import 'utils/preferences_helper.dart';
import 'notifiers/settings_notifier.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';
import 'models/task.dart';
import 'services/home_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations for web/desktop
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  await PreferencesHelper.init();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  final tasksBox = await Hive.openBox<Task>('tasksBox');

  // Listen to changes in the tasksBox and update the home widget
  tasksBox.listenable().addListener(() {
    HomeWidgetService.updateTasksWidget(tasksBox.values.toList());
  });

  // Initial update
  HomeWidgetService.updateTasksWidget(tasksBox.values.toList());

  final themeController = ThemeController();
  await themeController.initialize();
  await themeController.checkDynamicColorSupport();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeController),
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
      ],
      child: const OrchesApp(),
    ),
  );
}

class OrchesApp extends StatelessWidget {
  const OrchesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final useExpressiveVariant = context
        .watch<SettingsNotifier>()
        .useExpressiveVariant;

    final isLight = Theme.of(context).brightness == Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0x01000000),
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness: isLight
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: Color(0x01000000),
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return MaterialApp(
      title: 'Orches',
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData.from(
            colorScheme: isMonochrome(themeController.seedColor)
                ? ColorScheme.fromSeed(
                    seedColor: themeController.seedColor,
                    brightness: Brightness.light,
                    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
                  )
                : useExpressiveVariant
                ? ColorScheme.fromSeed(
                    seedColor: themeController.seedColor,
                    brightness: Brightness.light,
                    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                  )
                : ColorScheme.fromSeed(
                    seedColor: themeController.seedColor,
                    brightness: Brightness.light,
                  ),
            useMaterial3: true,
          ).copyWith(
            highlightColor: Colors.transparent,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
              },
            ),
          ),
      darkTheme:
          ThemeData.from(
            colorScheme: isMonochrome(themeController.seedColor)
                ? ColorScheme.fromSeed(
                    seedColor: themeController.seedColor,
                    brightness: Brightness.dark,
                    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
                  )
                : useExpressiveVariant
                ? ColorScheme.fromSeed(
                    seedColor: themeController.seedColor,
                    brightness: Brightness.dark,
                    dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                  )
                : ColorScheme.fromSeed(
                    seedColor: themeController.seedColor,
                    brightness: Brightness.dark,
                  ),
            useMaterial3: true,
          ).copyWith(
            highlightColor: Colors.transparent,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
                TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
                  transitionType: SharedAxisTransitionType.horizontal,
                ),
              },
            ),
          ),
      themeMode: themeController.themeMode,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate initialization delay to show the loading screen
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _isLoading
          ? const LoadingScreen(key: ValueKey('loading'))
          : const HomeScreen(key: ValueKey('home')),
    );
  }
}
