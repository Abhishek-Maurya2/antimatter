import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/session.dart';

part 'sessions_provider.g.dart';

@Riverpod(keepAlive: true)
class SessionsController extends _$SessionsController {
  late final Box<Session> _box;

  @override
  List<Session> build() {
    _box = Hive.box<Session>('sessionsBox');

    // Listen to Hive box changes
    final listenable = _box.listenable();
    void listener() {
      state = _box.values.toList();
    }

    listenable.addListener(listener);
    ref.onDispose(() {
      listenable.removeListener(listener);
    });

    return _box.values.toList();
  }

  Box<Session> get box => _box;
}
