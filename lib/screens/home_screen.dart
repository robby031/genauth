import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../services/storage_service.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(
      storage: StorageService.instance,
      otpRepository: OtpRepository(StorageService.instance),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (result == true) await _controller.loadAndRefresh();
  }

  void _startSearch() {
    _searchController.clear();
    _controller.startSearch();
  }

  void _stopSearch() {
    _searchController.clear();
    _controller.stopSearch();
  }

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        final filtered = _controller.filteredAccounts;

        return Scaffold(
          appBar: AppBar(
            title: _controller.isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchHint,
                      border: InputBorder.none,
                    ),
                    onChanged: _controller.setSearchQuery,
                  )
                : Text(context.l10n.appTitle),
            centerTitle: false,
            actions: [
              _controller.isSearching
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
                        _controller.isSearching
                            ? Icons.search_off
                            : Icons.lock_outline,
                        size: 64,
                        color: scheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _controller.isSearching
                            ? context.l10n.noResults
                            : context.l10n.noAccountsYet,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (!_controller.isSearching)
                        Text(context.l10n.tapToAddFirstAccount),
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
                      code: _controller.codeFor(account.id),
                      onDelete: () => _controller.deleteAccount(account.id),
                      onHotpIncrement: account.isHotp
                          ? () => _controller.incrementHotp(account)
                          : null,
                    );
                  },
                ),
          floatingActionButton: _controller.isSearching
              ? null
              : FloatingActionButton(
                  onPressed: _openAdd,
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}
