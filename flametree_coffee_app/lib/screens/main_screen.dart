import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'home_tab.dart';
import 'cart_tab.dart';
import 'orders_tab.dart';
import 'menu_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showMenu = false;

  void _onMemberSelected() {
    setState(() {
      _showMenu = true;
    });
  }

  void _onBackToHome() {
    setState(() {
      _showMenu = false;
    });
  }

  List<Widget> get _tabs => [
    _showMenu ? MenuTab(onBackToHome: _onBackToHome) : HomeTab(onMemberSelected: _onMemberSelected),
    const CartTab(),
    const OrdersTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              // 如果当前在菜单状态且点击了首页Tab，回到首页
              if (_showMenu && index == 0) {
                _onBackToHome();
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFFF8C42),
            unselectedItemColor: Colors.grey[600],
            elevation: 8,
            items: [
              BottomNavigationBarItem(
                icon: Icon(_showMenu ? Icons.home : Icons.home),
                label: _showMenu ? '首页' : '首页',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartProvider.totalItems > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cartProvider.totalItems}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: '购物车',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: '订单',
              ),
            ],
          );
        },
      ),
    );
  }
}