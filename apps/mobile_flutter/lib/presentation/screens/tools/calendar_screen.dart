import 'package:flutter/material.dart';

const _kAmber = Color(0xFFFFA000);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _expandedMonth = DateTime.now().month - 1; // 0-indexed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Bienenkalender'),
        backgroundColor: const Color(0xFF1A0E00),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _months.length,
        itemBuilder: (context, i) {
          final month = _months[i];
          final isExpanded = _expandedMonth == i;
          final isCurrent = i == DateTime.now().month - 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent ? _kAmber : Colors.transparent,
                width: isCurrent ? 2 : 0,
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 1))
              ],
            ),
            child: Column(
              children: [
                // Header
                InkWell(
                  onTap: () => setState(
                    () => _expandedMonth = isExpanded ? -1 : i,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: month.color.withAlpha(35),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(month.icon,
                              color: month.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    month.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _kAmber,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Jetzt',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                month.phase,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded tasks
                if (isExpanded) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Priority tasks
                        if (month.priority.isNotEmpty) ...[
                          _CategoryHeader(
                              label: 'Priorität',
                              color: Colors.red.shade700),
                          ...month.priority.map((t) => _TaskTile(
                              text: t,
                              color: Colors.red.shade700)),
                          const SizedBox(height: 8),
                        ],
                        // Regular tasks
                        if (month.tasks.isNotEmpty) ...[
                          _CategoryHeader(
                              label: 'Aufgaben', color: _kAmber),
                          ...month.tasks
                              .map((t) => _TaskTile(text: t, color: _kAmber)),
                          const SizedBox(height: 8),
                        ],
                        // Tips
                        if (month.tips.isNotEmpty) ...[
                          _CategoryHeader(
                              label: 'Tipps', color: Colors.teal),
                          ...month.tips
                              .map((t) => _TaskTile(text: t, color: Colors.teal)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String text;
  final Color color;

  const _TaskTile({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13.5, color: Color(0xFF2C2C2C)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar data ─────────────────────────────────────────────────────────────

class _Month {
  final String name;
  final String phase;
  final IconData icon;
  final Color color;
  final List<String> priority;
  final List<String> tasks;
  final List<String> tips;

  const _Month({
    required this.name,
    required this.phase,
    required this.icon,
    required this.color,
    this.priority = const [],
    this.tasks = const [],
    this.tips = const [],
  });
}

const _months = [
  _Month(
    name: 'Januar',
    phase: 'Winterruhe',
    icon: Icons.ac_unit,
    color: Colors.blueGrey,
    tasks: [
      'Gewicht der Beute kontrollieren (min. 8 kg Futter)',
      'Eingang auf tote Bienen oder Schnee prüfen',
      'Feuchtigkeit und Kondensation beobachten',
    ],
    tips: [
      'Nicht öffnen unter 8 °C',
      'Mäuseschutzgitter eingebaut lassen',
      'Geräte reinigen und reparieren',
    ],
  ),
  _Month(
    name: 'Februar',
    phase: 'Frühjahrserwachen',
    icon: Icons.wb_sunny_outlined,
    color: Colors.lightBlue,
    tasks: [
      'Erste Reinigungsflüge ermöglichen (> 8 °C)',
      'Tote Bienen am Flugloch entfernen',
      'Frühblüher in der Umgebung beachten (Weide, Hasel)',
    ],
    tips: [
      'Noch keine Durchsicht!',
      'Haselpollen beobachten = Frühlingssignal',
      'Futtervorrat bei Bedarf ergänzen',
    ],
  ),
  _Month(
    name: 'März',
    phase: 'Brutbeginn',
    icon: Icons.eco,
    color: Colors.green,
    tasks: [
      'Erste Frühjahrsdurchsicht ab 12 °C',
      'Brutnest kontrollieren, Legeleistung der Königin prüfen',
      'Futtervorrat abschätzen, ggf. Futterteig geben',
    ],
    priority: [
      'Varroa-Messung durchführen (Alkoholwaschung)',
    ],
    tips: [
      'Brutfläche sollte wachsen (gutes Zeichen)',
      'Aufwärmen der Beute hilft dem Brutnest',
    ],
  ),
  _Month(
    name: 'April',
    phase: 'Volksaufbau',
    icon: Icons.trending_up,
    color: Colors.teal,
    tasks: [
      'Regelmäßige Kontrollen alle 7–10 Tage',
      'Erweiterte Zargen bereitstellen',
      'Schwarmstimmung beobachten',
    ],
    priority: [
      'Schwarmkontrolle beginnt ab Mitte April',
    ],
    tips: [
      'Honigraumaufsetzen wenn 5–6 Waben bedeckt',
      'Ableger aus schwarmwilligen Völkern bilden',
    ],
  ),
  _Month(
    name: 'Mai',
    phase: 'Schwarmzeit / Hauptentwicklung',
    icon: Icons.air,
    color: Colors.amber,
    tasks: [
      'Alle 7 Tage Schwarmkontrolle',
      'Bei Schwarmstimmung: Ableger oder Kunstschwarm bilden',
      'Honigraum je nach Tracht erweitern',
    ],
    priority: [
      'Keine Weiselzellen übersehen!',
    ],
    tips: [
      'Gute Zeit für Jungköniginnen-Zucht',
      'Erster Honig (Raps) kann geerntet werden',
    ],
  ),
  _Month(
    name: 'Juni',
    phase: 'Honigsaison',
    icon: Icons.emoji_nature,
    color: _kAmber,
    tasks: [
      'Rapshonig rechtzeitig ernten (kristallisiert schnell)',
      'Honigraum beobachten und erweitern',
      'Weiterhin Schwarmkontrolle',
    ],
    tips: [
      'Lindentracht im Anmarsch',
      'Gute Zeit für Ableger-Bildung',
    ],
  ),
  _Month(
    name: 'Juli',
    phase: 'Ernte & Sommer',
    icon: Icons.local_dining,
    color: Colors.deepOrange,
    tasks: [
      'Honigernte und Schleudern',
      'Sommerfütterung vorbereiten',
      'Varroa-Behandlung planen (AS oder Thymol)',
    ],
    priority: [
      'Varroa-Befallskontrolle nach Ernte',
    ],
    tips: [
      'Winterbienen entstehen ab August – jetzt Völkerstärke aufbauen',
      'Behandlung nicht zu spät beginnen',
    ],
  ),
  _Month(
    name: 'August',
    phase: 'Einwinterungsvorbereitung',
    icon: Icons.restaurant,
    color: Colors.orange,
    tasks: [
      'Intensive Sommerfütterung (mind. 15 kg Zucker pro Volk)',
      'Varroa-Behandlung durchführen (AS 60%, Thymol, Oxalsäure)',
    ],
    priority: [
      'Varroa-Behandlung: kritischster Monat des Jahres!',
      'Spätestens jetzt füttern – Winterbienen entstehen!',
    ],
    tips: [
      'Jedes kg weniger Futter jetzt = kranke Winterbienen',
      'Adulte Varroa muss jetzt bekämpft werden',
    ],
  ),
  _Month(
    name: 'September',
    phase: 'Einwinterung',
    icon: Icons.park,
    color: Colors.brown,
    tasks: [
      'Futtervorrat abschließen und sicherstellen',
      'Varroa-Restbefall messen (Windel)',
      'Mäuseschutzgitter montieren',
    ],
    priority: [
      'Völker müssen mind. 20 kg Futter eingelagert haben',
    ],
    tips: [
      'Öffnung auf 1 Finger einengen',
      'Volk sollte mind. 5 Wabengassen bedecken',
    ],
  ),
  _Month(
    name: 'Oktober',
    phase: 'Wintervorbereitung',
    icon: Icons.cabin,
    color: Colors.deepOrangeAccent,
    tasks: [
      'Endgültige Einwinterung',
      'Eingang einengen / Mäuseschutz',
      'Windschutz aufstellen',
    ],
    priority: [
      'Oxalsäure-Träufelbehandlung bei brutfreien Völkern',
    ],
    tips: [
      'Letzte Oxalsäurebehandlung der Saison',
      'Beuten gegen Feuchtigkeit sichern',
    ],
  ),
  _Month(
    name: 'November',
    phase: 'Winterruhe',
    icon: Icons.nights_stay,
    color: Colors.indigo,
    tasks: [
      'Gelegentliche Gewichtskontrolle',
      'Gerätedesinfektion und -wartung',
      'Jahresplan für nächste Saison aufstellen',
    ],
    tips: [
      'Nicht stören – Wintertraube ist gebildet',
      'Klopftest zur Völkerkontrolle',
    ],
  ),
  _Month(
    name: 'Dezember',
    phase: 'Ruhezeit',
    icon: Icons.ac_unit,
    color: Colors.blueAccent,
    tasks: [
      'Ausrüstung warten und reparieren',
      'Bestellungen für nächste Saison aufgeben',
      'Imkerkurse, Bücher, Netzwerke',
    ],
    tips: [
      'Ruhezeit für Imker und Bienen',
      'Gute Zeit für Weiterbildung',
    ],
  ),
];
