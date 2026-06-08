import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'package:genauth/services/storage_service.dart';

class GoogleAccountService {
  GoogleAccountService._();
  static final GoogleAccountService instance = GoogleAccountService._();
  static const String _serverClientId =
      '392835116040-advgd18jo7241m66fb33ovj4nfaffpfc.apps.googleusercontent.com';

  static const String _driveScope = drive.DriveApi.driveAppdataScope;
  static const String _appDataSpace = 'appDataFolder';
  static const List<String> _driveScopes = [_driveScope];

  bool _initialized = false;
  GoogleSignInAccount? _currentUser;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventSub;

  final ValueNotifier<GoogleSignInAccount?> userNotifier =
      ValueNotifier<GoogleSignInAccount?>(null);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final signIn = GoogleSignIn.instance;
    await signIn.initialize(serverClientId: _serverClientId);

    _eventSub = signIn.authenticationEvents.listen((event) async {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          await _persistProfile(event.user);
          _setUser(event.user);
        case GoogleSignInAuthenticationEventSignOut():
          _setUser(null);
      }
    });

    await signIn.attemptLightweightAuthentication();
  }

  void _setUser(GoogleSignInAccount? user) {
    _currentUser = user;
    userNotifier.value = user;
  }

  Future<void> _persistProfile(GoogleSignInAccount user) async {
    await StorageService.instance.saveGoogleProfile(
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      googleId: user.id,
    );
  }

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<GoogleSignInAccount> signIn() async {
    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw const GoogleAccountException(
        'Google Sign-In tidak didukung di platform ini.',
      );
    }
    final account = await signIn.authenticate();
    await _persistProfile(account);
    _setUser(account);
    return account;
  }

  Future<void> signOut({bool clearProfile = true}) async {
    await GoogleSignIn.instance.signOut();
    _setUser(null);
    if (clearProfile) {
      await StorageService.instance.clearGoogleProfile();
    }
  }

  Future<void> disconnect({bool clearProfile = true}) async {
    await GoogleSignIn.instance.disconnect();
    _setUser(null);
    if (clearProfile) {
      await StorageService.instance.clearGoogleProfile();
    }
  }

  Future<Map<String, String>> _driveAuthHeaders() async {
    final user = _currentUser;
    if (user == null) {
      throw const GoogleAccountException('Belum sign-in ke Google.');
    }
    final auth = user.authorizationClient;
    var authz = await auth.authorizationForScopes(_driveScopes);
    authz ??= await auth.authorizeScopes(_driveScopes);
    final headers = await auth.authorizationHeaders(_driveScopes);
    if (headers == null) {
      throw const GoogleAccountException(
        'Gagal mendapatkan token Drive. Izin ditolak.',
      );
    }
    return headers;
  }

  Future<drive.DriveApi> _driveApi() async {
    final headers = await _driveAuthHeaders();
    return drive.DriveApi(_AuthedClient(headers));
  }

  Future<DriveBackupFile> uploadBackup({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final api = await _driveApi();
    final media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/octet-stream',
    );
    final fileMeta = drive.File(name: fileName, parents: [_appDataSpace]);
    final created = await api.files.create(
      fileMeta,
      uploadMedia: media,
      $fields: 'id,name,modifiedTime,size',
    );
    return DriveBackupFile.fromApi(created);
  }

  Future<List<DriveBackupFile>> listBackups() async {
    final api = await _driveApi();
    final result = await api.files.list(
      spaces: _appDataSpace,
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime,size)',
      pageSize: 50,
    );
    return (result.files ?? []).map(DriveBackupFile.fromApi).toList();
  }

  Future<Uint8List> downloadBackup(String fileId) async {
    final api = await _driveApi();
    final media =
        await api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await _driveApi();
    await api.files.delete(fileId);
  }

  Future<void> dispose() async {
    await _eventSub?.cancel();
    _eventSub = null;
  }
}

class DriveBackupFile {
  const DriveBackupFile({
    required this.id,
    required this.name,
    required this.modifiedTime,
    required this.size,
  });

  final String id;
  final String name;
  final DateTime? modifiedTime;
  final int? size;

  factory DriveBackupFile.fromApi(drive.File file) {
    return DriveBackupFile(
      id: file.id ?? '',
      name: file.name ?? '(unnamed)',
      modifiedTime: file.modifiedTime,
      size: int.tryParse(file.size ?? ''),
    );
  }
}

class GoogleAccountException implements Exception {
  const GoogleAccountException(this.message);
  final String message;

  @override
  String toString() => message;
}

class _AuthedClient extends http.BaseClient {
  _AuthedClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
