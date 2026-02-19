import 'package:flutter/material.dart';

const _kAmber = Color(0xFFFFA000);
const _kBg = Color(0xFFF8F9FA);

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          title: const Text('Imkerrechner'),
          backgroundColor: const Color(0xFF1A0E00),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: _kAmber,
            unselectedLabelColor: Colors.white54,
            indicatorColor: _kAmber,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Futtersirup'),
              Tab(text: 'Wintervorrat'),
              Tab(text: 'Wassertränke'),
              Tab(text: 'Oxalsäure'),
              Tab(text: 'Völkerstärke'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SyrupCalculator(),
            _WinterFoodCalculator(),
            _WaterCalculator(),
            _OxalicAcidCalculator(),
            _ColonyStrengthCalculator(),
          ],
        ),
      ),
    );
  }
}

// ── Syrup Calculator ─────────────────────────────────────────────────────────

class _SyrupCalculator extends StatefulWidget {
  const _SyrupCalculator();

  @override
  State<_SyrupCalculator> createState() => _SyrupCalculatorState();
}

class _SyrupCalculatorState extends State<_SyrupCalculator> {
  final _sugarCtrl = TextEditingController(text: '5');
  String _ratio = '3:2';

  double get sugar => double.tryParse(_sugarCtrl.text) ?? 0;

  double get water =>
      _ratio == '3:2' ? sugar * 2 / 3 : sugar;

  double get total => sugar + water;

  @override
  void dispose() {
    _sugarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCard(
            icon: Icons.water_drop,
            title: 'Zuckerwasser-Rechner',
            subtitle:
                '3:2 = Herbst-/Winterfutter  ·  1:1 = Frühlingsstimulation',
          ),
          const SizedBox(height: 16),

          _InputCard(
            label: 'Zuckermenge (kg)',
            controller: _sugarCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Ratio selector
          Row(
            children: ['3:2', '1:1'].map((r) {
              final selected = _ratio == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _ratio = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? _kAmber : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? _kAmber : Colors.grey.shade300),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: _kAmber.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Verhältnis $r',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                        Text(
                          r == '3:2' ? 'Herbst / Winter' : 'Frühling',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Results
          if (sugar > 0) ...[
            _ResultCard(
              items: [
                _ResultItem(
                  label: 'Wassermenge',
                  value: '${water.toStringAsFixed(2)} kg',
                  icon: Icons.water,
                  color: Colors.blue,
                ),
                _ResultItem(
                  label: 'Gesamtsirup',
                  value: '${total.toStringAsFixed(2)} kg',
                  icon: Icons.local_drink,
                  color: _kAmber,
                ),
                _ResultItem(
                  label: 'Ca. Liter',
                  value: '≈ ${(total * 0.77).toStringAsFixed(1)} L',
                  icon: Icons.science,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoBox(
              text: _ratio == '3:2'
                  ? '3:2 Sirup: ${water.toStringAsFixed(1)} L Wasser auf ${sugar.toStringAsFixed(1)} kg Zucker erhitzen, umrühren bis aufgelöst. '
                      'Abkühlen lassen vor dem Füttern.'
                  : '1:1 Sirup: ${water.toStringAsFixed(1)} L Wasser auf ${sugar.toStringAsFixed(1)} kg Zucker, '
                      'kalt oder warm auflösen. Als Frühjahrsstimulation.',
            ),
          ],
        ],
      ),
    );
  }
}

// ── Winter Food Calculator ────────────────────────────────────────────────────

class _WinterFoodCalculator extends StatefulWidget {
  const _WinterFoodCalculator();

  @override
  State<_WinterFoodCalculator> createState() => _WinterFoodCalculatorState();
}

class _WinterFoodCalculatorState extends State<_WinterFoodCalculator> {
  final _hivesCtrl = TextEditingController(text: '3');
  String _region = 'Mitteleuropa';

  // kg needed per colony by region
  static const _regionKg = {
    'Mitteleuropa': 15.0,
    'Nord/Berglagen': 20.0,
    'Süd/mild': 12.0,
  };

  int get hives => int.tryParse(_hivesCtrl.text) ?? 0;
  double get kgPerHive => _regionKg[_region] ?? 15.0;
  double get totalKg => hives * kgPerHive;
  double get sugarKg => totalKg * 0.72; // ~72% sugar in candy/syrup
  double get waterL => totalKg * 0.28 * 0.77;

  @override
  void dispose() {
    _hivesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCard(
            icon: Icons.kitchen,
            title: 'Wintervorrat-Rechner',
            subtitle: 'Mindestfuttermenge für sicheres Überwintern',
          ),
          const SizedBox(height: 16),

          _InputCard(
            label: 'Anzahl Völker',
            controller: _hivesCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Region selector
          Column(
            children: _regionKg.keys.map((r) {
              final selected = _region == r;
              return GestureDetector(
                onTap: () => setState(() => _region = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? _kAmber : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? _kAmber : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: selected ? Colors.white : Colors.grey,
                          size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey[700],
                            )),
                      ),
                      Text(
                        '${_regionKg[r]!.toStringAsFixed(0)} kg/Volk',
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? Colors.white70
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          if (hives > 0) ...[
            _ResultCard(
              items: [
                _ResultItem(
                  label: 'Gesamtfuttermenge',
                  value: '${totalKg.toStringAsFixed(1)} kg',
                  icon: Icons.kitchen,
                  color: _kAmber,
                ),
                _ResultItem(
                  label: 'Zucker benötigt',
                  value: '${sugarKg.toStringAsFixed(1)} kg',
                  icon: Icons.grain,
                  color: Colors.orange,
                ),
                _ResultItem(
                  label: 'Wasser für 3:2 Sirup',
                  value: '≈ ${waterL.toStringAsFixed(1)} L',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoBox(
              text: 'Einwinterung August/September: Völker brauchen '
                  'mind. ${kgPerHive.toStringAsFixed(0)} kg Futter für $_region.\n'
                  'Gewichtswaage empfehlenswert: Zielgewicht Magazinvolk ~30–35 kg.',
            ),
          ],
        ],
      ),
    );
  }
}

// ── Water Calculator ──────────────────────────────────────────────────────────

class _WaterCalculator extends StatefulWidget {
  const _WaterCalculator();

  @override
  State<_WaterCalculator> createState() => _WaterCalculatorState();
}

class _WaterCalculatorState extends State<_WaterCalculator> {
  double _hives = 3.0;
  String _season = 'Sommer';

  // Liters per colony per day by season
  static const _lPerDay = {
    'Frühjahr': 0.2,
    'Sommer': 0.5,
    'Brutzeit (heiß)': 1.0,
  };

  double get lPerDay => (_lPerDay[_season] ?? 0.5) * _hives;
  double get lPerWeek => lPerDay * 7;
  // Tränkenvolumen: gängige Volierenbehälter 5–20L
  int get containerRefills => (lPerWeek / 5).ceil();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCard(
            icon: Icons.water,
            title: 'Wassertränke-Rechner',
            subtitle: 'Süßwasserbedarf deiner Bienen',
          ),
          const SizedBox(height: 16),

          // Hive count slider
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 1))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Anzahl Völker',
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600)),
                    Text(
                      _hives.round().toString(),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E)),
                    ),
                  ],
                ),
                Slider(
                  value: _hives,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.blue.withAlpha(40),
                  onChanged: (v) => setState(() => _hives = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Season selector
          Column(
            children: _lPerDay.keys.map((s) {
              final selected = _season == s;
              return GestureDetector(
                onTap: () => setState(() => _season = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected
                            ? Colors.blue
                            : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.thermostat,
                          color:
                              selected ? Colors.white : Colors.grey,
                          size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey[700],
                            )),
                      ),
                      Text(
                        '${_lPerDay[s]!.toStringAsFixed(1)} L/Volk/Tag',
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? Colors.white70
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          _ResultCard(
            items: [
              _ResultItem(
                label: 'Tagesbedarf gesamt',
                value: '${lPerDay.toStringAsFixed(1)} L/Tag',
                icon: Icons.today,
                color: Colors.blue,
              ),
              _ResultItem(
                label: 'Wochenbedarf',
                value: '${lPerWeek.toStringAsFixed(1)} L/Woche',
                icon: Icons.date_range,
                color: Colors.lightBlue,
              ),
              _ResultItem(
                label: 'Nachfüllungen (5-L-Tränke)',
                value: '$containerRefills× pro Woche',
                icon: Icons.water,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoBox(
            text: 'Bienen brauchen frisches, sauberes Wasser – '
                'besonders bei Brutpflege und Hitze.\n'
                'Tränke nahe am Stand aufstellen (max. 200 m).\n'
                'Schwimmkork oder Steine einlegen damit Bienen nicht ertrinken.',
          ),
        ],
      ),
    );
  }
}

// ── Oxalic Acid Calculator ────────────────────────────────────────────────────

class _OxalicAcidCalculator extends StatefulWidget {
  const _OxalicAcidCalculator();

  @override
  State<_OxalicAcidCalculator> createState() => _OxalicAcidCalculatorState();
}

class _OxalicAcidCalculatorState extends State<_OxalicAcidCalculator> {
  final _hivesCtrl = TextEditingController(text: '3');
  String _method = 'Träufeln';

  int get hives => int.tryParse(_hivesCtrl.text) ?? 0;

  @override
  void dispose() {
    _hivesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Träufeln: 3.5% OA solution, 5 ml per hive interval (max 50 ml / colony)
    // Verdampfen: 1 g OA dihydrate per colony (broodless)
    final mlPerHive = _method == 'Träufeln' ? 50 : 0;
    final gPerHive = _method == 'Verdampfen' ? 1.0 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCard(
            icon: Icons.science,
            title: 'Oxalsäure-Rechner',
            subtitle: 'Für brutfreie Wintervölker · Zulassung beachten',
          ),
          const SizedBox(height: 16),

          _InputCard(
            label: 'Anzahl Völker',
            controller: _hivesCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Method selector
          Row(
            children: ['Träufeln', 'Verdampfen'].map((m) {
              final selected = _method == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _method = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? Colors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? Colors.teal
                              : Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          m == 'Träufeln'
                              ? Icons.water_drop
                              : Icons.cloud_queue,
                          color: selected ? Colors.white : Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                selected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          if (hives > 0) ...[
            _ResultCard(
              items: [
                if (_method == 'Träufeln')
                  _ResultItem(
                    label: 'Lösung benötigt (3,5%)',
                    value: '${(hives * mlPerHive)} ml',
                    icon: Icons.water_drop,
                    color: Colors.teal,
                  ),
                if (_method == 'Träufeln')
                  _ResultItem(
                    label: 'Oxalsäure-Dihydrat',
                    value: '${(hives * mlPerHive * 0.035).toStringAsFixed(1)} g',
                    icon: Icons.science,
                    color: Colors.orange,
                  ),
                if (_method == 'Verdampfen')
                  _ResultItem(
                    label: 'OA-Dihydrat pro Anwendung',
                    value: '${(hives * gPerHive).toStringAsFixed(1)} g',
                    icon: Icons.cloud_queue,
                    color: Colors.teal,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoBox(
              text: _method == 'Träufeln'
                  ? 'Träufeln: 3,5% Oxalsäurelösung, max. 5 ml pro besetzter Wabengasse.\n'
                      'Nur einmal pro Saison bei brutfreien Völkern!\nSchutzbrille und Handschuhe tragen.'
                  : 'Verdampfen (Varrox/OA Sublimator): 1 g OA-Dihydrat pro Volk.\n'
                      'Schutzmaske P3 + Schutzbrille sind Pflicht!\nZugelassene Präparate verwenden.',
            ),
          ],
        ],
      ),
    );
  }
}

// ── Colony Strength Calculator ────────────────────────────────────────────────

class _ColonyStrengthCalculator extends StatefulWidget {
  const _ColonyStrengthCalculator();

  @override
  State<_ColonyStrengthCalculator> createState() =>
      _ColonyStrengthCalculatorState();
}

class _ColonyStrengthCalculatorState extends State<_ColonyStrengthCalculator> {
  double _frames = 6.0;

  int get estimatedBees => (_frames * 2500).round();
  String get strength {
    if (_frames < 4) return 'Schwach';
    if (_frames < 8) return 'Mittel';
    if (_frames < 12) return 'Stark';
    return 'Sehr stark';
  }

  Color get strengthColor {
    if (_frames < 4) return Colors.red;
    if (_frames < 8) return Colors.orange;
    if (_frames < 12) return Colors.green;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCard(
            icon: Icons.hexagon,
            title: 'Völkerstärke',
            subtitle: 'Schätzung anhand besetzter Wabengassen',
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Besetzte Wabengassen',
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _frames.round().toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _frames,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: _kAmber,
                  inactiveColor: _kAmber.withAlpha(40),
                  onChanged: (v) => setState(() => _frames = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _ResultCard(
            items: [
              _ResultItem(
                label: 'Geschätzte Bienenzahl',
                value: '≈ ${_formatNumber(estimatedBees)}',
                icon: Icons.people,
                color: _kAmber,
              ),
              _ResultItem(
                label: 'Volksstärke',
                value: strength,
                icon: Icons.bar_chart,
                color: strengthColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoBox(
            text:
                'Faustregel: ~2.500 Bienen pro besetzter Wabengasse.\n'
                '< 4 Gassen = schwach (evtl. vereinen)\n'
                '4–7 Gassen = Normvolk\n'
                '8–11 Gassen = starkes Volk\n'
                '≥ 12 Gassen = sehr starkes Volk',
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return n.toString();
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0E00), Color(0xFF3E2723)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kAmber.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kAmber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _InputCard({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000),
              blurRadius: 4,
              offset: Offset(0, 1))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final List<_ResultItem> items;

  const _ResultCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.color.withAlpha(28),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.label,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 14)),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ResultItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ResultItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAmber.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmber.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _kAmber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
