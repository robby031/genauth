import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/services/storage_service.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  bool _initialized = false;

  @override
  Locale build() {
    return const Locale('en');
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final storedCode = await StorageService.instance.getPreferredLocaleCode();
    if (storedCode == null) return;

    final normalized = _normalizeLocaleCode(storedCode);
    state = Locale(normalized);
  }

  void setLocale(Locale locale) {
    final normalized = _normalizeLocaleCode(locale.languageCode);
    state = Locale(normalized);
    unawaited(StorageService.instance.setPreferredLocaleCode(normalized));
  }

  String _normalizeLocaleCode(String languageCode) {
    final normalized = languageCode.toLowerCase();
    if (normalized == 'id') {
      return 'id';
    }
    return 'en';
  }
}

final isLockScreenVisibleProvider = StateProvider<bool>((ref) {
  return false;
});
