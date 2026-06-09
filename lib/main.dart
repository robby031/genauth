import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genauth/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genauth/services/app_lock_state.dart';
import 'package:genauth/services/auto_backup_service.dart';
import 'package:genauth/services/locale_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/screens/onboarding_screen.dart';
import 'package:genauth/screens/lock/lock_screen.dart';
import 'package:genauth/screens/panic_corrupted_screen.dart';

const _brandSeedColor = Color(0xFF2F6BDE);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GenAuthApp());
}

class GenAuthApp extends StatefulWidget {
  const GenAuthApp({super.key});

  @override
  State<GenAuthApp> createState() => _GenAuthAppState();
}

class _GenAuthAppState extends State<GenAuthApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppLifecycleState? _lifecycleState;
  bool _lockArmed = false;
  bool _resumeLockRouteActive = false;

  bool get _shouldObscureForPrivacy {
    final state = _lifecycleState ?? WidgetsBinding.instance.lifecycleState;
    if (state == null) return false;
    return state != AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState = WidgetsBinding.instance.lifecycleState;
    unawaited(AutoBackupService.instance.maybeRun(reason: 'app_start'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _lifecycleState = state);

    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _armLockOnBackground();
      case AppLifecycleState.resumed:
        unawaited(AutoBackupService.instance.maybeRun(reason: 'app_resumed'));
        if (_lockArmed) {
          _presentResumeLock();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _armLockOnBackground() async {
    final onboardingDone = await StorageService.instance
        .isOnboardingCompleted();
    final panicTriggered = await StorageService.instance.isPanicTriggered();
    if (!mounted) return;
    if (!onboardingDone || panicTriggered) {
      return;
    }
    if (AppLockState.isLockScreenVisible.value) {
      return;
    }
    _lockArmed = true;
  }

  Future<void> _presentResumeLock() async {
    if (!mounted ||
        _resumeLockRouteActive ||
        AppLockState.isLockScreenVisible.value) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _lockArmed = false;
    _resumeLockRouteActive = true;

    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => LockScreen(
          replaceWithHomeOnSuccess: false,
          onAuthenticated: _dismissResumeLock,
        ),
      ),
    );

    _resumeLockRouteActive = false;
  }

  void _dismissResumeLock() {
    _resumeLockRouteActive = false;
    _lockArmed = false;
    _navigatorKey.currentState?.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, locale, child) {
        final lightColorScheme = ColorScheme.fromSeed(
          seedColor: _brandSeedColor,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        );
        final darkColorScheme = ColorScheme.fromSeed(
          seedColor: _brandSeedColor,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        );

        return MaterialApp(
          title: 'GenAuth',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            textTheme: GoogleFonts.robotoMonoTextTheme(),
            appBarTheme: AppBarTheme(
              backgroundColor: lightColorScheme.surface,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            textTheme: GoogleFonts.robotoMonoTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: darkColorScheme.surface,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          builder: (context, child) {
            final baseChild = child ?? const SizedBox.shrink();
            final stackChildren = <Widget>[baseChild];

            if (_shouldObscureForPrivacy) {
              stackChildren.add(
                Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Stack(fit: StackFit.expand, children: stackChildren);
          },
          home: const _AppEntryScreen(),
        );
      },
    );
  }
}

class _AppEntryScreen extends StatelessWidget {
  const _AppEntryScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppEntryState>(
      future: () async {
        final storage = StorageService.instance;
        final panic = await storage.isPanicTriggered();
        final onboardingDone = await storage.isOnboardingCompleted();
        return _AppEntryState(panic: panic, onboardingDone: onboardingDone);
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = snapshot.data!;
        if (entry.panic) {
          return const PanicCorruptedScreen();
        }

        if (!entry.onboardingDone) {
          return const OnboardingScreen();
        }

        return const LockScreen();
      },
    );
  }
}

class _AppEntryState {
  const _AppEntryState({required this.panic, required this.onboardingDone});

  final bool panic;
  final bool onboardingDone;
}
