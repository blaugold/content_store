import 'package:meta/meta.dart';

import 'content_store.dart';
import 'content_type.dart';
import 'entity.dart';
import 'entry.dart';
import 'utils.dart';

/// A storage backend is used by a [ContentStore] to persist and retrieve
/// [Entity]s.
///
/// This class must be extended not implemented.
///
/// Extending types must be able to persist [ContentType] and [Entry]
/// entities.
///
/// Ids are guaranteed to not contain the `:` character.
abstract class StorageBackend {
  /// Initializes this backend.
  ///
  /// Do not call this method directly. [ContentStore] will call this method
  /// before using this backend.
  @mustCallSuper
  Future<void> initialize() async {}

  /// Closes this backend.
  ///
  /// Do not call this method directly. [ContentStore] will call this method
  /// when it is no longer using this backend.
  @mustCallSuper
  Future<void> close() async {}

  /// Saves the given [entity].
  ///
  /// If the entity does not exists yet, it must be created.
  /// If the entity already exists, it must be replaced.
  Future<void> saveEntity(Entity entity);

  /// Retrieves the [Entity] with the given [id] and [type].
  ///
  /// If no entity with the given [id] and [type] exists, a
  /// [StorageBackendException] with [StorageBackendErrorCode.notFound] must
  /// be thrown.
  Future<Entity> getEntity(String id, {required EntityType type});

  /// Retries all the ids of [Entity]s of the given [type].
  Stream<String> getEntityIdsOfType(EntityType type);

  /// Retrieves all [Entity]s of the given [type].
  Stream<Entity> getEntitiesOfType(EntityType type) =>
      getEntityIdsOfType(type).asyncMap((id) => getEntity(id, type: type));

  /// Deletes the [Entity] with the given [id] and [type].
  ///
  /// If no entity with the given [id] and [type] exists, this method is a noop.
  Future<void> deleteEntity(String id, {required EntityType type});
}

/// Error code to differentiate between different [StorageBackendException]s.
enum StorageBackendErrorCode {
  /// The requested entity does not exist.
  notFound,
}

/// An exception that is thrown by a [StorageBackend] when an operation fails.
class StorageBackendException implements Exception {
  /// Creates a new [StorageBackendException] with the given [code] and
  /// [message].
  StorageBackendException(this.code, {this.message});

  /// The error code which details the reason for this exception.
  final StorageBackendErrorCode code;

  /// An optional human readable message describing this exception.
  final String? message;

  @override
  String toString() => [
        'StorageBackendException: ${code.name}',
        if (message != null) message
      ].join(': ');
}
