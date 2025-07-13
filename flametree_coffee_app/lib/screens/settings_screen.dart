import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentVersion = '';
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
    } catch (e) {
      print('Error loading version: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdate();
      
      if (updateInfo != null && updateInfo['hasUpdate'] == true) {
        if (mounted) {
          _showUpdateDialog(updateInfo);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已是最新版本'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('检查更新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    final isForceUpdate = updateInfo['forceUpdate'] == true;
    final fileSize = updateInfo['fileSize'] as int? ?? 0;
    
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !isForceUpdate,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  isForceUpdate ? Icons.warning : Icons.system_update,
                  color: isForceUpdate ? Colors.red : const Color(0xFFFF8C42),
                ),
                const SizedBox(width: 8),
                Text(isForceUpdate ? '必须更新' : '发现新版本'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('新版本:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${updateInfo['version']}', style: const TextStyle(color: Color(0xFFFF8C42))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('当前版本:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_currentVersion),
                        ],
                      ),
                      if (fileSize > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('文件大小:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(UpdateService.formatFileSize(fileSize)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (updateInfo['releaseNotes'] != null) ...[
                  const Text(
                    '更新内容:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      updateInfo['releaseNotes'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                if (isForceUpdate) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '此更新为强制更新，必须完成后才能继续使用应用',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isForceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('稍后更新'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performUpdate(updateInfo);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isForceUpdate ? Colors.red : const Color(0xFFFF8C42),
                ),
                child: Text(isForceUpdate ? '立即更新' : '开始更新'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performUpdate(Map<String, dynamic> updateInfo) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = '准备下载...';
    });

    try {
      // 显示下载进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.download, color: Color(0xFFFF8C42)),
                    SizedBox(width: 8),
                    Text('正在更新'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8C42),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _downloadStatus,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      final success = await UpdateService.downloadAndInstallUpdate(
        updateInfo,
        onProgress: (downloaded, total) {
          final progress = total > 0 ? downloaded / total : 0.0;
          final downloadedMB = (downloaded / (1024 * 1024)).toStringAsFixed(1);
          final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
          
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = total > 0 
                ? '已下载 ${downloadedMB}MB / ${totalMB}MB'
                : '正在下载...';
          });
        },
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('更新已下载，正在安装...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('更新失败，请检查网络连接或稍后重试'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新过程中出错: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFFFF8C42),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用信息区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '应用信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD84315),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '应用名称',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Text(
                        'Flametree Coffee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '当前版本',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        _currentVersion.isNotEmpty ? _currentVersion : '加载中...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 更新区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '应用更新',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD84315),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isCheckingUpdate || _isDownloading) ? null : _checkForUpdates,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isDownloading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: _downloadProgress,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('下载中 ${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                              ],
                            )
                          : _isCheckingUpdate
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('检查中...'),
                                  ],
                                )
                              : const Text(
                                  '检查更新',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击检查是否有新版本可用',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 缓存管理区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '缓存管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD84315),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.cached, color: Color(0xFFFF8C42)),
                    title: const Text('清除菜单缓存'),
                    subtitle: const Text('清除本地菜单缓存，下次将重新获取'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: 实现清除缓存功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('缓存已清除'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 关于区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '关于',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD84315),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info, color: Color(0xFFFF8C42)),
                    title: const Text('用户协议'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: 显示用户协议
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: Color(0xFFFF8C42)),
                    title: const Text('隐私政策'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: 显示隐私政策
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_support, color: Color(0xFFFF8C42)),
                    title: const Text('联系我们'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: 显示联系方式
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}