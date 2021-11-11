import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'entity.dart';

@immutable
class EntryData {
  EntryData({required this.fields});

  final Map<String, Object?> fields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryData &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(fields, other.fields);

  @override
  int get hashCode => const DeepCollectionEquality().hash(fields);

  @override
  String toString() => 'EntryData(fields: $fields)';
}

@immutable
class Entry extends EntryData implements Entity {
  Entry({
    required this.metadata,
    required this.contentType,
    required Map<String, Object?> fields,
  }) : super(fields: fields);

  @override
  final EntityMetadata metadata;

  final EntityRef contentType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entry &&
          runtimeType == other.runtimeType &&
          metadata == other.metadata &&
          contentType == other.contentType &&
          const DeepCollectionEquality().equals(fields, other.fields);

  @override
  int get hashCode =>
      metadata.hashCode ^
      contentType.hashCode ^
      const DeepCollectionEquality().hash(fields);

  @override
  String toString() => 'Entry(metadata: $metadata, contentType: $contentType, '
      'fields: $fields)';
}
