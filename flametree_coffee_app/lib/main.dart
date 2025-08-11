import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_common/flutter_common_core.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/update_checker.dart';

void main() {
  // 初始化flutter_common日志系统
  _initializeLogging();
  
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
  
  Log.i('火树咖啡应用启动', tag: 'App', context: {
    'platform': Platform.operatingSystem,
    'version': Platform.version,
    'locale': Platform.localeName,
  });
  
  runApp(const FlametreeCoffeeApp());
}

void _initializeLogging() {
  // 根据环境配置日志级别
  final isDebug = !kReleaseMode;
  
  Log.init(
    enableConsoleLog: isDebug,
    minLevel: isDebug ? LogLevel.debug : LogLevel.info,
  );
  
  Log.i('日志系统初始化完成', tag: 'Logger', context: {
    'mode': isDebug ? 'debug' : 'release',
    'minLevel': isDebug ? 'DEBUG' : 'INFO',
  });
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
    );
  }
}
