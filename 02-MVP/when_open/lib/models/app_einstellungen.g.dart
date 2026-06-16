// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_einstellungen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppEinstellungen _$AppEinstellungenFromJson(Map<String, dynamic> json) =>
    AppEinstellungen(
      heimatAdresse: json['heimat_adresse'] as String?,
      heimatLat: (json['heimat_lat'] as num?)?.toDouble(),
      heimatLon: (json['heimat_lon'] as num?)?.toDouble(),
      umkreisMeter:
          (json['umkreis_meter'] as num?)?.toInt() ??
          AppEinstellungen.standardUmkreis,
      tutorialStatus:
          $enumDecodeNullable(
            _$TutorialStatusEnumMap,
            json['tutorial_status'],
            unknownValue: TutorialStatus.offen,
          ) ??
          TutorialStatus.offen,
      spendenhinweisGezeigt: json['spendenhinweis_gezeigt'] as bool? ?? false,
      themeModus:
          $enumDecodeNullable(
            _$ThemeModusEnumMap,
            json['theme_modus'],
            unknownValue: ThemeModus.system,
          ) ??
          ThemeModus.system,
    );

Map<String, dynamic> _$AppEinstellungenToJson(AppEinstellungen instance) =>
    <String, dynamic>{
      'heimat_adresse': instance.heimatAdresse,
      'heimat_lat': instance.heimatLat,
      'heimat_lon': instance.heimatLon,
      'umkreis_meter': instance.umkreisMeter,
      'tutorial_status': _$TutorialStatusEnumMap[instance.tutorialStatus]!,
      'spendenhinweis_gezeigt': instance.spendenhinweisGezeigt,
      'theme_modus': _$ThemeModusEnumMap[instance.themeModus]!,
    };

const _$TutorialStatusEnumMap = {
  TutorialStatus.offen: 'offen',
  TutorialStatus.abgelehnt: 'abgelehnt',
  TutorialStatus.abgeschlossen: 'abgeschlossen',
};

const _$ThemeModusEnumMap = {
  ThemeModus.system: 'system',
  ThemeModus.hell: 'hell',
  ThemeModus.dunkel: 'dunkel',
};
