import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/mindfulness_practice_content_model.dart';
import 'mindfulness_global_audio_player.dart';

import '../models/mindfulness_practice_model.dart';
import '../models/mindfulness_session_model.dart';
import '../services/mindfulness_service.dart';
import 'mindfulness_player_page.dart';
import 'package:fl_chart/fl_chart.dart';

class MindfulnessHomePage extends StatefulWidget {
  const MindfulnessHomePage({super.key});

  @override
  State<MindfulnessHomePage> createState() => _MindfulnessHomePageState();
}

class _MindfulnessHomePageState extends State<MindfulnessHomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7FFD8), Color(0xFFB9F5A7), Color(0xFF8EDB83)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              const _Header(),
              const SizedBox(height: 18),
              _Segmented(
                value: _tabIndex,
                onChanged: (v) => setState(() => _tabIndex = v),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _tabIndex == 0
                      ? const _MindfulnessTimerPanel()
                      : _tabIndex == 1
                      ? const _HistoryPanel()
                      : const _InsightsPanel(),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );

  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _SegButton(label: 'Mindfulness', selected: value == 0, onTap: () => onChanged(0))),
          const SizedBox(width: 6),
          Expanded(child: _SegButton(label: 'History', selected: value == 1, onTap: () => onChanged(1))),
          const SizedBox(width: 6),
          Expanded(child: _SegButton(label: 'Insights', selected: value == 2, onTap: () => onChanged(2))),
        ],
      ),
    );
  }
}


class _SegButton extends StatelessWidget {
  const _SegButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.75) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MindfulnessTimerPanel extends StatefulWidget {
  const _MindfulnessTimerPanel();

  @override
  State<_MindfulnessTimerPanel> createState() => _MindfulnessTimerPanelState();
}

class _MindfulnessTimerPanelState extends State<_MindfulnessTimerPanel> {
  final _service = MindfulnessService();

  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  bool _loadingPractice = true;
  String? _err;
  List<MindfulnessPractice> _practices = [];
  MindfulnessPractice? _selectedPractice;

  bool _loadingMedia = false;
  String? _audioPath;
  String? _videoPath;

  List<MindfulnessPracticeContent> _audioList = [];
  List<MindfulnessPracticeContent> _videoList = [];
  bool _loadingAudioList = false;
  bool _loadingVideoList = false;

  DateTime? _startedAt;
  int? _preMood;
  String _tip = _tips.first;

  bool get _isRunning => _stopwatch.isRunning;

  static const List<String> _tips = [
    'Focus on your breath. Be present.',
    'Notice thoughts, then let them pass.',
    'Relax your shoulders and unclench your jaw.',
    'If distracted, gently return to breathing.',
    'Exhale longer than inhale to calm your body.',
  ];

  @override
  void initState() {
    super.initState();
    _loadPractices();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPractices() async {
    setState(() {
      _loadingPractice = true;
      _err = null;
    });

    try {
      final list = await _service.fetchPractices();
      setState(() {
        _practices = list;
        _selectedPractice = list.isNotEmpty ? list.first : null;
      });

      final p = _selectedPractice;
      if (p != null) {
        await _loadAudioList(p.id);
        await _loadVideoList(p.id);
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPractice = false);
    }
  }

  Future<void> _loadMediaForPractice(String mindPracticeId) async {
    setState(() {
      _loadingMedia = true;
      _audioPath = null;
      _videoPath = null;
    });

    try {
      final media = await _service.fetchPracticeMedia(mindPracticeId);
      if (!mounted) return;
      setState(() {
        _audioPath = (media?['audio_path'] ?? '').toString().trim().isEmpty
            ? null
            : media?['audio_path']?.toString().trim();
        _videoPath = (media?['video_path'] ?? '').toString().trim().isEmpty
            ? null
            : media?['video_path']?.toString().trim();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _audioPath = null;
        _videoPath = null;
      });
    } finally {
      if (mounted) setState(() => _loadingMedia = false);
    }
  }

  Future<void> _loadAudioList(String practiceId) async {
    setState(() => _loadingAudioList = true);
    try {
      final list = await _service.fetchAudioContents(practiceId);
      if (!mounted) return;
      setState(() => _audioList = list);
    } finally {
      if (mounted) setState(() => _loadingAudioList = false);
    }
  }

  Future<void> _loadVideoList(String practiceId) async {
    setState(() => _loadingVideoList = true);
    try {
      final list = await _service.fetchVideoContents(practiceId);
      if (!mounted) return;
      setState(() => _videoList = list);
    } finally {
      if (mounted) setState(() => _loadingVideoList = false);
    }
  }

  Future<int?> _pickMoodRating({
    required String title,
    required String subtitle,
  }) async {
    const items = <int, IconData>{
      1: Icons.sentiment_very_dissatisfied,
      2: Icons.sentiment_dissatisfied,
      3: Icons.sentiment_neutral,
      4: Icons.sentiment_satisfied,
      5: Icons.sentiment_very_satisfied,
    };

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
                children: items.entries.map((e) {
                  final v = e.key;
                  final icon = e.value;

                  return SizedBox(
                    width: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(icon, size: 34),
                          onPressed: () => Navigator.pop(ctx, v),
                        ),
                        const SizedBox(height: 4),
                        Text('$v'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _start() async {
    if (_selectedPractice == null) return;

    final pre = await _pickMoodRating(
      title: 'Pre-mood',
      subtitle: 'How do you feel before mindfulness? (1 = worst, 5 = best)',
    );
    if (pre == null) return;

    setState(() {
      _preMood = pre;
      _startedAt = DateTime.now();
      _tip = (List<String>.from(_tips)..shuffle()).first;
      _stopwatch
        ..reset()
        ..start();
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _stopAndSave() async {
    _timer?.cancel();
    _timer = null;

    _stopwatch.stop();
    final endedAt = DateTime.now();
    final startedAt = _startedAt ?? endedAt;
    final durationSeconds = _stopwatch.elapsed.inSeconds;

    if (durationSeconds <= 0) {
      _stopwatch.reset();
      return;
    }

    final p = _selectedPractice;
    if (p == null) return;

    final post = await _pickMoodRating(
      title: 'Post-mood',
      subtitle: 'How do you feel after mindfulness? (1 = worst, 5 = best)',
    );
    if (post == null) {
      _stopwatch.reset();
      _startedAt = null;
      _preMood = null;
      if (mounted) setState(() {});
      return;
    }

    final pre = _preMood ?? 3;

    try {
      await _service.createSession(
        practiceId: p.id,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
        completionStatus: 'completed',
        completionRate: 100,
        preMood: pre,
        postMood: post,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved to History')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      _stopwatch.reset();
      _startedAt = null;
      _preMood = null;
      if (mounted) setState(() {});
    }
  }

  String _formatElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  void _openMedia(String type, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MindfulnessPlayerPage(
          title: type,
          mediaType: type.toLowerCase(), // 'audio' or 'video'
          pathOrUrl: path,
        ),
      ),
    );
  }
  Future<void> _addAudioForPractice() async {
    final p = _selectedPractice;
    if (p == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = Uint8List.fromList(result.files.single.bytes!);
    final fileName = result.files.single.name;

    try {
      await _service.uploadAndInsertAudio(
        practiceId: p.id,
        bytes: bytes,
        fileName: fileName,
        title: fileName,
      );

      if (!mounted) return;
      await _loadAudioList(p.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio uploaded')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }
  Future<void> _addVideoForPractice() async {
    final p = _selectedPractice;
    if (p == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final bytes = Uint8List.fromList(result.files.single.bytes!);
    final fileName = result.files.single.name;

    try {
      await _service.uploadAndInsertVideo(
        practiceId: p.id,
        bytes: bytes,
        fileName: fileName,
        title: fileName,
      );

      if (!mounted) return;
      await _loadVideoList(p.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }
  Future<void> _showAudioPickerSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Select Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _addAudioForPractice();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Songs'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_loadingAudioList)
                  const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())
                else if (_audioList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No audio yet. Tap "Add Songs" to upload.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _audioList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = _audioList[i];
                        final path = (item.audioPath ?? '').trim();
                        final title = (item.textContent ?? '').trim().isNotEmpty
                            ? item.textContent!.trim()
                            : path.split('/').last;

                        return ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(title),
                          subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: path.isEmpty
                              ? null
                              : () {
                            Navigator.pop(ctx);
                            _openMedia('Audio', path);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<void> _showVideoPickerSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Select Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _addVideoForPractice();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Video'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_loadingVideoList)
                  const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())
                else if (_videoList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No video yet. Tap "Add Video" to upload.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _videoList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = _videoList[i];
                        final path = (item.videoPath ?? '').trim();
                        final title = (item.textContent ?? '').trim().isNotEmpty
                            ? item.textContent!.trim()
                            : path.split('/').last;

                        return ListTile(
                          leading: const Icon(Icons.ondemand_video),
                          title: Text(title),
                          subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: path.isEmpty
                              ? null
                              : () {
                            Navigator.pop(ctx);
                            _openMedia('Video', path);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPractice) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_err != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Load practices failed:\n$_err', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadPractices, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_selectedPractice == null) {
      return const Center(child: Text('No practice found. Please seed practices first.'));
    }

    final rawCover = (_selectedPractice?.coverImagePath ?? '').trim();
    final fileName = rawCover.split('/').isNotEmpty ? rawCover.split('/').last : rawCover;
    final coverAssetPath = fileName.isEmpty ? null : 'assets/images/$fileName';

    return Stack(
      children: [
        Positioned.fill(
          child: _PracticeCoverBackground(assetPath: coverAssetPath),
        ),

        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const Text('Mindfulness', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          const Text('Practice:', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),

                          _PracticeThumb(assetPath: coverAssetPath, size: 30),
                          const SizedBox(width: 10),

                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<MindfulnessPractice>(
                                isExpanded: true,
                                value: _selectedPractice,

                                selectedItemBuilder: (context) {
                                  return _practices.map((p) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('${p.practiceType} (${p.durationSeconds}s)'),
                                    );
                                  }).toList();
                                },

                                items: _practices.map((p) {
                                  final raw = (p.coverImagePath ?? '').trim();
                                  final file = raw.split('/').isNotEmpty ? raw.split('/').last : raw;
                                  final itemCover = file.isEmpty ? null : 'assets/images/$file';

                                  return DropdownMenuItem(
                                    value: p,
                                    child: Row(
                                      children: [
                                        _PracticeThumb(assetPath: itemCover, size: 26),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text('${p.practiceType} (${p.durationSeconds}s)')),
                                      ],
                                    ),
                                  );
                                }).toList(),

                                onChanged: _isRunning
                                    ? null
                                    : (p) async {
                                  if (p == null) return;
                                  setState(() => _selectedPractice = p);
                                  await _loadAudioList(p.id);
                                  await _loadVideoList(p.id);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Start/Stop button
                    InkWell(
                      onTap: () async {
                        if (_isRunning) {
                          await _stopAndSave();
                          await GlobalAudioPlayer.player.pause();
                        } else {
                          await _start();
                        }
                      },
                      borderRadius: BorderRadius.circular(120),
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRunning ? const Color(0xFF2E7D32) : const Color(0xFF3DDC5A),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                              color: Colors.black.withOpacity(0.12),
                            ),
                          ],
                          border: Border.all(color: Colors.black.withOpacity(0.25)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isRunning ? 'Stop' : 'Start',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Timer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.12)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatElapsed(_stopwatch.elapsed),
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Tips
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TIPS:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.12)),
                      ),
                      child: Text(_tip, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadingAudioList ? null : _onTapAudio,
                            icon: const Icon(Icons.headphones, size: 18),
                            label: Text(_loadingMedia ? 'Audio...' : 'Audio'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.white.withOpacity(0.35),
                              side: BorderSide(color: Colors.black.withOpacity(0.12)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadingVideoList ? null : _onTapVideo,
                            icon: const Icon(Icons.ondemand_video, size: 18),
                            label: Text(_loadingMedia ? 'Video...' : 'Video'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.white.withOpacity(0.35),
                              side: BorderSide(color: Colors.black.withOpacity(0.12)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  Future<void> _onTapAudio() async {
    final p = _selectedPractice;
    if (p == null) return;

    await _loadAudioList(p.id);

    if (!mounted) return;
    await _showAudioPickerSheet();
  }

  Future<void> _onTapVideo() async {
    final p = _selectedPractice;
    if (p == null) return;

    await _loadVideoList(p.id);

    if (!mounted) return;
    await _showVideoPickerSheet();
  }

}

class _HistoryPanel extends StatefulWidget {
  const _HistoryPanel();

  @override
  State<_HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<_HistoryPanel> {
  final _service = MindfulnessService();

  bool _loading = true;
  String? _error;
  List<MindfulnessSession> _sessions = [];

  DateTime? _filterFrom;
  DateTime? _filterTo;

  final _dfDate = DateFormat('M/d/yyyy');
  final _dfTime = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchSessions(from: _filterFrom, to: _filterTo);
      setState(() => _sessions = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDuration(int seconds) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = Duration(seconds: seconds);
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  Future<void> _showFilter() async {
    DateTime? tempFrom = _filterFrom;
    DateTime? tempTo = _filterTo;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              Future<void> pickFrom() async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: ctx,
                  firstDate: DateTime(now.year - 2),
                  lastDate: DateTime(now.year + 2),
                  initialDate: tempFrom ?? now,
                );
                if (d != null) setModalState(() => tempFrom = DateTime(d.year, d.month, d.day));
              }

              Future<void> pickTo() async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: ctx,
                  firstDate: DateTime(now.year - 2),
                  lastDate: DateTime(now.year + 2),
                  initialDate: tempTo ?? now,
                );
                if (d != null) {
                  setModalState(() => tempTo = DateTime(d.year, d.month, d.day, 23, 59, 59));
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickFrom,
                          child: Text(tempFrom == null ? 'From date' : 'From: ${_dfDate.format(tempFrom!)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: pickTo,
                          child: Text(tempTo == null ? 'To date' : 'To: ${_dfDate.format(tempTo!)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setModalState(() {
                      tempFrom = null;
                      tempTo = null;
                    }),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterFrom = tempFrom;
                        _filterTo = tempTo;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    await _load();
  }

  Future<void> _editDuration(MindfulnessSession s) async {
    final controller = TextEditingController(text: s.durationSeconds.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit duration (seconds)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 600'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (ok != true) return;

    final value = int.tryParse(controller.text.trim());
    if (value == null || value < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid duration')));
      return;
    }

    try {
      await _service.updateSessionDuration(sessionId: s.sessionId, durationSeconds: value);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _delete(MindfulnessSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete session?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _service.deleteSession(s.sessionId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            ),
            OutlinedButton.icon(
              onPressed: _showFilter,
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.12)),
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _sessions.isEmpty
                ? const Center(child: Text('No sessions yet'))
                : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingRowHeight: 48,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Duration')),
                    DataColumn(label: Text('Pre')),
                    DataColumn(label: Text('Post')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: _sessions.map((s) {
                    final date = _dfDate.format(s.startedAt.toLocal());
                    final time = _dfTime.format(s.startedAt.toLocal());
                    final duration = _formatDuration(s.durationSeconds);

                    return DataRow(
                      cells: [
                        DataCell(Text(date)),
                        DataCell(Text(time)),
                        DataCell(Text(duration)),
                        DataCell(Text('${s.preMood ?? '-'}')),
                        DataCell(Text('${s.postMood ?? '-'}')),
                        DataCell(Text(s.completionStatus)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _editDuration(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _delete(s),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ),
      ],
    );
  }
}

class _PracticeCoverBackground extends StatelessWidget {
  const _PracticeCoverBackground({required this.assetPath});
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = (assetPath ?? '').trim();
    if (path.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Opacity(
          key: ValueKey(path),
          opacity: 0.95,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                stops: [0.0, 0.18, 0.82, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox.expand(
              child: Image.asset(
                path,
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.45),
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeThumb extends StatelessWidget {
  const _PracticeThumb({required this.assetPath, this.size = 28});

  final String? assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = (assetPath ?? '').trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: path.isEmpty
            ? const Icon(Icons.image_not_supported, size: 16)
            : Image.asset(
          path,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 16);
          },
        ),
      ),
    );
  }

}
class _InsightsPanel extends StatefulWidget {
  const _InsightsPanel();

  @override
  State<_InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<_InsightsPanel> {
  final _service = MindfulnessService();
  int _rangeDays = 7; // 7 / 30
  static const double _capMinutes = 60.0;

  Future<List<MindfulnessSession>> _load() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).subtract(Duration(days: _rangeDays - 1));
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _service.fetchSessions(from: from, to: to, limit: 1000);
  }

  Map<DateTime, int> _groupByDaySeconds(List<MindfulnessSession> sessions) {
    final map = <DateTime, int>{};
    for (final s in sessions) {
      final dt = s.startedAt.toLocal();
      final day = DateTime(dt.year, dt.month, dt.day);
      map[day] = (map[day] ?? 0) + (s.durationSeconds);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MindfulnessSession>>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final sessions = snap.data!;
        if (sessions.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Insights', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  ),
                  _RangeToggle(
                    value: _rangeDays,
                    onChanged: (v) => setState(() => _rangeDays = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Expanded(child: Center(child: Text('No data yet. Do some sessions first.'))),
            ],
          );
        }

        final grouped = _groupByDaySeconds(sessions);

        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: _rangeDays - 1));
        final days = List.generate(_rangeDays, (i) => start.add(Duration(days: i)));

        final rawMinutes = days.map((d) => (grouped[d] ?? 0) / 60.0).toList();
        final valuesMinutes = rawMinutes.map((m) => m.clamp(0.0, _capMinutes)).toList();
        final maxY = _capMinutes;

        final df = DateFormat('MM/dd');
        final totalDays = valuesMinutes.length;
        final double barWidth = 18;
        final double groupSpace = 10;
        final double chartWidth = totalDays * (barWidth + groupSpace);

        final groups = <BarChartGroupData>[];
        for (var i = 0; i < days.length; i++) {
          final y = valuesMinutes[i];
          groups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valuesMinutes[i],
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Insights', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                ),
                _RangeToggle(
                  value: _rangeDays,
                  onChanged: (v) => setState(() => _rangeDays = v),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _InsightSummaryCard(
              sessions: sessions,
              rangeDays: _rangeDays,
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.12)),
                ),
                child: Builder(
                  builder: (context) {
                    final totalDays = days.length;
                    const double barWidth = 16;
                    const double groupSpace = 20;

                    final double chartWidth = totalDays * (barWidth + groupSpace);
                    final chart = BarChart(
                      BarChartData(
                        maxY: maxY,
                        alignment: BarChartAlignment.start,
                        groupsSpace: 24,

                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final real = rawMinutes[group.x];
                              final suffix = real > _capMinutes ? ' (capped)' : '';
                              return BarTooltipItem(
                                '${real.toStringAsFixed(1)}m$suffix',
                                const TextStyle(fontWeight: FontWeight.w700),
                              );
                            },
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        barGroups: groups,

                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: 15,
                              getTitlesWidget: (value, meta) {
                                if (value % 15 != 0) return const SizedBox.shrink();
                                return Text(value.toInt().toString());
                              },
                            ),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,

                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= totalDays) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(df.format(days[i]), style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );

                    if (_rangeDays <= 7) return chart;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth.clamp(MediaQuery.of(context).size.width, double.infinity),
                        child: chart,
                      ),
                    );
                  },
                ),
              ),
            ),

          ],
        );
      },
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7D')),
        ButtonSegment(value: 30, label: Text('30D')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _InsightSummaryCard extends StatelessWidget {
  const _InsightSummaryCard({required this.sessions, required this.rangeDays});
  final List<MindfulnessSession> sessions;
  final int rangeDays;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final totalMinutes = (totalSeconds / 60).round();
    final avgSeconds = sessions.isEmpty ? 0 : (totalSeconds / sessions.length).round();
    final avgMinutes = (avgSeconds / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Sessions: ${sessions.length}', style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text('Total: ${totalMinutes}m', style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text('Avg: ${avgMinutes}m', style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}