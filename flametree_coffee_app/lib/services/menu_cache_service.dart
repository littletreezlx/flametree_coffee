import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coffee_item.dart';

class MenuCacheService {
  static const String _menuKey = 'cached_menu';
  static const String _categoriesKey = 'cached_categories';
  static const String _lastUpdateKey = 'menu_last_update';
  
  // 缓存有效期：1小时
  static const Duration cacheValidDuration = Duration(hours: 1);

  // 保存菜单到本地
  static Future<void> saveMenuToCache(List<CoffeeItem> menu) async {
    final prefs = await SharedPreferences.getInstance();
    final menuJson = menu.map((item) => item.toJson()).toList();
    
    await prefs.setString(_menuKey, json.encode(menuJson));
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // 保存分类到本地
  static Future<void> saveCategoriesToCache(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoriesKey, json.encode(categories));
  }

  // 从本地获取菜单
  static Future<List<CoffeeItem>?> getMenuFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!await _isCacheValid()) {
      return null;
    }
    
    final menuString = prefs.getString(_menuKey);
    if (menuString == null) {
      return null;
    }
    
    try {
      final List<dynamic> menuJson = json.decode(menuString);
      return menuJson.map((item) => CoffeeItem.fromJson(item)).toList();
    } catch (e) {
      // 如果解析失败，清除缓存
      await clearCache();
      return null;
    }
  }

  // 从本地获取分类
  static Future<List<String>?> getCategoriesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!await _isCacheValid()) {
      return null;
    }
    
    final categoriesString = prefs.getString(_categoriesKey);
    if (categoriesString == null) {
      return null;
    }
    
    try {
      final List<dynamic> categoriesJson = json.decode(categoriesString);
      return categoriesJson.cast<String>();
    } catch (e) {
      return null;
    }
  }

  // 检查缓存是否有效
  static Future<bool> _isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    
    if (lastUpdate == null) {
      return false;
    }
    
    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();
    
    return now.difference(lastUpdateTime) < cacheValidDuration;
  }

  // 清除缓存
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_menuKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_lastUpdateKey);
  }

  // 强制刷新缓存（从服务器重新获取）
  static Future<void> forceRefresh() async {
    await clearCache();
  }

  // 获取缓存状态信息
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    final hasMenu = prefs.getString(_menuKey) != null;
    final hasCategories = prefs.getString(_categoriesKey) != null;
    final isValid = await _isCacheValid();
    
    return {
      'hasCache': hasMenu && hasCategories,
      'isValid': isValid,
      'lastUpdate': lastUpdate != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastUpdate).toIso8601String()
          : null,
    };
  }
}