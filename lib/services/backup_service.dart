import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:genauth/models/otp_account.dart';

class BackupService {
  static const int _iterations = 100000;
  static const int _saltLength = 32;

  static Future<Uint8List> export(
    List<OtpAccount> accounts,
    String password,
  ) async {
    final salt = _randomBytes(_saltLength);
    final algorithm = AesGcm.with256bits();
    final nonce = algorithm.newNonce();

    final key = await _deriveKey(password, salt);
    final secretKey = await algorithm.newSecretKeyFromBytes(key);

    final plaintext = utf8.encode(OtpAccount.listToJson(accounts));
    final box = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    final ciphertextWithTag = Uint8List.fromList([
      ...box.cipherText,
      ...box.mac.bytes,
    ]);

    final vault = {
      'version': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(ciphertextWithTag),
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(vault)));
  }

  static Future<List<OtpAccount>> import(
    Uint8List data,
    String password,
  ) async {
    final Map<String, dynamic> vault;
    try {
      vault = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Invalid backup file format');
    }

    final version = vault['version'] as int?;
    if (version != 1) {
      throw FormatException('Unsupported backup version: $version');
    }

    final salt = base64Decode(vault['salt'] as String);
    final nonce = base64Decode(vault['nonce'] as String);
    final ciphertextWithTag = base64Decode(vault['ciphertext'] as String);

    const tagLen = 16;
    if (ciphertextWithTag.length < tagLen) {
      throw const FormatException('Corrupted backup: ciphertext too short');
    }
    final ciphertext = ciphertextWithTag.sublist(
      0,
      ciphertextWithTag.length - tagLen,
    );
    final tag = ciphertextWithTag.sublist(ciphertextWithTag.length - tagLen);

    final key = await _deriveKey(password, salt);
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(key);

    final box = SecretBox(ciphertext, nonce: nonce, mac: Mac(tag));

    final plaintext = await algorithm.decrypt(box, secretKey: secretKey);

    return OtpAccount.listFromJson(utf8.decode(plaintext));
  }

  static Future<List<int>> _deriveKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    final derived = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return derived.extractBytes();
  }

  static List<int> _randomBytes(int length) {
    final rng = Random.secure();
    return List.generate(length, (_) => rng.nextInt(256));
  }
}
