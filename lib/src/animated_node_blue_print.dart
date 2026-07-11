// @license
// Copyright (c) 2019 - 2026 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

// .............................................................................
/// The identity (linear) animation curve.
double linearCurve(double t) => t;

// .............................................................................
/// The blue print of an [AnimatedNode].
///
/// See [AnimatedNode] for the animation semantics. An animated node has exactly
/// one supplier (the target value) and eases its output toward that target over
/// [totalFrames] frames.
class AnimatedNodeBluePrint<T> extends NodeBluePrint<T> {
  // ...........................................................................
  /// Creates a blue print for an [AnimatedNode].
  ///
  /// - [key]: the node key (camelCase)
  /// - [initialProduct]: the initial (and first snapped) output value
  /// - [suppliers]: exactly one supplier path - the target value
  /// - [totalFrames]: the number of [Scm.tick]s an animation spans (>= 1)
  /// - [curve]: maps normalized time t in [0, 1] to eased progress in [0, 1]
  /// - [lerp]: interpolates between two values of type [T]
  /// - [equals]: decides whether the input changed (defaults to `==`); also
  ///   used to gate redundant downstream propagation
  // Explicit super call: fixed produce/gating arguments are passed to super,
  // which super parameters do not allow.
  // ignore: use_super_parameters
  AnimatedNodeBluePrint({
    required String key,
    required T initialProduct,
    required List<String> suppliers,
    required this.totalFrames,
    required this.curve,
    required this.lerp,
    bool Function(T a, T b)? equals,
    String documentation = '',
  }) : isEqual = equals ?? _defaultEquals<T>,
       super(
         key: key,
         initialProduct: initialProduct,
         suppliers: suppliers,
         documentation: documentation,
         produce: _produce<T>,
         propagateOnChangeOnly: true,
         changeComparator: equals ?? _defaultEquals<T>,
       );

  // ...........................................................................
  /// The number of [Scm.tick]s an animation spans.
  final int totalFrames;

  /// Maps normalized time t in [0, 1] to eased progress in [0, 1].
  final double Function(double t) curve;

  /// Interpolates between two values of type [T] at progress t in [0, 1].
  final T Function(T a, T b, double t) lerp;

  /// Decides whether the input value changed between two productions.
  final bool Function(T a, T b) isEqual;

  // ...........................................................................
  @override
  void check() {
    super.check();
    if (suppliers.length != 1) {
      throw ArgumentError(
        'An AnimatedNode must have exactly one supplier (the target value).',
      );
    }
    if (totalFrames < 1) {
      throw ArgumentError('totalFrames must be >= 1.');
    }
  }

  // ...........................................................................
  @override
  Node<T> createNode({required Scope scope, Owner<Node<dynamic>>? owner}) =>
      AnimatedNode<T>(bluePrint: this, scope: scope, owner: owner);

  // ...........................................................................
  /// The produce function installed on every [AnimatedNode]. Drives the
  /// animation by delegating to [AnimatedNode.advance].
  static S _produce<S>(
    List<dynamic> components,
    S previousProduct,
    Node<S> node,
  ) => (node as AnimatedNode<S>).advance(components, previousProduct);

  // ...........................................................................
  /// Convenience blue print for animating a [double] with linear interpolation
  /// and NaN-aware change detection.
  // ignore: prefer_constructors_over_static_methods
  static AnimatedNodeBluePrint<double> forDouble({
    required String key,
    required double initialProduct,
    required List<String> suppliers,
    required int totalFrames,
    required double Function(double t) curve,
    String documentation = '',
  }) => AnimatedNodeBluePrint<double>(
    key: key,
    initialProduct: initialProduct,
    suppliers: suppliers,
    totalFrames: totalFrames,
    curve: curve,
    lerp: (a, b, t) => a + (b - a) * t,
    equals: (a, b) => a == b || (a.isNaN && b.isNaN),
    documentation: documentation,
  );

  // ...........................................................................
  /// Convenience blue print for animating an [int] with rounded linear
  /// interpolation.
  // ignore: prefer_constructors_over_static_methods
  static AnimatedNodeBluePrint<int> forInt({
    required String key,
    required int initialProduct,
    required List<String> suppliers,
    required int totalFrames,
    required double Function(double t) curve,
    String documentation = '',
  }) => AnimatedNodeBluePrint<int>(
    key: key,
    initialProduct: initialProduct,
    suppliers: suppliers,
    totalFrames: totalFrames,
    curve: curve,
    lerp: (a, b, t) => (a + (b - a) * t).round(),
    documentation: documentation,
  );
}

bool _defaultEquals<T>(T a, T b) => a == b;
