import 'dart:convert';

/// What one person's emergency card on the home screen shows. Everything
/// that can identify a medical detail is something the person turned on;
/// medicines start off.
class CardOptions {
  const CardOptions({
    this.bloodGroup = true,
    this.allergies = true,
    this.medicines = false,
    this.dial = true,
    this.dialContact = 0,
  });

  final bool bloodGroup;
  final bool allergies;
  final bool medicines;
  final bool dial;

  /// Index into the person's emergency contacts.
  final int dialContact;

  CardOptions copyWith({
    bool? bloodGroup,
    bool? allergies,
    bool? medicines,
    bool? dial,
    int? dialContact,
  }) => CardOptions(
    bloodGroup: bloodGroup ?? this.bloodGroup,
    allergies: allergies ?? this.allergies,
    medicines: medicines ?? this.medicines,
    dial: dial ?? this.dial,
    dialContact: dialContact ?? this.dialContact,
  );

  Map<String, Object> toJson() => {
    'bloodGroup': bloodGroup,
    'allergies': allergies,
    'medicines': medicines,
    'dial': dial,
    'dialContact': dialContact,
  };

  factory CardOptions.fromJson(Map<String, dynamic> j) => CardOptions(
    bloodGroup: j['bloodGroup'] as bool? ?? true,
    allergies: j['allergies'] as bool? ?? true,
    medicines: j['medicines'] as bool? ?? false,
    dial: j['dial'] as bool? ?? true,
    dialContact: j['dialContact'] as int? ?? 0,
  );
}

/// Device-local choices for the home screen widgets. Kept in the small
/// settings store, not in the database, so a restore never turns cards on:
/// they start off, and a person opts in.
class WidgetSettings {
  const WidgetSettings({this.enabled = false, this.cards = const {}});

  /// Master switch. While off, nothing is copied for the widgets.
  final bool enabled;

  /// Options by person id; a person without an entry uses the defaults.
  final Map<String, CardOptions> cards;

  static const storeKey = 'widget_cards';

  CardOptions optionsFor(String personId) => cards[personId] ?? const CardOptions();

  WidgetSettings withEnabled(bool on) => WidgetSettings(enabled: on, cards: cards);

  WidgetSettings withOptions(String personId, CardOptions options) =>
      WidgetSettings(enabled: enabled, cards: {...cards, personId: options});

  String encode() => jsonEncode({
    'enabled': enabled,
    'cards': {for (final e in cards.entries) e.key: e.value.toJson()},
  });

  /// A missing or damaged value is the safe default: off.
  static WidgetSettings decode(String? stored) {
    if (stored == null) return const WidgetSettings();
    try {
      final j = jsonDecode(stored) as Map<String, dynamic>;
      return WidgetSettings(
        enabled: j['enabled'] as bool? ?? false,
        cards: {
          for (final e in (j['cards'] as Map<String, dynamic>? ?? {}).entries)
            e.key: CardOptions.fromJson(e.value as Map<String, dynamic>),
        },
      );
    } on Object {
      return const WidgetSettings();
    }
  }
}
