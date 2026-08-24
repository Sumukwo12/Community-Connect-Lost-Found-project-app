class CategoryModel {
  final int id;
  final String name;
  final String? icon;
  final String? description;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id:          (json['id'] is int) ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name:        json['name']        as String? ?? '',
      icon:        json['icon']        as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'name':        name,
    'icon':        icon,
    'description': description,
  };
}
