import 'package:flutter/material.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'widgets/google_auth_migration.dart';
import 'widgets/export.dart';
import 'widgets/import.dart';
import 'widgets/google_drive.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          context.l10n.backupAndRestore,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GoogleAuthMigration(),
            SizedBox(height: 20),
            DriveBackup(),
            SizedBox(height: 20),
            Export(),
            SizedBox(height: 20),
            Import(),
          ],
        ),
      ),
    );
  }
}
