class FamilyMember {
  final String id;
  final String name;
  final String avatar;

  FamilyMember({
    required this.id,
    required this.name,
    required this.avatar,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}