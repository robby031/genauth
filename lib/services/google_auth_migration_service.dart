import 'dart:math';

import 'package:genotp_flutter/genotp_flutter.dart';

import 'package:genauth/models/otp_account.dart';

class GoogleAuthMigrationBatch {
  const GoogleAuthMigrationBatch({
    required this.uri,
    required this.accounts,
    required this.batchIndex,
    required this.totalBatches,
  });

  final String uri;
  final List<OtpAccount> accounts;
  final int batchIndex;
  final int totalBatches;
}

class GoogleAuthMigrationService {
  static const int maxAccountsPerQr = 10;

  Future<List<OtpAccount>> decodeAccounts(String value) async {
    final normalized = value.trim();

    if (normalized.startsWith('otpauth://')) {
      return [OtpAccount.fromUri(normalized)];
    }

    if (!normalized.startsWith('otpauth-migration://')) {
      throw const FormatException('Unsupported QR format');
    }

    final payload = await GenotpFlutter.parseOtpAuthMigrationUri(normalized);
    if (payload.accounts.isEmpty) {
      throw const FormatException('No accounts found in migration QR');
    }

    return payload.accounts.map(_accountFromMigration).toList();
  }

  Future<List<GoogleAuthMigrationBatch>> encodeAccounts(
    List<OtpAccount> accounts,
  ) async {
    if (accounts.isEmpty) return const [];

    final totalBatches = (accounts.length / maxAccountsPerQr).ceil();
    final batchId = Random.secure().nextInt(1 << 31);
    final batches = <GoogleAuthMigrationBatch>[];

    for (var batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final start = batchIndex * maxAccountsPerQr;
      final end = min(start + maxAccountsPerQr, accounts.length);
      final batchAccounts = accounts.sublist(start, end);

      final uri = await GenotpFlutter.buildOtpAuthMigrationUri(
        accounts: batchAccounts.map(_migrationFromAccount).toList(),
        version: 1,
        batchSize: totalBatches,
        batchIndex: batchIndex,
        batchId: batchId,
      );

      batches.add(
        GoogleAuthMigrationBatch(
          uri: uri,
          accounts: batchAccounts,
          batchIndex: batchIndex,
          totalBatches: totalBatches,
        ),
      );
    }

    return batches;
  }

  static String fingerprint(OtpAccount account) {
    final normalizedLabel = account.label.trim().toLowerCase();
    final normalizedIssuer = account.issuer.trim().toLowerCase();
    final normalizedSecret = account.secretB32
        .trim()
        .replaceAll(' ', '')
        .toUpperCase();
    return [
      normalizedIssuer,
      normalizedLabel,
      normalizedSecret,
      account.algorithm.toUpperCase(),
      account.digits,
      account.period,
      account.isHotp ? 'hotp' : 'totp',
    ].join('|');
  }

  static OtpAccount _accountFromMigration(OtpAuthMigrationAccount account) {
    return OtpAccount(
      id: OtpAccount.newId(),
      label: account.label.trim(),
      issuer: account.issuer.trim(),
      secretB32: account.secretB32.trim().replaceAll(' ', '').toUpperCase(),
      algorithm: account.algorithm.toUpperCase(),
      digits: account.digits,
      period: account.period,
      counter: account.counter,
      isHotp: account.isHotp,
    );
  }

  static OtpAuthMigrationAccount _migrationFromAccount(OtpAccount account) {
    return OtpAuthMigrationAccount(
      label: account.label,
      issuer: account.issuer,
      secretB32: account.secretB32,
      algorithm: account.algorithm,
      digits: account.digits,
      period: account.period,
      counter: account.counter,
      isHotp: account.isHotp,
    );
  }
}
