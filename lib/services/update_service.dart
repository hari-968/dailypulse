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

  // ── Check if an update is available ───────────────────────────────────────
  /// Returns a tuple of [UpdateCheckResult, AppUpdateInfo?].
  /// AppUpdateInfo is non-null only when result == updateAvailable.
  Future<(UpdateCheckResult, AppUpdateInfo?)> checkForUpdate() async {
    try {
      // 1. Fetch the remote version JSON
      final response = await _dio.get<Map<String, dynamic>>(_versionJsonUrl);
      if (response.statusCode != 200 || response.data == null) {
        return (UpdateCheckResult.error, null);
      }

      final info = AppUpdateInfo.fromJson(response.data!);

      // 2. Get the currently installed version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      debugPrint('[UpdateService] Current: $currentVersion | Remote: ${info.version}');

      // 3. Compare semantic versions
      if (_isNewer(info.version, currentVersion)) {
        return (UpdateCheckResult.updateAvailable, info);
      }

      return (UpdateCheckResult.upToDate, null);
    } on DioException catch (e) {
      debugPrint('[UpdateService] Network error: ${e.message}');
      return (UpdateCheckResult.error, null);
    } catch (e) {
      debugPrint('[UpdateService] Unexpected error: $e');
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
      // Request storage permission on Android < 10
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isDenied) {
          debugPrint('[UpdateService] Storage permission denied.');
          return null;
        }
      }

      // Save to external app files directory — no extra permission on Android 10+
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        debugPrint('[UpdateService] Could not get external storage directory.');
        return null;
      }

      final savePath = '${dir.path}/dailypulse_update.apk';
      final file = File(savePath);

      // Delete any previous partial download
      if (await file.exists()) await file.delete();

      await _dio.download(
        apkUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress(progress.clamp(0.0, 1.0));
          }
        },
      );

      debugPrint('[UpdateService] APK saved at: $savePath');
      return file;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[UpdateService] Download cancelled.');
      } else {
        debugPrint('[UpdateService] Download error: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('[UpdateService] Unexpected download error: $e');
      return null;
    }
  }

  // ── Install the downloaded APK ────────────────────────────────────────────
  /// Prompts the system installer to install the APK at [apkFile].
  Future<bool> installApk(File apkFile) async {
    try {
      // REQUEST_INSTALL_PACKAGES permission check (Android 8+)
      if (Platform.isAndroid) {
        final canInstall = await Permission.requestInstallPackages.isGranted;
        if (!canInstall) {
          final status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
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
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('[UpdateService] Install error: $e');
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
