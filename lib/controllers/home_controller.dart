import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/repositories/otp_repository.dart';
import 'package:genauth/services/otp_service.dart';
import 'package:genauth/services/storage_service.dart';

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
  final Set<String> _selectedTags = {};

  bool get isSearching => _isSearching;

  Set<String> get allTags {
    final tags = <String>{};
    for (final a in _accounts) {
      tags.addAll(a.tags);
    }
    return tags;
  }

  Set<String> get selectedTags => Set.unmodifiable(_selectedTags);

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  List<OtpAccount> get filteredAccounts {
    var list = _accounts;

    if (_selectedTags.isNotEmpty) {
      list = list.where((a) => a.tags.any(_selectedTags.contains)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (a) =>
                a.label.toLowerCase().contains(q) ||
                a.issuer.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
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
    await Future.wait(
      accounts.map((account) => _generateIfNeeded(account, force: true)),
    );

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

  Future<void> updateAccountTags(String id, List<String> tags) async {
    final idx = _accounts.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    _accounts[idx] = _accounts[idx].copyWith(tags: tags);
    _selectedTags.removeWhere((t) => allTags.contains(t) == false);
    await _storage.saveAccounts(_accounts);
    notifyListeners();
  }

  Future<void> reorderAccounts(int oldIndex, int newIndex) async {
    final account = _accounts.removeAt(oldIndex);
    _accounts.insert(newIndex, account);
    await _storage.saveAccounts(_accounts);
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
    unawaited(_refreshCodesAsync());
  }

  Future<void> _refreshCodesAsync() async {
    final accountsToRefresh = <OtpAccount>[];

    for (final account in _accounts) {
      if (account.isHotp) continue;

      final counter = OtpService.periodCounter(account.period);
      if (_lastCounters[account.id] != counter) {
        _lastCounters[account.id] = counter;
        accountsToRefresh.add(account);
      }
    }

    if (accountsToRefresh.isEmpty) return;

    final refreshedCodes = await Future.wait(
      accountsToRefresh.map(OtpService.generateCode),
    );

    for (var i = 0; i < accountsToRefresh.length; i++) {
      _codes[accountsToRefresh[i].id] = refreshedCodes[i];
    }

    notifyListeners();
  }
}
