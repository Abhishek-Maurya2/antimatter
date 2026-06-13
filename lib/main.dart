import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import 'package:supabase_flutter/supabase_flutter.dart' as supa show Session;
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/preferences_helper.dart';
import 'utils/typography_helper.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'models/task.dart';
import 'models/session.dart';
import 'services/home_widget_service.dart';
import 'services/supabase_sync_service.dart';
import 'services/session_sync_service.dart';
import 'services/notification_service.dart';
import 'services/google_calendar_service.dart';
import 'utils/window_state_manager.dart';


// Initialize Supabase details
const String supaUrl = 'https://gztupoebzdjjdcttenkb.supabase.co';
const String supaAnonKey = 'sb_publishable_fILUo9xhkWoqMlt2UiNlWg_kZf220ex';

// Global reference for Supabase Sync
late final SupabaseSyncService syncService;
late final SessionSyncService sessionSyncService;
late final AppLifecycleListener _appLifecycleListener;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesHelper.init();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    await WindowStateManager.init();
    if (Platform.isWindows) {
      await _registerWindowsProtocol();
    }
  }

  await Supabase.initialize(url: supaUrl, anonKey: supaAnonKey);
  await ThemeController.prefetchDynamicColors();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SessionAdapter());
  final tasksBox = await Hive.openBox<Task>('tasksBox');
  final sessionsBox = await Hive.openBox<Session>('sessionsBox');
  final gcalEventsBox = await Hive.openBox<String>('gcalEventsBox');

  // Initialize notifications
  await NotificationService().init();

  // Initialize Sync Services
  syncService = SupabaseSyncService(tasksBox);
  sessionSyncService = SessionSyncService(sessionsBox);
  await GoogleCalendarService().init(gcalEventsBox);

  // Set up auth state change listener to manage synchronization lifecycle
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final session = data.session;
    final event = data.event;
    debugPrint('Supabase Auth Change: Event: $event, User ID: ${session?.user.id}');

    if (session != null) {
      try {
        if (event == AuthChangeEvent.signedIn) {
          // Just signed in: upload offline changes, pull from cloud, and sync calendar
          await syncService.uploadLocalData();
          await sessionSyncService.uploadLocalData();
          await syncService.pullTasks();
          await sessionSyncService.pullSessions();
          await GoogleCalendarService().initialSync(tasksBox);
        } else if (event == AuthChangeEvent.initialSession) {
          // App opened with an existing session: pull latest
          await syncService.pullTasks();
          await sessionSyncService.pullSessions();
        }
      } catch (e, st) {
        debugPrint('Error during post-login sync: $e\n$st');
      }

      // Start listening to local changes and subscribe to Realtime AFTER initial pull/sync
      syncService.startListening();
      sessionSyncService.startListening();
      syncService.subscribeToRealtime();
      sessionSyncService.subscribeToRealtime();
      GoogleCalendarService().startListening(tasksBox);
    } else {
      if (event == AuthChangeEvent.signedOut) {
        debugPrint('Supabase Auth Change: User signed out. Cleaning up data...');
        await GoogleCalendarService().signOut();
        await syncService.clearLocalData();
        await sessionSyncService.clearLocalData();
      } else {
        // Startup with no session
        syncService.dispose();
        sessionSyncService.dispose();
      }
    }
  });

  // Listen to changes in the tasksBox and update the home widget
  tasksBox.listenable().addListener(() {
    HomeWidgetService.updateTasksWidget(tasksBox.values.toList());
  });

  // Initial update
  HomeWidgetService.updateTasksWidget(tasksBox.values.toList());

  // Sync any tasks completed from the widget
  await HomeWidgetService.syncWidgetCompletions(tasksBox);

  // Dispose sync services (unsubscribe realtime) when the app is fully detached
  _appLifecycleListener = AppLifecycleListener(
    onDetach: () {
      syncService.dispose();
      sessionSyncService.dispose();
    },
  );

  runApp(const ProviderScope(child: AntimatterApp()));
}

class AntimatterApp extends ConsumerStatefulWidget {
  const AntimatterApp({super.key});

  @override
  ConsumerState<AntimatterApp> createState() => _AntimatterAppState();
}

class _AntimatterAppState extends ConsumerState<AntimatterApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  supa.Session? _session;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      debugPrint('[AntimatterApp] Auth state changed: $event, Session: ${session != null}');
      if (mounted) {
        setState(() {
          _session = session;
        });
        if (session != null) {
          debugPrint('[AntimatterApp] Session detected. Popping routes to root...');
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      }
    });
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    debugPrint('[DeepLink] Initializing deep links listener...');
    
    // Check initial deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('[DeepLink] Found initial deep link on cold launch: $uri');
        _handleAuthLink(uri);
      } else {
        debugPrint('[DeepLink] No initial deep link found on cold launch.');
      }
    }).catchError((e) {
      debugPrint('[DeepLink] Error getting initial link: $e');
    });

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('[DeepLink] Stream received deep link: $uri');
      _handleAuthLink(uri);
    });
  }

  Future<void> _handleAuthLink(Uri uri) async {
    debugPrint('[DeepLink] Received deep link: $uri');
    debugPrint('[DeepLink] Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}, QueryParameters: ${uri.queryParameters}');
    
    // Check if the scheme matches antimatter and it targets the login callback.
    // Sometimes the path can contain the callback host depending on how it was parsed.
    final isCallback = uri.scheme == 'antimatter' && 
        (uri.host == 'login-callback' || uri.path.contains('login-callback'));

    if (isCallback) {
      try {
        debugPrint('[DeepLink] Parsing session from URL: $uri');
        final response = await Supabase.instance.client.auth.getSessionFromUrl(uri);
        debugPrint('[DeepLink] Session parsed successfully! User ID: ${response.session?.user.id}');
        
        await PreferencesHelper.setBool('offline_mode', false);
        
        // Force state refresh
        if (mounted) {
          setState(() {});
        }
      } catch (e, stackTrace) {
        debugPrint('[DeepLink] Auth callback failed with error: $e');
        debugPrint('[DeepLink] Stacktrace: $stackTrace');
      }
    } else {
      debugPrint('[DeepLink] Received deep link but it did not match callback criteria.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);
    final useVibrantVariant = ref
        .watch(settingsControllerProvider)
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
    final lightColorScheme = isMonochrome(themeState.seedColor)
        ? ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.light,
            dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          )
        : useVibrantVariant
        ? ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.light,
            dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
          )
        : ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.light,
          );

    final darkColorScheme = isMonochrome(themeState.seedColor)
        ? ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          )
        : useVibrantVariant
        ? ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
          )
        : ColorScheme.fromSeed(
            seedColor: themeState.seedColor,
            brightness: Brightness.dark,
          );

    return MaterialApp(
      navigatorKey: navigatorKey,
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
      themeMode: themeState.themeMode,
      home: (_session != null ||
              (PreferencesHelper.getBool('offline_mode') ?? false))
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}

Future<void> _registerWindowsProtocol() async {
  try {
    final appPath = Platform.resolvedExecutable;
    const scheme = 'antimatter';
    
    // Register the custom protocol scheme for Windows (HKCU doesn't require admin privileges)
    final regKeyResult = await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\$scheme',
      '/v',
      'URL Protocol',
      '/t',
      'REG_SZ',
      '/d',
      '',
      '/f'
    ]);
    
    final regCmdResult = await Process.run('reg', [
      'add',
      'HKCU\\Software\\Classes\\$scheme\\shell\\open\\command',
      '/ve',
      '/t',
      'REG_SZ',
      '/d',
      '"$appPath" "%1"',
      '/f'
    ]);

    if (regKeyResult.exitCode != 0 || regCmdResult.exitCode != 0) {
      debugPrint('Failed to register protocol: ${regKeyResult.stderr} ${regCmdResult.stderr}');
    } else {
      debugPrint('Successfully registered protocol antimatter:// to $appPath');
    }
  } catch (e) {
    debugPrint('Error registering Windows protocol: $e');
  }
}
