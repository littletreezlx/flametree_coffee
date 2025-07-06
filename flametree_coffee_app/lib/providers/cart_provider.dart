import 'package:flutter/foundation.dart';
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
    _selectedMember = member;
    notifyListeners();
  }

  void addItem(String id, String name, String temperature, int price) {
    final existingIndex = _items.indexWhere(
      (item) => item.id == id && item.temperature == temperature,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        temperature: temperature,
        quantity: 1,
        price: price,
      ));
    }
    notifyListeners();
  }

  void removeItem(String id, String temperature) {
    final existingIndex = _items.indexWhere(
      (item) => item.id == id && item.temperature == temperature,
    );

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity - 1,
        );
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  CartItem? getItem(String id, String temperature) {
    try {
      return _items.firstWhere(
        (item) => item.id == id && item.temperature == temperature,
      );
    } catch (e) {
      return null;
    }
  }
}