import 'package:flutter/material.dart';
import 'package:flutter_common/flutter_common_core.dart';
import 'package:provider/provider.dart';
import '../models/coffee_item.dart';
import '../providers/cart_provider.dart';

class CoffeeCard extends StatefulWidget {
  final CoffeeItem coffeeItem;

  const CoffeeCard({super.key, required this.coffeeItem});

  @override
  State<CoffeeCard> createState() => _CoffeeCardState();
}

class _CoffeeCardState extends State<CoffeeCard> {
  String selectedTemperature = 'hot';

  @override
  void initState() {
    super.initState();
    selectedTemperature = widget.coffeeItem.available.first;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final currentItem = cartProvider.getItem(
      widget.coffeeItem.id,
      selectedTemperature,
    );
    final quantity = currentItem?.quantity ?? 0;

    return Card(
      elevation: 8,
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.coffeeItem.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD84315),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.coffeeItem.popular)
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.coffeeItem.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (widget.coffeeItem.available.length > 1)
                Row(
                  children: widget.coffeeItem.available.map((temp) {
                    final isSelected = temp == selectedTemperature;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTemperature = temp;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF8C42)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF8C42),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            temp == 'ice' ? '冰' : '热',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFFF8C42),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.coffeeItem.prices[selectedTemperature]}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD84315),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (quantity > 0) ...[
                        GestureDetector(
                          onTap: () {
                            Log.i('点击减少商品', tag: 'CoffeeCard', context: {
                              'coffeeId': widget.coffeeItem.id,
                              'coffeeName': widget.coffeeItem.name,
                              'temperature': selectedTemperature,
                              'currentQuantity': quantity,
                            });
                            cartProvider.removeItem(
                              widget.coffeeItem.id,
                              selectedTemperature,
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8C42),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      GestureDetector(
                        onTap: () {
                          final price = widget.coffeeItem.prices[selectedTemperature]!;
                          Log.i('点击添加商品', tag: 'CoffeeCard', context: {
                            'coffeeId': widget.coffeeItem.id,
                            'coffeeName': widget.coffeeItem.name,
                            'temperature': selectedTemperature,
                            'price': price,
                            'currentQuantity': quantity,
                          });
                          cartProvider.addItem(
                            widget.coffeeItem.id,
                            widget.coffeeItem.name,
                            selectedTemperature,
                            price,
                          );
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF8C42),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}