import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../utils/preferences_helper.dart';

class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  http.Client? _client;
  CalendarApi? _calendarApi;
  Box<String>? _gcalBox;
  final Map<String, Timer> _debounceTimers = {};
  StreamSubscription<BoxEvent>? _subscription;

  CalendarApi? get calendarApi {
    if (_calendarApi != null) return _calendarApi;

    // Try initializing via Supabase provider token if present
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.providerToken != null) {
      _client = BearerAuthClient(session.providerToken!);
      _calendarApi = CalendarApi(_client!);
      return _calendarApi;
    }
    return null;
  }

  bool get isConnected => calendarApi != null;

  /// Get the email of the connected Google Account
  Future<String?> getConnectedEmail() async {
    final api = calendarApi;
    if (api == null) return null;
    try {
      final calendar = await api.calendars.get('primary');
      return calendar.summary; // The primary calendar summary is typically the email address
    } catch (e) {
      debugPrint('Google Calendar: Error fetching account email - $e');
      return null;
    }
  }

  /// Initialize the service with the Hive box mapping task IDs to calendar event IDs
  Future<void> init(Box<String> gcalBox) async {
    _gcalBox = gcalBox;

    if (calendarApi != null) return;

    final credentialsJson = PreferencesHelper.getJson('google_calendar_credentials');
    if (credentialsJson == null) return;

    final clientIdStr = PreferencesHelper.getString('google_calendar_client_id');
    final clientSecretStr = PreferencesHelper.getString('google_calendar_client_secret');

    if (clientIdStr == null || clientIdStr.isEmpty) return;

    final clientId = ClientId(clientIdStr, clientSecretStr ?? '');
    final credentials = AccessCredentials(
      AccessToken(
        credentialsJson['token_type'] as String,
        credentialsJson['access_token'] as String,
        DateTime.parse(credentialsJson['token_expiry'] as String),
      ),
      credentialsJson['refresh_token'] as String?,
      (credentialsJson['scopes'] as List<dynamic>).map((e) => e as String).toList(),
    );

    try {
      final authClient = autoRefreshingClient(clientId, credentials, http.Client());
      _client = authClient;
      _calendarApi = CalendarApi(authClient);

      authClient.credentialUpdates.listen((newCreds) {
        _saveCredentials(newCreds);
      });
    } catch (e) {
      debugPrint('Google Calendar: Initialization failed - $e');
    }
  }

  /// Start the OAuth 2.0 Loopback Consent Flow
  Future<void> signIn({
    required String clientIdStr,
    required String clientSecretStr,
    required Function(String url) onUrlReady,
  }) async {
    final clientId = ClientId(clientIdStr, clientSecretStr);
    final scopes = [CalendarApi.calendarEventsScope];

    // clientViaUserConsent starts a local loopback server, launches the browser via custom callback,
    // and blocks until the authorization code is received and exchanged.
    final authClient = await clientViaUserConsent(clientId, scopes, (url) {
      onUrlReady(url);
    });

    _client = authClient;
    _calendarApi = CalendarApi(authClient);

    await PreferencesHelper.setString('google_calendar_client_id', clientIdStr);
    await PreferencesHelper.setString('google_calendar_client_secret', clientSecretStr);
    await _saveCredentials(authClient.credentials);

    authClient.credentialUpdates.listen((newCreds) {
      _saveCredentials(newCreds);
    });
  }

  /// Log out and clean up credentials and state
  Future<void> signOut() async {
    // Cancel any active debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    await _subscription?.cancel();
    _subscription = null;

    _client?.close();
    _client = null;
    _calendarApi = null;

    await _gcalBox?.clear();

    await PreferencesHelper.remove('google_calendar_credentials');
    await PreferencesHelper.remove('google_calendar_client_id');
    await PreferencesHelper.remove('google_calendar_client_secret');
  }

  Future<void> _saveCredentials(AccessCredentials creds) async {
    await PreferencesHelper.setJson('google_calendar_credentials', {
      'access_token': creds.accessToken.data,
      'token_type': creds.accessToken.type,
      'token_expiry': creds.accessToken.expiry.toUtc().toIso8601String(),
      'refresh_token': creds.refreshToken,
      'scopes': creds.scopes,
    });
  }

  /// Listen to changes in the local Hive tasks box to sync in the background
  void startListening(Box<Task> tasksBox) {
    _subscription?.cancel();
    _subscription = tasksBox.watch().listen((event) {
      if (!isConnected) return;

      final taskId = event.key.toString();
      if (event.deleted) {
        _scheduleDebouncedDelete(taskId);
      } else {
        final task = event.value as Task;
        _scheduleDebouncedSync(task);
      }
    });
  }

  void _scheduleDebouncedDelete(String taskId) {
    _debounceTimers[taskId]?.cancel();
    _debounceTimers[taskId] = Timer(const Duration(milliseconds: 500), () async {
      try {
        final eventId = _gcalBox?.get(taskId) ?? _getEventId(taskId);
        await deleteEvent(eventId);
        await _gcalBox?.delete(taskId);
      } catch (e) {
        debugPrint('Google Calendar: Debounced delete failed - $e');
      }
      _debounceTimers.remove(taskId);
    });
  }

  void _scheduleDebouncedSync(Task task) {
    _debounceTimers[task.id]?.cancel();

    // Snapshot the task properties to prevent race conditions during debounce delay
    final taskId = task.id;
    final title = task.title;
    final description = task.description;
    final deadline = task.deadline;
    final isCompleted = task.isCompleted;
    final isDeleted = task.isDeleted;
    final isArchived = task.isArchived;
    final subTasks = task.subTasks.map((t) => Task(id: t.id, title: t.title, isCompleted: t.isCompleted)).toList();

    _debounceTimers[taskId] = Timer(const Duration(milliseconds: 200), () async {
      try {
        await _syncTaskData(
          taskId: taskId,
          title: title,
          description: description,
          deadline: deadline,
          isCompleted: isCompleted,
          isDeleted: isDeleted,
          isArchived: isArchived,
          subTasks: subTasks,
        );
      } catch (e) {
        debugPrint('Google Calendar: Debounced sync failed - $e');
      }
      _debounceTimers.remove(taskId);
    });
  }

  /// Perform a full initial sync of all tasks with deadlines
  Future<void> initialSync(Box<Task> tasksBox) async {
    final api = calendarApi;
    if (api == null) return;
    debugPrint('Google Calendar: Running initial sync...');
    for (final task in tasksBox.values) {
      if (!task.isDeleted && !task.isArchived && task.deadline != null) {
        final subTasksCopy = task.subTasks.map((t) => Task(id: t.id, title: t.title, isCompleted: t.isCompleted)).toList();
        await _syncTaskData(
          taskId: task.id,
          title: task.title,
          description: task.description,
          deadline: task.deadline,
          isCompleted: task.isCompleted,
          isDeleted: task.isDeleted,
          isArchived: task.isArchived,
          subTasks: subTasksCopy,
        );
      }
    }
    debugPrint('Google Calendar: Initial sync completed.');
  }

  String _getEventId(String taskId) {
    // Google Calendar event ID constraints: base32hex (a-v, 0-9), length 5-1024.
    // UUID with hyphens removed is 32 characters of a-f, 0-9, which is valid base32hex.
    return taskId.replaceAll('-', '').toLowerCase();
  }

  /// Internal sync implementation using snapshotted data
  Future<void> _syncTaskData({
    required String taskId,
    required String title,
    String? description,
    DateTime? deadline,
    required bool isCompleted,
    required bool isDeleted,
    required bool isArchived,
    required List<Task> subTasks,
  }) async {
    final api = calendarApi;
    if (api == null) return;

    final calEventId = _getEventId(taskId);

    // If task is deleted, archived, or has no deadline, remove from calendar
    if (isDeleted || isArchived || deadline == null) {
      final eventId = _gcalBox?.get(taskId) ?? calEventId;
      await deleteEvent(eventId);
      await _gcalBox?.delete(taskId);
      return;
    }

    final bool syncCompleted = PreferencesHelper.getBool('gcal_sync_completed') ?? true;

    // Delete event if task is completed but the user disabled completed tasks syncing
    if (isCompleted && !syncCompleted) {
      final eventId = _gcalBox?.get(taskId) ?? calEventId;
      await deleteEvent(eventId);
      await _gcalBox?.delete(taskId);
      return;
    }

    final eventTitle = isCompleted ? '✓ $title' : title;
    final eventDescription = _buildEventDescriptionText(description, subTasks);

    // Create 30-minute block for calendar events
    final event = Event(
      id: calEventId,
      summary: eventTitle,
      description: eventDescription,
      start: EventDateTime(
        dateTime: deadline.toUtc(),
        timeZone: 'UTC',
      ),
      end: EventDateTime(
        dateTime: deadline.add(const Duration(minutes: 30)).toUtc(),
        timeZone: 'UTC',
      ),
    );

    bool alreadyCheckedOrUpdated = false;
    final cachedEventId = _gcalBox?.get(taskId);

    if (cachedEventId != null) {
      try {
        await api.events.update(event, 'primary', cachedEventId);
        debugPrint('Google Calendar: Updated cached event $cachedEventId for task $taskId');
        alreadyCheckedOrUpdated = true;
      } catch (e) {
        if (e is DetailedApiRequestError && e.status == 404) {
          // Cached event was deleted from calendar
          alreadyCheckedOrUpdated = false;
        } else {
          debugPrint('Google Calendar: Error updating cached event - $e');
          rethrow;
        }
      }
    }

    if (!alreadyCheckedOrUpdated) {
      try {
        // Try updating first with the deterministic event ID in case it already exists in Google Calendar
        await api.events.update(event, 'primary', calEventId);
        await _gcalBox?.put(taskId, calEventId);
        debugPrint('Google Calendar: Updated existing event $calEventId for task $taskId');
      } catch (e) {
        if (e is DetailedApiRequestError && e.status == 404) {
          // Does not exist on Google Calendar, insert a new one
          try {
            final createdEvent = await api.events.insert(event, 'primary');
            if (createdEvent.id != null) {
              await _gcalBox?.put(taskId, createdEvent.id!);
              debugPrint('Google Calendar: Created event ${createdEvent.id} for task $taskId');
            }
          } catch (insertError) {
            debugPrint('Google Calendar: Error inserting event - $insertError');
            rethrow;
          }
        } else {
          debugPrint('Google Calendar: Error updating event by deterministic ID - $e');
          rethrow;
        }
      }
    }
  }

  /// Delete a Google Calendar event by ID
  Future<void> deleteEvent(String eventId) async {
    final api = calendarApi;
    if (api == null) return;
    try {
      await api.events.delete('primary', eventId);
      debugPrint('Google Calendar: Deleted event $eventId');
    } catch (e) {
      if (e is DetailedApiRequestError && e.status == 404) {
        return; // Ignore if already deleted from Calendar
      }
      debugPrint('Google Calendar: Error deleting event $eventId - $e');
      rethrow;
    }
  }

  String _buildEventDescriptionText(String? description, List<Task> subTasks) {
    final buffer = StringBuffer();
    if (description != null && description.trim().isNotEmpty) {
      buffer.writeln(description.trim());
      buffer.writeln();
    }
    if (subTasks.isNotEmpty) {
      buffer.writeln('Subtasks:');
      for (final sub in subTasks) {
        final checkbox = sub.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('$checkbox ${sub.title}');
      }
      buffer.writeln();
    }
    buffer.writeln('Synced from AntiMatter Task Manager');
    return buffer.toString();
  }
}

class BearerAuthClient extends http.BaseClient {
  final String _token;
  final http.Client _inner = http.Client();

  BearerAuthClient(this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
