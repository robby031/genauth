import 'package:flutter/material.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/services/google_auth_migration_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class BatchAccountsTable extends StatelessWidget {
  const BatchAccountsTable({
    super.key,
    required this.batches,
    required this.allAccounts,
  });

  final List<GoogleAuthMigrationBatch> batches;
  final List<OtpAccount> allAccounts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qrByFingerprint = <String, String>{};
    for (final batch in batches) {
      final qrLabel = '${batch.batchIndex + 1}/${batch.totalBatches}';
      for (final account in batch.accounts) {
        qrByFingerprint[GoogleAuthMigrationService.fingerprint(account)] =
            qrLabel;
      }
    }

    final supportedCount = allAccounts
        .where(GoogleAuthMigrationService.isExportCompatible)
        .length;
    final unsupportedCount = allAccounts.length - supportedCount;

    final rows = <DataRow>[
      for (final account in allAccounts)
        () {
          final supported = GoogleAuthMigrationService.isExportCompatible(
            account,
          );
          final qr =
              qrByFingerprint[GoogleAuthMigrationService.fingerprint(account)];

          return DataRow(
            color: WidgetStatePropertyAll(
              supported
                  ? Colors.transparent
                  : scheme.errorContainer.withValues(alpha: 0.26),
            ),
            cells: [
              DataCell(Text(qr ?? '-')),
              DataCell(Text(account.issuer.isEmpty ? '-' : account.issuer)),
              DataCell(Text(account.label)),
              DataCell(Text(account.isHotp ? 'HOTP' : 'TOTP')),
              DataCell(
                Text(
                  supported ? 'Supported' : 'Not supported',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: supported ? Colors.green.shade700 : scheme.error,
                  ),
                ),
              ),
            ],
          );
        }(),
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
                '${context.l10n.googleAuthBatchAccounts(allAccounts.length)} • $supportedCount supported • $unsupportedCount not supported',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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
                    headingRowHeight: 34,
                    horizontalMargin: 6,
                    columns: [
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableQr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableIssuer,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableAccount,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          context.l10n.googleAuthTableType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
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
