import 'package:flutter_riverpod/flutter_riverpod.dart';

final secondTickProvider = StreamProvider<int>((ref) async* {
  yield _currentSecond();
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield _currentSecond();
  }
});

int _currentSecond() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
