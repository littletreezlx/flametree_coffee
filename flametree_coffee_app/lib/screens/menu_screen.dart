import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/coffee_item.dart';
import '../services/api_service.dart';
import '../widgets/coffee_card.dart';
import '../widgets/fullscreen_image_viewer.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<CoffeeItem> allCoffeeItems = [];
  List<CoffeeItem> filteredCoffeeItems = [];
  List<String> categories = [];
  String selectedCategory = '全部';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMenuData();
  }

  Future<void> loadMenuData() async {
    try {
      final [coffeeItems, categoryList] = await Future.wait([
        ApiService.getMenu(),
        ApiService.getCategories(),
      ]);
      
      setState(() {
        allCoffeeItems = coffeeItems as List<CoffeeItem>;
        categories = ['全部', ...categoryList as List<String>];
        filteredCoffeeItems = allCoffeeItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载菜单失败: $e')),
      );
    }
  }

  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == '全部') {
        filteredCoffeeItems = allCoffeeItems;
      } else {
        filteredCoffeeItems = allCoffeeItems
            .where((item) => item.category == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('${cartProvider.selectedMember?.avatar} '),
            Text('${cartProvider.selectedMember?.name}的咖啡时光'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 手绘菜单图片
                Container(
                  margin: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FullscreenImageViewer(
                            imagePath: 'assets/images/menu.jpg',
                            heroTag: 'menu_image',
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'menu_image',
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/menu.jpg',
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 16,
                                left: 16,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '点击查看完整菜单',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;
                      
                      return GestureDetector(
                        onTap: () => filterByCategory(category),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF8C42)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF8C42),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFFF8C42),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredCoffeeItems.length,
                    itemBuilder: (context, index) {
                      return CoffeeCard(coffeeItem: filteredCoffeeItems[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}