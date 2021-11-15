import 'package:cbl/cbl.dart';
import 'package:content_store/content_store.dart';
import 'package:test/test.dart';

import 'utils/database.dart';

void main() {
  late final Database db;
  late CblStorageBackend backend;
  late ContentStore store;

  setUpAll(() async {
    await initCouchbaseLite();
    db = await Database.openAsync('test');
  });

  setUp(() async {
    await db.deleteAllIndexes();
    await db.deleteAllDocuments();

    backend = CblStorageBackend(database: db);
    store = ContentStore(backend: backend);
    await store.initialize();
    addTearDown(store.close);
  });

  test('create content type', () async {
    final contentType = await store.createContentType(ContentTypeData(
      label: 'a',
      fields: {'a': FieldSpec(type: FieldType.text)},
    ));

    expect(await store.getContentType(contentType.meta.id), contentType);
  });

  test('delete content type', () async {
    final contentType = await store.createContentType(ContentTypeData(
      label: 'a',
      fields: {'a': FieldSpec(type: FieldType.text)},
    ));
    await store.deleteContentType(contentType.meta.id);

    expect(
      store.getContentType(contentType.meta.id),
      throwsA(isA<ContentStoreException>()),
    );
  });

  test('create entry', () async {
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
}
