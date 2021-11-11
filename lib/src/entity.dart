import 'package:meta/meta.dart';

enum EntityType {
  contentType,
  entry,
}

@immutable
class EntityRef {
  EntityRef({
    required this.type,
    required this.id,
  });

  final EntityType type;
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityRef &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;

  @override
  String toString() => 'EntityRef(type: $type, id: $id)';
}

@immutable
class EntityMetadata extends EntityRef {
  EntityMetadata({
    required EntityType type,
    required String id,
    required this.createdAt,
    this.updatedAt,
  }) : super(type: type, id: id);

  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityMetadata &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      type.hashCode ^ id.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode;

  @override
  String toString() =>
      'EntityMetadata(type: $type, id: $id, createdAt: $createdAt, '
      'updatedAt: $updatedAt)';
}

abstract class Entity {
  EntityMetadata get metadata;
}
