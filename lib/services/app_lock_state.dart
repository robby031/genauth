import 'package:flutter/foundation.dart';

class AppLockState {
  AppLockState._();

  static final ValueNotifier<bool> isLockScreenVisible = ValueNotifier<bool>(
    false,
  );
}
