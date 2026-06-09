import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/l10n/app_localizations.dart';
import 'package:genauth/providers/app_state_provider.dart';
import 'package:genauth/services/android_autofill_telemetry_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genauth/services/auto_backup_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/screens/onboarding/onboarding_screen.dart';
import 'package:genauth/screens/lock/lock_screen.dart';

const _brandSeedColor = Color(0xFF2F6BDE);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: GenAuthApp()));
}

class GenAuthApp extends ConsumerStatefulWidget {
  const GenAuthApp({super.key});

  @override
  ConsumerState<GenAuthApp> createState() => _GenAuthAppState();
}

class _GenAuthAppState extends ConsumerState<GenAuthApp>
    with WidgetsBindingObserver {
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
    unawaited(ref.read(localeProvider.notifier).initialize());
    unawaited(AndroidAutofillTelemetryService.flushPendingTelemetry());
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
        unawaited(AndroidAutofillTelemetryService.flushPendingTelemetry());
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
    if (!mounted) return;
    if (!onboardingDone) {
      return;
    }
    if (ref.read(isLockScreenVisibleProvider)) {
      return;
    }
    _lockArmed = true;
  }

  Future<void> _presentResumeLock() async {
    if (!mounted ||
        _resumeLockRouteActive ||
        ref.read(isLockScreenVisibleProvider)) {
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
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'GenAuth',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandSeedColor,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoMonoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: _brandSeedColor,
            dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
          ).surface,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandSeedColor,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoMonoTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: _brandSeedColor,
            brightness: Brightness.dark,
            dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
          ).surface,
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
  }
}

class _AppEntryScreen extends StatelessWidget {
  const _AppEntryScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: () async {
        final storage = StorageService.instance;
        final onboardingDone = await storage.isOnboardingCompleted();
        return onboardingDone;
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final onboardingDone = snapshot.data!;
        if (!onboardingDone) {
          return const OnboardingScreen();
        }

        return const LockScreen();
      },
    );
  }
}
