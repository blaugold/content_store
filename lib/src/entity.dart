enum EntityType {
  contentType,
  entry,
}

class EntityRef {
  EntityRef({
    required this.type,
    required this.id,
  });

  final EntityType type;
  final String id;
}

class EntityMetadata extends EntityRef {
  EntityMetadata({
    required EntityType type,
    required String id,
    required this.createdAt,
    this.updatedAt,
  }) : super(type: type, id: id);

  final DateTime createdAt;
  final DateTime? updatedAt;
}

abstract class Entity {
  EntityMetadata get metadata;
}
