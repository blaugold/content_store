import 'dart:collection';

import 'entity.dart';

enum FieldType {
  text,
  integer,
}

class FieldSpec {
  FieldSpec({
    required this.type,
    this.required = true,
  });

  final FieldType type;
  final bool required;
}

class ContentTypeData {
  ContentTypeData({required Map<String, FieldSpec> fields})
      : fields = UnmodifiableMapView(fields);

  final Map<String, FieldSpec> fields;
}

class ContentType extends ContentTypeData implements Entity {
  ContentType({
    required this.metadata,
    required Map<String, FieldSpec> fields,
  })  : assert(metadata.type == EntityType.contentType),
        super(fields: fields);

  @override
  final EntityMetadata metadata;
}
