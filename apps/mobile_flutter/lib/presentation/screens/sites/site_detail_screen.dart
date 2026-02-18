import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../domain/models/site.dart';
import '../../../domain/models/hive.dart';
import '../../../domain/repositories/hive_repository.dart';
import '../../providers/sites_provider.dart';

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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_site == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tr('site_detail'))),
        body: Center(child: Text(l.tr('site_not_found'))),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Site info header
            SliverToBoxAdapter(
              child: _SiteHeader(site: _site!),
            ),

            // Hives section title
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l.tr('hives')} (${_hives.length})',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.go('/sites/${widget.siteId}/hives'),
                      icon: const Icon(Icons.list, size: 18),
                      label: Text(l.tr('view_all')),
                    ),
                  ],
                ),
              ),
            ),

            // Hive list
            if (_hives.isEmpty)
              SliverToBoxAdapter(
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.hexagon_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            l.tr('no_hives_at_site'),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final hive = _hives[index];
                    return _HiveCard(hive: hive);
                  },
                  childCount: _hives.length,
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/hives/create/${widget.siteId}');
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: Text(l.tr('add_hive')),
      ),
    );
  }
}

class _SiteHeader extends StatelessWidget {
  final SiteModel site;

  const _SiteHeader({required this.site});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha(200),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => GoRouter.of(context).go('/sites'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      // Edit not yet implemented
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                site.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (site.location != null && site.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      site.location!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
              if (site.latitude != null && site.longitude != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${site.latitude!.toStringAsFixed(4)}, ${site.longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
              if (site.notes != null && site.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  site.notes!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HiveCard extends StatelessWidget {
  final HiveModel hive;

  const _HiveCard({required this.hive});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Card(
      child: InkWell(
        onTap: () => context.push('/hives/${hive.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _queenColor(hive.queenColor).withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '#${hive.number}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _queenColor(hive.queenColor),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hive.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (hive.queenYear != null) ...[
                          Icon(Icons.star,
                              size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            '${l.tr('queen_year')} ${hive.queenYear}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (hive.queenMarked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _queenColor(hive.queenColor).withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l.tr('queen_marked'),
                              style: TextStyle(
                                fontSize: 11,
                                color: _queenColor(hive.queenColor),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.assignment_outlined),
                tooltip: l.tr('quick_inspection'),
                onPressed: () => context.push('/hives/${hive.id}/inspect'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _queenColor(String? color) {
    switch (color?.toLowerCase()) {
      case 'white':
        return Colors.grey;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
