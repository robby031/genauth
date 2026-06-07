import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genauth/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genauth/services/locale_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/screens/onboarding_screen.dart';
import 'package:genauth/screens/lock_screen.dart';

const _brandSeedColor = Color(0xFF2F6BDE);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const GenAuthApp());
}

class GenAuthApp extends StatelessWidget {
  const GenAuthApp({super.key});

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
    return FutureBuilder<bool>(
      future: StorageService.instance.isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const LockScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}
