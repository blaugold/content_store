import '../content_store.dart';
import 'entity.dart';
import 'storage_backend.dart';

/// A [StorageBackend] that stores entities in memory.
///
/// Useful for testing.
class MemoryStorageBackend extends StorageBackend {
  final Map<EntityType, Map<String, Entity>> _entities = {
    EntityType.contentType: {},
    EntityType.entry: {},
  };

  @override
  Future<void> saveEntity(Entity entity) async =>
      _entities[entity.meta.type]![entity.meta.id] = entity;

  @override
  Future<Entity> getEntity(String id, {required EntityType type}) async {
    final entity = _entities[type]![id];

    if (entity == null) {
      throw StorageBackendException(StorageBackendErrorCode.notFound);
    }

    return entity;
  }

  @override
  Stream<String> getEntityIdsOfType(EntityType type) =>
      Stream.fromIterable(_entities[type]!.keys.toList(growable: false));

  @override
  Stream<String> getEntryIdsWithContentTypeIn(
    Set<String> contentTypeIds, {
    bool not = false,
  }) =>
      Stream.fromIterable(List<Entry>.from(_entities[EntityType.entry]!.values,
              growable: false))
          .where((entry) {
        final hasMatchingContentType =
            contentTypeIds.contains(entry.contentType.id);
        return not ? !hasMatchingContentType : hasMatchingContentType;
      }).map((entry) => entry.meta.id);

  @override
  Future<void> deleteEntity(String id, {required EntityType type}) async =>
      _entities[type]!.remove(id);
}
