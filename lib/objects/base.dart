import 'dart:typed_data';

import 'package:flutter/material.dart';

abstract class Serializable {
  static int json_hashcode(Serializable o) => Object.hashAll(o.to_json().entries);

  static bool json_shallow_compare(Serializable o, Object other) {
    if (other is! Serializable || other.runtimeType != o.runtimeType) return false;

    Map<String, dynamic> json = o.to_json();
    Map<String, dynamic> other_json = other.to_json();
    for (MapEntry<String, dynamic> entry in json.entries) {
      if (other_json[entry.key] != entry.value) return false;
    }
    for (MapEntry<String, dynamic> entry in other_json.entries) {
      if (json[entry.key] != entry.value) return false;
    }
    return true;
  }

  const Serializable();

  Map<String, dynamic> to_json();

  @override
  int get hashCode => json_hashcode(this);

  @override
  bool operator ==(Object other) => json_shallow_compare(this, other);

  @override
  String toString() => "${runtimeType}(${to_json().map((key, value) => MapEntry(key, value is Uint8List ? "${value.lengthInBytes} bytes" : value)).toString()})";
}

abstract class DatabaseItem extends Serializable {
  const DatabaseItem();

  bool get is_new;

  Map<String, dynamic> to_edit_json();

  Future save(BuildContext context, [DatabaseItem? original]);
}

abstract class IDIdentifiable extends DatabaseItem {
  final int id;

  const IDIdentifiable({required this.id});

  @override
  bool get is_new => id < 0;
}
