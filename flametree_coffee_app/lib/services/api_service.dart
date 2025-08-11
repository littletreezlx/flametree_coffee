import 'dart:convert';
import 'package:flutter_common/flutter_common_core.dart';
import 'package:http/http.dart' as http;
import '../models/coffee_item.dart';
import '../models/family_member.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'menu_cache_service.dart';

class ApiService {
  static const String baseUrl = 'https://coffee.flametree.synology.me:60443/api';

  static Future<Result<List<CoffeeItem>>> getMenu({bool forceRefresh = false}) async {
    final startTime = DateTime.now();
    Log.i('开始获取菜单', tag: 'ApiService', context: {
      'forceRefresh': forceRefresh,
      'url': '$baseUrl/menu',
    });
    
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh) {
      final cachedMenu = await MenuCacheService.getMenuFromCache();
      if (cachedMenu != null) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        Log.i('使用缓存菜单数据', tag: 'ApiService', context: {
          'itemCount': cachedMenu.length,
          'duration': duration,
          'source': 'cache',
        });
        return Result.success(cachedMenu);
      }
      Log.d('缓存未命中，需要从服务器获取', tag: 'ApiService');
    }

    try {
      Log.i('正在从服务器获取菜单', tag: 'ApiService', context: {
        'endpoint': '$baseUrl/menu',
      });
      
      final requestStart = DateTime.now();
      final response = await http.get(Uri.parse('$baseUrl/menu'));
      final requestDuration = DateTime.now().difference(requestStart).inMilliseconds;
      
      Log.d('服务器响应', tag: 'ApiService', context: {
        'statusCode': response.statusCode,
        'requestDuration': requestDuration,
        'responseSize': response.body.length,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final menu = data.map((item) => CoffeeItem.fromJson(item)).toList();
        
        Log.i('菜单解析成功', tag: 'ApiService', context: {
          'itemCount': menu.length,
          'categories': menu.map((e) => e.category).toSet().length,
        });
        
        // 保存到缓存
        await MenuCacheService.saveMenuToCache(menu);
        Log.d('菜单已保存到缓存', tag: 'ApiService');
        
        final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
        Log.i('获取菜单完成', tag: 'ApiService', context: {
          'totalDuration': totalDuration,
          'source': 'server',
          'itemCount': menu.length,
        });
        
        return Result.success(menu);
      } else {
        Log.w('服务器响应异常', tag: 'ApiService', context: {
          'statusCode': response.statusCode,
          'body': response.body.substring(0, response.body.length.clamp(0, 200)),
        });
        
        // 服务器失败时，尝试使用缓存数据
        final cachedMenu = await MenuCacheService.getMenuFromCache();
        if (cachedMenu != null) {
          Log.w('服务器失败，回退使用缓存', tag: 'ApiService', context: {
            'statusCode': response.statusCode,
            'cachedItemCount': cachedMenu.length,
          });
          return Result.success(cachedMenu);
        }
        
        Log.e('获取菜单失败且无可用缓存', tag: 'ApiService', context: {
          'statusCode': response.statusCode,
        });
        return Result.failure(AppError.server('菜单加载失败'));
      }
    } catch (e, stackTrace) {
      Log.e('获取菜单发生异常', tag: 'ApiService', error: e, stackTrace: stackTrace, context: {
        'errorType': e.runtimeType.toString(),
      });
      
      // 网络错误时，尝试使用缓存数据
      final cachedMenu = await MenuCacheService.getMenuFromCache();
      if (cachedMenu != null) {
        Log.w('网络异常，使用缓存数据', tag: 'ApiService', context: {
          'cachedItemCount': cachedMenu.length,
          'error': e.toString(),
        });
        return Result.success(cachedMenu);
      }
      
      Log.e('网络异常且无可用缓存', tag: 'ApiService', context: {
        'error': e.toString(),
      });
      return Result.failure(AppError.network('网络连接失败，请检查网络设置'));
    }
  }

  static Future<List<String>> getCategories({bool forceRefresh = false}) async {
    final startTime = DateTime.now();
    Log.i('开始获取分类列表', tag: 'ApiService', context: {
      'forceRefresh': forceRefresh,
      'url': '$baseUrl/menu/categories',
    });
    
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh) {
      final cachedCategories = await MenuCacheService.getCategoriesFromCache();
      if (cachedCategories != null) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        Log.i('使用缓存分类数据', tag: 'ApiService', context: {
          'categoryCount': cachedCategories.length,
          'duration': duration,
          'source': 'cache',
        });
        return cachedCategories;
      }
      Log.d('分类缓存未命中，需要从服务器获取', tag: 'ApiService');
    }

    try {
      Log.i('正在从服务器获取分类', tag: 'ApiService', context: {
        'endpoint': '$baseUrl/menu/categories',
      });
      
      final requestStart = DateTime.now();
      final response = await http.get(Uri.parse('$baseUrl/menu/categories'));
      final requestDuration = DateTime.now().difference(requestStart).inMilliseconds;
      
      Log.d('分类服务器响应', tag: 'ApiService', context: {
        'statusCode': response.statusCode,
        'requestDuration': requestDuration,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final categories = data.cast<String>();
        
        Log.i('分类列表解析成功', tag: 'ApiService', context: {
          'categoryCount': categories.length,
          'categories': categories,
        });
        
        // 保存到缓存
        await MenuCacheService.saveCategoriesToCache(categories);
        Log.d('分类已保存到缓存', tag: 'ApiService');
        
        final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
        Log.i('获取分类完成', tag: 'ApiService', context: {
          'totalDuration': totalDuration,
          'source': 'server',
          'categoryCount': categories.length,
        });
        
        return categories;
      } else {
        Log.w('分类服务器响应异常', tag: 'ApiService', context: {
          'statusCode': response.statusCode,
        });
        
        // 服务器失败时，尝试使用缓存数据
        final cachedCategories = await MenuCacheService.getCategoriesFromCache();
        if (cachedCategories != null) {
          Log.w('服务器失败，回退使用分类缓存', tag: 'ApiService', context: {
            'statusCode': response.statusCode,
            'cachedCategoryCount': cachedCategories.length,
          });
          return cachedCategories;
        }
        
        Log.e('获取分类失败且无可用缓存', tag: 'ApiService', context: {
          'statusCode': response.statusCode,
        });
        throw Exception('Failed to load categories');
      }
    } catch (e, stackTrace) {
      Log.e('获取分类发生异常', tag: 'ApiService', error: e, stackTrace: stackTrace);
      
      // 网络错误时，尝试使用缓存数据
      final cachedCategories = await MenuCacheService.getCategoriesFromCache();
      if (cachedCategories != null) {
        Log.w('网络异常，使用分类缓存', tag: 'ApiService', context: {
          'cachedCategoryCount': cachedCategories.length,
          'error': e.toString(),
        });
        return cachedCategories;
      }
      
      Log.e('网络异常且无分类缓存可用', tag: 'ApiService');
      throw Exception('Error loading categories: $e');
    }
  }

  static Future<List<FamilyMember>> getFamilyMembers() async {
    final startTime = DateTime.now();
    Log.i('开始获取家庭成员列表', tag: 'ApiService', context: {
      'url': '$baseUrl/members',
    });
    
    try {
      final requestStart = DateTime.now();
      final response = await http.get(Uri.parse('$baseUrl/members'));
      final requestDuration = DateTime.now().difference(requestStart).inMilliseconds;
      
      Log.d('家庭成员服务器响应', tag: 'ApiService', context: {
        'statusCode': response.statusCode,
        'requestDuration': requestDuration,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final members = data.map((item) => FamilyMember.fromJson(item)).toList();
        
        final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
        Log.i('获取家庭成员成功', tag: 'ApiService', context: {
          'memberCount': members.length,
          'totalDuration': totalDuration,
        });
        
        return members;
      } else {
        Log.e('获取家庭成员失败', tag: 'ApiService', context: {
          'statusCode': response.statusCode,
          'body': response.body.substring(0, response.body.length.clamp(0, 200)),
        });
        throw Exception('Failed to load family members');
      }
    } catch (e, stackTrace) {
      Log.e('获取家庭成员发生异常', tag: 'ApiService', error: e, stackTrace: stackTrace);
      throw Exception('Error loading family members: $e');
    }
  }

  static Future<bool> submitOrder({
    required String memberId,
    required String memberName,
    required List<CartItem> items,
    required int totalPrice,
  }) async {
    final startTime = DateTime.now();
    Log.i('开始提交订单', tag: 'ApiService', context: {
      'memberId': memberId,
      'memberName': memberName,
      'itemCount': items.length,
      'totalPrice': totalPrice,
      'url': '$baseUrl/orders',
    });
    
    try {
      final orderData = {
        'memberId': memberId,
        'memberName': memberName,
        'items': items.map((item) => item.toJson()).toList(),
        'totalPrice': totalPrice,
      };
      
      Log.d('订单数据准备完成', tag: 'ApiService', context: {
        'dataSize': json.encode(orderData).length,
      });
      
      final requestStart = DateTime.now();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      final requestDuration = DateTime.now().difference(requestStart).inMilliseconds;
      
      Log.d('订单服务器响应', tag: 'ApiService', context: {
        'statusCode': response.statusCode,
        'requestDuration': requestDuration,
      });
      
      final success = response.statusCode == 200;
      final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
      
      if (success) {
        Log.i('订单提交成功', tag: 'ApiService', context: {
          'totalDuration': totalDuration,
          'orderId': response.body,
        });
      } else {
        Log.w('订单提交失败', tag: 'ApiService', context: {
          'statusCode': response.statusCode,
          'totalDuration': totalDuration,
          'response': response.body.substring(0, response.body.length.clamp(0, 200)),
        });
      }
      
      return success;
    } catch (e, stackTrace) {
      final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
      Log.e('订单提交发生异常', tag: 'ApiService', error: e, stackTrace: stackTrace, context: {
        'totalDuration': totalDuration,
      });
      return false;
    }
  }

  static Future<List<Order>> getOrders() async {
    final startTime = DateTime.now();
    Log.i('开始获取订单列表', tag: 'ApiService', context: {
      'url': '$baseUrl/orders',
    });
    
    try {
      final requestStart = DateTime.now();
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      final requestDuration = DateTime.now().difference(requestStart).inMilliseconds;
      
      Log.d('订单列表服务器响应', tag: 'ApiService', context: {
        'statusCode': response.statusCode,
        'requestDuration': requestDuration,
        'responseSize': response.body.length,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final orders = data.map((item) => Order.fromJson(item)).toList();
        
        final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
        Log.i('获取订单列表成功', tag: 'ApiService', context: {
          'orderCount': orders.length,
          'totalDuration': totalDuration,
        });
        
        // 性能监控
        if (totalDuration > 3000) {
          Log.w('获取订单列表耗时过长', tag: 'ApiService', context: {
            'duration': totalDuration,
            'threshold': 3000,
            'orderCount': orders.length,
          });
        }
        
        return orders;
      } else {
        Log.e('获取订单列表失败', tag: 'ApiService', context: {
          'statusCode': response.statusCode,
          'body': response.body.substring(0, response.body.length.clamp(0, 200)),
        });
        throw Exception('Failed to load orders');
      }
    } catch (e, stackTrace) {
      Log.e('获取订单列表发生异常', tag: 'ApiService', error: e, stackTrace: stackTrace);
      throw Exception('Error loading orders: $e');
    }
  }
}