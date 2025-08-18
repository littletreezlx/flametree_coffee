# 日志系统使用指南

## 概述

本项目使用flutter_common提供的日志系统，为整个应用提供统一、完善的日志记录功能。日志系统已集成到所有核心模块，提供全面的应用状态监控和问题排查能力。

## 日志级别

### 级别定义
- **DEBUG** - 详细的调试信息，仅开发环境启用
- **INFO** - 关键业务流程节点和正常运行状态
- **WARN** - 异常情况但程序可继续执行
- **ERROR** - 错误信息，需要立即关注

### 环境配置
- **开发环境**: 启用控制台输出，最小级别DEBUG
- **生产环境**: 禁用控制台输出，最小级别INFO

## 各层日志实现

### 1. Services层日志

#### API服务 (api_service.dart)
```dart
// 请求开始
Log.i('开始获取菜单', tag: 'ApiService', context: {
  'forceRefresh': forceRefresh,
  'url': '$baseUrl/menu',
});

// 性能监控
Log.d('服务器响应', tag: 'ApiService', context: {
  'statusCode': response.statusCode,
  'requestDuration': requestDuration,
  'responseSize': response.body.length,
});

// 错误处理
Log.e('获取菜单发生异常', tag: 'ApiService', 
  error: e, 
  stackTrace: stackTrace, 
  context: {'errorType': e.runtimeType.toString()}
);
```

#### 缓存服务 (menu_cache_service.dart)
```dart
// 缓存操作
Log.i('菜单缓存保存成功', tag: 'MenuCache', context: {
  'itemCount': menu.length,
  'dataSize': dataString.length,
});

// 缓存有效性
Log.d('缓存有效性检查', tag: 'MenuCache', context: {
  'isValid': isValid,
  'cacheAge': age.inMinutes,
  'maxAge': cacheValidDuration.inMinutes,
});
```

#### 更新服务 (update_service.dart)
```dart
// 版本检查
Log.i('开始检查应用更新', tag: 'UpdateService');

// 下载进度
Log.d('下载进度', tag: 'UpdateService', context: {
  'progress': currentProgress,
  'downloaded': formatFileSize(downloadedBytes),
  'total': formatFileSize(totalBytes),
});

// 性能监控
Log.i('文件下载完成', tag: 'UpdateService', context: {
  'filePath': filePath,
  'fileSize': formatFileSize(downloadedBytes),
  'duration': duration,
  'speed': '${formatFileSize((downloadedBytes * 1000 / duration).round())}/s',
});
```

### 2. Providers层日志

#### 购物车状态管理 (cart_provider.dart)
```dart
// 状态变更
Log.i('添加新商品到购物车', tag: 'CartProvider', context: {
  'itemId': id,
  'itemName': name,
  'temperature': temperature,
  'price': price,
  'totalItems': _items.length,
});

// 状态监控
Log.d('购物车状态更新', tag: 'CartProvider', context: {
  'totalItems': totalItems,
  'totalPrice': totalPrice,
  'cartSize': _items.length,
});
```

### 3. Screens层日志

#### 页面生命周期 (main_screen.dart)
```dart
@override
void initState() {
  super.initState();
  Log.i('主界面初始化', tag: 'MainScreen');
}

@override
void dispose() {
  Log.i('主界面销毁', tag: 'MainScreen');
  super.dispose();
}
```

#### 用户交互
```dart
// Tab切换
Log.i('切换到${tabNames[index]}', tag: 'MainScreen', context: {
  'fromIndex': _currentIndex,
  'toIndex': index,
  'tabName': tabNames[index],
});
```

### 4. Widgets层日志

#### 组件交互 (coffee_card.dart)
```dart
// 用户操作
Log.i('点击添加商品', tag: 'CoffeeCard', context: {
  'coffeeId': widget.coffeeItem.id,
  'coffeeName': widget.coffeeItem.name,
  'temperature': selectedTemperature,
  'price': price,
  'currentQuantity': quantity,
});

// 状态切换
Log.d('切换温度选项', tag: 'CoffeeCard', context: {
  'coffeeId': widget.coffeeItem.id,
  'from': selectedTemperature,
  'to': temp,
});
```

### 5. Models层日志

#### 数据序列化 (coffee_item.dart)
```dart
// 解析成功
Log.d('咖啡商品解析成功', tag: 'CoffeeItem', context: {
  'id': item.id,
  'name': item.name,
  'category': item.category,
  'priceCount': item.prices.length,
});

// 解析失败
Log.e('咖啡商品解析失败', tag: 'CoffeeItem', 
  error: e, 
  stackTrace: stackTrace, 
  context: {'json': json}
);
```

## 日志初始化配置

### main.dart
```dart
void _initializeLogging() {
  final isDebug = !kReleaseMode;
  
  Log.init(
    enableConsoleLog: isDebug,
    minLevel: isDebug ? LogLevel.debug : LogLevel.info,
  );
  
  // 注册Flutter错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    Log.e('Flutter框架错误', 
      tag: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toDescription(),
      }
    );
  };
}
```

## 最佳实践

### 1. 日志粒度控制
- **关键业务流程**: 使用INFO级别
- **调试信息**: 使用DEBUG级别
- **性能监控**: 记录耗时和资源消耗
- **错误处理**: 包含完整的错误上下文

### 2. 上下文信息
始终提供有用的上下文信息：
```dart
Log.i('操作名称', tag: 'ModuleName', context: {
  'userId': userId,
  'action': actionName,
  'params': parameters,
  'duration': duration,
});
```

### 3. 性能监控
对关键操作进行性能监控：
```dart
final startTime = DateTime.now();
// 执行操作
final duration = DateTime.now().difference(startTime).inMilliseconds;

if (duration > threshold) {
  Log.w('操作执行缓慢', tag: 'Performance', context: {
    'operation': operationName,
    'duration': duration,
    'threshold': threshold,
  });
}
```

### 4. 错误处理
完整记录错误信息：
```dart
try {
  // 业务逻辑
} catch (e, stackTrace) {
  Log.e('操作失败', 
    tag: 'ModuleName',
    error: e,
    stackTrace: stackTrace,
    context: {
      'operation': operationName,
      'params': parameters,
    }
  );
}
```

## 日志查看和分析

### 开发环境
- 使用Flutter日志控制台查看实时日志
- 使用VS Code或Android Studio的日志过滤功能
- 通过tag筛选特定模块日志

### 生产环境
- 日志级别自动调整为INFO及以上
- 可集成第三方日志收集服务
- 支持错误上报和性能监控

## 注意事项

1. **敏感信息**: 避免在日志中记录密码、密钥等敏感信息
2. **性能影响**: 避免在高频调用的函数中添加过多DEBUG日志
3. **日志格式**: 保持日志格式统一，便于分析和搜索
4. **错误恢复**: 记录错误后的恢复策略和结果

## 扩展建议

### 未来可考虑的改进
1. 集成远程日志收集服务（如Sentry、Firebase Crashlytics）
2. 添加日志文件持久化功能
3. 实现日志分析和可视化工具
4. 添加用户行为追踪和分析
5. 实现日志加密和压缩功能

## 相关文档
- [flutter_common日志系统文档](https://github.com/littletreezlx/flutter_common)
- [Flutter错误处理最佳实践](https://flutter.dev/docs/testing/errors)