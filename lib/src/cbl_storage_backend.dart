import 'dart:async';

import 'package:cbl/cbl.dart';

import 'content_type.dart';
import 'entity.dart';
import 'entry.dart';
import 'storage_backend.dart';
import 'utils.dart';

const _indexPrefix = '__cbl_storage_backend__';
const _indexDelimiter = ':';
const _docIdDelimiter = ':';
const _idKey = 'id';
const _entityTypeKey = 'entityType';
const _createdAtKey = 'createdAt';
const _updatedAtKey = 'updatedAt';
const _contentTypeIdKey = 'contentTypeId';
const _labelKey = 'label';
const _fieldsKey = 'fields';

/// An implementation of [StorageBackend] that uses Couchbase Lite to persist
/// [Entity]s.
///
/// The provided [database] is managed by this class and should not be directly
/// used by other code.
class CblStorageBackend extends StorageBackend {
  /// Creates a new [CblStorageBackend] that uses the provided [database].
  CblStorageBackend({
    required this.database,
  });

  /// The database to use for storage by this backend.
  final Database database;

  late Query _entityIdsQuery;

  @override
  Future<void> initialize() async {
    super.initialize();

    final indexes = await database.indexes;

    final backendIndexes = {
      'id': ValueIndexConfiguration([_idKey]),
      'entityType': ValueIndexConfiguration([_entityTypeKey]),
    };

    // Create indexes if they don't exist.
    for (final backendIndex in backendIndexes.entries) {
      final indexName = '$_indexPrefix$_indexDelimiter${backendIndex.key}';

      if (indexes.contains(indexName)) {
        // We want to keep this index, so we remove it from list of indexes
        // to potentially remove.
        indexes.remove(indexName);
      } else {
        await database.createIndex(indexName, backendIndex.value);
      }
    }

    // Remove indexes that are no longer needed.
    for (final index in indexes) {
      if (index.startsWith(_indexPrefix)) {
        await database.deleteIndex(index);
      }
    }

    _entityIdsQuery = await Query.fromN1ql(
      database,
      'SELECT id FROM _ WHERE $_entityTypeKey = \$type',
    );
  }

  @override
  Future<void> saveEntity(Entity entity) async {
    final existingDoc = await database.document(_entityDocIdFromEntity(entity));

    MutableDocument doc;
    if (existingDoc != null) {
      doc = existingDoc.toMutable();
      _updateEntityDoc(doc, entity);
    } else {
      doc = _createEntityDoc(entity);
    }

    await database.saveDocument(doc);
  }

  @override
  Future<Entity> getEntity(String id, {required EntityType type}) async {
    final doc = await database.document(_entityDocId(id, type: type));

    if (doc == null) {
      throw StorageBackendException(StorageBackendErrorCode.notFound);
    }

    final metadata = EntityMetadata(
      type: EntityType.values.byName(doc.string(_entityTypeKey)!),
      id: id,
      createdAt: doc.date(_createdAtKey)!,
    );

    switch (metadata.type) {
      case EntityType.contentType:
        return _readContentTypeFromDoc(doc, metadata);
      case EntityType.entry:
        return _readEntryFromDoc(doc, metadata);
    }
  }

  @override
  Stream<String> getEntityIdsOfType(EntityType type) => Future.sync(() async {
        await _entityIdsQuery.setParameters(Parameters({'type': type.name}));
        return _entityIdsQuery.execute();
      })
          .asStream()
          .asyncExpand((resultSet) => resultSet.asStream())
          .map((result) => result.value(0)!);

  @override
  Stream<String> getEntryIdsWithContentTypeIn(
    Set<String> contentTypeIds, {
    bool not = false,
  }) =>
      Future.sync(() async {
        var predicate = Expression.property(_contentTypeIdKey)
            .in_(contentTypeIds.map((e) => Expression.string(e)));

        if (not) {
          predicate = Expression.not(predicate);
        }

        final query = QueryBuilder()
            .select(SelectResult.property(_idKey))
            .from(DataSource.database(database))
            .where(
              Expression.property(_entityTypeKey)
                  .equalTo(Expression.value(EntityType.entry.name))
                  .and(predicate),
            );
        return query.execute();
      })
          .asStream()
          .asyncExpand((resultSet) => resultSet.asStream())
          .map((result) => result.value(0)!);

  @override
  Future<void> deleteEntity(String id, {required EntityType type}) async {
    final doc = await database.document(_entityDocId(id, type: type));

    // Entity has already been deleted.
    if (doc == null) {
      return;
    }

    await database.deleteDocument(doc);
  }

  String _entityDocId(String id, {required EntityType type}) =>
      '${type.name}$_docIdDelimiter$id';

  String _entityDocIdFromEntity(Entity entity) => _entityDocId(
        entity.metadata.id,
        type: entity.metadata.type,
      );

  MutableDocument _createEntityDoc(Entity entity) {
    final doc = MutableDocument.withId(_entityDocIdFromEntity(entity));
    doc.setString(entity.metadata.id, key: _idKey);
    doc.setString(entity.metadata.type.name, key: _entityTypeKey);
    doc.setDate(entity.metadata.createdAt, key: _createdAtKey);

    if (entity is ContentType) {
      _writeContentTypeToDoc(doc, entity);
    } else if (entity is Entry) {
      _writeEntryToDoc(doc, entity);
    } else {
      throw UnimplementedError();
    }

    return doc;
  }

  void _updateEntityDoc(MutableDocument doc, Entity entity) {
    doc.setDate(entity.metadata.updatedAt, key: _updatedAtKey);

    if (entity is ContentType) {
      _writeContentTypeToDoc(doc, entity);
    } else if (entity is Entry) {
      _writeEntryToDoc(doc, entity);
    } else {
      throw UnimplementedError();
    }
  }

  void _writeContentTypeToDoc(MutableDocument doc, ContentType entity) {
    Map<String, Object> writeFieldSpec(FieldSpec spec) => {
          'type': spec.type.name,
          'required': spec.required,
        };

    final data = {
      _labelKey: entity.label,
      _fieldsKey: {
        for (final field in entity.fields.entries)
          field.key: writeFieldSpec(field.value),
      }
    };

    for (final entry in data.entries) {
      doc.setValue(entry.value, key: entry.key);
    }
  }

  ContentType _readContentTypeFromDoc(
    Document doc,
    EntityMetadata metadata,
  ) {
    FieldSpec readFieldSpec(Dictionary dict) => FieldSpec(
          type: FieldType.values.byName(dict.string('type')!),
          required: dict.boolean('required'),
        );

    final label = doc.string(_labelKey)!;
    final fields = doc.dictionary(_fieldsKey)!;

    return ContentType(
      metadata: metadata,
      label: label,
      fields: {
        for (final name in fields)
          name: readFieldSpec(fields.dictionary(name)!),
      },
    );
  }

  void _writeEntryToDoc(MutableDocument doc, Entry entity) {
    final data = {
      _fieldsKey: {
        for (final field in entity.fields.entries) field.key: field.value,
      },
      _contentTypeIdKey: entity.contentType.id,
    };

    for (final entry in data.entries) {
      doc.setValue(entry.value, key: entry.key);
    }
  }

  Entity _readEntryFromDoc(Document doc, EntityMetadata metadata) {
    final contentTypeId = doc.string(_contentTypeIdKey)!;
    final fields = doc.dictionary(_fieldsKey)!;

    return Entry(
      metadata: metadata,
      contentType: EntityRef(
        type: EntityType.contentType,
        id: contentTypeId,
      ),
      fields: {
        for (final name in fields) name: fields.value(name)!,
      },
    );
  }
}
