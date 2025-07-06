class CoffeeItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final Map<String, int> prices;
  final List<String> available;
  final String image;
  final bool popular;

  CoffeeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.prices,
    required this.available,
    required this.image,
    required this.popular,
  });

  factory CoffeeItem.fromJson(Map<String, dynamic> json) {
    return CoffeeItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      prices: Map<String, int>.from(json['prices']),
      available: List<String>.from(json['available']),
      image: json['image'],
      popular: json['popular'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'prices': prices,
      'available': available,
      'image': image,
      'popular': popular,
    };
  }
}