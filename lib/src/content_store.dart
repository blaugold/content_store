import 'dart:convert';
import 'dart:math';

import 'package:synchronized/synchronized.dart';

import 'content_type.dart';
import 'entity.dart';
import 'entry.dart';
import 'storage_backend.dart';
import 'utils.dart';

/// A store which stores content in the form of [Entry]s of one or more
/// [ContentType]s.
///
/// A [StorageBackend] is used for persisting and retrieving data. The data
/// managed by a [StorageBackend] must not be used by multiple [ContentStore]s
/// at the same time. During the lifetime of a [StorageBackend] it must only be
/// used by a single [ContentStore].
abstract class ContentStore {
  /// Creates a new [ContentStore] with the given [backend].
  factory ContentStore({
    required StorageBackend backend,
  }) = _ContentStoreImpl;

  /// Initializes the store and must be called before any other method.
  Future<void> initialize();

  /// Closes the store.
  Future<void> close();

  /// Creates a new [ContentType] with the given [id].
  Future<ContentType> createContentType(
    String id,
    ContentTypeData contentType,
  );

  /// Gets the [ContentType] with the given [id].
  Future<ContentType> getContentType(String id);

  /// Deletes the [ContentType] with the given [id].
  Future<void> deleteContentType(String id);

  /// Creates a new [Entry] of the [ContentType] with the given [contentTypeId].
  Future<Entry> createEntry(String contentTypeId, EntryData entry);

  /// Gets the [Entry] with the given [id].
  Future<Entry> getEntry(String id);
}

/// Error code to differentiate between different [ContentStoreException]s.
enum ContentStoreErrorCode {
  /// The requested [Entity] does not exist.
  notFound,

  /// The [ContentType] with the given [id] already exists.
  contentTypeAlreadyExists,

  /// The given value cannot be used as an id.
  invalidId,

  /// The [ContentType] failed validation.
  invalidContentType,

  /// The [Entry] failed validation against its [ContentType].
  invalidEntry,
}

/// An exception that is thrown by a [ContentStore] when an operation fails.
class ContentStoreException implements Exception {
  /// Creates a new [ContentStoreException] with the given [code] and [message].
  ContentStoreException(this.code, {this.message});

  /// The error code which details the reason for this error.
  final ContentStoreErrorCode code;

  /// An optional human readable message describing this exception.
  final String? message;

  @override
  String toString() => [
        'ContentStoreException: ${code.name}',
        if (message != null) message
      ].join(': ');
}

final _random = Random.secure();

final _fieldNameRegexp = RegExp(r'^[a-zA-Z0-9_]+$');

bool _isValidFieldName(String name) => _fieldNameRegexp.hasMatch(name);

final _idRegexp = RegExp(r'^[a-zA-Z0-9_]+$');

bool _isValidId(String name) => _idRegexp.hasMatch(name);

class _ContentStoreImpl implements ContentStore {
  _ContentStoreImpl({
    required StorageBackend backend,
  }) : _backend = backend;

  final StorageBackend _backend;

  final _lock = Lock();

  final Map<String, ContentType> _contentTypes = {};

  var _initialized = false;

  @override
  Future<void> initialize() async {
    await _backend.initialize();
    await _loadContentTypes();

    assert(() {
      _initialized = true;
      return true;
    }());
  }

  @override
  Future<void> close() async {
    _debugAssertInitialized();

    await _backend.close();
  }

  @override
  Future<ContentType> createContentType(
    String id,
    ContentTypeData contentType,
  ) =>
      _lock.synchronized(() async {
        _debugAssertInitialized();

        if (_contentTypes.containsKey(id)) {
          throw ContentStoreException(
            ContentStoreErrorCode.contentTypeAlreadyExists,
          );
        }

        _validateId(id);
        _validateContentTypeData(contentType);

        final entity = ContentType(
          metadata: EntityMetadata(
            type: EntityType.contentType,
            id: id,
            createdAt: DateTime.now(),
          ),
          fields: contentType.fields,
        );

        await _backend.saveEntity(entity);

        _contentTypes[id] = entity;

        return entity;
      });

  @override
  Future<ContentType> getContentType(String id) => _lock.synchronized(() async {
        _debugAssertInitialized();

        final contentType = _contentTypes[id];

        if (contentType == null) {
          throw ContentStoreException(ContentStoreErrorCode.notFound);
        }

        return contentType;
      });

  @override
  Future<void> deleteContentType(String id) => _lock.synchronized(() async {
        _debugAssertInitialized();

        await _backend.deleteEntity(id, type: EntityType.contentType);
        _contentTypes.remove(id);
      });

  @override
  Future<Entry> createEntry(String contentTypeId, EntryData entry) async {
    _debugAssertInitialized();

    final contentType = await getContentType(contentTypeId);

    _validateEntryData(contentType, entry);

    final id = _createEntityId();

    final entity = Entry(
      metadata: EntityMetadata(
        type: EntityType.entry,
        id: id,
        createdAt: DateTime.now(),
      ),
      contentType: EntityRef(
        type: EntityType.contentType,
        id: contentType.metadata.id,
      ),
      fields: entry.fields,
    );

    await _backend.saveEntity(entity);

    return entity;
  }

  @override
  Future<Entry> getEntry(String id) async {
    _debugAssertInitialized();

    try {
      return await _backend
          .getEntity(id, type: EntityType.entry)
          .then((entity) => entity as Entry);
    } on StorageBackendException catch (e) {
      if (e.code == StorageBackendErrorCode.notFound) {
        throw ContentStoreException(ContentStoreErrorCode.notFound);
      }
      rethrow;
    }
  }

  void _debugAssertInitialized() {
    assert(_initialized, 'initialize must be called before using the store');
  }

  Future<void> _loadContentTypes() async {
    _contentTypes.clear();

    await for (final contentType
        in _backend.getEntitiesOfType(EntityType.contentType)) {
      _contentTypes[contentType.metadata.id] = contentType as ContentType;
    }
  }

  String _createEntityId() {
    final bytes = List.generate(16, (index) => _random.nextInt(256));
    return base64Encode(bytes).replaceAll('=', '');
  }

  void _validateId(String id) {
    if (!_isValidId(id)) {
      throw ContentStoreException(
        ContentStoreErrorCode.invalidId,
        message: 'The given value cannot be used as an id: $id',
      );
    }
  }

  void _validateFieldName(String name) {
    if (!_isValidFieldName(name)) {
      throw ContentStoreException(
        ContentStoreErrorCode.invalidContentType,
        message: 'The given value cannot be used as a field name: $name',
      );
    }
  }

  void _validateContentTypeData(ContentTypeData data) {
    for (final fieldName in data.fields.keys) {
      _validateFieldName(fieldName);
    }
  }

  void _validateEntryData(ContentType contentType, EntryData data) {
    final knownFields = contentType.fields.keys.toSet();
    final unknownFields = data.fields.keys.toSet().difference(knownFields);
    if (unknownFields.isNotEmpty) {
      throw ContentStoreException(
        ContentStoreErrorCode.invalidEntry,
        message: 'Entry contains fields that are not defined for its '
            'content type: $unknownFields',
      );
    }

    for (final field in contentType.fields.entries) {
      final name = field.key;
      final spec = field.value;
      final value = data.fields[name];

      if (spec.required && value == null) {
        throw ContentStoreException(
          ContentStoreErrorCode.invalidEntry,
          message: 'Entry is missing a required field: $name',
        );
      }

      switch (spec.type) {
        case FieldType.text:
          if (value is String) return;
          break;
        case FieldType.integer:
          if (value is int) return;
          break;
      }

      throw ContentStoreException(
        ContentStoreErrorCode.invalidEntry,
        message: 'Entry has incorrect type for field $name. '
            'Expected type ${spec.type.name} and got ${value.runtimeType}',
      );
    }
  }
}
