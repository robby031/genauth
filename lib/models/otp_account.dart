import 'dart:convert';
import 'dart:math';

class OtpAccount {
  final String id;
  final String label;
  final String issuer;
  final String secretB32;
  final String algorithm;
  final int digits;
  final int period;
  final int counter;
  final bool isHotp;
  final List<String> tags;

  const OtpAccount({
    required this.id,
    required this.label,
    required this.issuer,
    required this.secretB32,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    this.counter = 0,
    this.isHotp = false,
    this.tags = const [],
  });

  int get algorithmInt {
    switch (algorithm.toUpperCase()) {
      case 'SHA256':
        return 1;
      case 'SHA512':
        return 2;
      default:
        return 0;
    }
  }

  OtpAccount copyWith({int? counter, List<String>? tags}) => OtpAccount(
    id: id,
    label: label,
    issuer: issuer,
    secretB32: secretB32,
    algorithm: algorithm,
    digits: digits,
    period: period,
    counter: counter ?? this.counter,
    isHotp: isHotp,
    tags: tags ?? this.tags,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'issuer': issuer,
    'secretB32': secretB32,
    'algorithm': algorithm,
    'digits': digits,
    'period': period,
    'counter': counter,
    'isHotp': isHotp,
    if (tags.isNotEmpty) 'tags': tags,
  };

  factory OtpAccount.fromJson(Map<String, dynamic> json) => OtpAccount(
    id: json['id'] as String,
    label: json['label'] as String,
    issuer: json['issuer'] as String? ?? '',
    secretB32: json['secretB32'] as String,
    algorithm: json['algorithm'] as String? ?? 'SHA1',
    digits: json['digits'] as int? ?? 6,
    period: json['period'] as int? ?? 30,
    counter: json['counter'] as int? ?? 0,
    isHotp: json['isHotp'] as bool? ?? false,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  // Parse otpauth://totp/label?secret=X&issuer=Y&algorithm=Z&digits=6&period=30
  factory OtpAccount.fromUri(String uriStr) {
    final uri = Uri.parse(uriStr);
    if (uri.scheme != 'otpauth') throw FormatException('Not an otpauth URI');

    final isHotp = uri.host == 'hotp';
    final rawLabel = Uri.decodeComponent(uri.path.replaceFirst('/', ''));
    String issuer = '';
    String label = rawLabel;
    if (rawLabel.contains(':')) {
      final parts = rawLabel.split(':');
      issuer = parts[0].trim();
      label = parts[1].trim();
    }

    final params = uri.queryParameters;
    issuer = params['issuer'] ?? issuer;
    final secret = params['secret'] ?? '';
    final algorithm = params['algorithm'] ?? 'SHA1';
    final digits = int.tryParse(params['digits'] ?? '6') ?? 6;
    final period = int.tryParse(params['period'] ?? '30') ?? 30;
    final counter = int.tryParse(params['counter'] ?? '0') ?? 0;

    if (secret.isEmpty) throw FormatException('Missing secret in otpauth URI');

    return OtpAccount(
      id: newId(),
      label: label,
      issuer: issuer,
      secretB32: secret.toUpperCase(),
      algorithm: algorithm.toUpperCase(),
      digits: digits,
      period: period,
      counter: counter,
      isHotp: isHotp,
    );
  }

  static String newId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static List<OtpAccount> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => OtpAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<OtpAccount> accounts) {
    return jsonEncode(accounts.map((a) => a.toJson()).toList());
  }

  String toUri() {
    final type = isHotp ? 'hotp' : 'totp';
    final labelValue = issuer.isNotEmpty ? '$issuer:$label' : label;
    final queryParameters = <String, String>{
      'secret': secretB32,
      if (issuer.isNotEmpty) 'issuer': issuer,
      'algorithm': algorithm,
      'digits': digits.toString(),
      if (isHotp)
        'counter': counter.toString()
      else
        'period': period.toString(),
    };

    return Uri(
      scheme: 'otpauth',
      host: type,
      pathSegments: [labelValue],
      queryParameters: queryParameters,
    ).toString();
  }
}
