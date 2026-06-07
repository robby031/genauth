import 'package:flutter/material.dart';
import 'package:genauth/controllers/home_controller.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/widgets/otp_tile.dart';
import 'package:genauth/widgets/tag_filter_bar.dart';
import 'package:genauth/screens/add_account_screen.dart';
import 'package:genauth/screens/lock_screen.dart';
import 'package:genauth/screens/drawer_screen.dart';
import 'package:genauth/repositories/otp_repository.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/l10n_extensions.dart';

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
      applicationIcon: Image.asset(
        AppAssets.logoNoBackground,
        width: 48,
        height: 48,
      ),
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
        final tagBar = TagFilterBar(
          allTags: _controller.allTags,
          selectedTags: _controller.selectedTags,
          onToggle: _controller.toggleTag,
        );

        final emptyState = ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
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
              ),
            ),
          ],
        );

        final accountList = ReorderableListView.builder(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          onReorderItem: _controller.isSearching
              ? (oldIdx, newIdx) {}
              : _controller.reorderAccounts,
          proxyDecorator: (child, _, animation) => Material(
            elevation: 4,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final account = filtered[i];
            return Column(
              key: ValueKey(account.id),
              mainAxisSize: MainAxisSize.min,
              children: [
                OtpTile(
                  account: account,
                  code: _controller.codeFor(account.id),
                  onDelete: () => _controller.deleteAccount(account.id),
                  onHotpIncrement: account.isHotp
                      ? () => _controller.incrementHotp(account)
                      : null,
                  showDragHandle: !_controller.isSearching,
                  onEditTags: (tags) =>
                      _controller.updateAccountTags(account.id, tags),
                ),
                const Divider(height: 1),
              ],
            );
          },
        );

        final body = Column(
          children: [
            tagBar,
            Expanded(child: filtered.isEmpty ? emptyState : accountList),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,

            title: _controller.isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchHint,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: _controller.setSearchQuery,
                  )
                : Text(
                    context.l10n.appTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
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
          body: RefreshIndicator(
            onRefresh: _controller.loadAndRefresh,
            child: body,
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
