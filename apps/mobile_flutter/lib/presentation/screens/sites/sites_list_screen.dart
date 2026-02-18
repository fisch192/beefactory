import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/sites_provider.dart';
import '../../../domain/models/site.dart';

class SitesListScreen extends StatelessWidget {
  const SitesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      body: Consumer<SitesProvider>(
        builder: (context, sitesProvider, _) {
          if (sitesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sitesProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('${l.tr('error')}: ${sitesProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => sitesProvider.loadSites(),
                    child: Text(l.tr('retry')),
                  ),
                ],
              ),
            );
          }

          if (sitesProvider.sites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l.tr('no_sites'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.tr('no_sites_hint'),
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/sites/create'),
                    icon: const Icon(Icons.add),
                    label: Text(l.tr('add_site')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 52),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => sitesProvider.loadSites(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: sitesProvider.sites.length,
              itemBuilder: (context, index) {
                final site = sitesProvider.sites[index];
                return _SiteCard(site: site);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/sites/create'),
        icon: const Icon(Icons.add),
        label: Text(l.tr('add_site')),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final SiteModel site;

  const _SiteCard({required this.site});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Card(
      child: InkWell(
        onTap: () => context.go('/sites/${site.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (site.location != null && site.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          site.location!,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.hexagon_outlined,
                            size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${site.hiveCount} ${l.tr('hives_count')}',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        _SyncStatusBadge(status: site.syncStatus),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  final String status;

  const _SyncStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case 'uploaded':
        color = Colors.green;
        icon = Icons.cloud_done;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.cloud_off;
        break;
      default:
        color = Colors.orange;
        icon = Icons.cloud_upload;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          status,
          style: TextStyle(color: color, fontSize: 11),
        ),
      ],
    );
  }
}
