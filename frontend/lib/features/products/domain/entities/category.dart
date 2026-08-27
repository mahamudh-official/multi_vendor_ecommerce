import 'package:equatable/equatable.dart';

/// Product category entity.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, slug, description, imageUrl, isActive];
}
