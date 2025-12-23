import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mindfulness_category_model.dart';
import '../models/mindfulness_practice_model.dart';
import '../models/mindfulness_practice_content_model.dart';
import '../models/mindfulness_session_model.dart';

class MindfulnessService {
  MindfulnessService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String _requireEmail() {
    final email = _client.auth.currentUser?.email;
    if (email == null) throw const AuthException('User not logged in');
    return email;
  }


  Future<int> _requireAppUserId() async {
    final email = _requireEmail();

    final row = await _client
        .from('user')
        .select('user_id')
        .eq('user_email', email)
        .limit(1)
        .maybeSingle();

    if (row == null) {
      final inserted = await _client
          .from('user')
          .insert({
        'user_name': email.split('@').first,
        'user_email': email,
        'user_icon': 'assets/images/defaultIcon.png',
        'user_type': 'user',
        'user_status': true,
      })
          .select('user_id')
          .single();

      return (inserted['user_id'] as num).toInt();
    }

    return (row['user_id'] as num).toInt();
  }

  // ----- Category -----
  Future<List<MindfulnessCategory>> fetchCategories() async {
    final data = await _client
        .from('mindfulnessCategory')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => MindfulnessCategory.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ----- Practice -----
  Future<List<MindfulnessPractice>> fetchPractices({String? categoryId}) async {
    var q = _client.from('mindfulnessPractice').select();

    if (categoryId != null) {
      final cid = int.tryParse(categoryId);
      if (cid != null) q = q.eq('mind_category_id', cid);
    }

    final data = await q.order('created_at', ascending: true);

    return (data as List)
        .map((e) => MindfulnessPractice.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ----- Content -----
  Future<List<MindfulnessPracticeContent>> fetchPracticeContents(String practiceId) async {
    final pid = int.tryParse(practiceId);

    final data = await _client
        .from('mindfulnessPracticeContent')
        .select()
        .eq('mind_practice_id', pid ?? practiceId)
        .order('sort_order', ascending: true);

    return (data as List)
        .map((e) => MindfulnessPracticeContent.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ----- Session -----
  Future<List<MindfulnessSession>> fetchSessions({
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    final userId = await _requireAppUserId();

    var q = _client
        .from('mindfulnessSession')
        .select('session_id, user_id, mind_practice_id, started_at, ended_at, duration_seconds, completion_status, completion_rate, pre_mood, post_mood, created_at, mindfulnessPractice(practice_type)')
        .eq('user_id', userId);


    if (from != null) q = q.gte('started_at', from.toUtc().toIso8601String());
    if (to != null) q = q.lte('started_at', to.toUtc().toIso8601String());

    final data = await q.order('started_at', ascending: false).limit(limit);

    return (data as List)
        .map((e) => MindfulnessSession.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<MindfulnessSession> createSession({
    required String practiceId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    String completionStatus = 'completed',
    double completionRate = 100,
    int? preMood,
    int? postMood,
  }) async {
    final userId = await _requireAppUserId();
    final pid = int.tryParse(practiceId);
    final inserted = await _client
        .from('mindfulnessSession')
        .insert({
      'user_id': userId,
      'mind_practice_id': pid ?? practiceId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'duration_seconds': durationSeconds,
      'completion_status': completionStatus,
      'completion_rate': completionRate,
      'pre_mood': preMood,
      'post_mood': postMood,
    })
        .select()
        .single();

    return MindfulnessSession.fromMap(inserted as Map<String, dynamic>);
  }

  Future<void> updateSessionDuration({
    required String sessionId,
    required int durationSeconds,
  }) async {
    final sid = int.tryParse(sessionId);
    await _client
        .from('mindfulnessSession')
        .update({'duration_seconds': durationSeconds})
        .eq('session_id', sid ?? sessionId);
  }

  Future<void> deleteSession(String sessionId) async {
    final sid = int.tryParse(sessionId);
    await _client.from('mindfulnessSession').delete().eq('session_id', sid ?? sessionId);
  }
  Future<Map<String, dynamic>?> fetchPracticeMedia(String mindPracticeId) async {
    final pid = int.tryParse(mindPracticeId);

    final res = await _client
        .from('mindfulnessPracticeContent')
        .select('audio_path, video_path')
        .eq('mind_practice_id', pid ?? mindPracticeId)
        .order('sort_order', ascending: true)
        .limit(1)
        .maybeSingle();

    return res == null ? null : (res as Map<String, dynamic>);
  }
  Future<List<MindfulnessPracticeContent>> fetchAudioContents(String practiceId) async {
    final pid = int.tryParse(practiceId);

    final data = await _client
        .from('mindfulnessPracticeContent')
        .select()
        .eq('mind_practice_id', pid ?? practiceId)
        .not('audio_path', 'is', null)
        .neq('audio_path', '')
        .order('sort_order', ascending: true);

    return (data as List)
        .map((e) => MindfulnessPracticeContent.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MindfulnessPracticeContent>> fetchVideoContents(String practiceId) async {
    final pid = int.tryParse(practiceId);

    final data = await _client
        .from('mindfulnessPracticeContent')
        .select()
        .eq('mind_practice_id', pid ?? practiceId)
        .not('video_path', 'is', null)
        .neq('video_path', '')
        .order('sort_order', ascending: true);

    return (data as List)
        .map((e) => MindfulnessPracticeContent.fromMap(e as Map<String, dynamic>))
        .toList();
  }


  Future<int> _nextSortOrder(String practiceId, String type) async {
    final pid = int.tryParse(practiceId);

    final row = await _client
        .from('mindfulnessPracticeContent')
        .select('sort_order')
        .eq('mind_practice_id', pid ?? practiceId)
        .eq('content_type', type)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return 1;
    final last = (row['sort_order'] as num?)?.toInt() ?? 0;
    return last + 1;
  }
  Future<void> uploadAndInsertAudio({
    required String practiceId,
    required Uint8List bytes,
    required String fileName,
    String? title,
    String bucketName = 'mindfulness_media',
  }) async {
    final sortOrder = await _nextSortOrder(practiceId, 'audio');

    final safeName = fileName.replaceAll(' ', '_');
    final storagePath = 'mindfulness/audio/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage.from(bucketName).uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'audio/mpeg',
      ),
    );

    final url = _client.storage.from(bucketName).getPublicUrl(storagePath);

    final pid = int.tryParse(practiceId);
    await _client.from('mindfulnessPracticeContent').insert({
      'mind_practice_id': pid ?? practiceId,
      'content_type': 'audio',
      'audio_path': url,
      'text_content': (title?.trim().isNotEmpty ?? false) ? title!.trim() : safeName, // 當歌曲名
      'sort_order': sortOrder,
    });
  }
  Future<void> uploadAndInsertVideo({
    required String practiceId,
    required Uint8List bytes,
    required String fileName,
    String? title,
    String bucketName = 'mindfulness_media',
  }) async {
    final sortOrder = await _nextSortOrder(practiceId, 'video');

    final safeName = fileName.replaceAll(' ', '_');
    final storagePath = 'mindfulness/video/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage.from(bucketName).uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'video/mp4',
      ),
    );

    final url = _client.storage.from(bucketName).getPublicUrl(storagePath);

    final pid = int.tryParse(practiceId);
    await _client.from('mindfulnessPracticeContent').insert({
      'mind_practice_id': pid ?? practiceId,
      'content_type': 'video',
      'video_path': url,
      'text_content': (title?.trim().isNotEmpty ?? false) ? title!.trim() : safeName, // 當影片名
      'sort_order': sortOrder,
    });
  }

}
