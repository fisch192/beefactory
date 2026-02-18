import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/hive.dart';
import '../../../domain/repositories/hive_repository.dart';
import '../../../l10n/app_localizations.dart';

class HiveListScreen extends StatefulWidget {
  final int siteId;

  const HiveListScreen({super.key, required this.siteId});

  @override
  State<HiveListScreen> createState() => _HiveListScreenState();
}

class _HiveListScreenState extends State<HiveListScreen> {
  List<HiveModel> _hives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHives();
  }

  Future<void> _loadHives() async {
    setState(() => _isLoading = true);
    try {
      final hives =
          await context.read<HiveRepository>().getBySiteId(widget.siteId);
      if (mounted) {
        setState(() {
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hives.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hexagon_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        l.tr('no_hives'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context
                              .push('/hives/create/${widget.siteId}');
                          _loadHives();
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l.tr('add_hive')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHives,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _hives.length,
                    itemBuilder: (context, index) {
                      final hive = _hives[index];
                      return Card(
                        child: InkWell(
                          onTap: () => context.push('/hives/${hive.id}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${hive.number}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hive.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (hive.queenYear != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '${l.tr('queen_year')}: ${hive.queenYear}${hive.queenMarked ? ' (${l.tr('queen_marked')})' : ''}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      if (hive.notes != null &&
                                          hive.notes!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            hive.notes!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.assignment_outlined),
                                      tooltip: l.tr('inspect'),
                                      onPressed: () => context
                                          .push('/hives/${hive.id}/inspect'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/hives/create/${widget.siteId}');
          _loadHives();
        },
        icon: const Icon(Icons.add),
        label: Text(l.tr('add_hive')),
      ),
    );
  }
}
