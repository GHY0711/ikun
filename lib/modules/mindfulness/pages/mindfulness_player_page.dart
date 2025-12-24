import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'mindfulness_global_audio_player.dart';


class MindfulnessPlayerPage extends StatefulWidget {
  const MindfulnessPlayerPage({
    super.key,
    required this.title,
    required this.mediaType, 
    required this.pathOrUrl,
  });

  final String title;
  final String mediaType;
  final String pathOrUrl;

  @override
  State<MindfulnessPlayerPage> createState() => _MindfulnessPlayerPageState();
}

class _MindfulnessPlayerPageState extends State<MindfulnessPlayerPage> {
  
  final AudioPlayer _audioPlayer = GlobalAudioPlayer.player;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;
  String? _currentSource;

 
  VideoPlayerController? _videoController;

  bool get _isAsset => widget.pathOrUrl.trim().startsWith('assets/');
  String get _audioAssetSource =>
      widget.pathOrUrl.replaceFirst(RegExp(r'^assets\/'), ''); 
  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'audio') {
      _initAudio();
    } else {
      _initVideo();
    }
  }

  Future<void> _initAudio() async {
    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
    });

    if (GlobalAudioPlayer.currentSource != widget.pathOrUrl) {
      GlobalAudioPlayer.currentSource = widget.pathOrUrl;

      if (_isAsset) {
        await _audioPlayer.setSource(AssetSource(_audioAssetSource));
      } else {
        await _audioPlayer.setSourceUrl(widget.pathOrUrl);
      }
    }
  }

  Future<void> _initVideo() async {
    final controller = _isAsset
        ? VideoPlayerController.asset(widget.pathOrUrl)
        : VideoPlayerController.networkUrl(Uri.parse(widget.pathOrUrl));

    _videoController = controller;

    await controller.initialize();
    controller.setLooping(true);
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    final h = d.inHours;
    return h > 0 ? '${two(h)}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isAudio = widget.mediaType == 'audio';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isAudio ? _buildAudio() : _buildVideo(),
      ),
    );
  }

  Widget _buildAudio() {
    final canSeek = _duration.inMilliseconds > 0;
    final maxMs = _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_isAsset ? 'Source: Asset' : 'Source: URL'),
        const SizedBox(height: 10),
        Slider(
          value: canSeek ? posMs : 0,
          max: canSeek ? maxMs : 1,
          onChanged: canSeek
              ? (v) => _audioPlayer.seek(Duration(milliseconds: v.round()))
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(_position)),
            Text(_fmt(_duration)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 44,
              onPressed: () async {
                if (_playerState == PlayerState.playing) {
                  await _audioPlayer.pause();
                  return;
                }
                if (_playerState == PlayerState.stopped) {
                  if (_isAsset) {
                    await _audioPlayer.play(AssetSource(_audioAssetSource));
                  } else {
                    await _audioPlayer.play(UrlSource(widget.pathOrUrl));
                  }
                  return;
                }
                await _audioPlayer.resume();
              },

              icon: Icon(
                _playerState == PlayerState.playing ? Icons.pause_circle : Icons.play_circle,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              iconSize: 44,
              onPressed: () async {
                await _audioPlayer.stop();
                await _audioPlayer.seek(Duration.zero);
              },
              icon: const Icon(Icons.stop_circle),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideo() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: VideoPlayer(c),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 44,
              onPressed: () {
                setState(() {
                  c.value.isPlaying ? c.pause() : c.play();
                });
              },
              icon: Icon(c.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
            ),
            const SizedBox(width: 12),
            IconButton(
              iconSize: 44,
              onPressed: () {
                c.seekTo(Duration.zero);
                c.pause();
                setState(() {});
              },
              icon: const Icon(Icons.stop_circle),
            ),
          ],
        ),
      ],
    );
  }
}
