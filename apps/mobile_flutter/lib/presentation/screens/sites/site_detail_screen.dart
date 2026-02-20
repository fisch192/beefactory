import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../data/remote/weather_api.dart';
import '../../../domain/models/hive.dart';
import '../../../domain/models/site.dart';
import '../../../domain/repositories/hive_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/sites_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _kAmber = Color(0xFFFFA000);
const _kSurface = Color(0xFFFFF8E1);

class SiteDetailScreen extends StatefulWidget {
  final int siteId;

  const SiteDetailScreen({super.key, required this.siteId});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  SiteModel? _site;
  List<HiveModel> _hives = [];
  bool _isLoading = true;
  bool _isSatellite = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final site =
          await context.read<SitesProvider>().getSiteById(widget.siteId);
      final hives =
          await context.read<HiveRepository>().getBySiteId(widget.siteId);
      if (mounted) {
        setState(() {
          _site = site;
          _hives = hives;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_site == null) {
      final l = AppLocalizations.watch(context);
      return Scaffold(
        appBar: AppBar(title: Text(l.tr('site_detail'))),
        body: Center(child: Text(l.tr('site_not_found'))),
      );
    }

    return _SiteDetailBody(
      site: _site!,
      hives: _hives,
      onRefresh: _loadData,
      isSatellite: _isSatellite,
      onToggleLayer: () => setState(() => _isSatellite = !_isSatellite),
    );
  }
}

class _SiteDetailBody extends StatelessWidget {
  final SiteModel site;
  final List<HiveModel> hives;
  final VoidCallback onRefresh;
  final bool isSatellite;
  final VoidCallback onToggleLayer;

  const _SiteDetailBody({
    required this.site,
    required this.hives,
    required this.onRefresh,
    required this.isSatellite,
    required this.onToggleLayer,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    final hasCoords = site.latitude != null && site.longitude != null;

    return Scaffold(
      body: RefreshIndicator(
        color: _kAmber,
        onRefresh: () async => onRefresh(),
        child: CustomScrollView(
          slivers: [
            // ── Hero: Map or Gradient Header ─────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    // Map or placeholder
                    hasCoords
                        ? _SiteMap(
                            lat: site.latitude!,
                            lng: site.longitude!,
                            hivesCount: hives.length,
                            isSatellite: isSatellite,
                          )
                        : _MapPlaceholder(site: site),

                    if (hasCoords)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 4,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                isSatellite ? Icons.map : Icons.satellite,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: onToggleLayer,
                          ),
                        ),
                      ),

                    // Bottom gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.5, 1.0],
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ),

                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 4,
                      left: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child:
                                const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                          onPressed: () => GoRouter.of(context).go('/sites'),
                        ),
                      ),
                    ),

                    // Site name overlay
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 8, color: Colors.black54),
                              ],
                            ),
                          ),
                          if (site.location != null &&
                              site.location!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  site.location!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),

            // ── Stats bar ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.hexagon,
                      label: '${hives.length} ${l.tr('hives')}',
                      color: _kAmber,
                    ),
                    const _Divider(),
                    if (site.elevation != null)
                      _StatChip(
                        icon: Icons.terrain,
                        label: '${site.elevation!.round()} m',
                        color: Colors.teal,
                      )
                    else
                      _StatChip(
                        icon: Icons.terrain,
                        label: '— m',
                        color: Colors.grey,
                      ),
                    const _Divider(),
                    _StatChip(
                      icon: Icons.radar,
                      label: '3 km',
                      color: Colors.blue,
                    ),
                  ],
                ).animate().fade(delay: 200.ms, duration: 400.ms),
              ),
            ),

            // ── Weather ──────────────────────────────────────────────────
            if (hasCoords)
              SliverToBoxAdapter(
                child: _WeatherCard(
                    lat: site.latitude!, lng: site.longitude!),
              ),

            // ── Section header ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l.tr('hives')} (${hives.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => GoRouter.of(context)
                          .push('/sites/${hives.isNotEmpty ? hives.first.siteId : 0}/hives'),
                      icon: const Icon(Icons.list, size: 16),
                      label: Text(l.tr('view_all')),
                      style: TextButton.styleFrom(foregroundColor: _kAmber),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hive grid ────────────────────────────────────────────────
            if (hives.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyHives(l: l),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: hives
                      .map((h) => _HiveCard(hive: h).animate().fade().scale(begin: const Offset(0.9, 0.9)))
                      .toList(),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await GoRouter.of(context).push('/hives/create/${site.id}');
          onRefresh();
        },
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).tr('add_hive')),
        backgroundColor: _kAmber,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ── Map Widget ──────────────────────────────────────────────────────────────
class _SiteMap extends StatelessWidget {
  final double lat;
  final double lng;
  final int hivesCount;
  final bool isSatellite;

  const _SiteMap({
    required this.lat,
    required this.lng,
    required this.hivesCount,
    required this.isSatellite,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(lat, lng);
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        if (isSatellite)
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.bee.bee_app',
            maxZoom: 19,
          )
        else
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.bee.bee_app',
            maxZoom: 19,
          ),
        // 3km flight range circle
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: 3000,
              useRadiusInMeter: true,
              color: _kAmber.withAlpha(30),
              borderColor: _kAmber,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        // Hive marker
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 52,
              height: 52,
              child: _HiveMapMarker(count: hivesCount),
            ),
          ],
        ),
        // OSM attribution
        const SimpleAttributionWidget(
          source: Text(
            '© OpenStreetMap',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _HiveMapMarker extends StatelessWidget {
  final int count;

  const _HiveMapMarker({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kAmber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hexagon, color: Colors.white, size: 16),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map Placeholder (no coordinates) ────────────────────────────────────────
class _MapPlaceholder extends StatelessWidget {
  final SiteModel site;

  const _MapPlaceholder({required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0F00), Color(0xFF3E2723)],
        ),
      ),
      child: Stack(
        children: [
          // Hex pattern
          CustomPaint(painter: _HexBgPainter(), size: Size.infinite),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, color: Colors.white38, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Keine Koordinaten',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  site.location ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HexBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFA000).withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const r = 24.0;
    final w = r * 2;
    final h = r * math.sqrt(3);
    for (double y = -h; y < size.height + h; y += h) {
      for (double x = -w; x < size.width + w; x += w * 1.5) {
        _hex(canvas, Offset(x, y), r, p);
        _hex(canvas, Offset(x + w * 0.75, y + h / 2), r, p);
      }
    }
  }

  void _hex(Canvas canvas, Offset c, double r, Paint p) {
    final path = ui.Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * 60 - 30) * math.pi / 180;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_HexBgPainter _) => false;
}

// ── Weather Card ─────────────────────────────────────────────────────────────

class _WeatherCard extends StatefulWidget {
  final double lat;
  final double lng;

  const _WeatherCard({required this.lat, required this.lng});

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  WeatherData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await WeatherApi.fetch(widget.lat, widget.lng);
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(color: _kAmber, minHeight: 2),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final w = _data!;
    final varroaColor = switch (w.varroaRisk) {
      VarroaWeatherRisk.low => Colors.green,
      VarroaWeatherRisk.medium => Colors.orange,
      VarroaWeatherRisk.high => Colors.red,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0E00), Color(0xFF2D1600)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x30000000),
              blurRadius: 8,
              offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: _kAmber, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Bienenwetter',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
              const Spacer(),
              if (w.goodForBeesFlight)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withAlpha(100)),
                  ),
                  child: const Text('🐝 Flugtag',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Kein Flugtag',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Main row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                w.conditionEmoji,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${w.temperature.toStringAsFixed(1)} °C',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    w.conditionText,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
              const Spacer(),
              // Conditions column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _WeatherStat(
                      icon: Icons.water_drop_outlined,
                      value: '${w.humidity}%',
                      label: 'Feuchte'),
                  const SizedBox(height: 4),
                  _WeatherStat(
                      icon: Icons.air,
                      value: '${w.windSpeed.round()} km/h',
                      label: 'Wind'),
                  const SizedBox(height: 4),
                  _WeatherStat(
                      icon: Icons.grain,
                      value: '${w.precipitation.toStringAsFixed(1)} mm',
                      label: 'Regen'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Varroa weather
          Row(
            children: [
              const Icon(Icons.bug_report, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              const Text(
                'Varroawetter: ',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: varroaColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: varroaColor.withAlpha(100)),
                ),
                child: Text(
                  w.varroaRiskLabel,
                  style: TextStyle(
                      color: varroaColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _varroaHint(w.varroaRisk),
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _varroaHint(VarroaWeatherRisk risk) {
    switch (risk) {
      case VarroaWeatherRisk.low:
        return 'Geringe Aktivität';
      case VarroaWeatherRisk.medium:
        return 'Beobachten';
      case VarroaWeatherRisk.high:
        return 'Warme/feuchte Bedingungen – Messung empfohlen!';
    }
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 20, width: 1, color: Colors.grey.shade200);
  }
}

// ── Empty hives placeholder ──────────────────────────────────────────────────
class _EmptyHives extends StatelessWidget {
  final AppLocalizations l;

  const _EmptyHives({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAmber.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(Icons.hexagon_outlined, size: 52, color: _kAmber.withAlpha(120)),
          const SizedBox(height: 12),
          Text(
            l.tr('no_hives_at_site'),
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l.tr('add_hive'),
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Hive Card ────────────────────────────────────────────────────────────────
class _HiveCard extends StatelessWidget {
  final HiveModel hive;

  const _HiveCard({required this.hive});

  Color _queenColor(String? c) {
    switch (c?.toLowerCase()) {
      case 'white':
        return Colors.blueGrey;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return _kAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qc = _queenColor(hive.queenColor);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => context.push('/hives/${hive.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: qc.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '#${hive.number}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: qc,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hive.queenMarked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: qc.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '♛',
                        style: TextStyle(fontSize: 12, color: qc),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hive.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hive.queenYear != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: qc),
                    const SizedBox(width: 2),
                    Text(
                      '${hive.queenYear}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
