import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/repositories/otp_repository.dart';
import 'package:genauth/services/otp_service.dart';
import 'package:genauth/services/storage_service.dart';

final homeStorageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final otpRepositoryProvider = Provider<OtpRepository>((ref) {
  return OtpRepository(ref.read(homeStorageServiceProvider));
});

final homeProvider = AutoDisposeNotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class HomeState {
  HomeState({
    this.accounts = const [],
    this.codes = const {},
    this.isSearching = false,
    this.searchQuery = '',
    this.selectedTags = const {},
    this.loading = true,
  });

  final List<OtpAccount> accounts;
  final Map<String, String> codes;
  final bool isSearching;
  final String searchQuery;
  final Set<String> selectedTags;
  final bool loading;

  Set<String> get allTags {
    final tags = <String>{};
    for (final account in accounts) {
      tags.addAll(account.tags);
    }
    return tags;
  }

  List<OtpAccount> get filteredAccounts {
    var list = accounts;

    if (selectedTags.isNotEmpty) {
      list = list.where((a) => a.tags.any(selectedTags.contains)).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
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

  String codeFor(String id) => codes[id] ?? '------';

  HomeState copyWith({
    List<OtpAccount>? accounts,
    Map<String, String>? codes,
    bool? isSearching,
    String? searchQuery,
    Set<String>? selectedTags,
    bool? loading,
  }) {
    return HomeState(
      accounts: accounts ?? this.accounts,
      codes: codes ?? this.codes,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      loading: loading ?? this.loading,
    );
  }
}

class HomeNotifier extends AutoDisposeNotifier<HomeState> {
  final Map<String, int> _lastCounters = {};
  Timer? _timer;

  @override
  HomeState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    _startTicker();
    Future<void>(() async {
      await loadAndRefresh();
    });

    return HomeState();
  }

  Future<void> loadAndRefresh() async {
    state = state.copyWith(loading: true);

    final accounts = await ref.read(homeStorageServiceProvider).loadAccounts();
    final codes = <String, String>{};

    for (final account in accounts) {
      await _generateIfNeeded(account, codes: codes, force: true);
    }

    final allTags = <String>{};
    for (final account in accounts) {
      allTags.addAll(account.tags);
    }

    final selectedTags = Set<String>.from(state.selectedTags)
      ..removeWhere((tag) => !allTags.contains(tag));

    state = state.copyWith(
      accounts: accounts,
      codes: codes,
      selectedTags: selectedTags,
      loading: false,
    );
  }

  void startSearch() {
    state = state.copyWith(isSearching: true, searchQuery: '');
  }

  void stopSearch() {
    state = state.copyWith(isSearching: false, searchQuery: '');
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleTag(String tag) {
    final nextSelected = Set<String>.from(state.selectedTags);
    if (nextSelected.contains(tag)) {
      nextSelected.remove(tag);
    } else {
      nextSelected.add(tag);
    }

    state = state.copyWith(selectedTags: nextSelected);
  }

  Future<void> deleteAccount(String id) async {
    await ref.read(homeStorageServiceProvider).deleteAccount(id);

    final nextAccounts = state.accounts.where((a) => a.id != id).toList();
    final nextCodes = Map<String, String>.from(state.codes)..remove(id);
    _lastCounters.remove(id);

    state = state.copyWith(accounts: nextAccounts, codes: nextCodes);
  }

  Future<void> updateAccountTags(String id, List<String> tags) async {
    final idx = state.accounts.indexWhere((a) => a.id == id);
    if (idx < 0) return;

    final nextAccounts = List<OtpAccount>.from(state.accounts);
    nextAccounts[idx] = nextAccounts[idx].copyWith(tags: tags);

    final allTags = <String>{};
    for (final account in nextAccounts) {
      allTags.addAll(account.tags);
    }

    final selectedTags = Set<String>.from(state.selectedTags)
      ..removeWhere((tag) => !allTags.contains(tag));

    await ref.read(homeStorageServiceProvider).saveAccounts(nextAccounts);

    state = state.copyWith(accounts: nextAccounts, selectedTags: selectedTags);
  }

  Future<void> reorderAccounts(int oldIndex, int newIndex) async {
    final nextAccounts = List<OtpAccount>.from(state.accounts);
    final account = nextAccounts.removeAt(oldIndex);
    nextAccounts.insert(newIndex, account);

    await ref.read(homeStorageServiceProvider).saveAccounts(nextAccounts);
    state = state.copyWith(accounts: nextAccounts);
  }

  Future<void> incrementHotp(OtpAccount account) async {
    final result = await ref.read(otpRepositoryProvider).hotpIncrement(account);
    final updated = result['account'] as OtpAccount;
    final code = result['code'] as String;

    final nextAccounts = List<OtpAccount>.from(state.accounts);
    final index = nextAccounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      nextAccounts[index] = updated;
    }

    final nextCodes = Map<String, String>.from(state.codes);
    nextCodes[updated.id] = code;

    state = state.copyWith(accounts: nextAccounts, codes: nextCodes);
  }

  Future<void> _generateIfNeeded(
    OtpAccount account, {
    required Map<String, String> codes,
    bool force = false,
  }) async {
    if (account.isHotp) {
      if (force || !codes.containsKey(account.id)) {
        codes[account.id] = await OtpService.generateCode(account);
      }
      return;
    }

    final counter = OtpService.periodCounter(account.period);
    if (force || _lastCounters[account.id] != counter) {
      _lastCounters[account.id] = counter;
      codes[account.id] = await OtpService.generateCode(account);
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshCodes();
    });
  }

  void _refreshCodes() {
    unawaited(_refreshCodesAsync());
  }

  Future<void> _refreshCodesAsync() async {
    final accountsToRefresh = <OtpAccount>[];

    for (final account in state.accounts) {
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

    final nextCodes = Map<String, String>.from(state.codes);
    for (var i = 0; i < accountsToRefresh.length; i++) {
      nextCodes[accountsToRefresh[i].id] = refreshedCodes[i];
    }

    state = state.copyWith(codes: nextCodes);
  }
}
