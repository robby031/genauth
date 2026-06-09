import 'package:flutter/material.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/services/google_auth_migration_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'widgets/batch.dart';
import 'widgets/batch_table.dart';

class GoogleAuthExportScreen extends StatelessWidget {
  const GoogleAuthExportScreen({super.key, required this.accounts});

  final List<OtpAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          context.l10n.googleAuthExportTitle,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: FutureBuilder<List<GoogleAuthMigrationBatch>>(
            future: GoogleAuthMigrationService().encodeAccounts(accounts),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final batches = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.googleAuthExportIntro(accounts.length),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.googleAuthExportHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 6,
                          child: PageView.builder(
                            itemCount: batches.length,
                            controller: PageController(viewportFraction: 1),
                            itemBuilder: (context, index) {
                              final batch = batches[index];
                              return Batch(batch: batch);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 4,
                          child: BatchAccountsTable(batches: batches),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
