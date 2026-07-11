// @license
// Copyright (c) 2019 - 2026 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:meta/meta.dart';
import 'package:supply_chain/supply_chain.dart';

// .............................................................................
/// A node that eases its output toward a new input value.
///
/// An [AnimatedNode] has exactly one supplier: the target (input) value. When
/// the target changes, the node animates its own output from its current value
/// toward the new target over [AnimatedNodeBluePrint.totalFrames] frames,
/// producing one intermediate value per [Scm.tick]. The shape of the easing is
/// given by [AnimatedNodeBluePrint.curve]; the interpolation between two values
/// by [AnimatedNodeBluePrint.lerp].
///
/// The node manages [Node.isAnimated] itself: it starts animating when the
/// input changes and stops when the animation settles. The very first input is
/// snapped without animation (there is no previous value to animate from).
///
/// Frames advance with [Scm.tick]s: every production consumes at most one
/// frame, and only when a tick happened since the previous production. A
/// target change rebases the animation from the current output - and when the
/// production was tick-driven the animation still advances one frame, so a
/// target that changes on every tick keeps easing toward its latest value
/// instead of freezing at its old one.
class AnimatedNode<T> extends Node<T> {
  // ...........................................................................
  /// Creates an animated node from [bluePrint] within [scope].
  AnimatedNode({
    required AnimatedNodeBluePrint<T> bluePrint,
    required super.scope,
    super.owner,
  }) : _from = bluePrint.initialProduct,
       _to = bluePrint.initialProduct,
       _lastSeenInput = bluePrint.initialProduct,
       _frame = bluePrint.totalFrames,
       super(bluePrint: bluePrint);

  // ...........................................................................
  /// Returns true while an animation is in progress.
  bool get isAnimating => isAnimated;

  /// Called once when an animation reaches its final frame.
  ///
  /// Invoked after the final product has been applied and the production has
  /// been finalized - the callback observes the settled value and may safely
  /// mutate the graph.
  void Function()? onComplete;

  // ...........................................................................
  /// The current animation frame.
  @visibleForTesting
  int get frame => _frame;

  /// The value the current animation started from.
  @visibleForTesting
  T get from => _from;

  /// The value the current animation is heading toward.
  @visibleForTesting
  T get to => _to;

  // ...........................................................................
  /// Advances the animation and returns this production's value.
  ///
  /// Called by [AnimatedNodeBluePrint] on every production. A changed input
  /// (re)starts the animation from the current output. At most one frame is
  /// consumed per production, and only when a [Scm.tick] happened since the
  /// previous production - a supplier re-emission between ticks returns the
  /// current output unchanged.
  @internal
  T advance(List<dynamic> components, T previousOutput) {
    final input = components.single as T;
    final config = _config;
    final equals = config.isEqual;

    // Did a tick happen since the previous production? Only then a frame
    // may be consumed.
    final tick = scm.tickCount;
    final tickElapsed = tick != _lastSeenTick;
    _lastSeenTick = tick;

    // First production: snap to the input, no animation.
    if (!_initialized) {
      _initialized = true;
      _from = input;
      _to = input;
      _lastSeenInput = input;
      _frame = config.totalFrames;
      return input;
    }

    // Input changed -> (re)start the animation from the current output.
    if (!equals(input, _lastSeenInput)) {
      _from = previousOutput;
      _to = input;
      _lastSeenInput = input;

      // Nothing to animate: snap and settle.
      if (equals(_from, _to)) {
        _frame = config.totalFrames;
        isAnimated = false;
        return _to;
      }

      _frame = 0;
      isAnimated = true;

      // A tick-driven production still advances one frame - otherwise a
      // target changing on every tick would freeze the output forever.
      return tickElapsed ? _advanceFrame(config) : _from;
    }

    // Input unchanged and already settled: keep the settled value.
    if (_frame >= config.totalFrames) {
      isAnimated = false;
      return _to;
    }

    // No tick since the previous production (the supplier re-emitted the
    // same value): don't consume a frame.
    if (!tickElapsed) {
      return previousOutput;
    }

    return _advanceFrame(config);
  }

  // ...........................................................................
  @override
  void finalizeProduction() {
    super.finalizeProduction();

    // Deferred from _advanceFrame: at this point the final product has been
    // applied and the node has left the production pipeline, so onComplete
    // observes the settled value and may safely mutate the graph.
    if (_completePending) {
      _completePending = false;
      onComplete?.call();
    }
  }

  // ...........................................................................
  @override
  set mockedProduct(T? t) {
    // Mocking bypasses advance(). Stop the animation so the node does not
    // stay in the SCM's animated set and produce on every tick forever.
    if (t != null) {
      isAnimated = false;
      _completePending = false;
      _frame = _config.totalFrames;
    }
    super.mockedProduct = t;
  }

  // ...........................................................................
  @override
  void addBluePrint(NodeBluePrint<T> bluePrint) {
    super.addBluePrint(bluePrint);
    _stopAnimationIfProduceWasRerouted();
  }

  @override
  void removeBluePrint(NodeBluePrint<T> bp) {
    super.removeBluePrint(bp);
    _stopAnimationIfProduceWasRerouted();
  }

  // ...........................................................................
  /// Creates an example animated node for test purposes.
  static AnimatedNode<double> example({
    String key = 'animated',
    int totalFrames = 4,
  }) {
    final scope = Scope.example();
    scope.mockContent({
      'target': 0.0,
      key: AnimatedNodeBluePrint.forDouble(
        key: key,
        initialProduct: 0.0,
        suppliers: ['target'],
        totalFrames: totalFrames,
        curve: linearCurve,
      ),
    });
    scope.scm.flush();
    return scope.findNode<double>(key)! as AnimatedNode<double>;
  }

  // ######################
  // Private
  // ######################

  /// The animation config is read live from the blue print, so replacing the
  /// blue print on a live node (e.g. via [Node.addBluePrint]) takes effect.
  AnimatedNodeBluePrint<T> get _config => bluePrint as AnimatedNodeBluePrint<T>;

  /// Consumes one frame and returns its value. Settles on the final frame.
  T _advanceFrame(AnimatedNodeBluePrint<T> config) {
    _frame++;
    if (_frame >= config.totalFrames) {
      isAnimated = false;
      _completePending = true;
      return _to;
    }
    return config.lerp(_from, _to, config.curve(_frame / config.totalFrames));
  }

  /// A blue print that routes production away from [advance] must not leave
  /// the node in the SCM's animated set - it would be re-produced on every
  /// tick forever.
  void _stopAnimationIfProduceWasRerouted() {
    if (bluePrint is! AnimatedNodeBluePrint<T>) {
      isAnimated = false;
      _completePending = false;
    }
  }

  T _from;
  T _to;
  T _lastSeenInput;
  int _frame;
  int _lastSeenTick = -1;
  bool _initialized = false;
  bool _completePending = false;
}
