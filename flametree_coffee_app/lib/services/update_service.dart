import 'dart:convert';
import 'dart:io';
import 'package:flutter_common/flutter_common_core.dart';
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
    final startTime = DateTime.now();
    Log.i('开始检查应用更新', tag: 'UpdateService');
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      Log.d('当前应用版本', tag: 'UpdateService', context: {
        'currentVersion': currentVersion,
        'buildNumber': packageInfo.buildNumber,
      });
      
      final response = await http.get(
        Uri.parse('$baseUrl/update/check'),
        headers: {
          'Content-Type': 'application/json',
          'Current-Version': currentVersion,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        
        Log.i('更新检查完成', tag: 'UpdateService', context: {
          'hasUpdate': data['hasUpdate'] ?? false,
          'latestVersion': data['version'],
          'currentVersion': currentVersion,
          'duration': duration,
        });
        
        return data;
      } else {
        Log.w('更新检查失败', tag: 'UpdateService', context: {
          'statusCode': response.statusCode,
        });
        throw Exception('Failed to check for updates: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('检查更新发生异常', tag: 'UpdateService', error: e, stackTrace: stackTrace);
      throw Exception('检查更新失败: $e');
    }
  }

  /// 下载并安装更新
  static Future<bool> downloadAndInstallUpdate(
    Map<String, dynamic> updateInfo, {
    Function(int, int)? onProgress,
  }) async {
    final startTime = DateTime.now();
    Log.i('开始下载更新', tag: 'UpdateService', context: {
      'version': updateInfo['version'],
      'size': updateInfo['size'],
    });
    
    try {
      final downloadUrl = updateInfo['downloadUrl'] as String?;
      if (downloadUrl == null) {
        Log.e('下载链接不存在', tag: 'UpdateService');
        throw Exception('Download URL not found');
      }

      // 检查并请求权限
      if (Platform.isAndroid) {
        Log.i('请求Android安装权限', tag: 'UpdateService');
        final hasPermission = await _requestPermissions();
        if (!hasPermission) {
          Log.e('权限被拒绝', tag: 'UpdateService');
          throw Exception('权限被拒绝，无法下载更新');
        }
        Log.i('权限获取成功', tag: 'UpdateService');
      }

      // 下载更新文件
      Log.i('开始下载更新文件', tag: 'UpdateService', context: {
        'url': downloadUrl,
      });
      
      final filePath = await _downloadFile(downloadUrl, onProgress);
      
      Log.i('下载完成', tag: 'UpdateService', context: {
        'filePath': filePath,
        'duration': DateTime.now().difference(startTime).inMilliseconds,
      });
      
      // 安装更新
      if (Platform.isAndroid) {
        Log.i('开始安装APK', tag: 'UpdateService');
        final success = await _installApkOnAndroid(filePath);
        
        if (success) {
          Log.i('APK安装成功', tag: 'UpdateService');
        } else {
          Log.e('APK安装失败', tag: 'UpdateService');
        }
        
        return success;
      } else if (Platform.isIOS) {
        // iOS应用更新通常通过App Store
        Log.i('打开App Store进行更新', tag: 'UpdateService');
        await _openAppStore(updateInfo);
        return true;
      }

      return true;
    } catch (e, stackTrace) {
      Log.e('下载安装更新失败', tag: 'UpdateService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 下载文件并支持进度回调
  static Future<String> _downloadFile(
    String url,
    Function(int, int)? onProgress,
  ) async {
    final startTime = DateTime.now();
    Log.d('创建下载请求', tag: 'UpdateService', context: {
      'url': url,
    });
    
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();
    
    if (response.statusCode != 200) {
      Log.e('下载响应异常', tag: 'UpdateService', context: {
        'statusCode': response.statusCode,
      });
      throw Exception('下载失败: ${response.statusCode}');
    }

    // 获取文件保存路径
    final directory = await getApplicationDocumentsDirectory();
    final fileName = url.split('/').last;
    final filePath = '${directory.path}/$fileName';
    
    Log.d('准备保存文件', tag: 'UpdateService', context: {
      'fileName': fileName,
      'filePath': filePath,
    });
    
    // 创建文件
    final file = File(filePath);
    final sink = file.openWrite();
    
    int downloadedBytes = 0;
    final totalBytes = response.contentLength ?? 0;
    int lastLoggedProgress = 0;
    
    Log.i('开始下载文件', tag: 'UpdateService', context: {
      'totalBytes': totalBytes,
      'totalSize': formatFileSize(totalBytes),
    });
    
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        onProgress?.call(downloadedBytes, totalBytes);
        
        // 每10%记录一次进度
        final currentProgress = totalBytes > 0 ? (downloadedBytes * 100 ~/ totalBytes) : 0;
        if (currentProgress - lastLoggedProgress >= 10) {
          Log.d('下载进度', tag: 'UpdateService', context: {
            'progress': currentProgress,
            'downloaded': formatFileSize(downloadedBytes),
            'total': formatFileSize(totalBytes),
          });
          lastLoggedProgress = currentProgress;
        }
      }
    } finally {
      await sink.close();
    }
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    Log.i('文件下载完成', tag: 'UpdateService', context: {
      'filePath': filePath,
      'fileSize': formatFileSize(downloadedBytes),
      'duration': duration,
      'speed': '${formatFileSize((downloadedBytes * 1000 / duration).round())}/s',
    });
    
    return filePath;
  }

  /// 请求必要权限
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      Log.i('请求Android权限', tag: 'UpdateService');
      
      // 请求存储权限
      final storageStatus = await Permission.storage.request();
      Log.d('存储权限状态', tag: 'UpdateService', context: {
        'status': storageStatus.toString(),
      });
      
      // 请求安装权限
      final installStatus = await Permission.requestInstallPackages.request();
      Log.d('安装权限状态', tag: 'UpdateService', context: {
        'status': installStatus.toString(),
      });
      
      final hasPermission = storageStatus.isGranted && installStatus.isGranted;
      
      if (hasPermission) {
        Log.i('所有权限获取成功', tag: 'UpdateService');
      } else {
        Log.w('权限获取失败', tag: 'UpdateService', context: {
          'storage': storageStatus.isGranted,
          'install': installStatus.isGranted,
        });
      }
      
      return hasPermission;
    }
    return true;
  }

  /// 在Android上安装APK
  static Future<bool> _installApkOnAndroid(String filePath) async {
    Log.i('准备安装APK', tag: 'UpdateService', context: {
      'filePath': filePath,
    });
    
    try {
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        Log.e('APK文件不存在', tag: 'UpdateService', context: {
          'filePath': filePath,
        });
        return false;
      }
      
      final fileSize = await file.length();
      Log.d('APK文件信息', tag: 'UpdateService', context: {
        'fileSize': formatFileSize(fileSize),
        'exists': true,
      });
      
      // 使用open_file插件打开APK文件进行安装
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      
      final success = result.type == ResultType.done;
      
      if (success) {
        Log.i('APK安装请求发送成功', tag: 'UpdateService');
      } else {
        Log.w('APK安装请求失败', tag: 'UpdateService', context: {
          'resultType': result.type.toString(),
          'message': result.message,
        });
      }
      
      return success;
    } catch (e, stackTrace) {
      Log.e('APK安装发生异常', tag: 'UpdateService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 打开App Store（iOS）
  static Future<void> _openAppStore(Map<String, dynamic> updateInfo) async {
    Log.i('准备打开App Store', tag: 'UpdateService');
    
    try {
      final appStoreUrl = updateInfo['appStoreUrl'] as String?;
      if (appStoreUrl == null) {
        Log.w('App Store链接不存在', tag: 'UpdateService');
        return;
      }
      
      Log.d('打开App Store', tag: 'UpdateService', context: {
        'url': appStoreUrl,
      });
      
      final uri = Uri.parse(appStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Log.i('App Store打开成功', tag: 'UpdateService');
      } else {
        Log.e('无法打开App Store', tag: 'UpdateService', context: {
          'url': appStoreUrl,
        });
      }
    } catch (e, stackTrace) {
      Log.e('打开App Store失败', tag: 'UpdateService', error: e, stackTrace: stackTrace);
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
    Log.i('获取更新历史', tag: 'UpdateService');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/update/history'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final history = data.cast<Map<String, dynamic>>();
        
        Log.i('获取更新历史成功', tag: 'UpdateService', context: {
          'versionCount': history.length,
        });
        
        return history;
      } else {
        Log.w('获取更新历史失败', tag: 'UpdateService', context: {
          'statusCode': response.statusCode,
        });
        throw Exception('Failed to get update history');
      }
    } catch (e, stackTrace) {
      Log.e('获取更新历史发生异常', tag: 'UpdateService', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// 检查应用启动时是否需要更新
  static Future<Map<String, dynamic>?> checkForUpdateOnStartup() async {
    Log.i('启动时检查更新', tag: 'UpdateService');
    
    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo != null && updateInfo['hasUpdate'] == true) {
        Log.i('发现新版本', tag: 'UpdateService', context: {
          'newVersion': updateInfo['version'],
          'releaseNotes': updateInfo['releaseNotes'],
        });
        return updateInfo;
      }
      
      Log.i('已是最新版本', tag: 'UpdateService');
      return null;
    } catch (e) {
      // 静默失败，不影响应用启动
      Log.w('启动时检查更新失败，已忽略', tag: 'UpdateService', context: {
        'error': e.toString(),
      });
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