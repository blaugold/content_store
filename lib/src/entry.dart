import 'entity.dart';

class EntryData {
  EntryData({required this.fields});

  final Map<String, Object?> fields;
}

class Entry extends EntryData implements Entity {
  Entry({
    required this.metadata,
    required this.contentType,
    required Map<String, Object?> fields,
  }) : super(fields: fields);

  @override
  final EntityMetadata metadata;

  final EntityRef contentType;
}
