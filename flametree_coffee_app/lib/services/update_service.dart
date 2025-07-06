import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String baseUrl = 'http://192.168.0.123:3001/api';

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
  static Future<bool> downloadAndInstallUpdate(Map<String, dynamic> updateInfo) async {
    try {
      final downloadUrl = updateInfo['downloadUrl'] as String?;
      if (downloadUrl == null) {
        throw Exception('Download URL not found');
      }

      // 下载更新文件
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download update');
      }

      // 获取应用目录
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/update.apk';
      
      // 保存文件
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // 在Android上，通常需要使用Intent来安装APK
      // 这里简化处理，实际应用中可能需要使用插件如 install_plugin
      if (Platform.isAndroid) {
        return await _installApkOnAndroid(filePath);
      } else if (Platform.isIOS) {
        // iOS应用更新通常通过App Store
        return false;
      }

      return true;
    } catch (e) {
      print('Error downloading and installing update: $e');
      return false;
    }
  }

  /// 在Android上安装APK
  static Future<bool> _installApkOnAndroid(String filePath) async {
    try {
      // 这里需要使用平台特定的代码来安装APK
      // 可以使用 method_channel 或者现有的插件
      // 为了简化，这里只是返回true
      print('Installing APK at: $filePath');
      return true;
    } catch (e) {
      print('Error installing APK: $e');
      return false;
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
  static Future<void> checkForUpdateOnStartup() async {
    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo != null && updateInfo['hasUpdate'] == true) {
        print('New version available: ${updateInfo['version']}');
        // 可以在这里显示更新提示
      }
    } catch (e) {
      print('Error checking for updates on startup: $e');
      // 静默失败，不影响应用启动
    }
  }
}