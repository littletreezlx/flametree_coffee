class CartItem {
  final String id;
  final String name;
  final String temperature;
  final int quantity;
  final int price;

  CartItem({
    required this.id,
    required this.name,
    required this.temperature,
    required this.quantity,
    required this.price,
  });

  CartItem copyWith({
    String? id,
    String? name,
    String? temperature,
    int? quantity,
    int? price,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      temperature: temperature ?? this.temperature,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'temperature': temperature,
      'quantity': quantity,
      'price': price,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      temperature: json['temperature'],
      quantity: json['quantity'],
      price: json['price'],
    );
  }
}