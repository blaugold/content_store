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
        ContentTypeData(fields: {
          'a': FieldSpec(type: FieldType.text),
        }),
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
  });
}
