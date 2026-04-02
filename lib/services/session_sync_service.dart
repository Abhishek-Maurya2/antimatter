import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../models/session.dart';

class SessionSyncService {
  final _supabase = Supabase.instance.client;
  final Box<Session> _sessionsBox;
  bool _isSyncingFromServer = false;

  SessionSyncService(this._sessionsBox);

  /// Pull all sessions from Supabase and merge them into the local Hive box
  Future<void> pullSessions() async {
    try {
      _isSyncingFromServer = true;
      final response = await _supabase
          .from('sessions')
          .select()
          .timeout(const Duration(seconds: 15));

      if (response != null) {
        for (final row in response) {
          final session = Session.fromJson(row);
          await _sessionsBox.put(session.id, session);
        }
        debugPrint(
          'Supabase Session Sync: Successfully pulled ${response.length} sessions.',
        );
      }
    } catch (e) {
      debugPrint('Supabase Session Sync: Error pulling sessions - $e');
    } finally {
      _isSyncingFromServer = false;
    }
  }

  /// Push a single session to Supabase
  Future<void> pushSession(Session session) async {
    if (_isSyncingFromServer) return;

    try {
      await _supabase
          .from('sessions')
          .upsert(session.toJson())
          .timeout(const Duration(seconds: 15));
      // debugPrint('Supabase Session Sync: Pushed session ${session.id}');
    } catch (e) {
      debugPrint(
        'Supabase Session Sync: Error pushing session ${session.id} - $e',
      );
    }
  }

  /// Listen to local Hive box changes
  void startListening() {
    _sessionsBox.listenable().addListener(() {
      if (_isSyncingFromServer) return;

      // Push all currently unsynced or newly added sessions
      // For simplicity, we just push all (Supabase upsert handles duplicates)
      for (final session in _sessionsBox.values) {
        pushSession(session);
      }
    });
  }
}
