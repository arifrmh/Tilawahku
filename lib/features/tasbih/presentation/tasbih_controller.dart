import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/tasbih_repository.dart';
import '../domain/tasbih_models.dart';

const MethodChannel _hapticsChannel = MethodChannel('id.tilawahku/haptics');

Future<void> _defaultTapHaptic() async {
  try {
    final handled = await _hapticsChannel.invokeMethod<bool>('tap');
    if (handled == true) return;
  } on MissingPluginException {
    // Fallback untuk platform non-Android dan lingkungan tes.
  } catch (_) {}
  await HapticFeedback.heavyImpact();
}

Future<void> _defaultTargetHaptic() async {
  try {
    final handled = await _hapticsChannel.invokeMethod<bool>('targetReached');
    if (handled == true) return;
  } on MissingPluginException {
    // Fallback untuk platform non-Android dan lingkungan tes.
  } catch (_) {}
  await HapticFeedback.vibrate();
}

class TasbihController extends ChangeNotifier {
  TasbihController({
    required TasbihRepository repository,
    Future<void> Function()? onTapHaptic,
    Future<void> Function()? onTargetReachedHaptic,
  }) : _repository = repository,
       _onTapHaptic = onTapHaptic ?? _defaultTapHaptic,
       _onTargetReachedHaptic =
           onTargetReachedHaptic ?? _defaultTargetHaptic;

  final TasbihRepository _repository;
  final Future<void> Function() _onTapHaptic;
  final Future<void> Function() _onTargetReachedHaptic;

  TasbihState _state = const TasbihState();
  bool _loading = true;
  bool _justReachedTarget = false;
  bool _disposed = false;

  TasbihState get state => _state;
  bool get loading => _loading;
  bool get justReachedTarget => _justReachedTarget;

  Future<void> load() async {
    _loading = true;
    _notify();
    _state = await _repository.loadState();
    _loading = false;
    _notify();
  }

  Future<void> tap() async {
    final (next, reached) = _state.increment();
    _state = next;
    _justReachedTarget = reached;
    _notify();
    if (_state.hapticEnabled) {
      try {
        if (reached) {
          await _onTargetReachedHaptic();
        } else {
          await _onTapHaptic();
        }
      } catch (_) {}
    }
    await _repository.saveState(_state);
  }

  Future<void> undo() async {
    final next = _state.decrement();
    if (identical(next, _state)) return;
    _state = next;
    _justReachedTarget = false;
    _notify();
    await _repository.saveState(_state);
  }

  Future<void> selectPreset(TasbihPreset preset) async {
    if (_state.presetId == preset.id) return;
    _state = _state.copyWith(
      presetId: preset.id,
      count: 0,
      target: preset.defaultTarget,
      completedRounds: 0,
      totalCount: 0,
    );
    _justReachedTarget = false;
    _notify();
    await _repository.saveState(_state);
  }

  Future<void> setTarget(int target) async {
    _state = _state.withTarget(target);
    _justReachedTarget = false;
    _notify();
    await _repository.saveState(_state);
  }

  Future<void> toggleHaptic() async {
    _state = _state.copyWith(hapticEnabled: !_state.hapticEnabled);
    _notify();
    await _repository.saveState(_state);
  }

  Future<void> resetCurrentRound() async {
    _state = _state.copyWith(count: 0);
    _justReachedTarget = false;
    _notify();
    await _repository.saveState(_state);
  }

  Future<void> resetAll() async {
    _state = _state.copyWith(count: 0, completedRounds: 0, totalCount: 0);
    _justReachedTarget = false;
    _notify();
    await _repository.saveState(_state);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
