import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:genauth/services/app_info_service.dart';
import 'package:genauth/services/locale_service.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/app_links.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/screens/backup_screen.dart';
import 'package:genauth/screens/audit_log_screen.dart';
import 'package:genauth/screens/pin_screen.dart';
import 'package:genauth/services/storage_service.dart';

class DrawerScreen extends StatefulWidget {
  final VoidCallback onLock;
  final VoidCallback onAbout;
  final VoidCallback onOpenOnboarding;
  const DrawerScreen({
    super.key,
    required this.onLock,
    required this.onAbout,
    required this.onOpenOnboarding,
  });

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  bool _hasPin = false;
  bool _hasPanicPin = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _refreshPinState();
    _loadAppVersion();
  }

  Future<void> _refreshPinState() async {
    final has = await StorageService().hasPin();
    final hasPanic = await StorageService().hasPanicPin();
    if (mounted) {
      setState(() {
        _hasPin = has;
        _hasPanicPin = hasPanic;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final version = await AppInfoService.versionLabel();
    if (!mounted) return;
    setState(() => _appVersion = version);
  }

  Future<void> _openPinSetup() async {
    Navigator.pop(context);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.setup)),
    );
    if (ok == true) _refreshPinState();
  }

  Future<void> _removePin() async {
    Navigator.pop(context);
    await StorageService().clearPin();
    _refreshPinState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pinRemoved),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _openPanicPinSetup() async {
    Navigator.pop(context);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinScreen(mode: PinMode.panicSetup),
      ),
    );
    if (ok == true) _refreshPinState();
  }

  Future<void> _removePanicPin() async {
    Navigator.pop(context);
    await StorageService().clearPanicPin();
    _refreshPinState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.panicPinRemoved),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _openGithubRepo(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(AppLinks.repoUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.githubLinkOpenFailed),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
    }
  }

  Future<void> _openPrivacyPolicyDirect() async {
    Navigator.pop(context);

    final raw = AppLinks.privacyPolicyUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.privacyPolicyNotConfigured),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.privacyPolicyInvalidUrl),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.privacyPolicyLoadFailed),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  Future<void> _openTermsConditionsDirect() async {
    Navigator.pop(context);

    final raw = AppLinks.termsConditionsUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.termsConditionsNotConfigured),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.termsConditionsInvalidUrl),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.termsConditionsLoadFailed),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minLeadingWidth: 20,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: scheme.primary, size: 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, Locale currentLocale) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuTile(
                context: context,
                icon: Icons.language,
                title: context.l10n.english,
                trailing: currentLocale.languageCode == 'en'
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () {
                  LocaleService.changeLocale('en');
                  Navigator.pop(context);
                },
              ),
              _menuTile(
                context: context,
                icon: Icons.translate,
                title: context.l10n.indonesian,
                trailing: currentLocale.languageCode == 'id'
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () {
                  LocaleService.changeLocale('id');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      width: 292,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.surfaceContainerHigh,
                    ],
                  ),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(AppAssets.logoNoBackground),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GenAuth',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.l10n.authenticator,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: scheme.onPrimaryContainer.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _sectionHeader(context, context.l10n.drawerSectionSecurity),
              _menuTile(
                context: context,
                icon: Icons.lock_outline,
                title: context.l10n.lockapp,
                onTap: widget.onLock,
              ),
              _menuTile(
                context: context,
                icon: Icons.pin_outlined,
                title: _hasPin
                    ? context.l10n.removePinOption
                    : context.l10n.setPinOption,
                onTap: _hasPin ? _removePin : _openPinSetup,
              ),
              _menuTile(
                context: context,
                icon: Icons.warning_amber_outlined,
                title: _hasPanicPin
                    ? context.l10n.removePanicPinOption
                    : context.l10n.setPanicPinOption,
                subtitle: context.l10n.panicPinOptionSubtitle,
                onTap: _hasPanicPin ? _removePanicPin : _openPanicPinSetup,
              ),
              const SizedBox(height: 6),
              _sectionHeader(context, context.l10n.drawerSectionData),
              _menuTile(
                context: context,
                icon: Icons.backup_outlined,
                title: context.l10n.backupAndRestore,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  );
                },
              ),
              _menuTile(
                context: context,
                icon: Icons.history_edu_outlined,
                title: context.l10n.auditLogMenu,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                  );
                },
              ),
              _menuTile(
                context: context,
                icon: Icons.privacy_tip_outlined,
                title: context.l10n.privacyPolicyMenu,
                onTap: _openPrivacyPolicyDirect,
              ),
              _menuTile(
                context: context,
                icon: Icons.gavel_outlined,
                title: context.l10n.termsConditionsMenu,
                onTap: _openTermsConditionsDirect,
              ),
              const SizedBox(height: 6),
              _sectionHeader(context, context.l10n.drawerSectionApp),
              _menuTile(
                context: context,
                icon: Icons.info_outline,
                title: context.l10n.about,
                onTap: widget.onAbout,
              ),
              _menuTile(
                context: context,
                icon: Icons.rocket_launch_outlined,
                title: context.l10n.getStarted,
                onTap: widget.onOpenOnboarding,
              ),
              ValueListenableBuilder<Locale>(
                valueListenable: LocaleService.localeNotifier,
                builder: (context, currentLocale, child) {
                  final currentLangName = currentLocale.languageCode == 'id'
                      ? context.l10n.indonesian
                      : context.l10n.english;

                  return _menuTile(
                    context: context,
                    icon: Icons.language,
                    title: context.l10n.language,
                    subtitle: currentLangName,
                    trailing: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.primary,
                    ),
                    onTap: () =>
                        _showLanguageBottomSheet(context, currentLocale),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: context.l10n.openGithubRepository,
                    onPressed: () => _openGithubRepo(context),
                    icon: SvgPicture.asset(
                      AppAssets.githubSvg,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        scheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'GenAuth',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  color: scheme.outline,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '© 2026 GenAuth. ${context.l10n.allRightsReserved}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 10,
                  color: scheme.outlineVariant,
                ),
              ),
              Text(
                context.l10n.versionLabel(
                  _appVersion.isEmpty ? '...' : _appVersion,
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 10,
                  color: scheme.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
