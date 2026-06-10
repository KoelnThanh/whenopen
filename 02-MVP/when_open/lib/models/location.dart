import 'package:flutter/foundation.dart' show immutable;
import 'package:json_annotation/json_annotation.dart';

import 'kategorie.dart';
import 'opening_day.dart';
import 'wochentag.dart';

part 'location.g.dart';

/// Ein gespeicherter Ort mit Oeffnungszeiten (Schema 2.0).
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class Location {
  Location({
    required this.id,
    required this.name,
    required List<OpeningDay> oeffnungszeiten,
    this.adresse,
    this.telefon,
    this.googleMapsLink,
    this.kategorie,
    required this.erstelltAm,
    required this.geaendertAm,
  }) : oeffnungszeiten = vervollstaendigeWoche(oeffnungszeiten);

  final String id;
  final String name;

  /// Immer genau 7 Eintraege (Mo–So) — fehlende Tage werden beim
  /// Konstruieren als geschlossen aufgefuellt.
  final List<OpeningDay> oeffnungszeiten;

  final String? adresse;
  final String? telefon;
  final String? googleMapsLink;

  /// Kategorie-ID (E15). `null` = Auffang-Gruppe "Sonstige".
  final String? kategorie;

  final DateTime erstelltAm;
  final DateTime geaendertAm;

  /// Stellt sicher, dass alle 7 Wochentage vorhanden sind (Reihenfolge Mo–So).
  static List<OpeningDay> vervollstaendigeWoche(List<OpeningDay> tage) {
    return Wochentag.values
        .map((w) => tage.firstWhere(
              (t) => t.wochentag == w,
              orElse: () => OpeningDay.geschlossen(w),
            ))
        .toList();
  }

  OpeningDay tagFuer(Wochentag wochentag) =>
      oeffnungszeiten.firstWhere((t) => t.wochentag == wochentag);

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);

  Location copyWith({
    String? id,
    String? name,
    List<OpeningDay>? oeffnungszeiten,
    String? adresse,
    bool adresseLoeschen = false,
    String? telefon,
    bool telefonLoeschen = false,
    String? googleMapsLink,
    bool googleMapsLinkLoeschen = false,
    String? kategorie,
    bool kategorieLoeschen = false,
    DateTime? erstelltAm,
    DateTime? geaendertAm,
  }) =>
      Location(
        id: id ?? this.id,
        name: name ?? this.name,
        oeffnungszeiten: oeffnungszeiten ?? this.oeffnungszeiten,
        adresse: adresseLoeschen ? null : (adresse ?? this.adresse),
        telefon: telefonLoeschen ? null : (telefon ?? this.telefon),
        googleMapsLink: googleMapsLinkLoeschen
            ? null
            : (googleMapsLink ?? this.googleMapsLink),
        kategorie: kategorieLoeschen ? null : (kategorie ?? this.kategorie),
        erstelltAm: erstelltAm ?? this.erstelltAm,
        geaendertAm: geaendertAm ?? this.geaendertAm,
      );
}

/// Wurzelobjekt der JSON-Datei (Schema 2.0): version, kategorien, eintraege.
@immutable
@JsonSerializable()
class WhenOpenData {
  const WhenOpenData({
    this.version = WhenOpenData.schemaVersion,
    this.kategorien = const [],
    this.eintraege = const [],
  });

  static const schemaVersion = '2.0';

  final String version;
  final List<Kategorie> kategorien;
  final List<Location> eintraege;

  factory WhenOpenData.fromJson(Map<String, dynamic> json) =>
      _$WhenOpenDataFromJson(json);

  Map<String, dynamic> toJson() => _$WhenOpenDataToJson(this);

  WhenOpenData copyWith({
    String? version,
    List<Kategorie>? kategorien,
    List<Location>? eintraege,
  }) =>
      WhenOpenData(
        version: version ?? this.version,
        kategorien: kategorien ?? this.kategorien,
        eintraege: eintraege ?? this.eintraege,
      );
}
