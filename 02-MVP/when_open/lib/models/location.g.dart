// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  id: json['id'] as String,
  name: json['name'] as String,
  oeffnungszeiten: (json['oeffnungszeiten'] as List<dynamic>)
      .map((e) => OpeningDay.fromJson(e as Map<String, dynamic>))
      .toList(),
  adresse: json['adresse'] as String?,
  telefon: json['telefon'] as String?,
  googleMapsLink: json['google_maps_link'] as String?,
  kategorie: json['kategorie'] as String?,
  erstelltAm: DateTime.parse(json['erstellt_am'] as String),
  geaendertAm: DateTime.parse(json['geaendert_am'] as String),
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'oeffnungszeiten': instance.oeffnungszeiten,
  'adresse': instance.adresse,
  'telefon': instance.telefon,
  'google_maps_link': instance.googleMapsLink,
  'kategorie': instance.kategorie,
  'erstellt_am': instance.erstelltAm.toIso8601String(),
  'geaendert_am': instance.geaendertAm.toIso8601String(),
};

WhenOpenData _$WhenOpenDataFromJson(Map<String, dynamic> json) => WhenOpenData(
  version: json['version'] as String? ?? WhenOpenData.schemaVersion,
  kategorien:
      (json['kategorien'] as List<dynamic>?)
          ?.map((e) => Kategorie.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  eintraege:
      (json['eintraege'] as List<dynamic>?)
          ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WhenOpenDataToJson(WhenOpenData instance) =>
    <String, dynamic>{
      'version': instance.version,
      'kategorien': instance.kategorien,
      'eintraege': instance.eintraege,
    };
