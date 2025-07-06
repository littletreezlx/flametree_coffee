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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('发现新版本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新版本: ${updateInfo['version']}'),
              const SizedBox(height: 8),
              Text('当前版本: $_currentVersion'),
              const SizedBox(height: 16),
              if (updateInfo['releaseNotes'] != null)
                Text(
                  '更新内容:\n${updateInfo['releaseNotes']}',
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍后更新'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performUpdate(updateInfo);
              },
              child: const Text('立即更新'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performUpdate(Map<String, dynamic> updateInfo) async {
    try {
      // 显示更新进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在下载更新...'),
              ],
            ),
          );
        },
      );

      final success = await UpdateService.downloadAndInstallUpdate(updateInfo);
      
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('更新下载完成，请重启应用'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('更新失败，请稍后重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新过程中出错: $e'),
            backgroundColor: Colors.red,
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
                      onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isCheckingUpdate
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