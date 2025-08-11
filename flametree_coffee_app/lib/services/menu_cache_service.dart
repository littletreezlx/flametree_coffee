import 'dart:convert';
import 'package:flutter_common/flutter_common_core.dart';
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
    Log.i('开始保存菜单到缓存', tag: 'MenuCache', context: {
      'itemCount': menu.length,
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final menuJson = menu.map((item) => item.toJson()).toList();
      final dataString = json.encode(menuJson);
      
      await prefs.setString(_menuKey, dataString);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      
      Log.i('菜单缓存保存成功', tag: 'MenuCache', context: {
        'itemCount': menu.length,
        'dataSize': dataString.length,
      });
    } catch (e, stackTrace) {
      Log.e('保存菜单缓存失败', tag: 'MenuCache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // 保存分类到本地
  static Future<void> saveCategoriesToCache(List<String> categories) async {
    Log.i('开始保存分类到缓存', tag: 'MenuCache', context: {
      'categoryCount': categories.length,
      'categories': categories,
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_categoriesKey, json.encode(categories));
      
      Log.i('分类缓存保存成功', tag: 'MenuCache', context: {
        'categoryCount': categories.length,
      });
    } catch (e, stackTrace) {
      Log.e('保存分类缓存失败', tag: 'MenuCache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // 从本地获取菜单
  static Future<List<CoffeeItem>?> getMenuFromCache() async {
    Log.d('尝试从缓存获取菜单', tag: 'MenuCache');
    
    final prefs = await SharedPreferences.getInstance();
    
    if (!await _isCacheValid()) {
      Log.i('菜单缓存已过期或无效', tag: 'MenuCache');
      return null;
    }
    
    final menuString = prefs.getString(_menuKey);
    if (menuString == null) {
      Log.i('菜单缓存不存在', tag: 'MenuCache');
      return null;
    }
    
    try {
      final List<dynamic> menuJson = json.decode(menuString);
      final menu = menuJson.map((item) => CoffeeItem.fromJson(item)).toList();
      
      Log.i('菜单缓存读取成功', tag: 'MenuCache', context: {
        'itemCount': menu.length,
        'dataSize': menuString.length,
      });
      
      return menu;
    } catch (e, stackTrace) {
      Log.e('菜单缓存解析失败', tag: 'MenuCache', error: e, stackTrace: stackTrace);
      // 如果解析失败，清除缓存
      await clearCache();
      return null;
    }
  }

  // 从本地获取分类
  static Future<List<String>?> getCategoriesFromCache() async {
    Log.d('尝试从缓存获取分类', tag: 'MenuCache');
    
    final prefs = await SharedPreferences.getInstance();
    
    if (!await _isCacheValid()) {
      Log.i('分类缓存已过期或无效', tag: 'MenuCache');
      return null;
    }
    
    final categoriesString = prefs.getString(_categoriesKey);
    if (categoriesString == null) {
      Log.i('分类缓存不存在', tag: 'MenuCache');
      return null;
    }
    
    try {
      final List<dynamic> categoriesJson = json.decode(categoriesString);
      final categories = categoriesJson.cast<String>();
      
      Log.i('分类缓存读取成功', tag: 'MenuCache', context: {
        'categoryCount': categories.length,
      });
      
      return categories;
    } catch (e, stackTrace) {
      Log.e('分类缓存解析失败', tag: 'MenuCache', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // 检查缓存是否有效
  static Future<bool> _isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    
    if (lastUpdate == null) {
      Log.d('缓存时间戳不存在', tag: 'MenuCache');
      return false;
    }
    
    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();
    final age = now.difference(lastUpdateTime);
    final isValid = age < cacheValidDuration;
    
    Log.d('缓存有效性检查', tag: 'MenuCache', context: {
      'isValid': isValid,
      'cacheAge': age.inMinutes,
      'maxAge': cacheValidDuration.inMinutes,
      'lastUpdate': lastUpdateTime.toIso8601String(),
    });
    
    return isValid;
  }

  // 清除缓存
  static Future<void> clearCache() async {
    Log.i('开始清除菜单缓存', tag: 'MenuCache');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_menuKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_lastUpdateKey);
      
      Log.i('菜单缓存清除成功', tag: 'MenuCache');
    } catch (e, stackTrace) {
      Log.e('清除菜单缓存失败', tag: 'MenuCache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // 强制刷新缓存（从服务器重新获取）
  static Future<void> forceRefresh() async {
    Log.i('强制刷新缓存', tag: 'MenuCache');
    await clearCache();
  }

  // 获取缓存状态信息
  static Future<Map<String, dynamic>> getCacheInfo() async {
    Log.d('获取缓存状态信息', tag: 'MenuCache');
    
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    final menuString = prefs.getString(_menuKey);
    final categoriesString = prefs.getString(_categoriesKey);
    final hasMenu = menuString != null;
    final hasCategories = categoriesString != null;
    final isValid = await _isCacheValid();
    
    final info = {
      'hasCache': hasMenu && hasCategories,
      'isValid': isValid,
      'lastUpdate': lastUpdate != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastUpdate).toIso8601String()
          : null,
      'menuSize': menuString?.length ?? 0,
      'categoriesSize': categoriesString?.length ?? 0,
    };
    
    Log.i('缓存状态', tag: 'MenuCache', context: info);
    
    return info;
  }
}