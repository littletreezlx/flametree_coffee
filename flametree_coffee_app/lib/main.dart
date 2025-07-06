import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/main_screen.dart';
import 'services/update_service.dart';

void main() {
  runApp(const FlametreeCoffeeApp());
}

class FlametreeCoffeeApp extends StatefulWidget {
  const FlametreeCoffeeApp({super.key});

  @override
  State<FlametreeCoffeeApp> createState() => _FlametreeCoffeeAppState();
}

class _FlametreeCoffeeAppState extends State<FlametreeCoffeeApp> {
  @override
  void initState() {
    super.initState();
    // 启动时检查更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdateOnStartup();
    });
  }

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
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
