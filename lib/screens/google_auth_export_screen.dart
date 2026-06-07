import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/otp_account.dart';
import '../services/google_auth_migration_service.dart';
import '../utils/app_assets.dart';
import '../utils/l10n_extensions.dart';

class GoogleAuthExportScreen extends StatelessWidget {
  const GoogleAuthExportScreen({super.key, required this.accounts});

  final List<OtpAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.googleAuthExportTitle)),
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
                              return _BatchCard(batch: batch);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 4,
                          child: _BatchAccountsTable(batches: batches),
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

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final GoogleAuthMigrationBatch batch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.googleAuthBatchLabel(
                batch.batchIndex + 1,
                batch.totalBatches,
              ),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.googleAuthBatchAccounts(batch.accounts.length),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: QrImageView(
                      data: batch.uri,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      embeddedImage: const AssetImage(
                        AppAssets.logoNoBackground,
                      ),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchAccountsTable extends StatelessWidget {
  const _BatchAccountsTable({required this.batches});

  final List<GoogleAuthMigrationBatch> batches;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rows = <DataRow>[
      for (final batch in batches)
        for (final account in batch.accounts)
          DataRow(
            cells: [
              DataCell(Text('${batch.batchIndex + 1}/${batch.totalBatches}')),
              DataCell(Text(account.issuer.isEmpty ? '-' : account.issuer)),
              DataCell(Text(account.label)),
              DataCell(Text(account.isHotp ? 'HOTP' : 'TOTP')),
            ],
          ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              color: scheme.surfaceContainerHigh,
              child: Text(
                context.l10n.googleAuthBatchAccounts(rows.length),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      scheme.surfaceContainerHigh,
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableQr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableIssuer,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableAccount,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableType,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
