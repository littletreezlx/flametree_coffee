import 'package:flutter/material.dart';
import 'package:flutter_common/flutter_common_core.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/update_checker.dart';

/// 集成flutter_common后的主应用文件
/// 
/// 主要改进：
/// 1. 添加了日志系统初始化
/// 2. 添加了错误边界处理
/// 3. 使用了flutter_common的扩展方法
/// 
/// 使用方式：将此文件重命名为main.dart替换原文件
void main() {
  // 初始化日志系统
  Log.init(
    enableConsoleLog: true,
    minLevel: LogLevel.debug,
  );
  
  Log.i('Flametree Coffee App启动', tag: 'App');
  
  runApp(const FlametreeCoffeeApp());
}

class FlametreeCoffeeApp extends StatefulWidget {
  const FlametreeCoffeeApp({super.key});

  @override
  State<FlametreeCoffeeApp> createState() => _FlametreeCoffeeAppState();
}

class _FlametreeCoffeeAppState extends State<FlametreeCoffeeApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: ErrorBoundary(
        onError: (details) {
          Log.crash('应用崩溃', error: details.exception, stackTrace: details.stack);
        },
        child: MaterialApp(
          title: '火树咖啡厅',
          theme: ThemeData(
            primarySwatch: Colors.orange,
            primaryColor: const Color(0xFFFF8C42),
            scaffoldBackgroundColor: const Color(0xFFFFF8E1),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF8C42),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          home: const UpdateChecker(child: MainScreen()),
          routes: {
            '/settings': (context) => const SettingsScreen(),
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

/// 使用flutter_common改进的购物车ViewModel示例
/// 
/// 可以替换原有的CartProvider，提供更好的状态管理
class CartViewModel extends BaseViewModel {
  final cartItemsState = SimpleState<List<CartItem>>([]);
  final totalPriceState = SimpleState<double>(0.0);
  
  List<CartItem> get cartItems => cartItemsState.value;
  double get totalPrice => totalPriceState.value;
  bool get isEmpty => cartItems.isEmpty;
  int get itemCount => cartItems.length;
  
  /// 添加商品到购物车
  Future<void> addToCart(CoffeeItem coffee, {int quantity = 1}) async {
    await execute(() async {
      Log.i('添加商品到购物车', tag: 'Cart', context: {
        'coffee': coffee.name,
        'quantity': quantity,
      });
      
      final items = List<CartItem>.from(cartItems);
      
      // 查找是否已存在相同商品
      final existingIndex = items.indexWhere((item) => item.coffee.id == coffee.id);
      
      if (existingIndex >= 0) {
        // 更新数量
        items[existingIndex] = items[existingIndex].copyWith(
          quantity: items[existingIndex].quantity + quantity,
        );
      } else {
        // 添加新商品
        items.add(CartItem(
          coffee: coffee,
          quantity: quantity,
        ));
      }
      
      cartItemsState.value = items;
      _calculateTotal();
    }, errorMessage: '添加商品失败');
  }
  
  /// 从购物车移除商品
  Future<void> removeFromCart(String coffeeId) async {
    await execute(() async {
      Log.i('从购物车移除商品', tag: 'Cart', context: {'coffeeId': coffeeId});
      
      final items = cartItems.where((item) => item.coffee.id != coffeeId).toList();
      cartItemsState.value = items;
      _calculateTotal();
    }, errorMessage: '移除商品失败');
  }
  
  /// 更新商品数量
  Future<void> updateQuantity(String coffeeId, int quantity) async {
    await execute(() async {
      if (quantity <= 0) {
        await removeFromCart(coffeeId);
        return;
      }
      
      final items = cartItems.map((item) {
        if (item.coffee.id == coffeeId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      
      cartItemsState.value = items;
      _calculateTotal();
    }, errorMessage: '更新数量失败');
  }
  
  /// 清空购物车
  Future<void> clearCart() async {
    await execute(() async {
      Log.i('清空购物车', tag: 'Cart');
      cartItemsState.value = [];
      totalPriceState.value = 0.0;
    }, errorMessage: '清空购物车失败');
  }
  
  /// 计算总价
  void _calculateTotal() {
    final total = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.coffee.price * item.quantity),
    );
    totalPriceState.value = total;
  }
}

/// 使用flutter_common改进的API服务示例
class CoffeeApiService {
  static final _client = SimpleHttpClient(
    baseUrl: 'https://api.flametree-coffee.com',
    timeout: const Duration(seconds: 30),
  );
  
  /// 获取菜单
  static Future<Result<List<CoffeeItem>>> getMenu() async {
    Log.i('获取菜单', tag: 'API');
    
    final result = await _client.get('/menu');
    
    return result.fold(
      onSuccess: (data) {
        try {
          final List<dynamic> menuData = data['menu'] ?? [];
          final coffees = menuData.map((json) => CoffeeItem.fromJson(json)).toList();
          
          Log.i('菜单获取成功', tag: 'API', context: {'count': coffees.length});
          return Result.success(coffees);
        } catch (e) {
          Log.e('菜单数据解析失败', tag: 'API', error: e);
          return Result.failure(AppError.data('菜单数据格式错误'));
        }
      },
      onFailure: (error) {
        Log.e('菜单获取失败', tag: 'API', error: error);
        return Result.failure(error);
      },
    );
  }
  
  /// 提交订单
  static Future<Result<Order>> submitOrder(List<CartItem> items) async {
    Log.i('提交订单', tag: 'API', context: {'itemCount': items.length});
    
    final orderData = {
      'items': items.map((item) => {
        'coffee_id': item.coffee.id,
        'quantity': item.quantity,
        'price': item.coffee.price,
      }).toList(),
      'total': items.fold<double>(0.0, (sum, item) => sum + (item.coffee.price * item.quantity)),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final result = await _client.post('/orders', data: orderData);
    
    return result.fold(
      onSuccess: (data) {
        try {
          final order = Order.fromJson(data);
          Log.i('订单提交成功', tag: 'API', context: {'orderId': order.id});
          return Result.success(order);
        } catch (e) {
          Log.e('订单数据解析失败', tag: 'API', error: e);
          return Result.failure(AppError.data('订单数据格式错误'));
        }
      },
      onFailure: (error) {
        Log.e('订单提交失败', tag: 'API', error: error);
        return Result.failure(error);
      },
    );
  }
}

/// 使用flutter_common改进的UI组件示例
class CoffeeCard extends StatelessWidget {
  final CoffeeItem coffee;
  final VoidCallback? onTap;
  
  const CoffeeCard({
    super.key,
    required this.coffee,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 咖啡图片
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  coffee.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const AppErrorWidget.icon(
                      Icons.broken_image,
                      '图片加载失败',
                      iconColor: Colors.grey,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 120,
                      child: LoadingWidget.small(),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 咖啡名称
              Text(
                coffee.name,
                style: context.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // 咖啡描述
              Text(
                coffee.description,
                style: context.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 价格和添加按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '¥${coffee.price.toStringAsFixed(2)}',
                    style: context.titleMedium?.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  ElevatedButton.icon(
                    onPressed: () => _addToCart(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('加入'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _addToCart(BuildContext context) {
    // 使用flutter_common的扩展方法显示成功提示
    context.showSuccess('${coffee.name} 已添加到购物车');
    
    // 震动反馈
    DeviceUtil.vibrateSelection();
    
    // 记录用户行为
    LogUtil.userAction('添加到购物车', 
      screen: 'MenuScreen',
      parameters: {'coffee_id': coffee.id, 'coffee_name': coffee.name},
    );
  }
}

/// 改进的菜单页面，使用flutter_common组件
class MenuScreenWithFlutterCommon extends StatefulWidget {
  const MenuScreenWithFlutterCommon({super.key});
  
  @override
  State<MenuScreenWithFlutterCommon> createState() => _MenuScreenWithFlutterCommonState();
}

class _MenuScreenWithFlutterCommonState extends State<MenuScreenWithFlutterCommon> {
  final _menuState = SimpleState<List<CoffeeItem>>([]);
  
  @override
  void initState() {
    super.initState();
    _loadMenu();
  }
  
  Future<void> _loadMenu() async {
    await _menuState.updateAsync(() async {
      final result = await CoffeeApiService.getMenu();
      return result.fold(
        onSuccess: (menu) => menu,
        onFailure: (error) => throw error,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('咖啡菜单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenu,
          ),
        ],
      ),
      body: StateBuilder<List<CoffeeItem>>(
        state: _menuState,
        loadingBuilder: (context) => const LoadingWidget.message('加载菜单中...'),
        errorBuilder: (context, error) => AppErrorWidget.retry(
          error,
          onRetry: _loadMenu,
        ),
        builder: (context, coffees) {
          if (coffees.isEmpty) {
            return EmptyWidget.message('暂无咖啡商品');
          }
          
          return GridView.builder(
            padding: context.responsivePadding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.responsive(
                mobile: 2,
                tablet: 3,
                desktop: 4,
              ),
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: coffees.length,
            itemBuilder: (context, index) {
              final coffee = coffees[index];
              return CoffeeCard(
                coffee: coffee,
                onTap: () => _showCoffeeDetail(coffee),
              );
            },
          );
        },
      ),
    );
  }
  
  void _showCoffeeDetail(CoffeeItem coffee) {
    // 使用flutter_common的扩展方法显示详情
    context.showBottomSheet(
      CoffeeDetailSheet(coffee: coffee),
    );
  }
}

/// 模拟的数据模型类
class CoffeeItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  
  const CoffeeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
  
  factory CoffeeItem.fromJson(Map<String, dynamic> json) {
    return CoffeeItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['image_url'],
    );
  }
}

class CartItem {
  final CoffeeItem coffee;
  final int quantity;
  
  const CartItem({
    required this.coffee,
    required this.quantity,
  });
  
  CartItem copyWith({
    CoffeeItem? coffee,
    int? quantity,
  }) {
    return CartItem(
      coffee: coffee ?? this.coffee,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime timestamp;
  
  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.timestamp,
  });
  
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: [], // 简化实现
      total: json['total'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class CoffeeDetailSheet extends StatelessWidget {
  final CoffeeItem coffee;
  
  const CoffeeDetailSheet({super.key, required this.coffee});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coffee.name,
            style: context.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            coffee.description,
            style: context.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            '价格: ¥${coffee.price.toStringAsFixed(2)}',
            style: context.titleLarge?.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.showSuccess('已添加到购物车');
                  },
                  child: const Text('添加到购物车'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}