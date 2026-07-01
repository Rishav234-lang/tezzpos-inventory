import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String status;
  final int itemCount;
  final List<Map<String, dynamic>> products;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.status = 'ACTIVE',
    this.itemCount = 0,
    this.products = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [id, name, description, imageUrl, status, itemCount, products];
}
