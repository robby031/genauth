import 'dart:async';

import 'package:flutter/foundation.dart';

class SecondTickService {
  SecondTickService._() {
    _secondNotifier = ValueNotifier<int>(_currentSecond());
    Timer.periodic(const Duration(seconds: 1), (_) {
      _secondNotifier.value = _currentSecond();
    });
  }

  static final SecondTickService instance = SecondTickService._();

  late final ValueNotifier<int> _secondNotifier;

  ValueListenable<int> get secondListenable => _secondNotifier;

  static int _currentSecond() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
