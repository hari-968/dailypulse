// ─────────────────────────────────────────────────────────────────────────────
// update_service.dart
//
// Responsibilities:
//   • Fetch version JSON from GitHub (or any public URL)
//   • Compare with the installed app version via package_info_plus
//   • Download the APK using Dio with real-time progress callbacks
//   • Trigger APK installation via open_filex
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Data model for the remote version JSON ─────────────────────────────────────
class AppUpdateInfo {
  /// e.g. "1.2.0"
  final String version;

  /// Direct download URL to the APK file
  final String apkUrl;

  /// If true, the "Later" button is hidden and user cannot dismiss the sheet
  final bool forceUpdate;

  /// Human-readable update message shown in the bottom sheet
  final String message;

  const AppUpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.forceUpdate,
    required this.message,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String? ?? '0.0.0',
      apkUrl: json['apk_url'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      message: json['message'] as String? ??
          'A new version is available. Please update to continue.',
    );
  }
}

// ── Possible states returned by checkForUpdate() ──────────────────────────────
enum UpdateCheckResult {
  /// App is up to date — no action needed
  upToDate,

  /// A newer version is available
  updateAvailable,

  /// Network or parse error while checking
  error,
}

// ── UpdateService ─────────────────────────────────────────────────────────────
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Human-readable reason for the latest failure in update flow.
  String? lastError;

  // ── CONFIGURE THIS ────────────────────────────────────────────────────────
  //
  // Host a file like this on GitHub (raw URL) or any public server:
  //
  //   https://raw.githubusercontent.com/<user>/<repo>/main/version.json
  //
  // version.json contents:
  // {
  //   "version"     : "1.1.0",
  //   "apk_url"     : "https://github.com/.../releases/download/v1.1.0/app.apk",
  //   "force_update": false,
  //   "message"     : "Bug fixes and performance improvements."
  // }
  static const String _versionJsonUrl =
      'https://raw.githubusercontent.com/hari-968/dailypulse/main/version.json';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // ── Get the currently installed app version ──────────────────────────────
  /// Returns the version string from pubspec (e.g. "1.0.0").
  /// Source file: lib/services/update_service.dart
  Future<String> getInstalledVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    debugPrint(
      '[update_service.dart] Installed version: ${packageInfo.version}+${packageInfo.buildNumber}',
    );
    return packageInfo.version;
  }

  // ── Check if an update is available ───────────────────────────────────────
  /// Returns a tuple of [UpdateCheckResult, AppUpdateInfo?].
  /// AppUpdateInfo is non-null only when result == updateAvailable.
  /// Source file: lib/services/update_service.dart
  Future<(UpdateCheckResult, AppUpdateInfo?)> checkForUpdate() async {
    try {
      lastError = null;
      debugPrint('[update_service.dart] checkForUpdate() called — fetching $_versionJsonUrl');

      // 1. Fetch the remote version JSON
      final response = await _dio.get<Map<String, dynamic>>(_versionJsonUrl);
      if (response.statusCode != 200 || response.data == null) {
        debugPrint('[update_service.dart] Bad response: HTTP ${response.statusCode}');
        return (UpdateCheckResult.error, null);
      }

      final info = AppUpdateInfo.fromJson(response.data!);

      if (info.apkUrl.trim().isEmpty || !_looksLikeDownloadableApkUrl(info.apkUrl)) {
        lastError =
            'Invalid apk_url in version.json. Use a direct .apk file link (prefer GitHub Releases download URL).';
        debugPrint('[update_service.dart] ❌ $lastError');
        return (UpdateCheckResult.error, null);
      }

      // 2. Get the currently installed version
      final currentVersion = await getInstalledVersion();

      debugPrint(
        '[update_service.dart] Installed: $currentVersion  |  Remote: ${info.version}  |  ForceUpdate: ${info.forceUpdate}',
      );

      // 3. Compare semantic versions
      if (_isNewer(info.version, currentVersion)) {
        debugPrint('[update_service.dart] ✅ Update available → ${info.version}');
        return (UpdateCheckResult.updateAvailable, info);
      }

      debugPrint('[update_service.dart] ✔ App is up to date ($currentVersion)');
      return (UpdateCheckResult.upToDate, null);
    } on DioException catch (e) {
      lastError = 'Could not check updates: ${e.message ?? 'network error'}';
      debugPrint('[update_service.dart] ❌ Network error: ${e.message}');
      return (UpdateCheckResult.error, null);
    } catch (e) {
      lastError = 'Unexpected update check error: $e';
      debugPrint('[update_service.dart] ❌ Unexpected error: $e');
      return (UpdateCheckResult.error, null);
    }
  }

  // ── Download the APK with progress ────────────────────────────────────────
  /// [onProgress] receives values from 0.0 to 1.0.
  /// Returns the local [File] on success, or null on failure.
  Future<File?> downloadApk(
    String apkUrl, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      lastError = null;

      if (apkUrl.trim().isEmpty) {
        lastError = 'APK URL is empty.';
        debugPrint('[UpdateService] $lastError');
        return null;
      }

      final apkUri = Uri.tryParse(apkUrl.trim());
      if (apkUri == null || !(apkUri.isScheme('https') || apkUri.isScheme('http'))) {
        lastError = 'APK URL is invalid.';
        debugPrint('[UpdateService] $lastError -> $apkUrl');
        return null;
      }

      // Save to app-specific external storage; no broad storage permission needed.
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        lastError = 'Could not access device storage path.';
        debugPrint('[UpdateService] Could not get external storage directory.');
        return null;
      }

      final savePath = '${dir.path}/dailypulse_update.apk';
      final file = File(savePath);

      // Delete any previous partial download
      if (await file.exists()) await file.delete();

      await _dio.download(
        apkUri.toString(),
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress(progress.clamp(0.0, 1.0));
          }
        },
      );

      if (!await file.exists() || await file.length() == 0) {
        lastError = 'Downloaded file is empty.';
        debugPrint('[UpdateService] $lastError');
        return null;
      }

      if (!await _hasZipSignature(file)) {
        lastError =
            'Download is not a valid APK file. Check apk_url (must be direct APK download URL).';
        debugPrint('[UpdateService] $lastError');
        return null;
      }

      debugPrint('[UpdateService] APK saved at: $savePath');
      return file;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        lastError = 'Download cancelled.';
        debugPrint('[UpdateService] Download cancelled.');
      } else {
        lastError = 'Download failed: ${e.message ?? 'network error'}';
        debugPrint('[UpdateService] Download error: ${e.message}');
      }
      return null;
    } catch (e) {
      lastError = 'Unexpected download error: $e';
      debugPrint('[UpdateService] Unexpected download error: $e');
      return null;
    }
  }

  // ── Install the downloaded APK ────────────────────────────────────────────
  /// Prompts the system installer to install the APK at [apkFile].
  Future<bool> installApk(File apkFile) async {
    try {
      lastError = null;

      if (!await apkFile.exists() || await apkFile.length() == 0) {
        lastError = 'APK file not found on device.';
        return false;
      }

      // REQUEST_INSTALL_PACKAGES permission check (Android 8+)
      if (Platform.isAndroid) {
        final canInstall = await Permission.requestInstallPackages.isGranted;
        if (!canInstall) {
          final status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
            lastError =
                'Install permission denied. Enable "Install unknown apps" for this app.';
            debugPrint('[UpdateService] Install packages permission denied.');
            return false;
          }
        }
      }

      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('[UpdateService] OpenFilex result: ${result.message}');
      if (result.type != ResultType.done) {
        lastError =
            'Installer could not be opened (${result.message}). Please allow unknown app installs.';
        return false;
      }

      return true;
    } catch (e) {
      lastError = 'Install error: $e';
      debugPrint('[UpdateService] Install error: $e');
      return false;
    }
  }

  bool _looksLikeDownloadableApkUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/tree/') || lower.endsWith('/releases') || lower.contains('/blob/')) {
      return false;
    }
    return lower.contains('.apk') || lower.contains('/releases/download/');
  }

  Future<bool> _hasZipSignature(File file) async {
    try {
      final raf = await file.open();
      final bytes = await raf.read(2);
      await raf.close();
      return bytes.length == 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    } catch (_) {
      return false;
    }
  }

  // ── Semantic version comparison ────────────────────────────────────────────
  /// Returns true if [remote] is strictly newer than [current].
  /// Handles versions like "1.0.0", "2.10.3" etc.
  bool _isNewer(String remote, String current) {
    try {
      final r = remote.trim().split('.').map(int.parse).toList();
      final c = current.trim().split('.').map(int.parse).toList();

      // Pad shorter list with zeros
      while (r.length < 3) r.add(0);
      while (c.length < 3) c.add(0);

      for (int i = 0; i < 3; i++) {
        if (r[i] > c[i]) return true;
        if (r[i] < c[i]) return false;
      }
      return false; // versions are equal
    } catch (_) {
      return false;
    }
  }
}
