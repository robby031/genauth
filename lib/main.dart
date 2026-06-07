import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genauth/l10n/app_localizations.dart';
import 'package:genauth/services/locale_service.dart';
import 'screens/lock_screen.dart';

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
        return MaterialApp(
          title: 'GenAuth',
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _brandSeedColor,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _brandSeedColor,
              brightness: Brightness.dark,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            useMaterial3: true,
          ),
          home: const LockScreen(),
        );
      },
    );
  }
}
