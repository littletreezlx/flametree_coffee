import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String baseUrl = 'https://coffee.flametree.synology.me:60443/api';

  /// 检查是否有新版本可用
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final response = await http.get(
        Uri.parse('$baseUrl/update/check'),
        headers: {
          'Content-Type': 'application/json',
          'Current-Version': currentVersion,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to check for updates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking for updates: $e');
      throw Exception('检查更新失败: $e');
    }
  }

  /// 下载并安装更新
  static Future<bool> downloadAndInstallUpdate(
    Map<String, dynamic> updateInfo, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final downloadUrl = updateInfo['downloadUrl'] as String?;
      if (downloadUrl == null) {
        throw Exception('Download URL not found');
      }

      // 检查并请求权限
      if (Platform.isAndroid) {
        final hasPermission = await _requestPermissions();
        if (!hasPermission) {
          throw Exception('权限被拒绝，无法下载更新');
        }
      }

      // 下载更新文件
      final filePath = await _downloadFile(downloadUrl, onProgress);
      
      // 安装更新
      if (Platform.isAndroid) {
        return await _installApkOnAndroid(filePath);
      } else if (Platform.isIOS) {
        // iOS应用更新通常通过App Store
        await _openAppStore(updateInfo);
        return true;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading and installing update: $e');
      }
      return false;
    }
  }

  /// 下载文件并支持进度回调
  static Future<String> _downloadFile(
    String url,
    Function(int, int)? onProgress,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();
    
    if (response.statusCode != 200) {
      throw Exception('下载失败: ${response.statusCode}');
    }

    // 获取文件保存路径
    final directory = await getApplicationDocumentsDirectory();
    final fileName = url.split('/').last;
    final filePath = '${directory.path}/$fileName';
    
    // 创建文件
    final file = File(filePath);
    final sink = file.openWrite();
    
    int downloadedBytes = 0;
    final totalBytes = response.contentLength ?? 0;
    
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        onProgress?.call(downloadedBytes, totalBytes);
      }
    } finally {
      await sink.close();
    }
    
    return filePath;
  }

  /// 请求必要权限
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // 请求存储权限
      final storageStatus = await Permission.storage.request();
      
      // 请求安装权限
      final installStatus = await Permission.requestInstallPackages.request();
      
      return storageStatus.isGranted && installStatus.isGranted;
    }
    return true;
  }

  /// 在Android上安装APK
  static Future<bool> _installApkOnAndroid(String filePath) async {
    try {
      if (kDebugMode) {
        print('Installing APK at: $filePath');
      }
      
      // 使用open_file插件打开APK文件进行安装
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      
      return result.type == ResultType.done;
    } catch (e) {
      if (kDebugMode) {
        print('Error installing APK: $e');
      }
      return false;
    }
  }

  /// 打开App Store（iOS）
  static Future<void> _openAppStore(Map<String, dynamic> updateInfo) async {
    try {
      final appStoreUrl = updateInfo['appStoreUrl'] as String?;
      if (appStoreUrl != null) {
        final uri = Uri.parse(appStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening App Store: $e');
      }
    }
  }

  /// 比较版本号
  static bool isNewVersionAvailable(String currentVersion, String newVersion) {
    final current = _parseVersion(currentVersion);
    final newer = _parseVersion(newVersion);
    
    for (int i = 0; i < 3; i++) {
      if (newer[i] > current[i]) {
        return true;
      } else if (newer[i] < current[i]) {
        return false;
      }
    }
    return false;
  }

  /// 解析版本号字符串
  static List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }

  /// 获取更新历史
  static Future<List<Map<String, dynamic>>> getUpdateHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/update/history'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get update history');
      }
    } catch (e) {
      print('Error getting update history: $e');
      return [];
    }
  }

  /// 检查应用启动时是否需要更新
  static Future<Map<String, dynamic>?> checkForUpdateOnStartup() async {
    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo != null && updateInfo['hasUpdate'] == true) {
        if (kDebugMode) {
          print('New version available: ${updateInfo['version']}');
        }
        return updateInfo;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for updates on startup: $e');
      }
      // 静默失败，不影响应用启动
      return null;
    }
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}