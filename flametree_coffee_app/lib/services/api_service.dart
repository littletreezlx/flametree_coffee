import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coffee_item.dart';
import '../models/family_member.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'menu_cache_service.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.123:3001/api';

  static Future<List<CoffeeItem>> getMenu({bool forceRefresh = false}) async {
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh) {
      final cachedMenu = await MenuCacheService.getMenuFromCache();
      if (cachedMenu != null) {
        print('Using cached menu data');
        return cachedMenu;
      }
    }

    try {
      print('Fetching menu from server');
      final response = await http.get(Uri.parse('$baseUrl/menu'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final menu = data.map((item) => CoffeeItem.fromJson(item)).toList();
        
        // 保存到缓存
        await MenuCacheService.saveMenuToCache(menu);
        
        return menu;
      } else {
        // 服务器失败时，尝试使用缓存数据
        final cachedMenu = await MenuCacheService.getMenuFromCache();
        if (cachedMenu != null) {
          print('Server failed, using cached menu');
          return cachedMenu;
        }
        throw Exception('Failed to load menu');
      }
    } catch (e) {
      // 网络错误时，尝试使用缓存数据
      final cachedMenu = await MenuCacheService.getMenuFromCache();
      if (cachedMenu != null) {
        print('Network error, using cached menu');
        return cachedMenu;
      }
      throw Exception('Error loading menu: $e');
    }
  }

  static Future<List<String>> getCategories({bool forceRefresh = false}) async {
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh) {
      final cachedCategories = await MenuCacheService.getCategoriesFromCache();
      if (cachedCategories != null) {
        print('Using cached categories data');
        return cachedCategories;
      }
    }

    try {
      print('Fetching categories from server');
      final response = await http.get(Uri.parse('$baseUrl/menu/categories'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final categories = data.cast<String>();
        
        // 保存到缓存
        await MenuCacheService.saveCategoriesToCache(categories);
        
        return categories;
      } else {
        // 服务器失败时，尝试使用缓存数据
        final cachedCategories = await MenuCacheService.getCategoriesFromCache();
        if (cachedCategories != null) {
          print('Server failed, using cached categories');
          return cachedCategories;
        }
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      // 网络错误时，尝试使用缓存数据
      final cachedCategories = await MenuCacheService.getCategoriesFromCache();
      if (cachedCategories != null) {
        print('Network error, using cached categories');
        return cachedCategories;
      }
      throw Exception('Error loading categories: $e');
    }
  }

  static Future<List<FamilyMember>> getFamilyMembers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/members'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => FamilyMember.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load family members');
      }
    } catch (e) {
      throw Exception('Error loading family members: $e');
    }
  }

  static Future<bool> submitOrder({
    required String memberId,
    required String memberName,
    required List<CartItem> items,
    required int totalPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'memberId': memberId,
          'memberName': memberName,
          'items': items.map((item) => item.toJson()).toList(),
          'totalPrice': totalPrice,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting order: $e');
      return false;
    }
  }

  static Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Order.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Error loading orders: $e');
    }
  }
}