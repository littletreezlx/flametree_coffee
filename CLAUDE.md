# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a Flametree Coffee project with two main components:

- **flametree_coffee_app/**: Flutter mobile application (iOS/Android/Web/Desktop)
- **flametree_coffee_server/**: Next.js web server with TypeScript and Tailwind CSS

## Flutter App (flametree_coffee_app/)

### Development Commands
```bash
# Navigate to Flutter app directory
cd flametree_coffee_app

# Install dependencies
flutter pub get

# Run the app (debug mode with hot reload)
flutter run

# Run on specific device
flutter run -d chrome  # Web
flutter run -d ios     # iOS simulator
flutter run -d android # Android emulator

# Build for production
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web

# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated packages
flutter pub outdated
```

### Architecture
- Standard Flutter project structure with Material Design
- Uses `flutter_lints` for code quality
- Cupertino icons included for iOS-style UI elements
- Supports all platforms (iOS, Android, Web, Windows, macOS, Linux)

## Next.js Server (flametree_coffee_server/)

### Development Commands
```bash
# Navigate to server directory
cd flametree_coffee_server

# Install dependencies
npm install

# Start development server with Turbo
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linting
npm run lint
```

### Architecture
- Next.js 15.3.5 with App Router
- React 19 with TypeScript
- Tailwind CSS 4 for styling
- Geist font family integration
- PostCSS configuration

### Key Files
- `app/page.tsx`: Main landing page component
- `app/layout.tsx`: Root layout component
- `next.config.ts`: Next.js configuration
- `tsconfig.json`: TypeScript configuration
- `postcss.config.mjs`: PostCSS configuration

## Flutter Common 通用库集成

### 概述
本项目集成了flutter_common作为submodule，提供统一的通用组件、工具类和基础架构。

### Submodule管理
```bash
# 初始化submodule（首次克隆后）
git submodule update --init --recursive

# 更新flutter_common到最新版本
git submodule update --remote flutter_common

# 提交submodule更新
git add flutter_common
git commit -m "更新flutter_common submodule到最新版本"
```

### 同步规则
**⚠️ 重要**: 当修改flutter_common代码时，必须同步所有项目！

1. **修改flutter_common流程**:
   ```bash
   # 进入flutter_common目录
   cd flutter_common
   
   # 进行修改并提交
   git add .
   git commit -m "feat: 添加新功能"
   git push origin master
   
   # 返回根目录同步所有项目
   cd ../..
   ./sync_flutter_common.sh sync
   ./sync_flutter_common.sh push
   ```

2. **检查同步状态**:
   ```bash
   # 在Flutter根目录检查所有项目状态
   ./sync_flutter_common.sh status
   ```

3. **同步其他项目**:
   ```bash
   # 自动同步所有项目
   ./sync_flutter_common.sh sync
   ```

### 使用说明
在Flutter app中集成flutter_common:
```dart
// 导入flutter_common核心功能
import 'package:flutter_common/flutter_common_core.dart';

// 使用工具扩展
'user@example.com'.isEmail;          // 邮箱验证
'13812345678'.maskPhone;             // 手机号脱敏
DateTime.now().timeAgo;              // 相对时间
context.showSnackBar('操作成功');      // 显示提示

// 使用通用组件
LoadingWidget.message('加载中...');
AppErrorWidget.network(onRetry: _retry);
EmptyWidget.search('Flutter');

// 使用状态管理
final counter = SimpleState<int>(0);
StateBuilder<int>(
  state: counter,
  builder: (context, count) => Text('$count'),
);
```

### 注意事项
- 不要直接在submodule目录中修改代码
- 修改flutter_common后务必同步所有项目
- 定期检查和更新submodule版本
- 参考 `../FLUTTER_COMMON_SYNC_RULES.md` 获取详细规则

## Development Workflow

When working across both projects:
1. Changes to the Flutter app require `flutter pub get` after dependency updates
2. Changes to the server require `npm install` after package.json updates  
3. Both projects support hot reload during development
4. Use `flutter analyze` and `npm run lint` to check code quality before committing
5. **重要**: 修改flutter_common后务必同步所有项目