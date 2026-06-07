import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../utils/l10n_extensions.dart';

class DrawerScreen extends StatelessWidget {
  final VoidCallback onLock;
  final VoidCallback onAbout;
  const DrawerScreen({super.key, required this.onLock, required this.onAbout});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.lock, size: 40, color: scheme.onPrimaryContainer),
                const SizedBox(height: 8),
                Text(
                  'GenAuth',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Authenticator',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(context.l10n.lockapp),
            onTap: onLock,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.about),
            onTap: onAbout,
          ),
          const Divider(),
          ValueListenableBuilder<Locale>(
            valueListenable: LocaleService.localeNotifier,
            builder: (context, currentLocale, child) {
              final currentLangName = currentLocale.languageCode == 'id'
                  ? 'Bahasa Indonesia'
                  : 'English';

              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.l10n.language),
                subtitle: Text(
                  currentLangName,
                  style: TextStyle(color: scheme.primary),
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('English'),
                            trailing: currentLocale.languageCode == 'en'
                                ? Icon(Icons.check, color: scheme.primary)
                                : null,
                            onTap: () {
                              LocaleService.changeLocale('en');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Bahasa Indonesia'),
                            trailing: currentLocale.languageCode == 'id'
                                ? Icon(Icons.check, color: scheme.primary)
                                : null,
                            onTap: () {
                              LocaleService.changeLocale('id');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
