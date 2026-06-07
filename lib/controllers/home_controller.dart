import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/otp_account.dart';
import '../repositories/otp_repository.dart';
import '../services/otp_service.dart';
import '../services/storage_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({required this._storage, required this._otpRepository});

  final StorageService _storage;
  final OtpRepository _otpRepository;

  final Map<String, String> _codes = {};
  final Map<String, int> _lastCounters = {};
  List<OtpAccount> _accounts = [];
  Timer? _timer;

  bool _isSearching = false;
  String _searchQuery = '';

  bool get isSearching => _isSearching;
  List<OtpAccount> get filteredAccounts {
    if (_searchQuery.isEmpty) return _accounts;
    final query = _searchQuery.toLowerCase();
    return _accounts
        .where(
          (a) =>
              a.label.toLowerCase().contains(query) ||
              a.issuer.toLowerCase().contains(query),
        )
        .toList();
  }

  String codeFor(String id) => _codes[id] ?? '------';

  Future<void> initialize() async {
    await loadAndRefresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshCodes());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadAndRefresh() async {
    final accounts = await _storage.loadAccounts();
    _accounts = accounts;

    for (final account in accounts) {
      await _generateIfNeeded(account, force: true);
    }

    notifyListeners();
  }

  void startSearch() {
    _isSearching = true;
    _searchQuery = '';
    notifyListeners();
  }

  void stopSearch() {
    _isSearching = false;
    _searchQuery = '';
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    await _storage.deleteAccount(id);
    _accounts.removeWhere((a) => a.id == id);
    _codes.remove(id);
    _lastCounters.remove(id);
    notifyListeners();
  }

  Future<void> incrementHotp(OtpAccount account) async {
    final result = await _otpRepository.hotpIncrement(account);
    final updated = result['account'] as OtpAccount;
    final code = result['code'] as String;

    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      _accounts[index] = updated;
    }
    _codes[updated.id] = code;

    notifyListeners();
  }

  Future<void> _generateIfNeeded(
    OtpAccount account, {
    bool force = false,
  }) async {
    if (account.isHotp) {
      if (force || !_codes.containsKey(account.id)) {
        _codes[account.id] = await OtpService.generateCode(account);
      }
      return;
    }

    final counter = OtpService.periodCounter(account.period);
    if (force || _lastCounters[account.id] != counter) {
      _lastCounters[account.id] = counter;
      _codes[account.id] = await OtpService.generateCode(account);
    }
  }

  void _refreshCodes() {
    var changed = false;
    for (final account in _accounts) {
      if (account.isHotp) continue;

      final counter = OtpService.periodCounter(account.period);
      if (_lastCounters[account.id] != counter) {
        _lastCounters[account.id] = counter;
        changed = true;
        OtpService.generateCode(account).then((code) {
          _codes[account.id] = code;
          notifyListeners();
        });
      }
    }

    if (changed) {
      notifyListeners();
    }
  }
}
