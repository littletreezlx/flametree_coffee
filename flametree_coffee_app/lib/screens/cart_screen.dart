import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '购物车是空的',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '去选择一些美味的咖啡吧！',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFFFE0B2),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      cartProvider.selectedMember?.avatar ?? '',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cartProvider.selectedMember?.name}的订单',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD84315),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFF8E1),
                              Color(0xFFFFE0B2),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD84315),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.temperature == 'ice' ? '冰饮' : '热饮',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '¥${item.price}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF8C42),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      cartProvider.removeItem(
                                        item.id,
                                        item.temperature,
                                      );
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF8C42),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      cartProvider.addItem(
                                        item.id,
                                        item.name,
                                        item.temperature,
                                        item.price,
                                      );
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF8C42),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '总计:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '¥${cartProvider.totalPrice}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD84315),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _submitOrder(context, cartProvider),
                        child: const Text(
                          '提交订单',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitOrder(BuildContext context, CartProvider cartProvider) async {
    if (cartProvider.selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择家庭成员')),
      );
      return;
    }

    try {
      final success = await ApiService.submitOrder(
        memberId: cartProvider.selectedMember!.id,
        memberName: cartProvider.selectedMember!.name,
        items: cartProvider.items,
        totalPrice: cartProvider.totalPrice,
      );

      if (success) {
        cartProvider.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订单提交成功！'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订单提交失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提交订单时出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}