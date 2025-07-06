import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/family_member.dart';
import '../services/api_service.dart';
import 'menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载家庭成员失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            style: TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '火树咖啡厅',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD84315),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '家庭点餐系统',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      '请选择家庭成员',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD84315),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: familyMembers.length,
                              itemBuilder: (context, index) {
                                final member = familyMembers[index];
                                return GestureDetector(
                                  onTap: () {
                                    Provider.of<CartProvider>(context, listen: false)
                                        .selectMember(member);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const MenuScreen(),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 6,
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
                                          Text(
                                            member.avatar,
                                            style: const TextStyle(fontSize: 48),
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
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
}