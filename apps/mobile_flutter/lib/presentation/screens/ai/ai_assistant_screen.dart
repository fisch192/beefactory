import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/local/daos/events_dao.dart';
import '../../../data/local/daos/hives_dao.dart';
import '../../../data/local/daos/tasks_dao.dart';
import '../../../services/ai_service.dart';

const _kAmber = Color(0xFFFFA000);
const _kAmberSurface = Color(0xFFFFF8E7);

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  final List<Map<String, String>> _history = [];

  bool _loading = false;
  int _remaining = 0; // -1 = premium
  bool _isPremium = false;

  // Context
  String? _hiveContext;
  bool _contextLoaded = false;
  int _hiveCount = 0;
  int _eventCount = 0;

  // Pending image
  String? _pendingImageBase64;
  String? _pendingImagePath;
  String _pendingImageMime = 'image/jpeg';

  // Smart suggestions derived from context
  List<String> _suggestions = [
    'Varroa-Behandlung planen',
    'Fütterungsempfehlung',
    'Schwarmzeichen erkennen',
    'Wintervorrat berechnen',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatus();
      _loadHiveContext();
    });
  }

  Future<void> _loadStatus() async {
    final remaining = await AiService.remainingRequests();
    final premium = await AiService.isPremium();
    if (mounted) {
      setState(() {
        _remaining = remaining;
        _isPremium = premium;
      });
    }
  }

  // ─── Context loading from local DB ────────────────────────────────────────

  Future<void> _loadHiveContext() async {
    try {
      final hivesDao = context.read<HivesDao>();
      final eventsDao = context.read<EventsDao>();
      final tasksDao = context.read<TasksDao>();

      final hives = await hivesDao.getAll();
      final events = await eventsDao.getAll();
      final tasks = await tasksDao.getAll();

      final now = DateTime.now();
      final in14Days = now.add(const Duration(days: 14));

      // Recent events: last 20, sorted newest first
      final sortedEvents = List.of(events)
        ..sort((a, b) => b.occurredAtLocal.compareTo(a.occurredAtLocal));
      final recentRaw = sortedEvents.take(20).toList();

      // Hive lookup
      final hiveMap = {for (final h in hives) h.id: h};

      // Format events for context
      final recentEvents = recentRaw.map((e) {
        final hiveName = hiveMap[e.hiveId]?.name ??
            (e.hiveId != null ? 'Volk #${e.hiveId}' : '–');
        final date = DateFormat('dd.MM.yy').format(e.occurredAtLocal);

        String summary = '';
        try {
          final payload = e.payload != null
              ? jsonDecode(e.payload!) as Map<String, dynamic>
              : <String, dynamic>{};
          switch (e.type) {
            case 'VARROA_MEASUREMENT':
            case 'varroa_measurement':
              final rate = payload['normalized_rate'];
              summary = rate != null
                  ? '${(rate as num).toStringAsFixed(1)} Milben/Tag'
                  : 'Messung';
            case 'INSPECTION':
            case 'inspection':
              final queens = payload['queen_seen'] == true ? ', Königin gesehen' : '';
              summary = 'Kontrolle$queens';
            case 'TREATMENT':
            case 'treatment':
              summary = payload['treatment_type'] ?? 'Behandlung';
            case 'harvest':
              final kg = payload['kg'];
              summary = kg != null ? '${kg}kg Honig' : 'Ernte';
            default:
              summary = e.type;
          }
        } catch (_) {
          summary = e.type;
        }

        return {
          'date': date,
          'hive': hiveName,
          'type': _localizeEventType(e.type),
          'summary': summary,
        };
      }).toList();

      // Varroa summary (most recent measurement with trend)
      Map<String, dynamic>? varroaSummary;
      final varroaEvents = sortedEvents
          .where((e) =>
              e.type == 'VARROA_MEASUREMENT' ||
              e.type == 'varroa_measurement')
          .toList();
      if (varroaEvents.isNotEmpty) {
        final latest = varroaEvents.first;
        try {
          final p = jsonDecode(latest.payload ?? '{}') as Map<String, dynamic>;
          final rate = (p['normalized_rate'] as num?)?.toStringAsFixed(1);
          if (rate != null) {
            // Count how many measurements to determine trend
            final sameHive = varroaEvents
                .where((e) => e.hiveId == latest.hiveId)
                .toList();
            String trend = 'unbekannt';
            if (sameHive.length >= 2) {
              try {
                final prevP = jsonDecode(sameHive[1].payload ?? '{}')
                    as Map<String, dynamic>;
                final prev = (prevP['normalized_rate'] as num?)?.toDouble();
                final curr = (p['normalized_rate'] as num?)?.toDouble();
                if (prev != null && curr != null) {
                  if (curr > prev + 0.2) trend = '↑ steigend';
                  else if (curr < prev - 0.2) trend = '↓ sinkend';
                  else trend = '→ stabil';
                }
              } catch (_) {}
            }
            varroaSummary = {
              'hive': hiveMap[latest.hiveId]?.name ?? 'Volk #${latest.hiveId}',
              'rate': rate,
              'trend': trend,
            };
          }
        } catch (_) {}
      }

      // Upcoming tasks (next 14 days)
      final upcoming = tasks
          .where((t) =>
              t.status == 'open' &&
              t.dueAt != null &&
              !t.dueAt!.isBefore(now) &&
              t.dueAt!.isBefore(in14Days))
          .toList()
        ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

      final upcomingTasks = upcoming
          .take(5)
          .map((t) => {
                'due': DateFormat('dd.MM').format(t.dueAt!),
                'title': t.title,
              })
          .toList();

      final contextData = HiveContextData(
        hives: hives
            .map((h) => {
                  'number': h.number,
                  'name': h.name ?? '',
                  'queen_year': h.queenYear,
                })
            .toList(),
        recentEvents: recentEvents,
        upcomingTasks: upcomingTasks,
        varroaSummary: varroaSummary,
      );

      final contextStr = AiService.buildHiveContext(contextData);

      // Build smart suggestions based on data
      final suggestions = _buildSuggestions(
        hiveCount: hives.length,
        hasVarroa: varroaEvents.isNotEmpty,
        varroaRate: varroaSummary != null
            ? double.tryParse(varroaSummary['rate'] as String? ?? '')
            : null,
        hasTasks: upcoming.isNotEmpty,
      );

      if (mounted) {
        setState(() {
          _hiveContext = contextStr;
          _contextLoaded = true;
          _hiveCount = hives.length;
          _eventCount = recentRaw.length;
          _suggestions = suggestions;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _contextLoaded = true);
    }
  }

  String _localizeEventType(String type) {
    switch (type.toUpperCase()) {
      case 'VARROA_MEASUREMENT':
        return 'Varroa';
      case 'INSPECTION':
        return 'Durchsicht';
      case 'TREATMENT':
        return 'Behandlung';
      case 'HARVEST':
        return 'Ernte';
      default:
        return type;
    }
  }

  List<String> _buildSuggestions({
    required int hiveCount,
    required bool hasVarroa,
    required double? varroaRate,
    required bool hasTasks,
  }) {
    final list = <String>[];
    if (varroaRate != null && varroaRate > 1) {
      list.add('Varroa ${varroaRate.toStringAsFixed(1)}: Was tun?');
    } else if (!hasVarroa) {
      list.add('Wann Varroa-Kontrolle starten?');
    } else {
      list.add('Varroa-Behandlung planen');
    }
    list.add('Fütterungsempfehlung diese Saison');
    list.add('Schwarmzeichen erkennen');
    if (hiveCount > 0) {
      list.add('Wintervorrat für $hiveCount Volk${hiveCount > 1 ? "völker" : ""}');
    } else {
      list.add('Wintervorrat berechnen');
    }
    return list;
  }

  // ─── Image picker ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = xfile.mimeType ?? 'image/jpeg';

    setState(() {
      _pendingImageBase64 = b64;
      _pendingImagePath = xfile.path;
      _pendingImageMime = mime;
      if (_controller.text.isEmpty) {
        _controller.text =
            'Analysiere dieses Bild: Erkennst du Krankheiten, Schädlinge oder Bienenrassen?';
      }
    });
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImageBase64 = null;
      _pendingImagePath = null;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: _kAmber),
                title: const Text('Foto aufnehmen'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _kAmber),
                title: const Text('Aus Galerie wählen'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Send ──────────────────────────────────────────────────────────────────

  Future<void> _send({String? overrideText}) async {
    final text = overrideText ?? _controller.text.trim();
    if (text.isEmpty || _loading) return;
    if (!_isPremium && _remaining <= 0) {
      _showLimitDialog();
      return;
    }

    final imageB64 = _pendingImageBase64;
    final imagePath = _pendingImagePath;
    final imageMime = _pendingImageMime;

    _controller.clear();
    setState(() {
      _messages.add(_Message(
        role: 'user',
        content: text,
        imagePath: imagePath,
      ));
      _pendingImageBase64 = null;
      _pendingImagePath = null;
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await AiService.chat(
        history: List.from(_history),
        userMessage: text,
        hiveContext: _hiveContext,
        imageBase64: imageB64,
        imageMime: imageMime,
      );
      _history.add({'role': 'user', 'content': text});
      _history.add({'role': 'assistant', 'content': reply});
      await _loadStatus();
      if (mounted) {
        setState(() {
          _messages.add(_Message(role: 'assistant', content: reply));
          _loading = false;
        });
        _scrollToBottom();
      }
    } on AiLimitException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showLimitDialog(message: e.message);
      }
    } on AiException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Message(
              role: 'error', content: 'Fehler: ${e.message}'));
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showLimitDialog({String? message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: _kAmber, size: 48),
        title: const Text('Tageslimit erreicht'),
        content: Text(
          message ??
              'Du hast deine 3 kostenlosen KI-Anfragen für heute aufgebraucht.\n\n'
                  'Schalte Premium frei für unlimitierte KI-Nutzung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kAmber, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AiService.setPremium(true);
              await _loadStatus();
            },
            child: const Text('Premium freischalten'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAmberSurface,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, size: 22),
            SizedBox(width: 8),
            Text('Imker-KI'),
          ],
        ),
        backgroundColor: _kAmber,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _isPremium
                  ? const Chip(
                      label: Text('Premium',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      avatar: Icon(Icons.star, size: 14, color: Colors.amber),
                      backgroundColor: Colors.white24,
                      labelStyle: TextStyle(color: Colors.white),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    )
                  : Chip(
                      label: Text(
                        _remaining >= 0 ? '$_remaining/3' : '∞',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      avatar: const Icon(Icons.bolt,
                          size: 14, color: Colors.yellow),
                      backgroundColor: Colors.white24,
                      labelStyle: const TextStyle(color: Colors.white),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Context badge
          if (_contextLoaded && _hiveCount > 0)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.green.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Kontext geladen: $_hiveCount Volk${_hiveCount > 1 ? "völker" : ""}, '
                    '$_eventCount Ereignisse – KI antwortet personalisiert',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          if (!_contextLoaded)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey.withAlpha(20),
              child: const Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.grey),
                  ),
                  SizedBox(width: 8),
                  Text('Lade deine Imkerei-Daten...',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          if (_messages.isEmpty)
            _WelcomeBanner(
              suggestions: _suggestions,
              onSuggestion: (s) => _send(overrideText: s),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          // Pending image preview
          if (_pendingImagePath != null)
            _PendingImageBar(
              imagePath: _pendingImagePath!,
              onRemove: _clearPendingImage,
            ),
          _InputBar(
            controller: _controller,
            enabled: !_loading && (_isPremium || _remaining > 0),
            onSend: () => _send(),
            onImageTap: _showImageSourceSheet,
          ),
        ],
      ),
    );
  }
}

// ── Welcome banner ─────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestion;

  const _WelcomeBanner({
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAmber.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kAmber.withAlpha(60)),
      ),
      child: Column(
        children: [
          const Text('🐝', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text(
            'Dein KI-Imker-Assistent',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Varroa-Trends · Fütterung · Krankheitserkennung · Wetter',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: suggestions
                .map((s) => ActionChip(
                      label: Text(s,
                          style: const TextStyle(fontSize: 11)),
                      onPressed: () => onSuggestion(s),
                      backgroundColor: _kAmber.withAlpha(15),
                      side: BorderSide(color: _kAmber.withAlpha(60)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Foto senden für Krankheits- oder Rassenbestimmung',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pending image bar ──────────────────────────────────────────────────────

class _PendingImageBar extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _PendingImageBar(
      {required this.imagePath, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Foto wird mit deiner Nachricht gesendet',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────

class _Message {
  final String role; // 'user' | 'assistant' | 'error'
  final String content;
  final String? imagePath;

  const _Message({
    required this.role,
    required this.content,
    this.imagePath,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({required this.message});

  bool get _isUser => message.role == 'user';
  bool get _isError => message.role == 'error';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!_isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _isError ? Colors.red.shade100 : _kAmber,
              child: Text(
                _isError ? '!' : '🐝',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isUser
                    ? _kAmber
                    : _isError
                        ? Colors.red.shade50
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isUser ? 16 : 4),
                  bottomRight: Radius.circular(_isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 180,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isUser ? Colors.white : Colors.black87,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUser) ...[
            const SizedBox(width: 6),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFFE8A000),
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing indicator ───────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _kAmber,
            child: const Text('🐝', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                SizedBox(width: 4),
                _Dot(delay: 150),
                SizedBox(width: 4),
                _Dot(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.2, end: 1).animate(
        CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ac.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: _kAmber,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onImageTap;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Image picker button
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              color: enabled ? _kAmber : Colors.grey[300],
              onPressed: enabled ? onImageTap : null,
              tooltip: 'Foto für Krankheitserkennung',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Frag deinen Imker-Assistenten...'
                      : 'Tageslimit erreicht',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: enabled ? _kAmber : Colors.grey[300],
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: enabled ? onSend : null,
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
