import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/people/v1.dart' as people;
import 'package:http/http.dart' as http;

import 'package:genauth/services/storage_service.dart';

class GoogleAccountService {
  GoogleAccountService._();
  static final GoogleAccountService instance = GoogleAccountService._();
  static const String _serverClientId =
      '392835116040-advgd18jo7241m66fb33ovj4nfaffpfc.apps.googleusercontent.com';

  static const String _driveScope = drive.DriveApi.driveAppdataScope;
  static const String _profileScope =
      'https://www.googleapis.com/auth/userinfo.profile';
  static const String _emailScope =
      'https://www.googleapis.com/auth/userinfo.email';
  static const String _appDataSpace = 'appDataFolder';
  static const List<String> _driveScopes = [_driveScope];
  static const List<String> _profileScopes = [_profileScope, _emailScope];

  bool _initialized = false;
  Future<void>? _initializing;
  GoogleSignInAccount? _currentUser;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _eventSub;

  final ValueNotifier<GoogleSignInAccount?> userNotifier =
      ValueNotifier<GoogleSignInAccount?>(null);

  Future<void> initialize({bool restorePreviousSignIn = true}) {
    if (_initialized) {
      return Future.value();
    }
    if (_initializing != null) {
      return _initializing!;
    }

    _initializing = _initializeInternal(
      restorePreviousSignIn: restorePreviousSignIn,
    );
    return _initializing!;
  }

  Future<void> _initializeInternal({
    required bool restorePreviousSignIn,
  }) async {
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

    _initialized = true;

    if (restorePreviousSignIn) {
      await signIn.attemptLightweightAuthentication();
    }
  }

  Future<void> ensureInitialized() => initialize(restorePreviousSignIn: true);

  void _setUser(GoogleSignInAccount? user) {
    _currentUser = user;
    userNotifier.value = user;
  }

  Future<void> _persistProfile(GoogleSignInAccount user) async {
    final peopleProfile = await _fetchPeopleProfile(user);

    await StorageService.instance.saveGoogleProfile(
      email: peopleProfile?.email ?? user.email,
      displayName: peopleProfile?.displayName ?? user.displayName,
      photoUrl: peopleProfile?.photoUrl ?? user.photoUrl,
      googleId: peopleProfile?.googleId ?? user.id,
      givenName: peopleProfile?.givenName,
      familyName: peopleProfile?.familyName,
      localeCode: peopleProfile?.localeCode,
    );
  }

  Future<_PeopleProfileData?> _fetchPeopleProfile(
    GoogleSignInAccount user,
  ) async {
    try {
      final headers = await _profileAuthHeaders(user);
      final api = people.PeopleServiceApi(_AuthedClient(headers));
      final person = await api.people.get(
        'people/me',
        personFields: 'names,emailAddresses,photos,locales,metadata',
      );

      final name = _primaryByMetadata(person.names, (n) => n.metadata);
      final email = _primaryByMetadata(
        person.emailAddresses,
        (e) => e.metadata,
      );
      final photo = _primaryByMetadata(person.photos, (p) => p.metadata);
      final locale = _primaryByMetadata(person.locales, (l) => l.metadata);

      return _PeopleProfileData(
        email: email?.value ?? user.email,
        displayName: name?.displayName ?? user.displayName,
        givenName: name?.givenName,
        familyName: name?.familyName,
        photoUrl: photo?.url ?? user.photoUrl,
        googleId: person.resourceName?.replaceFirst('people/', '') ?? user.id,
        localeCode: locale?.value,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _profileAuthHeaders(
    GoogleSignInAccount user,
  ) async {
    final auth = user.authorizationClient;
    var authz = await auth.authorizationForScopes(_profileScopes);
    authz ??= await auth.authorizeScopes(_profileScopes);
    final headers = await auth.authorizationHeaders(_profileScopes);
    if (headers == null) {
      throw const GoogleAccountException(
        'Gagal mendapatkan token profile Google. Izin ditolak.',
      );
    }
    return headers;
  }

  T? _primaryByMetadata<T>(
    List<T>? entries,
    people.FieldMetadata? Function(T entry) metadataOf,
  ) {
    if (entries == null || entries.isEmpty) {
      return null;
    }

    for (final entry in entries) {
      if (metadataOf(entry)?.primary == true) {
        return entry;
      }
    }

    return entries.first;
  }

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<GoogleSignInAccount> signIn() async {
    await ensureInitialized();
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

  Future<void> refreshCurrentProfile() async {
    await ensureInitialized();
    final user = _currentUser;
    if (user == null) {
      throw const GoogleAccountException('Belum sign-in ke Google.');
    }
    await _persistProfile(user);
  }

  Future<void> signOut({bool clearProfile = true}) async {
    await ensureInitialized();
    await GoogleSignIn.instance.signOut();
    _setUser(null);
    if (clearProfile) {
      await StorageService.instance.clearGoogleProfile();
    }
  }

  Future<void> disconnect({bool clearProfile = true}) async {
    await ensureInitialized();
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

class _PeopleProfileData {
  const _PeopleProfileData({
    required this.email,
    required this.displayName,
    required this.givenName,
    required this.familyName,
    required this.photoUrl,
    required this.googleId,
    required this.localeCode,
  });

  final String email;
  final String? displayName;
  final String? givenName;
  final String? familyName;
  final String? photoUrl;
  final String? googleId;
  final String? localeCode;
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
