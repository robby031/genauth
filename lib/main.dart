import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genauth/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genauth/services/locale_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/screens/onboarding_screen.dart';
import 'package:genauth/screens/lock_screen.dart';
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
  AppLifecycleState? _lifecycleState;

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
            if (!_shouldObscureForPrivacy || child == null) {
              return child ?? const SizedBox.shrink();
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                child,
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
              ],
            );
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
    return FutureBuilder<(bool panic, bool onboardingDone)>(
      future: () async {
        final panic = await StorageService.instance.isPanicTriggered();
        final onboardingDone = await StorageService.instance
            .isOnboardingCompleted();
        return (panic, onboardingDone);
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = snapshot.data!;
        if (entry.$1) {
          return const PanicCorruptedScreen();
        }

        if (entry.$2) {
          return const LockScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}
