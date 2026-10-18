import 'dart:developer' as dev;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String updateTitle;
  final String updateMessage;
  final String updateUrl;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateTitle,
    required this.updateMessage,
    required this.updateUrl,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check Firebase Remote Config for version updates
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Skip if on web or unsupported platforms
    if (kIsWeb) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      final remoteConfig = FirebaseRemoteConfig.instance;

      // Remote config settings: quick fetch interval in dev, standard in prod
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Default values
      await remoteConfig.setDefaults(const {
        'latest_version': '1.0.0',
        'min_required_version': '1.0.0',
        'is_force_update': false,
        'update_title': 'New Update Available!',
        'update_message':
            'A new version of Cheesy Pizza is available. Please update to enjoy the latest features and improvements.',
        'update_url':
            'https://github.com/aman-khan/cheesy-pizza/releases/latest',
      });

      await remoteConfig.fetchAndActivate();

      final latestVersion = remoteConfig.getString('latest_version').trim();
      final minRequiredVersion =
          remoteConfig.getString('min_required_version').trim();
      final isForceUpdateFlag = remoteConfig.getBool('is_force_update');
      final updateTitle = remoteConfig.getString('update_title');
      final updateMessage = remoteConfig.getString('update_message');
      final updateUrl = remoteConfig.getString('update_url');

      final hasUpdate = _isVersionGreater(latestVersion, currentVersion);
      final isForce = isForceUpdateFlag ||
          _isVersionGreater(minRequiredVersion, currentVersion);

      dev.log(
        'App Version: $currentVersion, Latest: $latestVersion, Min: $minRequiredVersion, HasUpdate: $hasUpdate, Force: $isForce',
        name: 'UpdateService',
      );

      if (!hasUpdate && !isForce) return null;

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        isForceUpdate: isForce,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        updateTitle: updateTitle.isNotEmpty ? updateTitle : 'Update Available',
        updateMessage: updateMessage.isNotEmpty
            ? updateMessage
            : 'A new version is available.',
        updateUrl: updateUrl,
      );
    } catch (e) {
      dev.log('Error checking for updates: $e', name: 'UpdateService');
      return null;
    }
  }

  /// Compares semantic versions (e.g. 1.0.1 > 1.0.0)
  bool _isVersionGreater(String v1, String v2) {
    if (v1.isEmpty || v2.isEmpty) return false;
    try {
      final v1Clean = v1.split('+').first;
      final v2Clean = v2.split('+').first;

      final v1Parts = v1Clean.split('.').map(int.parse).toList();
      final v2Parts = v2Clean.split('.').map(int.parse).toList();

      final length = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

      for (int i = 0; i < length; i++) {
        final num1 = i < v1Parts.length ? v1Parts[i] : 0;
        final num2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (num1 > num2) return true;
        if (num1 < num2) return false;
      }
      return false;
    } catch (e) {
      dev.log('Version parse error: $e', name: 'UpdateService');
      return false;
    }
  }

  /// Show the in-app update dialog
  Future<void> showUpdateDialog(BuildContext context, AppUpdateInfo info) async {
    return showDialog(
      context: context,
      barrierDismissible: !info.isForceUpdate,
      builder: (ctx) {
        return PopScope(
          canPop: !info.isForceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded,
                      color: AppColors.primaryRed, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    info.updateTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.updateMessage,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current: v${info.currentVersion}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      Text(
                        'Latest: v${info.latestVersion}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (!info.isForceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Later', style: TextStyle(color: AppColors.mediumGrey)),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final uri = Uri.parse(info.updateUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  if (!info.isForceUpdate && ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
