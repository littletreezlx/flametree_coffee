import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../services/api_service.dart';

class MemberSelectionScreen extends StatefulWidget {
  const MemberSelectionScreen({super.key});

  @override
  State<MemberSelectionScreen> createState() => _MemberSelectionScreenState();
}

class _MemberSelectionScreenState extends State<MemberSelectionScreen> {
  List<FamilyMember> familyMembers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFamilyMembers();
  }

  Future<void> loadFamilyMembers() async {
    try {
      final members = await ApiService.getFamilyMembers();
      setState(() {
        familyMembers = members;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载家庭成员失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择家庭成员'),
        backgroundColor: const Color(0xFFFF8C42),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFE0B2),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 装饰元素
              Positioned(
                top: 50,
                left: 30,
                child: Text('❤️', style: TextStyle(fontSize: 20)),
              ),
              Positioned(
                top: 80,
                right: 40,
                child: Text('☕', style: TextStyle(fontSize: 24)),
              ),
              Positioned(
                bottom: 200,
                right: 30,
                child: Text('✨', style: TextStyle(fontSize: 22)),
              ),
              Positioned(
                bottom: 150,
                left: 20,
                child: Text('🍃', style: TextStyle(fontSize: 20)),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.family_restroom,
                            size: 40,
                            color: Color(0xFFFF8C42),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '请选择您的身份',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD84315),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '每个家庭成员都有 10000 ❤️ 爱心值',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: familyMembers.length,
                              itemBuilder: (context, index) {
                                final member = familyMembers[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop(member);
                                  },
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFFFE0B2),
                                            Color(0xFFFFCC80),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Color(0xFFFF8C42),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            member.name,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD84315),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  '❤️',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  '10000',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFD84315),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 跳转到管理页面
                          _openManagementPage();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('管理家庭成员'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openManagementPage() {
    // TODO: 打开网页管理界面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('管理功能正在开发中...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}