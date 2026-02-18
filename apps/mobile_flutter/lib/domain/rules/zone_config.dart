/// Static zone configuration describing season boundaries per region and
/// elevation band.  Week numbers follow ISO-8601 (1-52/53).
///
/// Currently only Suedtirol is configured.  Additional regions can be added
/// to [ZoneConfig.zones] without changing any other code.

class SeasonConfig {
  /// First week where meaningful outdoor work begins (Auswinterung).
  final int seasonStartWeek;

  /// First and last week of the swarm-control window.
  final int swarmStartWeek;
  final int swarmEndWeek;

  /// Summer harvest window (start/end).
  final int summerStartWeek;
  final int summerEndWeek;

  /// Varroa monitoring window (start/end).
  final int varroaStartWeek;
  final int varroaEndWeek;

  /// Autumn feeding/wintering window (start/end).
  final int autumnStartWeek;
  final int autumnEndWeek;

  /// Week at which true winter rest begins.
  final int winterStartWeek;

  const SeasonConfig({
    required this.seasonStartWeek,
    required this.swarmStartWeek,
    required this.swarmEndWeek,
    required this.summerStartWeek,
    required this.summerEndWeek,
    required this.varroaStartWeek,
    required this.varroaEndWeek,
    required this.autumnStartWeek,
    required this.autumnEndWeek,
    required this.winterStartWeek,
  });

  /// Whether [week] falls within the spring inspection window
  /// (seasonStart .. swarmStart-1).
  bool isSpring(int week) =>
      week >= seasonStartWeek && week < swarmStartWeek;

  /// Whether [week] falls within the swarm season.
  bool isSwarmSeason(int week) =>
      week >= swarmStartWeek && week <= swarmEndWeek;

  /// Whether [week] falls within the summer / harvest window.
  bool isSummer(int week) =>
      week >= summerStartWeek && week <= summerEndWeek;

  /// Whether [week] falls within the varroa monitoring window.
  bool isVarroaWindow(int week) =>
      week >= varroaStartWeek && week <= varroaEndWeek;

  /// Whether [week] falls in the autumn / feeding window.
  bool isAutumn(int week) =>
      week >= autumnStartWeek && week <= autumnEndWeek;

  /// Whether [week] falls in winter rest.
  bool isWinter(int week) =>
      week >= winterStartWeek || week < seasonStartWeek;
}

class ZoneConfig {
  ZoneConfig._();

  /// All known zone/elevation combinations.
  ///
  /// Key 1: region slug (e.g. "suedtirol").
  /// Key 2: elevation band ("low", "mid", "high").
  static const Map<String, Map<String, SeasonConfig>> zones = {
    'suedtirol': {
      // ---- Tallage / fondovalle  (< 700 m) ----
      'low': SeasonConfig(
        seasonStartWeek: 10,  // early March
        swarmStartWeek: 16,   // mid April
        swarmEndWeek: 26,     // end June
        summerStartWeek: 24,  // mid June
        summerEndWeek: 32,    // early August
        varroaStartWeek: 25,  // late June
        varroaEndWeek: 40,    // early October
        autumnStartWeek: 36,  // early September
        autumnEndWeek: 44,    // end October
        winterStartWeek: 45,  // November
      ),
      // ---- Mittellage / mezza montagna  (700-1200 m) ----
      'mid': SeasonConfig(
        seasonStartWeek: 12,  // late March
        swarmStartWeek: 18,   // early May
        swarmEndWeek: 28,     // mid July
        summerStartWeek: 26,  // late June
        summerEndWeek: 34,    // late August
        varroaStartWeek: 27,  // early July
        varroaEndWeek: 40,    // early October
        autumnStartWeek: 36,  // early September
        autumnEndWeek: 44,    // end October
        winterStartWeek: 45,  // November
      ),
      // ---- Hochlage / alta montagna  (> 1200 m) ----
      'high': SeasonConfig(
        seasonStartWeek: 14,  // early April
        swarmStartWeek: 20,   // mid May
        swarmEndWeek: 30,     // late July
        summerStartWeek: 28,  // mid July
        summerEndWeek: 34,    // late August
        varroaStartWeek: 29,  // mid July
        varroaEndWeek: 40,    // early October
        autumnStartWeek: 36,  // early September
        autumnEndWeek: 44,    // end October
        winterStartWeek: 44,  // late October
      ),
    },
  };

  /// Convenience lookup that returns `null` when region or band is unknown.
  static SeasonConfig? lookup(String region, String elevationBand) {
    return zones[region]?[elevationBand];
  }
}
