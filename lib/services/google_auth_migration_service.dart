import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:otpauth_migration/generated/GoogleAuthenticatorImport.pb.dart';

import '../models/otp_account.dart';

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
  static const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  List<OtpAccount> decodeAccounts(String value) {
    final normalized = value.trim();

    if (normalized.startsWith('otpauth://')) {
      return [OtpAccount.fromUri(normalized)];
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.scheme != 'otpauth-migration') {
      throw const FormatException('Unsupported QR format');
    }

    final encodedPayload = uri.queryParameters['data'];
    if (encodedPayload == null || encodedPayload.isEmpty) {
      throw const FormatException('Missing migration payload');
    }

    final payload = GoogleAuthenticatorImport.fromBuffer(
      _decodeBase64Payload(encodedPayload),
    );

    if (payload.otpParameters.isEmpty) {
      throw const FormatException('No accounts found in migration QR');
    }

    return payload.otpParameters.map(_accountFromPayload).toList();
  }

  List<GoogleAuthMigrationBatch> encodeAccounts(List<OtpAccount> accounts) {
    if (accounts.isEmpty) return const [];

    final totalBatches = (accounts.length / maxAccountsPerQr).ceil();
    final batchId = Random.secure().nextInt(1 << 31);
    final batches = <GoogleAuthMigrationBatch>[];

    for (var batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final start = batchIndex * maxAccountsPerQr;
      final end = min(start + maxAccountsPerQr, accounts.length);
      final batchAccounts = accounts.sublist(start, end);

      final payload = GoogleAuthenticatorImport(
        otpParameters: batchAccounts.map(_payloadFromAccount),
        version: 1,
        batchSize: totalBatches,
        batchIndex: batchIndex,
        batchId: batchId,
      );

      final encoded = base64Url.encode(payload.writeToBuffer());
      final uri = Uri(
        scheme: 'otpauth-migration',
        host: 'offline',
        queryParameters: {'data': encoded},
      ).toString();

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

  OtpAccount _accountFromPayload(
    GoogleAuthenticatorImport_OtpParameters param,
  ) {
    final issuer = param.issuer.trim();
    final name = param.name.trim();
    final parsedName = _splitName(name, issuer);

    return OtpAccount(
      id: OtpAccount.newId(),
      label: parsedName.$2,
      issuer: parsedName.$1,
      secretB32: _encodeBase32(param.secret),
      algorithm: _algorithmFromPayload(param.algorithm),
      digits: _digitsFromPayload(param.digits),
      period: 30,
      counter: param.counter.toInt(),
      isHotp: param.type == GoogleAuthenticatorImport_OtpType.OTP_TYPE_HOTP,
    );
  }

  GoogleAuthenticatorImport_OtpParameters _payloadFromAccount(
    OtpAccount account,
  ) {
    final name = account.issuer.isNotEmpty
        ? '${account.issuer}:${account.label}'
        : account.label;

    return GoogleAuthenticatorImport_OtpParameters(
      secret: _decodeBase32(account.secretB32),
      name: name,
      issuer: account.issuer,
      algorithm: _algorithmToPayload(account.algorithm),
      digits: _digitsToPayload(account.digits),
      type: account.isHotp
          ? GoogleAuthenticatorImport_OtpType.OTP_TYPE_HOTP
          : GoogleAuthenticatorImport_OtpType.OTP_TYPE_TOTP,
      counter: Int64(account.counter),
    );
  }

  static Uint8List _decodeBase64Payload(String input) {
    final normalized = base64Url.normalize(input.trim());

    try {
      return Uint8List.fromList(base64Url.decode(normalized));
    } catch (_) {
      return Uint8List.fromList(base64.decode(normalized));
    }
  }

  static (String, String) _splitName(String name, String issuer) {
    if (issuer.isNotEmpty) {
      final prefix = '$issuer:';
      if (name.startsWith(prefix)) {
        return (issuer, name.substring(prefix.length).trim());
      }
    }

    final separator = name.indexOf(':');
    if (separator > 0) {
      return (
        name.substring(0, separator).trim(),
        name.substring(separator + 1).trim(),
      );
    }

    return (issuer, name);
  }

  static String _algorithmFromPayload(
    GoogleAuthenticatorImport_Algorithm algorithm,
  ) {
    switch (algorithm) {
      case GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA256:
        return 'SHA256';
      case GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA512:
        return 'SHA512';
      case GoogleAuthenticatorImport_Algorithm.ALGORITHM_MD5:
        return 'MD5';
      case GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA1:
      case GoogleAuthenticatorImport_Algorithm.ALGORITHM_UNSPECIFIED:
        return 'SHA1';
    }

    throw StateError('Unsupported algorithm: $algorithm');
  }

  static GoogleAuthenticatorImport_Algorithm _algorithmToPayload(
    String algorithm,
  ) {
    switch (algorithm.toUpperCase()) {
      case 'SHA256':
        return GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA256;
      case 'SHA512':
        return GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA512;
      case 'MD5':
        return GoogleAuthenticatorImport_Algorithm.ALGORITHM_MD5;
      default:
        return GoogleAuthenticatorImport_Algorithm.ALGORITHM_SHA1;
    }
  }

  static int _digitsFromPayload(GoogleAuthenticatorImport_DigitCount digits) {
    switch (digits) {
      case GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_EIGHT:
        return 8;
      case GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_SIX:
      case GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_UNSPECIFIED:
        return 6;
    }

    throw StateError('Unsupported digit count: $digits');
  }

  static GoogleAuthenticatorImport_DigitCount _digitsToPayload(int digits) {
    return digits == 8
        ? GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_EIGHT
        : GoogleAuthenticatorImport_DigitCount.DIGIT_COUNT_SIX;
  }

  static String _encodeBase32(List<int> bytes) {
    if (bytes.isEmpty) return '';

    final output = StringBuffer();
    var buffer = 0;
    var bitsLeft = 0;

    for (final byte in bytes) {
      buffer = (buffer << 8) | (byte & 0xff);
      bitsLeft += 8;

      while (bitsLeft >= 5) {
        final index = (buffer >> (bitsLeft - 5)) & 0x1f;
        bitsLeft -= 5;
        output.write(_base32Alphabet[index]);
      }
    }

    if (bitsLeft > 0) {
      final index = (buffer << (5 - bitsLeft)) & 0x1f;
      output.write(_base32Alphabet[index]);
    }

    return output.toString();
  }

  static Uint8List _decodeBase32(String value) {
    final normalized = value
        .toUpperCase()
        .replaceAll('=', '')
        .replaceAll(RegExp(r'\s+'), '');

    if (normalized.isEmpty) return Uint8List(0);

    var buffer = 0;
    var bitsLeft = 0;
    final output = <int>[];

    for (final rune in normalized.runes) {
      final char = String.fromCharCode(rune);
      final index = _base32Alphabet.indexOf(char);
      if (index == -1) {
        throw FormatException('Invalid Base32 secret: $char');
      }

      buffer = (buffer << 5) | index;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        output.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }

    return Uint8List.fromList(output);
  }
}
