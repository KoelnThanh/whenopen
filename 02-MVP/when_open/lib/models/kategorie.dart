import 'package:flutter/foundation.dart' show immutable;
import 'package:json_annotation/json_annotation.dart';

part 'kategorie.g.dart';

/// Verwaltete Kategorie (E15) mit stabiler ID.
/// "Sonstige" ist KEIN Datensatz — Eintraege mit `kategorie == null`
/// fallen implizit in diese Auffang-Gruppe.
@immutable
@JsonSerializable()
class Kategorie {
  const Kategorie({
    required this.id,
    required this.name,
    this.farbe,
    required this.sortierung,
  });

  final String id;
  final String name;

  /// Hex-Farbe (z.B. "#5b8def") fuer Wiedererkennung in Liste und Widget.
  final String? farbe;

  /// Reihenfolge in Liste/Widget.
  final int sortierung;

  factory Kategorie.fromJson(Map<String, dynamic> json) =>
      _$KategorieFromJson(json);

  Map<String, dynamic> toJson() => _$KategorieToJson(this);

  Kategorie copyWith({
    String? id,
    String? name,
    String? farbe,
    bool farbeLoeschen = false,
    int? sortierung,
  }) =>
      Kategorie(
        id: id ?? this.id,
        name: name ?? this.name,
        farbe: farbeLoeschen ? null : (farbe ?? this.farbe),
        sortierung: sortierung ?? this.sortierung,
      );
}
