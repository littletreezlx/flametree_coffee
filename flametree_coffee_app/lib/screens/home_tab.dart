import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cart_provider.dart';
import '../models/family_member.dart';
import 'member_selection_screen.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onMemberSelected;
  
  const HomeTab({super.key, required this.onMemberSelected});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  FamilyMember? selectedMember;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStoredMember();
  }

  Future<void> _checkStoredMember() async {
    final prefs = await SharedPreferences.getInstance();
    final memberId = prefs.getString('selected_member_id');
    final memberName = prefs.getString('selected_member_name');
    
    if (memberId != null && memberName != null) {
      setState(() {
        selectedMember = FamilyMember(
          id: memberId,
          name: memberName,
          avatar: '',
        );
        isLoading = false;
      });
      
      // 自动设置到CartProvider并显示菜单
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).selectMember(selectedMember!);
        widget.onMemberSelected();
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToMemberSelection(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MemberSelectionScreen(),
      ),
    );
    
    if (result != null && result is FamilyMember) {
      // 保存选择的成员到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_member_id', result.id);
      await prefs.setString('selected_member_name', result.name);
      
      setState(() {
        selectedMember = result;
      });
      
      // 设置到CartProvider并显示菜单
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).selectMember(result);
        widget.onMemberSelected();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('火树咖啡厅'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
            tooltip: '设置',
          ),
        ],
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
                child: Text('⭐', style: TextStyle(fontSize: 20)),
              ),
              Positioned(
                top: 80,
                right: 40,
                child: Text('☕', style: TextStyle(fontSize: 24)),
              ),
              Positioned(
                top: 150,
                left: 60,
                child: Text('🧸', style: TextStyle(fontSize: 18)),
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
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🔥🌳',
                            style: TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '火树咖啡厅',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD84315),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '家庭点餐系统',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      '欢迎来到火树咖啡厅',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD84315),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToMemberSelection(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C42),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.family_restroom, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              '我是老板的？',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      '点击上方按钮选择家庭成员开始点餐',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}