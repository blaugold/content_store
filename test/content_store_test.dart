import 'package:content_store/content_store.dart';
import 'package:test/test.dart';

void main() {
  late MemoryStorageBackend backend;
  late ContentStore store;

  setUp(() async {
    backend = MemoryStorageBackend();
    store = ContentStore(backend: backend);
    await store.initialize();
    addTearDown(store.close);
  });

  group('createContentType', () {
    test('creates a new content type', () async {
      final contentType = await store.createContentType(ContentTypeData(
        label: 'a',
        fields: {'a': FieldSpec(type: FieldType.text)},
      ));

      expect(contentType.meta.type, EntityType.contentType);
      expect(
        contentType.meta.createdAt.millisecondsSinceEpoch,
        closeTo(DateTime.now().millisecondsSinceEpoch, 100),
      );
      expect(contentType.meta.lastModifiedAt, isNull);
      expect(contentType.label, 'a');
      expect(contentType.fields['a'], isNotNull);
      expect(contentType.fields['a']!.type, FieldType.text);
      expect(contentType.fields['a']!.required, isTrue);
    });

    test('throws when content type is invalid', () async {
      expect(
        store.createContentType(ContentTypeData(
          label: 'a',
          fields: {
            ':': FieldSpec(type: FieldType.text),
          },
        )),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });

  group('getContentType', () {
    test('returns existing content type', () async {
      final contentType = await store
          .createContentType(ContentTypeData(label: 'a', fields: {}));
      expect(await store.getContentType(contentType.meta.id), contentType);
    });

    test('throws when content type does not exist', () async {
      expect(
        store.getContentType('a'),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });

  group('listContentTypes', () {
    test('returns all content types', () async {
      final contentTypeA = await store
          .createContentType(ContentTypeData(label: 'a', fields: {}));
      final contentTypeB = await store
          .createContentType(ContentTypeData(label: 'b', fields: {}));

      expect(
        store.listContentTypes(),
        emitsInAnyOrder(<Object>[contentTypeA, contentTypeB]),
      );
    });
  });

  group('deleteContentType', () {
    test('deletes an existing content type', () async {
      final contentType = await store
          .createContentType(ContentTypeData(label: 'a', fields: {}));
      await store.deleteContentType(contentType.meta.id);

      expect(
        store.getContentType(contentType.meta.id),
        throwsA(isA<ContentStoreException>()),
      );
    });

    test('deletes all entries of that content type', () async {
      final contentType = await store
          .createContentType(ContentTypeData(label: 'a', fields: {}));
      final entry = await store.createEntry(
        contentType.meta.id,
        EntryData(fields: {}),
      );

      await store.deleteContentType(contentType.meta.id);

      expect(
        store.getEntry(entry.meta.id),
        throwsA(isA<ContentStoreException>()),
      );
    });

    test('deleting non-existent content type is a noop', () async {
      await store.deleteContentType('');
    });
  });

  group('createEntry', () {
    test('creates a new entry', () async {
      final contentType = await store.createContentType(ContentTypeData(
        label: 'a',
        fields: {'a': FieldSpec(type: FieldType.text)},
      ));

      final entry = await store.createEntry(
        contentType.meta.id,
        EntryData(fields: {'a': 'a'}),
      );

      expect(entry.meta.type, EntityType.entry);
      expect(
        entry.meta.createdAt.millisecondsSinceEpoch,
        closeTo(DateTime.now().millisecondsSinceEpoch, 100),
      );
      expect(entry.meta.lastModifiedAt, isNull);
      expect(entry.contentType.id, contentType.meta.id);
      expect(entry.contentType.type, EntityType.contentType);
      expect(entry.fields, hasLength(1));
      expect(entry.fields['a'], 'a');
    });

    test('throws if entries fields are invalid', () async {
      await store.createContentType(ContentTypeData(
        label: 'a',
        fields: {'a': FieldSpec(type: FieldType.text)},
      ));

      expect(
        store.createEntry('a', EntryData(fields: {'a': null})),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });

  group('getEntry', () {
    test('returns existing entry', () async {
      final contentType = await store.createContentType(ContentTypeData(
        label: 'a',
        fields: {'a': FieldSpec(type: FieldType.text)},
      ));

      final entry = await store.createEntry(
        contentType.meta.id,
        EntryData(fields: {'a': 'a'}),
      );

      expect(await store.getEntry(entry.meta.id), entry);
    });

    test('throws when entry does not exist', () async {
      expect(
        store.getEntry('a'),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });
}
