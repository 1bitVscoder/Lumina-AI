import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String downloadUrl;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  final Dio _dio = Dio();

  // Fetches latest release from GitHub and compares it with the local app version
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final owner = dotenv.env['GITHUB_REPO_OWNER'] ?? 'soumya';
      final repo = dotenv.env['GITHUB_REPO_NAME'] ?? 'Lumina';
      
      final url = 'https://api.github.com/repos/$owner/$repo/releases/latest';
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            // Simple GitHub API limits might apply, but standard checks work fine without auth
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['tag_name'] as String;
        final releaseNotes = data['body'] as String? ?? 'No release notes provided.';
        
        // Find APK asset download URL
        final assets = data['assets'] as List<dynamic>? ?? [];
        String downloadUrl = '';
        for (var asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? '';
            break;
          }
        }

        // If no APK asset is found in release, fall back to the release HTML URL
        if (downloadUrl.isEmpty) {
          downloadUrl = data['html_url'] as String? ?? '';
        }

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          return UpdateInfo(
            latestVersion: latestVersion,
            currentVersion: currentVersion,
            releaseNotes: releaseNotes,
            downloadUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
    return null;
  }

  // Downloads APK directly to local temp directory, tracking download progress
  Future<String> downloadApk(String url, Function(double progress) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/lumina_update.apk';
      
      // Delete old file if it exists to avoid caching issues
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress.clamp(0.0, 1.0));
          }
        },
      );
      
      return filePath;
    } catch (e) {
      debugPrint("Download APK exception: $e");
      rethrow;
    }
  }

  // Opens/Installs APK using the native system installer
  Future<void> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      debugPrint("Install APK exception: $e");
      rethrow;
    }
  }

  // Semantic version check helper
  bool _isNewerVersion(String current, String latest) {
    // Strip "v" prefix if present and trim spaces
    final cleanCurrent = current.replaceAll(RegExp(r'^v'), '').trim();
    final cleanLatest = latest.replaceAll(RegExp(r'^v'), '').trim();

    final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = max(currentParts.length, latestParts.length);
    for (int i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (currentPart > latestPart) return false;
    }
    return false;
  }
}
