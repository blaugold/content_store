extension EnumExt<T extends Enum> on T {
  String get name => toString().split('.').last;
}

extension EnumValuesExt<T extends Enum> on Iterable<T> {
  T byName(String name) => firstWhere((e) => e.name == name);
}
