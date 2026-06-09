import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:genauth/services/google_account_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class DriveBackupPickerSheet extends StatelessWidget {
  const DriveBackupPickerSheet({super.key, required this.files});

  final List<DriveBackupFile> files;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd().add_jm();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                l10n.driveBackupRestore,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final file = files[i];
                  final modified = file.modifiedTime;
                  final subtitle = modified == null
                      ? null
                      : dateFmt.format(modified.toLocal());
                  return ListTile(
                    leading: Icon(Icons.lock_outlined, color: scheme.primary),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: subtitle != null ? Text(subtitle) : null,
                    onTap: () => Navigator.pop(context, file),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
