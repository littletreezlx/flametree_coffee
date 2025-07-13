import 'dart:io';
import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;
  
  const UpdateChecker({
    super.key,
    required this.child,
  });

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdateOnStartup();
    });
  }

  Future<void> _checkForUpdateOnStartup() async {
    if (_hasCheckedForUpdate) return;
    
    _hasCheckedForUpdate = true;
    
    try {
      // 延迟3秒后检查更新，确保应用完全启动
      await Future.delayed(const Duration(seconds: 3));
      
      final updateInfo = await UpdateService.checkForUpdateOnStartup();
      
      if (updateInfo != null && mounted) {
        _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      // 静默失败，不影响应用使用
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
                  isForceUpdate ? Icons.warning : Icons.system_update_alt,
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
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        updateInfo['releaseNotes'],
                        style: const TextStyle(fontSize: 14),
                      ),
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
                  if (Platform.isIOS) {
                    // iOS跳转到设置页面
                    Navigator.of(context).pushNamed('/settings');
                  } else {
                    // Android跳转到设置页面
                    Navigator.of(context).pushNamed('/settings');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isForceUpdate ? Colors.red : const Color(0xFFFF8C42),
                ),
                child: Text(isForceUpdate ? '立即更新' : '前往更新'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}