import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'entity.dart';

enum FieldType {
  text,
  integer,
}

@immutable
class FieldSpec {
  FieldSpec({
    required this.type,
    this.required = true,
  });

  final FieldType type;

  final bool required;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldSpec &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          required == other.required;

  @override
  int get hashCode => type.hashCode ^ required.hashCode;

  @override
  String toString() => 'FieldSpec(type: $type, required: $required)';
}

@immutable
class ContentTypeData {
  ContentTypeData({required this.label, required Map<String, FieldSpec> fields})
      : fields = UnmodifiableMapView(fields);

  final String label;

  final Map<String, FieldSpec> fields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentTypeData &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          const DeepCollectionEquality().equals(fields, other.fields);

  @override
  int get hashCode =>
      label.hashCode ^ const DeepCollectionEquality().hash(fields);

  @override
  String toString() => 'ContentTypeData(fields: $fields)';
}

@immutable
class ContentType extends ContentTypeData implements Entity {
  ContentType({
    required this.metadata,
    required String label,
    required Map<String, FieldSpec> fields,
  })  : assert(metadata.type == EntityType.contentType),
        super(label: label, fields: fields);

  @override
  final EntityMetadata metadata;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentType &&
          runtimeType == other.runtimeType &&
          metadata == other.metadata &&
          label == other.label &&
          const DeepCollectionEquality().equals(fields, other.fields);

  @override
  int get hashCode =>
      metadata.hashCode ^
      label.hashCode ^
      const DeepCollectionEquality().hash(fields);

  @override
  String toString() =>
      'ContentType(metadata: $metadata, label: $label, fields: $fields)';
}
