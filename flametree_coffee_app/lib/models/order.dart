import 'package:flutter/material.dart';
import 'cart_item.dart';

class Order {
  final String id;
  final String memberId;
  final String memberName;
  final List<CartItem> items;
  final int totalPrice;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      memberId: json['memberId'],
      memberName: json['memberName'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalPrice: json['totalPrice'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return '待处理';
      case 'preparing':
        return '制作中';
      case 'ready':
        return '已完成';
      case 'completed':
        return '已取餐';
      default:
        return '未知状态';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'preparing':
        return const Color(0xFF2196F3);
      case 'ready':
        return const Color(0xFF4CAF50);
      case 'completed':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}