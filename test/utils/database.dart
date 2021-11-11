import 'dart:convert';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';

Future<void> initCouchbaseLite() async {
  final tempDir = await Directory.systemTemp.createTemp();
  print('CBL temp dir ${tempDir.path}');

  await CouchbaseLiteDart.init(
    edition: Edition.community,
    filesDir: tempDir.path,
  );
}

extension DatabaseExt on Database {
  Stream<String> allDocumentIds() =>
      Future.sync(() => Query.fromN1ql(this, 'SELECT Meta().id FROM _'))
          .asStream()
          .asyncMap((query) => query.execute())
          .asyncExpand((resultSet) => resultSet.asStream())
          .map((result) => result.value(0)!);

  Future<void> deleteAllDocuments() async => inBatch(() async {
        await for (final id in allDocumentIds()) {
          await deleteDocument((await document(id))!);
        }
      });

  Future<void> deleteAllIndexes() async {
    for (final index in await indexes) {
      await deleteIndex(index);
    }
  }

  Future<void> dump() async {
    final jsonEncoder = JsonEncoder.withIndent('  ');
    await for (final id in allDocumentIds()) {
      final doc = await document(id);
      print(jsonEncoder.convert({
        'id': doc!.id,
        'revisionId': doc.revisionId,
        'sequence': doc.sequence,
        'properties': doc.toPlainMap(),
      }));
    }
  }
}
