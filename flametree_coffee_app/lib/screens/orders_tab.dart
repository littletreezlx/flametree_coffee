import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final orderList = await ApiService.getOrders();
      setState(() {
        orders = orderList.reversed.toList(); // 最新的订单在前
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载订单失败: $e')),
        );
      }
    }
  }

  String _getMemberEmoji(String memberId) {
    switch (memberId) {
      case 'dad':
        return '👨';
      case 'mom':
        return '👩';
      case 'child1':
        return '🧒';
      case 'child2':
        return '👶';
      default:
        return '👤';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭订单'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无订单记录',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '去首页开始点餐吧！',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _getMemberEmoji(order.memberId),
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          order.memberName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD84315),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: order.statusColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            order.statusText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatDateTime(order.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      ...order.items.map((item) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        item.temperature == 'ice' 
                                                            ? Icons.ac_unit 
                                                            : Icons.whatshot,
                                                        size: 16,
                                                        color: item.temperature == 'ice' 
                                                            ? Colors.blue 
                                                            : Colors.orange,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          '${item.name} x${item.quantity}',
                                                          style: const TextStyle(fontSize: 14),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Text('❤️', style: TextStyle(fontSize: 14)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${item.price * item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: Color(0xFFFF8C42),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            '订单总计:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Text('❤️', style: TextStyle(fontSize: 18)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${order.totalPrice}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFD84315),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}