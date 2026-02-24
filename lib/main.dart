import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'utils/theme_controller.dart';
import 'utils/preferences_helper.dart';
import 'utils/typography_helper.dart';
import 'notifiers/settings_notifier.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';
import 'models/task.dart';
import 'services/home_widget_service.dart';
import 'services/supabase_sync_service.dart';

// Initialize Supabase details
const String supaUrl = 'https://gztupoebzdjjdcttenkb.supabase.co';
const String supaAnonKey = 'sb_publishable_fILUo9xhkWoqMlt2UiNlWg_kZf220ex';

// Global reference for Supabase Sync
late final SupabaseSyncService syncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supaUrl, anonKey: supaAnonKey);

  // Allow all orientations for web/desktop
  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  await PreferencesHelper.init();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  final tasksBox = await Hive.openBox<Task>('tasksBox');

  // Initialize and start Sync Service
  syncService = SupabaseSyncService(tasksBox);
  // Asynchronously pull latest tasks from the cloud
  syncService.pullTasks();
  // Start pushing future local changes
  syncService.startListening();

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
    final useVibrantVariant = context
        .watch<SettingsNotifier>()
        .useVibrantVariant;

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

    // Build color schemes first so we can reference their colors in appBarTheme
    final lightColorScheme = isMonochrome(themeController.seedColor)
        ? ColorScheme.fromSeed(
            seedColor: themeController.seedColor,
            brightness: Brightness.light,
            dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          )
        : useVibrantVariant
        ? ColorScheme.fromSeed(
            seedColor: themeController.seedColor,
            brightness: Brightness.light,
            dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
          )
        : ColorScheme.fromSeed(
            seedColor: themeController.seedColor,
            brightness: Brightness.light,
          );

    final darkColorScheme = isMonochrome(themeController.seedColor)
        ? ColorScheme.fromSeed(
            seedColor: themeController.seedColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          )
        : useVibrantVariant
        ? ColorScheme.fromSeed(
            seedColor: themeController.seedColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
          )
        : ColorScheme.fromSeed(
            seedColor: themeController.seedColor,
            brightness: Brightness.dark,
          );

    return MaterialApp(
      title: 'AntiMatter',
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData.from(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            textTheme: TypographyHelper.getTextTheme(context),
          ).copyWith(
            appBarTheme: AppBarTheme(
              titleTextStyle: TypographyHelper.getTextTheme(context).titleLarge
                  ?.copyWith(
                    fontFamily: 'RobotoFlex',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: lightColorScheme.onSurface,
                  ),
            ),
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
            colorScheme: darkColorScheme,
            useMaterial3: true,
            textTheme: TypographyHelper.getTextTheme(context),
          ).copyWith(
            appBarTheme: AppBarTheme(
              titleTextStyle: TypographyHelper.getTextTheme(context).titleLarge
                  ?.copyWith(
                    fontFamily: 'RobotoFlex',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: darkColorScheme.onSurface,
                  ),
            ),
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
  // Static flag — survives widget rebuilds & app resumes within the same process.
  // The splash only ever shows once: the very first cold launch.
  static bool _hasLoaded = false;

  bool _showSplash = !_hasLoaded;

  @override
  void initState() {
    super.initState();
    if (!_hasLoaded) {
      _runSplash();
    }
  }

  Future<void> _runSplash() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    _hasLoaded = true;
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSplash
          ? const LoadingScreen(key: ValueKey('loading'))
          : const HomeScreen(key: ValueKey('home')),
    );
  }
}
