# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

火树咖啡厅Flutter应用 - 一个多平台咖啡点餐应用，支持iOS、Android、Web和桌面平台。

## 开发命令

### 基础开发
```bash
# 安装依赖
flutter pub get

# 运行应用（Debug模式，支持热重载）
flutter run

# 指定平台运行
flutter run -d chrome    # Web浏览器
flutter run -d ios       # iOS模拟器
flutter run -d android   # Android模拟器
flutter run -d macos     # macOS桌面
flutter run -d windows   # Windows桌面
flutter run -d linux     # Linux桌面

# 代码分析（检查代码质量）
flutter analyze

# 运行测试
flutter test

# 检查过期依赖
flutter pub outdated

# 升级依赖
flutter pub upgrade
```

### 构建发布版本
```bash
# Android APK
flutter build apk --release

# Android App Bundle (推荐用于Play Store)
flutter build appbundle --release

# iOS (需要macOS和Xcode)
flutter build ios --release

# Web
flutter build web --release

# macOS桌面应用
flutter build macos --release

# Windows桌面应用
flutter build windows --release

# Linux桌面应用
flutter build linux --release
```

## 架构设计

### 项目结构
```
lib/
├── main.dart                    # 应用入口，集成flutter_common
├── main_with_flutter_common.dart # flutter_common集成示例
├── models/                      # 数据模型
│   ├── cart_item.dart          # 购物车项
│   ├── coffee_item.dart        # 咖啡商品
│   ├── family_member.dart      # 家庭成员
│   └── order.dart              # 订单
├── providers/                   # 状态管理
│   └── cart_provider.dart      # 购物车状态（Provider）
├── screens/                     # 页面组件
│   ├── main_screen.dart        # 主屏幕（底部导航）
│   ├── home_tab.dart           # 首页标签
│   ├── menu_tab.dart           # 菜单标签
│   ├── cart_tab.dart           # 购物车标签
│   ├── orders_tab.dart         # 订单标签
│   ├── member_selection_screen.dart # 成员选择
│   └── settings_screen.dart    # 设置页面
├── services/                    # 服务层
│   ├── api_service.dart        # API调用（使用flutter_common的Result）
│   ├── menu_cache_service.dart # 菜单缓存
│   └── update_service.dart     # 应用更新
└── widgets/                     # 可复用组件
    ├── coffee_card.dart         # 咖啡卡片
    ├── fullscreen_image_viewer.dart # 全屏图片查看
    └── update_checker.dart      # 更新检查器
```

### 核心技术栈

#### 状态管理
- **Provider** (6.1.1) - 主要状态管理方案
- **flutter_common** - 提供SimpleState轻量级状态管理（可选）

#### 网络请求
- **http** (1.1.0) - HTTP请求
- **API基础URL**: `https://coffee.flametree.synology.me:60443/api`
- 使用flutter_common的Result模式处理API响应

#### 本地存储
- **shared_preferences** (2.2.2) - 键值存储
- **path_provider** (2.1.4) - 文件路径
- 菜单数据缓存机制

#### 其他依赖
- **package_info_plus** (8.0.0) - 应用信息
- **url_launcher** (6.2.5) - 打开外部链接
- **open_file** (3.3.2) - 打开文件
- **permission_handler** (11.3.1) - 权限管理

### flutter_common集成

项目已集成flutter_common通用框架，提供：

#### 日志系统
```dart
Log.i('信息日志', tag: 'ApiService');
Log.w('警告日志', tag: 'Cache');
Log.e('错误日志', tag: 'Network', error: exception);
```

#### 错误处理
```dart
// API返回Result类型
Result<List<CoffeeItem>> result = await ApiService.getMenu();
result.fold(
  onSuccess: (menu) => _updateMenu(menu),
  onFailure: (error) => _showError(error),
);
```

#### 工具扩展
- 字符串扩展（邮箱验证、手机号脱敏等）
- 日期时间扩展（相对时间显示）
- BuildContext扩展（便捷UI操作）

#### 通用组件
- LoadingWidget - 加载状态
- AppErrorWidget - 错误显示
- EmptyWidget - 空状态

## API接口

### 基础配置
- **基础URL**: `https://coffee.flametree.synology.me:60443/api`
- **响应格式**: JSON
- **错误处理**: 使用Result模式包装响应

### 主要端点
- `GET /menu` - 获取菜单列表
- `GET /family-members` - 获取家庭成员
- `POST /order` - 提交订单
- `GET /orders` - 获取订单列表
- `GET /latest-version` - 检查更新

## 开发注意事项

### 缓存策略
- 菜单数据自动缓存到本地
- 网络失败时优先使用缓存数据
- 支持强制刷新获取最新数据

### 图片资源
- 静态图片存放在 `assets/images/`
- 网络图片支持缓存和错误处理
- 支持全屏查看功能

### 更新机制
- 应用启动时自动检查更新
- 支持APK下载和安装（Android）
- 版本信息存储在SharedPreferences

### Material Design主题
- 主色调：橙色 (#FF8C42)
- 背景色：米黄色 (#FFF8E1)
- 卡片设计：圆角16px，阴影4
- 按钮样式：圆角12px

## 测试策略

### 单元测试
```bash
flutter test
```

### Widget测试
- 测试文件位于 `test/` 目录
- 使用flutter_test框架

### 集成测试
```bash
flutter test integration_test
```

## 性能优化

### 关键优化点
- 使用const构造函数减少重建
- 图片懒加载和缓存
- API响应缓存机制
- Provider监听优化，避免不必要的重建

### 调试工具
- Flutter Inspector - Widget树分析
- Flutter Performance - 性能监控
- flutter_common日志系统 - 问题追踪

## 部署注意事项

### Android
- 最小SDK版本：21 (Android 5.0)
- 目标SDK版本：根据build.gradle配置
- 需要网络权限和存储权限

### iOS
- 最小iOS版本：12.0
- 需要在Info.plist配置网络权限
- 需要配置App Transport Security

### Web
- 支持PWA（渐进式Web应用）
- 需要HTTPS部署
- 注意CORS配置