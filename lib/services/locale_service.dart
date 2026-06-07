import 'package:flutter/material.dart';

class LocaleService {
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('en'),
  );

  static void changeLocale(String languageCode) {
    localeNotifier.value = Locale(languageCode);
  }
}
