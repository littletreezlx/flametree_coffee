import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/coffee_item.dart';
import '../services/api_service.dart';
import '../widgets/coffee_card.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../services/menu_cache_service.dart';

class MenuTab extends StatefulWidget {
  final VoidCallback onBackToHome;
  
  const MenuTab({super.key, required this.onBackToHome});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  List<CoffeeItem> allCoffeeItems = [];
  List<CoffeeItem> filteredCoffeeItems = [];
  List<String> categories = [];
  String selectedCategory = '全部';
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    loadMenuData();
  }

  Future<void> loadMenuData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        isRefreshing = true;
      });
    }

    try {
      final [coffeeItems, categoryList] = await Future.wait([
        ApiService.getMenu(forceRefresh: forceRefresh),
        ApiService.getCategories(forceRefresh: forceRefresh),
      ]);
      
      setState(() {
        allCoffeeItems = coffeeItems as List<CoffeeItem>;
        categories = ['全部', ...categoryList as List<String>];
        filteredCoffeeItems = allCoffeeItems;
        isLoading = false;
        isRefreshing = false;
      });
      
      if (forceRefresh && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('菜单数据已刷新'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载菜单失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Text('${cartProvider.selectedMember?.name}的咖啡时光'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: isRefreshing ? null : () => loadMenuData(forceRefresh: true),
            tooltip: '刷新菜单',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: widget.onBackToHome,
            tooltip: '返回首页',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
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
                                      height: double.infinity,
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
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CategoryHeaderDelegate(
                      categories: categories,
                      selectedCategory: selectedCategory,
                      onCategorySelected: filterByCategory,
                    ),
                  ),
                ];
              },
              body: GridView.builder(
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
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          
          return GestureDetector(
            onTap: () => onCategorySelected(category),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
    );
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}