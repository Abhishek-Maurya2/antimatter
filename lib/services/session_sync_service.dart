import 'dart:async';
import 'dart:collection';
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
  final Set<String> _pendingPushSessionIds = HashSet<String>();
  final Set<String> _pendingDeleteSessionIds = HashSet<String>();
  final Map<String, Timer> _debounceTimers = {};
  RealtimeChannel? _realtimeChannel;

  // Queue to serialize realtime event processing and avoid interleaving
  Future<void> _realtimeQueue = Future.value();

  SessionSyncService(this._sessionsBox);

  /// Pull all sessions from Supabase, merge into local Hive box,
  /// then push any local-only sessions that are missing from the server.
  Future<void> pullSessions() async {
    try {
      _isSyncingFromServer = true;
      List<Map<String, dynamic>>? response;
      int retryCount = 0;
      const maxRetries = 3;

      final lastSync = PreferencesHelper.getString('sessions_last_sync');

      while (retryCount < maxRetries) {
        try {
          var query = _supabase.from('sessions').select();
          if (lastSync != null) {
            query = query.gte('updated_at', lastSync);
          }
          response = await query.timeout(const Duration(seconds: 15));
          break; // Success
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          // Exponential backoff
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      if (response != null) {
        // Track which session IDs came from the server in this pull
        final Set<String> pulledIds = {};

        for (final row in response) {
          final session = Session.fromJson(row);
          pulledIds.add(session.id);
          await _sessionsBox.put(session.id, session);
        }
        debugPrint(
          'Supabase Session Sync: Successfully pulled ${response.length} sessions.',
        );
        PreferencesHelper.setString(
          'sessions_last_sync',
          DateTime.now()
              .toUtc()
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
        );

        // Push local sessions that are missing from the server.
        // If this is an incremental sync (lastSync != null), we need to
        // fetch all remote session IDs to know which local ones are missing.
        await _pushMissingSessions(lastSync != null ? pulledIds : null);
      }
    } catch (e) {
      debugPrint('Supabase Session Sync: Error pulling sessions - $e');
    } finally {
      _isSyncingFromServer = false;
      await _flushPendingPushes();
    }
  }

  /// Identify local sessions that don't exist on the server and push them.
  /// For incremental syncs we fetch all remote IDs to compare; for full syncs
  /// we already have the complete set from the pull response.
  Future<void> _pushMissingSessions(Set<String>? incrementalPulledIds) async {
    try {
      Set<String> remoteIds;

      if (incrementalPulledIds != null) {
        // Incremental sync – the pulled IDs only include recently updated rows,
        // so fetch the full list of remote session IDs for comparison.
        final allRemote = await _supabase
            .from('sessions')
            .select('id')
            .timeout(const Duration(seconds: 15));
        remoteIds = {
          for (final row in allRemote) row['id'] as String,
        };
      } else {
        // Full sync – we already have the complete set.
        // But incrementalPulledIds is null for first sync with no lastSync.
        // Re-read: when lastSync == null we did a full pull, but the caller
        // passes null, so we need to handle this. Let's query anyway to be safe.
        final allRemote = await _supabase
            .from('sessions')
            .select('id')
            .timeout(const Duration(seconds: 15));
        remoteIds = {
          for (final row in allRemote) row['id'] as String,
        };
      }

      // Find local sessions missing from the server
      final localIds = _sessionsBox.keys.cast<String>().toSet();
      final missingIds = localIds.difference(remoteIds);

      if (missingIds.isNotEmpty) {
        debugPrint(
          'Supabase Session Sync: Found ${missingIds.length} local-only sessions, pushing to server...',
        );
        for (final id in missingIds) {
          final session = _sessionsBox.get(id);
          if (session != null) {
            await _pushSessionDirect(session);
          }
        }
        debugPrint(
          'Supabase Session Sync: Pushed ${missingIds.length} missing sessions.',
        );
      }
    } catch (e) {
      debugPrint(
        'Supabase Session Sync: Error pushing missing sessions - $e',
      );
    }
  }

  /// Push a single session to Supabase (called from listener or flush).
  /// Skips push if currently syncing from server and queues it instead.
  Future<void> pushSession(Session session) async {
    if (_isSyncingFromServer) {
      _pendingDeleteSessionIds.remove(session.id);
      _pendingPushSessionIds.add(session.id);
      return;
    }

    if (_pendingDeleteSessionIds.contains(session.id)) {
      return;
    }

    await _pushSessionDirect(session);
  }

  /// Direct push with retry logic, bypassing the syncing-from-server guard.
  Future<void> _pushSessionDirect(Session session) async {
    try {
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          await _supabase
              .from('sessions')
              .upsert(session.toJson())
              .timeout(const Duration(seconds: 15));
          break; // Success
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }
    } catch (e) {
      debugPrint(
        'Supabase Session Sync: Error pushing session ${session.id} - $e',
      );
    }
  }

  /// Permanently delete a session in Supabase by ID
  Future<void> deleteSession(String sessionId) async {
    if (_isSyncingFromServer) {
      _pendingPushSessionIds.remove(sessionId);
      _pendingDeleteSessionIds.add(sessionId);
      return;
    }

    try {
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          await _supabase
              .from('sessions')
              .delete()
              .eq('id', sessionId)
              .timeout(const Duration(seconds: 15));
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      debugPrint('Supabase Session Sync: Deleted session $sessionId');
    } catch (e) {
      debugPrint(
        'Supabase Session Sync: Error deleting session $sessionId - $e',
      );
    }
  }

  /// Listen to local Hive box changes
  void startListening() {
    _sessionsBox.watch().listen((event) {
      if (_isSyncingFromServer) {
        if (event.deleted) {
          _pendingDeleteSessionIds.add(event.key.toString());
        } else {
          _pendingPushSessionIds.add(event.key.toString());
        }
        return;
      }

      if (event.deleted) {
        deleteSession(event.key.toString());
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

  /// Flush any pushes/deletes that were deferred while syncing from the server.
  Future<void> _flushPendingPushes() async {
    if (_pendingPushSessionIds.isEmpty && _pendingDeleteSessionIds.isEmpty) {
      return;
    }

    final pendingDeleteIds = _pendingDeleteSessionIds.toList();
    _pendingDeleteSessionIds.clear();
    for (final id in pendingDeleteIds) {
      await deleteSession(id);
    }

    final pendingIds = _pendingPushSessionIds.toList();
    _pendingPushSessionIds.clear();
    for (final id in pendingIds) {
      final session = _sessionsBox.get(id);
      if (session != null) {
        await pushSession(session);
      }
    }
  }

  /// Subscribe to Supabase Realtime so that session changes made on other
  /// devices are immediately applied to the local Hive box.
  void subscribeToRealtime() {
    _realtimeChannel = _supabase
        .channel('public:sessions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sessions',
          callback: _handleRealtimeEvent,
        )
        .subscribe();
    debugPrint('Supabase Realtime: Subscribed to sessions table.');
  }

  Future<void> _handleRealtimeEvent(PostgresChangePayload payload) {
    // Enqueue to serialize processing and prevent flag interleaving
    _realtimeQueue = _realtimeQueue.then((_) => _processRealtimeEvent(payload));
    return _realtimeQueue;
  }

  Future<void> _processRealtimeEvent(PostgresChangePayload payload) async {
    try {
      _isSyncingFromServer = true;
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          await _sessionsBox.delete(id);
          debugPrint(
            'Supabase Realtime: Deleted session $id from local box.',
          );
        }
      } else {
        // INSERT or UPDATE
        final session = Session.fromJson(payload.newRecord);
        await _sessionsBox.put(session.id, session);
        debugPrint(
          'Supabase Realtime: Upserted session ${session.id} in local box.',
        );
      }
    } catch (e) {
      debugPrint('Supabase Realtime: Error handling session event - $e');
    } finally {
      _isSyncingFromServer = false;
    }
  }

  /// Unsubscribe from Supabase Realtime and cancel all debounce timers.
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }
}
