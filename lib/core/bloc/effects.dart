import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One-shot effects (shake, toast, navigate) next to a bloc's state.
///
/// State is deduplicated, so a second identical failure would emit nothing;
/// effects always arrive, once.
mixin Effects<S, E> on BlocBase<S> {
  final _effects = StreamController<E>.broadcast();

  Stream<E> get effects => _effects.stream;

  @protected
  void effect(E e) {
    if (!_effects.isClosed) _effects.add(e);
  }

  @override
  Future<void> close() async {
    await _effects.close();
    return super.close();
  }
}

/// Runs [listener] for every effect of the nearest [B].
class EffectListener<B extends Effects<Object?, E>, E> extends StatefulWidget {
  const EffectListener({
    super.key,
    required this.listener,
    required this.child,
  });

  final void Function(BuildContext context, E effect) listener;
  final Widget child;

  @override
  State<EffectListener<B, E>> createState() => _EffectListenerState<B, E>();
}

class _EffectListenerState<B extends Effects<Object?, E>, E>
    extends State<EffectListener<B, E>> {
  StreamSubscription<E>? _sub;
  B? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<B>();
    if (identical(bloc, _bloc)) return;
    _sub?.cancel();
    _bloc = bloc;
    _sub = bloc.effects.listen((e) {
      if (mounted) widget.listener(context, e);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
