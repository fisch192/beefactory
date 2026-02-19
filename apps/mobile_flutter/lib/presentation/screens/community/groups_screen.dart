import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local-first groups/Vereine. When backend supports /community/groups,
// swap the _LocalGroupsStore calls for GroupsApi calls.

const Color _kHoney = Color(0xFFFFA000);
const Color _kDark = Color(0xFF1A1A2E);
const Color _kCard = Color(0xFF232340);

// ── Local data store ─────────────────────────────────────────────────────────

class _LocalGroup {
  final String id;
  final String name;
  final String? description;
  final String emoji;
  final String inviteCode;
  final List<String> memberNames;
  final bool isAdmin;
  final DateTime createdAt;

  const _LocalGroup({
    required this.id,
    required this.name,
    this.description,
    required this.emoji,
    required this.inviteCode,
    required this.memberNames,
    required this.isAdmin,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emoji': emoji,
        'inviteCode': inviteCode,
        'memberNames': memberNames,
        'isAdmin': isAdmin,
        'createdAt': createdAt.toIso8601String(),
      };

  factory _LocalGroup.fromJson(Map<String, dynamic> j) => _LocalGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        emoji: j['emoji'] as String? ?? '🐝',
        inviteCode: j['inviteCode'] as String,
        memberNames: (j['memberNames'] as List?)?.cast<String>() ?? [],
        isAdmin: j['isAdmin'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class _LocalGroupsStore {
  static const _key = 'local_groups_v1';

  static String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static Future<List<_LocalGroup>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => _LocalGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<_LocalGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(groups.map((g) => g.toJson()).toList()));
  }

  static Future<_LocalGroup> create({
    required String name,
    String? description,
    required String emoji,
    required String creatorName,
  }) async {
    final groups = await load();
    final group = _LocalGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      emoji: emoji,
      inviteCode: _randomCode(),
      memberNames: [creatorName],
      isAdmin: true,
      createdAt: DateTime.now(),
    );
    groups.add(group);
    await save(groups);
    return group;
  }

  static Future<_LocalGroup?> joinByCode(String code, String userName) async {
    final groups = await load();
    final idx = groups.indexWhere(
        (g) => g.inviteCode.toUpperCase() == code.trim().toUpperCase());
    if (idx == -1) return null;
    final g = groups[idx];
    if (!g.memberNames.contains(userName)) {
      final updated = _LocalGroup(
        id: g.id,
        name: g.name,
        description: g.description,
        emoji: g.emoji,
        inviteCode: g.inviteCode,
        memberNames: [...g.memberNames, userName],
        isAdmin: false,
        createdAt: g.createdAt,
      );
      groups[idx] = updated;
      await save(groups);
      return updated;
    }
    return g;
  }

  static Future<void> delete(String id) async {
    final groups = await load();
    groups.removeWhere((g) => g.id == id);
    await save(groups);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<_LocalGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final groups = await _LocalGroupsStore.load();
    if (mounted) {
      setState(() {
        _groups = groups;
        _loading = false;
      });
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String emoji = '🐝';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: _kCard,
          title: const Text('Gruppe erstellen',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji picker row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['🐝', '🍯', '🌸', '🌿', '🏕️', '🤝', '👨‍🌾']
                      .map((e) => GestureDetector(
                            onTap: () => setS(() => emoji = e),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: emoji == e
                                    ? _kHoney.withAlpha(50)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: emoji == e
                                    ? Border.all(color: _kHoney)
                                    : null,
                              ),
                              child: Text(e,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _DarkField(controller: nameCtrl, label: 'Gruppenname'),
              const SizedBox(height: 12),
              _DarkField(
                  controller: descCtrl,
                  label: 'Beschreibung (optional)',
                  maxLines: 2),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: _kHoney),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await _LocalGroupsStore.create(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  emoji: emoji,
                  creatorName: 'Ich',
                );
                _load();
              },
              child: const Text('Erstellen',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _showJoinDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Gruppe beitreten',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gib den 6-stelligen Einladungscode ein:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _DarkField(
              controller: codeCtrl,
              label: 'Einladungscode',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                UpperCaseTextFormatter(),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kHoney),
            onPressed: () async {
              if (codeCtrl.text.trim().length < 4) return;
              Navigator.pop(ctx);
              final group = await _LocalGroupsStore.joinByCode(
                  codeCtrl.text.trim(), 'Ich');
              if (mounted) {
                if (group != null) {
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${group.emoji} ${group.name} beigetreten!'),
                    backgroundColor: _kHoney,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Code nicht gefunden.'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Beitreten',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(_LocalGroup group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: Text('${group.emoji} ${group.name} einladen',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Teile diesen Code, damit andere beitreten können:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _kHoney.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kHoney.withAlpha(80)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    group.inviteCode,
                    style: const TextStyle(
                      color: _kHoney,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: group.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code kopiert!')),
                      );
                    },
                    icon: const Icon(Icons.copy, color: _kHoney),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${group.memberNames.length} Mitglied(er)',
              style: TextStyle(
                  color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        title: const Text('Gruppen & Vereine'),
        backgroundColor: _kCard,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Gruppe beitreten',
            onPressed: _showJoinDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: _kHoney,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Gruppe erstellen'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kHoney))
          : _groups.isEmpty
              ? _EmptyGroups(onCreate: _showCreateDialog, onJoin: _showJoinDialog)
              : RefreshIndicator(
                  color: _kHoney,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _groups.length,
                    itemBuilder: (ctx, i) => _GroupTile(
                      group: _groups[i],
                      onInvite: () => _showInviteDialog(_groups[i]),
                      onDelete: () async {
                        await _LocalGroupsStore.delete(_groups[i].id);
                        _load();
                      },
                    ),
                  ),
                ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final _LocalGroup group;
  final VoidCallback onInvite;
  final VoidCallback onDelete;

  const _GroupTile(
      {required this.group,
      required this.onInvite,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _kHoney.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(group.emoji,
                style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null) ...[
              const SizedBox(height: 2),
              Text(
                group.description!,
                style: TextStyle(
                    color: Colors.grey[400], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people_outline,
                    size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${group.memberNames.length} Mitglied(er)',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12),
                ),
                if (group.isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kHoney.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Admin',
                        style: TextStyle(
                            color: _kHoney,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: _kHoney, size: 22),
              tooltip: 'Einladen',
              onPressed: onInvite,
            ),
            PopupMenuButton<String>(
              color: _kCard,
              onSelected: (v) {
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Verlassen',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert,
                  color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _EmptyGroups({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐝',
                style:
                    TextStyle(fontSize: 64, color: _kHoney.withAlpha(180))),
            const SizedBox(height: 16),
            const Text(
              'Noch keine Gruppen',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle eine Gruppe für deinen Imkerverein oder tritt einer bestehenden Gruppe bei.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Gruppe erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kHoney,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Gruppe beitreten'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kHoney,
                side: const BorderSide(color: _kHoney),
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _DarkField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withAlpha(80)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kHoney),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
