import 'package:flutter/foundation.dart';
import 'package:flutter_common/flutter_common_core.dart';
import '../models/cart_item.dart';
import '../models/family_member.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  FamilyMember? _selectedMember;

  List<CartItem> get items => _items;
  FamilyMember? get selectedMember => _selectedMember;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  int get totalPrice => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void selectMember(FamilyMember member) {
    Log.i('选择家庭成员', tag: 'CartProvider', context: {
      'memberId': member.id,
      'memberName': member.name,
      'previousMember': _selectedMember?.name,
    });
    
    _selectedMember = member;
    notifyListeners();
  }

  void addItem(String id, String name, String temperature, int price) {
    final existingIndex = _items.indexWhere(
      (item) => item.id == id && item.temperature == temperature,
    );

    if (existingIndex >= 0) {
      final oldQuantity = _items[existingIndex].quantity;
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: oldQuantity + 1,
      );
      
      Log.i('增加购物车商品数量', tag: 'CartProvider', context: {
        'itemId': id,
        'itemName': name,
        'temperature': temperature,
        'oldQuantity': oldQuantity,
        'newQuantity': oldQuantity + 1,
        'price': price,
      });
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        temperature: temperature,
        quantity: 1,
        price: price,
      ));
      
      Log.i('添加新商品到购物车', tag: 'CartProvider', context: {
        'itemId': id,
        'itemName': name,
        'temperature': temperature,
        'price': price,
        'totalItems': _items.length,
      });
    }
    
    Log.d('购物车状态更新', tag: 'CartProvider', context: {
      'totalItems': totalItems,
      'totalPrice': totalPrice,
      'cartSize': _items.length,
    });
    
    notifyListeners();
  }

  void removeItem(String id, String temperature) {
    final existingIndex = _items.indexWhere(
      (item) => item.id == id && item.temperature == temperature,
    );

    if (existingIndex >= 0) {
      final item = _items[existingIndex];
      final oldQuantity = item.quantity;
      
      if (oldQuantity > 1) {
        _items[existingIndex] = item.copyWith(
          quantity: oldQuantity - 1,
        );
        
        Log.i('减少购物车商品数量', tag: 'CartProvider', context: {
          'itemId': id,
          'itemName': item.name,
          'temperature': temperature,
          'oldQuantity': oldQuantity,
          'newQuantity': oldQuantity - 1,
        });
      } else {
        _items.removeAt(existingIndex);
        
        Log.i('从购物车移除商品', tag: 'CartProvider', context: {
          'itemId': id,
          'itemName': item.name,
          'temperature': temperature,
          'remainingItems': _items.length,
        });
      }
      
      Log.d('购物车状态更新', tag: 'CartProvider', context: {
        'totalItems': totalItems,
        'totalPrice': totalPrice,
        'cartSize': _items.length,
      });
      
      notifyListeners();
    } else {
      Log.w('尝试移除不存在的购物车商品', tag: 'CartProvider', context: {
        'itemId': id,
        'temperature': temperature,
      });
    }
  }

  void clearCart() {
    final previousItemCount = _items.length;
    final previousTotalPrice = totalPrice;
    
    Log.i('清空购物车', tag: 'CartProvider', context: {
      'previousItemCount': previousItemCount,
      'previousTotalPrice': previousTotalPrice,
    });
    
    _items.clear();
    notifyListeners();
  }

  CartItem? getItem(String id, String temperature) {
    try {
      final item = _items.firstWhere(
        (item) => item.id == id && item.temperature == temperature,
      );
      
      Log.d('查询购物车商品', tag: 'CartProvider', context: {
        'itemId': id,
        'temperature': temperature,
        'found': true,
        'quantity': item.quantity,
      });
      
      return item;
    } catch (e) {
      Log.d('购物车商品不存在', tag: 'CartProvider', context: {
        'itemId': id,
        'temperature': temperature,
        'found': false,
      });
      return null;
    }
  }
}