import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/providers/home_provider.dart';
import 'package:genauth/screens/home/widgets/otp_tile.dart';
import 'package:genauth/widgets/tag_filter_bar.dart';
import 'package:genauth/screens/add_account/add_account_screen.dart';
import 'package:genauth/screens/backup/backup_screen.dart';
import 'package:genauth/screens/lock/lock_screen.dart';
import 'package:genauth/screens/drawer/drawer_screen.dart';
import 'package:genauth/screens/onboarding/onboarding_screen.dart';
import 'package:genauth/screens/profile/profile_screen.dart';
import 'package:genauth/providers/google_account_provider.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/app_info_service.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'widgets/smart_floating.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _bubbleExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    _collapseBubble();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (result == true) {
      await ref.read(homeProvider.notifier).loadAndRefresh();
    }
  }

  Future<void> _openBackup() async {
    _collapseBubble();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackupScreen()),
    );
  }

  void _startSearch() {
    _collapseBubble();
    _searchController.clear();
    ref.read(homeProvider.notifier).startSearch();
  }

  void _stopSearch() {
    _searchController.clear();
    ref.read(homeProvider.notifier).stopSearch();
  }

  void _lockApp() {
    AuditLogService.instance.log('app_locked_by_user');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen()),
      (_) => false,
    );
  }

  Future<void> _showAbout() async {
    Navigator.pop(context);
    final version = await AppInfoService.versionLabel();
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: context.l10n.appTitle,
      applicationVersion: version,
      applicationIcon: Image.asset(
        AppAssets.logoNoBackground,
        width: 48,
        height: 48,
      ),
      children: [Text(context.l10n.aboutDescription)],
    );
  }

  void _openOnboardingFromDrawer() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(fromDrawer: true),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _toggleBubble() {
    setState(() => _bubbleExpanded = !_bubbleExpanded);
  }

  void _collapseBubble() {
    if (_bubbleExpanded) {
      setState(() => _bubbleExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final googleUser = ref.watch(googleAccountUserProvider);

    final scheme = Theme.of(context).colorScheme;
    final filtered = homeState.filteredAccounts;
    final totpAccounts = filtered.where((a) => !a.isHotp).toList();
    final hotpAccounts = filtered.where((a) => a.isHotp).toList();
    final tagBar = TagFilterBar(
      allTags: homeState.allTags,
      selectedTags: homeState.selectedTags,
      onToggle: homeNotifier.toggleTag,
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
                  homeState.isSearching ? Icons.search_off : Icons.lock_outline,
                  size: 64,
                  color: scheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  homeState.isSearching
                      ? context.l10n.noResults
                      : context.l10n.noAccountsYet,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (!homeState.isSearching)
                  Text(context.l10n.tapToAddFirstAccount),
              ],
            ),
          ),
        ),
      ],
    );

    Widget buildAccountSection({
      required String title,
      required List<OtpAccount> accounts,
    }) {
      if (accounts.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: homeState.isSearching
                ? (oldIdx, newIdx) {}
                : (oldIdx, newIdx) => homeNotifier.reorderVisibleAccounts(
                    accounts,
                    oldIdx,
                    newIdx,
                  ),
            proxyDecorator: (child, _, animation) => Material(
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
            itemCount: accounts.length,
            itemBuilder: (_, i) {
              final account = accounts[i];
              return Column(
                key: ValueKey(account.id),
                mainAxisSize: MainAxisSize.min,
                children: [
                  OtpTile(
                    reorderIndex: i,
                    account: account,
                    code: homeState.codeFor(account.id),
                    onDelete: () => homeNotifier.deleteAccount(account.id),
                    onHotpIncrement: account.isHotp
                        ? () => homeNotifier.incrementHotp(account)
                        : null,
                    showDragHandle: !homeState.isSearching,
                    onEditTags: (tags) =>
                        homeNotifier.updateAccountTags(account.id, tags),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          ),
        ],
      );
    }

    final accountList = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        buildAccountSection(title: 'TOTP', accounts: totpAccounts),
        buildAccountSection(title: 'HOTP', accounts: hotpAccounts),
      ],
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
        centerTitle: false,
        title: homeState.isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.searchHint,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: homeNotifier.setSearchQuery,
              )
            : Text(
                context.l10n.appTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          if (homeState.isSearching)
            IconButton(icon: const Icon(Icons.close), onPressed: _stopSearch)
          else ...[
            IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
            if (googleUser != null && googleUser.photoUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: _openProfile,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: googleUser.photoUrl!,
                          placeholder: (context, url) =>
                              const Icon(Icons.account_circle, size: 32),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.account_circle, size: 32),
                          fit: BoxFit.cover,
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      drawer: DrawerScreen(
        onLock: _lockApp,
        onAbout: _showAbout,
        onOpenOnboarding: _openOnboardingFromDrawer,
      ),
      body: RefreshIndicator(
        onRefresh: homeNotifier.loadAndRefresh,
        child: body,
      ),
      floatingActionButton: homeState.isSearching
          ? null
          : SmartFloatingBubble(
              expanded: _bubbleExpanded,
              onToggle: _toggleBubble,
              onAdd: _openAdd,
              onSearch: _startSearch,
              onBackup: _openBackup,
              addLabel: context.l10n.addAccount,
              searchLabel: context.l10n.searchHint,
              backupLabel: context.l10n.backupAndRestore,
            ),
    );
  }
}
