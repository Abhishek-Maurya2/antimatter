import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../models/session.dart';
import '../utils/preferences_helper.dart';

class SessionSyncService {
  final _supabase = Supabase.instance.client;
  final Box<Session> _sessionsBox;
  bool _isSyncingFromServer = false;
  final Map<String, Timer> _debounceTimers = {};

  SessionSyncService(this._sessionsBox);

  /// Pull all sessions from Supabase and merge them into the local Hive box
  Future<void> pullSessions() async {
    try {
      _isSyncingFromServer = true;
      final lastSync = PreferencesHelper.getString('sessions_last_sync');
      var query = _supabase.from('sessions').select();
      if (lastSync != null) {
        query = query.gte('updated_at', lastSync);
      }
      final response = await query.timeout(const Duration(seconds: 15));

      if (response != null) {
        for (final row in response) {
          final session = Session.fromJson(row);
          await _sessionsBox.put(session.id, session);
        }
        debugPrint(
          'Supabase Session Sync: Successfully pulled ${response.length} sessions.',
        );
        PreferencesHelper.setString('sessions_last_sync', DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String());
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
    _sessionsBox.watch().listen((event) {
      if (_isSyncingFromServer) return;

      if (event.deleted) {
        // Handle deletion if necessary
      } else {
        final session = event.value as Session;
        _scheduleDebouncedPush(session);
      }
    });
  }

  void _scheduleDebouncedPush(Session session) {
    _debounceTimers[session.id]?.cancel();
    _debounceTimers[session.id] = Timer(const Duration(milliseconds: 500), () {
      pushSession(session);
      _debounceTimers.remove(session.id);
    });
  }
}
