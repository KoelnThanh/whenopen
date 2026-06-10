// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kategorie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Kategorie _$KategorieFromJson(Map<String, dynamic> json) => Kategorie(
  id: json['id'] as String,
  name: json['name'] as String,
  farbe: json['farbe'] as String?,
  sortierung: (json['sortierung'] as num).toInt(),
);

Map<String, dynamic> _$KategorieToJson(Kategorie instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'farbe': instance.farbe,
  'sortierung': instance.sortierung,
};
