import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../services/resource_service.dart';

class ResourceDetailPage extends StatefulWidget {
  const ResourceDetailPage({super.key});

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  // Async load future and route arg
  late Future<ResourceDto?> _future;
  late int _resourceId;

  // Favorite state
  bool _isFav = false;

  // Controllers for media
  YoutubePlayerController? _ytController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _ytErrorText;

  // Green palette helpers
  Color get _primaryGreen => Colors.green.shade600;
  Color get _chipGreen => Colors.green.shade100;

  // Read route args and kick off load
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resourceId = ModalRoute.of(context)!.settings.arguments as int;
    _future = _load();
  }

  // Dispose controllers to avoid leaks
  @override
  void dispose() {
    _ytController?.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // Load resource, record view, and sync favorites
  Future<ResourceDto?> _load() async {
    try {
      final r = await ResourceService.fetchById(_resourceId);
      if (r != null) await ResourceService.recordView(_resourceId);
      final favs = await ResourceService.fetchFavoriteIds();
      if (mounted) setState(() => _isFav = favs.contains(_resourceId));
      return r;
    } catch (e) {
      debugPrint('Error loading resource: $e');
      return null;
    }
  }

  // Toggle favorite state
  Future<void> _toggleFav() async {
    try {
      await ResourceService.toggleFavorite(_resourceId, !_isFav);
      final favs = await ResourceService.fetchFavoriteIds();
      if (mounted) {
        setState(() => _isFav = favs.contains(_resourceId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFav ? 'Added to favorites' : 'Removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Main UI with FutureBuilder
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResourceDto?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        if (snap.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Resource'),
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Resource not found')),
          );
        }

        final r = snap.data!;
        final c = r.content;

        return Scaffold(
          appBar: AppBar(
            title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  _isFav ? Icons.favorite : Icons.favorite_border,
                  color: _isFav ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFav,
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  r.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Category + type chips
                Row(
                  children: [
                    if (r.categoryName != null)
                      Chip(
                        label: Text(r.categoryName!),
                        backgroundColor: _chipGreen,
                      ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(r.contentType),
                      backgroundColor: Colors.green.shade50,
                      avatar: Icon(_iconForType(r.contentType), size: 16, color: _primaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Summary
                if (r.summary != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(r.summary!),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Content block
                if (c != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Content',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildContent(r.contentType, c),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Tags
                if (r.tags.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Tags',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: r.tags
                            .map((t) => Chip(
                          label: Text(t),
                          backgroundColor: Colors.grey[200],
                        ))
                            .toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Route to the right content renderer
  Widget _buildContent(String type, ResourceContent c) {
    switch (type) {
      case 'video':
        return _buildInlineVideo(c);
      case 'counselling':
        return _buildCounsellingContent(c);
      default:
        return _buildExternalLinkContent(c);
    }
  }

  // Video renderer (YouTube or direct)
  Widget _buildInlineVideo(ResourceContent c) {
    final raw = c.videoUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return const Text('No video link available');
    }
    final normalized = _normalizeUrl(raw);

    // YouTube
    final ytId =
        YoutubePlayer.convertUrlToId(normalized) ?? _extractYouTubeIdFromMaybeBare(normalized);
    if (_isYouTube(normalized) && ytId != null) {
      _ytController ??= YoutubePlayerController(
        initialVideoId: ytId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          forceHD: false,
          enableCaption: true,
        ),
      )..addListener(() {
        final val = _ytController?.value;
        if (val == null) return;
        if (val.hasError) {
          setState(() => _ytErrorText = val.errorCode.toString());
        }
      });

      if (_ytErrorText != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YouTube error: $_ytErrorText'),
            const SizedBox(height: 8),
            _fallbackLaunch(normalized, 'Open video externally'),
          ],
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: _primaryGreen,
        ),
      );
    }

    // Non-YouTube direct link
    _videoController ??= VideoPlayerController.networkUrl(Uri.parse(normalized));
    _chewieController ??= ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
    );

    return FutureBuilder(
      future: _videoController!.initialize(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return _fallbackLaunch(normalized, 'Open video');
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        );
      },
    );
  }

  // Extract possible YouTube ID variants
  String? _extractYouTubeIdFromMaybeBare(String url) {
    final trimmed = url.trim();
    if (!trimmed.contains('.') && trimmed.length >= 6 && trimmed.length <= 64) {
      return trimmed;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    final embedIdx = uri.pathSegments.indexOf('embed');
    if (embedIdx != -1 && embedIdx + 1 < uri.pathSegments.length) {
      return uri.pathSegments[embedIdx + 1];
    }
    final shortsIdx = uri.pathSegments.indexOf('shorts');
    if (shortsIdx != -1 && shortsIdx + 1 < uri.pathSegments.length) {
      return uri.pathSegments[shortsIdx + 1];
    }
    return null;
  }

  // Fallback button to open externally
  Widget _fallbackLaunch(String url, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inline playback unavailable.'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _launchUrl(url),
        ),
      ],
    );
  }

  // Counselling info renderer
  Widget _buildCounsellingContent(ResourceContent c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.contactName != null) ...[
          _buildInfoRow(Icons.person, 'Counsellor', c.contactName!),
          const SizedBox(height: 12),
        ],
        if (c.contactEmail != null) ...[
          _buildLinkRow(Icons.email, 'Email', c.contactEmail!, 'mailto:${c.contactEmail}'),
          const SizedBox(height: 12),
        ],
        if (c.contactPhone != null) ...[
          _buildLinkRow(Icons.phone, 'Phone', c.contactPhone!, 'tel:${c.contactPhone}'),
          const SizedBox(height: 12),
        ],
        if (c.officeLocation != null) ...[
          _buildInfoRow(Icons.location_on, 'Location', c.officeLocation!),
          const SizedBox(height: 12),
        ],
        if (c.officeHours != null) ...[
          _buildInfoRow(Icons.schedule, 'Hours', c.officeHours!),
        ],
      ],
    );
  }

  // External link renderer (kept purple per original)
  Widget _buildExternalLinkContent(ResourceContent c) {
    if (c.externalLink == null || c.externalLink!.isEmpty) {
      return const Text('No external link available');
    }
    final link = _normalizeUrl(c.externalLink!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.link, size: 48, color: Colors.purple),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _launchUrl(link),
          ),
        ],
      ),
    );
  }

  // Info row helper
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  // Link row helper
  Widget _buildLinkRow(IconData icon, String label, String value, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Launch URL (external for YouTube, in-app for others)
  Future<void> _launchUrl(String url) async {
    try {
      final normalized = _normalizeUrl(url);
      final uri = Uri.tryParse(normalized);

      if (uri == null || uri.host.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Invalid link')));
        }
        return;
      }

      final mode = (uri.host.contains('youtube.com') || uri.host.contains('youtu.be'))
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView;

      final ok = await launchUrl(uri, mode: mode);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Helpers: URL type checks and normalization
  bool _isYouTube(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') || lower.contains('youtu.be');
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('www.')) {
      return 'https://$trimmed';
    }
    if (!trimmed.contains('.') && trimmed.length >= 6 && trimmed.length <= 64) {
      return 'https://youtu.be/$trimmed';
    }
    return 'https://$trimmed';
  }

  // Icon helper for content type
  IconData _iconForType(String t) {
    switch (t) {
      case 'video':
        return Icons.play_circle_fill;
      case 'counselling':
        return Icons.support_agent;
      case 'external':
        return Icons.link;
      default:
        return Icons.description;
    }
  }
}