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
  });

  tearDown(() => store.close());

  test('create entry', () async {
    final contentType = ContentTypeData(fields: {
      'a': FieldSpec(type: FieldType.text),
    });
    await store.createContentType('a', contentType);
    await store.createEntry('a', EntryData(fields: {'a': 'b'}));

    await db.dump();
  });
}
