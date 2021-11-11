import 'package:content_store/content_store.dart';
import 'package:test/test.dart';

void main() {
  late MemoryStorageBackend backend;
  late ContentStore store;

  setUp(() async {
    backend = MemoryStorageBackend();
    store = ContentStore(backend: backend);
    await store.initialize();
  });

  tearDown(() => store.close());

  group('createContentType', () {
    test('creates a new content type', () async {
      final contentType = await store.createContentType(
        'a',
        ContentTypeData(fields: {'a': FieldSpec(type: FieldType.text)}),
      );

      expect(contentType.metadata.id, 'a');
      expect(contentType.metadata.type, EntityType.contentType);
      expect(
        contentType.metadata.createdAt.millisecondsSinceEpoch,
        closeTo(DateTime.now().millisecondsSinceEpoch, 100),
      );
      expect(contentType.metadata.updatedAt, isNull);
      expect(contentType.fields['a'], isNotNull);
      expect(contentType.fields['a']!.type, FieldType.text);
      expect(contentType.fields['a']!.required, isTrue);
    });

    test('throws when content type with given id already exists', () async {
      await store.createContentType('a', ContentTypeData(fields: {}));
      expect(
        store.createContentType('a', ContentTypeData(fields: {})),
        throwsA(isA<ContentStoreException>()),
      );
    });

    test('throws when id is invalid', () async {
      expect(
        store.createContentType(':', ContentTypeData(fields: {})),
        throwsA(isA<ContentStoreException>()),
      );
    });

    test('throws when content type is invalid', () async {
      expect(
        store.createContentType(
            'a',
            ContentTypeData(fields: {
              ':': FieldSpec(type: FieldType.text),
            })),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });

  group('getContentType', () {
    test('returns existing content type', () async {
      final contentType =
          await store.createContentType('a', ContentTypeData(fields: {}));
      expect(await store.getContentType('a'), contentType);
    });

    test('throws when content type does not exist', () async {
      expect(
        store.getContentType('a'),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });

  group('deleteContentType', () {
    test('deletes an existing content type', () async {
      await store.createContentType('a', ContentTypeData(fields: {}));
      await store.deleteContentType('a');

      expect(
        store.getContentType('a'),
        throwsA(isA<ContentStoreException>()),
      );
    });

    test('deleting non-existent content type is a noop', () async {
      await store.deleteContentType('a');
    });
  });

  group('createEntry', () {
    test('creates a new entry', () async {
      await store.createContentType(
        'a',
        ContentTypeData(fields: {'a': FieldSpec(type: FieldType.text)}),
      );

      final entry = await store.createEntry('a', EntryData(fields: {'a': 'a'}));

      expect(entry.metadata.type, EntityType.entry);
      expect(
        entry.metadata.createdAt.millisecondsSinceEpoch,
        closeTo(DateTime.now().millisecondsSinceEpoch, 100),
      );
      expect(entry.metadata.updatedAt, isNull);
      expect(entry.contentType.id, 'a');
      expect(entry.contentType.type, EntityType.contentType);
      expect(entry.fields, hasLength(1));
      expect(entry.fields['a'], 'a');
    });

    test('throws if entries fields are invalid', () async {
      await store.createContentType(
        'a',
        ContentTypeData(fields: {'a': FieldSpec(type: FieldType.text)}),
      );

      expect(
        store.createEntry('a', EntryData(fields: {'a': null})),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });

  group('getEntry', () {
    test('returns existing entry', () async {
      await store.createContentType(
        'a',
        ContentTypeData(fields: {'a': FieldSpec(type: FieldType.text)}),
      );

      final entry = await store.createEntry('a', EntryData(fields: {'a': 'a'}));

      expect(await store.getEntry(entry.metadata.id), entry);
    });

    test('throws when entry does not exist', () async {
      expect(
        store.getEntry('a'),
        throwsA(isA<ContentStoreException>()),
      );
    });
  });
}
