import 'dart:async';
import 'package:flutter/material.dart';
import '../models/otp_account.dart';
import '../services/storage_service.dart';
import '../services/otp_service.dart';
import '../widgets/otp_tile.dart';
import 'add_account_screen.dart';
import 'lock_screen.dart';
import 'drawer_screen.dart';
import '../repositories/otp_repository.dart';
import '../utils/l10n_extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _storage = StorageService.instance;
  List<OtpAccount> _accounts = [];
  final Map<String, String> _codes = {};
  final Map<String, int> _lastCounters = {};
  Timer? _timer;

  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final _otpRepository = OtpRepository(StorageService.instance);

  List<OtpAccount> get _filteredAccounts {
    if (_searchQuery.isEmpty) return _accounts;
    final q = _searchQuery.toLowerCase();
    return _accounts
        .where(
          (a) =>
              a.label.toLowerCase().contains(q) ||
              a.issuer.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndRefresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshCodes());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAndRefresh() async {
    final accounts = await _storage.loadAccounts();
    setState(() => _accounts = accounts);
    for (final a in accounts) {
      await _generateIfNeeded(a, force: true);
    }
    if (mounted) setState(() {});
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
    for (final a in _accounts) {
      if (!a.isHotp) {
        final counter = OtpService.periodCounter(a.period);
        if (_lastCounters[a.id] != counter) {
          _lastCounters[a.id] = counter;
          OtpService.generateCode(a).then((code) {
            if (mounted) setState(() => _codes[a.id] = code);
          });
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteAccount(String id) async {
    await _storage.deleteAccount(id);
    setState(() {
      _accounts.removeWhere((a) => a.id == id);
      _codes.remove(id);
      _lastCounters.remove(id);
    });
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (result == true) await _loadAndRefresh();
  }

  void _startSearch() => setState(() {
    _isSearching = true;
    _searchQuery = '';
    _searchController.clear();
  });

  void _stopSearch() => setState(() {
    _isSearching = false;
    _searchQuery = '';
    _searchController.clear();
  });

  void _lockApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen()),
      (_) => false,
    );
  }

  void _showAbout() {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: context.l10n.appTitle,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.lock, size: 48),
      children: [Text(context.l10n.aboutDescription)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredAccounts;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.searchHint,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(context.l10n.appTitle),
        centerTitle: false,
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _stopSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
        ],
      ),
      drawer: DrawerScreen(onLock: _lockApp, onAbout: _showAbout),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.lock_outline,
                    size: 64,
                    color: scheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? context.l10n.noResults
                        : context.l10n.noAccountsYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (!_isSearching) Text(context.l10n.tapToAddFirstAccount),
                ],
              ),
            )
          : ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, i) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final account = filtered[i];
                return OtpTile(
                  account: account,
                  code: _codes[account.id] ?? '------',
                  onDelete: () => _deleteAccount(account.id),
                  onHotpIncrement: account.isHotp
                      ? () => _otpRepository.hotpIncrement(account)
                      : null,
                );
              },
            ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton(
              onPressed: _openAdd,
              child: const Icon(Icons.add),
            ),
    );
  }
}
