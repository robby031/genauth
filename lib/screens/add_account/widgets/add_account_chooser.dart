import 'package:flutter/material.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'add_account_method.dart';

class AddAccountChooser extends StatelessWidget {
  const AddAccountChooser({
    super.key,
    required this.onScanSelected,
    required this.onManualSelected,
  });

  final VoidCallback onScanSelected;
  final VoidCallback onManualSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.l10n.addAccount,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.googleAuthSectionDesc,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        AddMethod(
          icon: Icons.qr_code_scanner_rounded,
          title: context.l10n.scanQr,
          subtitle: context.l10n.googleAuthImportAction,
          onTap: onScanSelected,
        ),
        const SizedBox(height: 12),
        AddMethod(
          icon: Icons.edit_note_rounded,
          title: context.l10n.manualEntry,
          subtitle: context.l10n.addAccount,
          onTap: onManualSelected,
        ),
      ],
    );
  }
}
