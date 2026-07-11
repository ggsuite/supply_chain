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
class AnimatedNode<T> extends Node<T> {
  // ...........................................................................
  /// Creates an animated node from [bluePrint] within [scope].
  // Explicit super call: [bluePrint] is narrowed and its config is read into
  // final fields, which super parameters do not allow.
  // ignore: use_super_parameters
  AnimatedNode({
    required AnimatedNodeBluePrint<T> bluePrint,
    required Scope scope,
    Owner<Node<dynamic>>? owner,
  }) : _totalFrames = bluePrint.totalFrames,
       _curve = bluePrint.curve,
       _lerp = bluePrint.lerp,
       _equals = bluePrint.isEqual,
       _from = bluePrint.initialProduct,
       _to = bluePrint.initialProduct,
       _lastSeenInput = bluePrint.initialProduct,
       _frame = bluePrint.totalFrames,
       super(bluePrint: bluePrint, scope: scope, owner: owner);

  // ...........................................................................
  /// Returns true while an animation is in progress.
  bool get isAnimating => isAnimated;

  /// Called once when an animation reaches its final frame.
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
  /// Advances the animation by one frame and returns this frame's value.
  ///
  /// Called by [animatedNodeProduce] on every production. A production that is
  /// triggered by a changed input (re)starts the animation without consuming a
  /// frame; a production triggered by a tick (input unchanged) advances exactly
  /// one frame.
  @internal
  T advance(List<dynamic> components, T previousOutput) {
    final input = components.single as T;

    // First production: snap to the input, no animation.
    if (!_initialized) {
      _initialized = true;
      _to = input;
      _lastSeenInput = input;
      _frame = _totalFrames;
      return input;
    }

    // Input changed -> (re)start the animation. Do not consume a frame.
    if (!_equals(input, _lastSeenInput)) {
      _from = previousOutput;
      _to = input;
      _lastSeenInput = input;
      _frame = 0;

      // Nothing to animate: snap.
      if (_equals(_from, _to)) {
        isAnimated = false;
        return _to;
      }

      isAnimated = true;
      return _from;
    }

    // Input unchanged -> this production came from a tick. Advance one frame.
    if (_frame >= _totalFrames) {
      isAnimated = false;
      return _to;
    }

    _frame++;
    if (_frame >= _totalFrames) {
      isAnimated = false;
      onComplete?.call();
      return _to;
    }

    return _lerp(_from, _to, _curve(_frame / _totalFrames));
  }

  // ...........................................................................
  @override
  void dispose() {
    // Stop animating before disposal. Node.dispose() only removes the node
    // from the SCM's animated set when it is erased (no customers left); an
    // animating node kept alive by customers would otherwise tick forever.
    isAnimated = false;
    super.dispose();
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
    scope.scm.flush(tick: false);
    return scope.findNode<double>(key)! as AnimatedNode<double>;
  }

  // ######################
  // Private
  // ######################

  final int _totalFrames;
  final double Function(double t) _curve;
  final T Function(T a, T b, double t) _lerp;
  final bool Function(T a, T b) _equals;

  T _from;
  T _to;
  T _lastSeenInput;
  int _frame;
  bool _initialized = false;
}
