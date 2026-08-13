// @license
// Copyright (c) ggsuite
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
  /// - [equals]: decides whether the input (target) changed between two
  ///   productions (defaults to `==` with NaN treated equal to NaN). It is
  ///   deliberately NOT used to gate downstream propagation: output gating
  ///   always uses exact equality, so a tolerance-based [equals] cannot
  ///   swallow intermediate animation frames.
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
    bool canBeSmart = true,
    List<String> smartMaster = const [],
    Duration? productionTimeout,
  }) : isEqual = equals ?? _defaultEquals<T>,
       super(
         key: key,
         initialProduct: initialProduct,
         suppliers: suppliers,
         documentation: documentation,
         produce: _produce<T>,
         canBeSmart: canBeSmart,
         smartMaster: smartMaster,
         productionTimeout: productionTimeout,
         propagateOnChangeOnly: true,
         changeComparator: _defaultEquals<T>,
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
  /// Creates a modified copy that stays an [AnimatedNodeBluePrint].
  ///
  /// Passing a [produce] intentionally makes the copy non-animated (e.g. the
  /// muting in [Node.dispose]) and falls back to the base implementation.
  /// [propagateOnChangeOnly] and [changeComparator] are fixed for animated
  /// blue prints and cannot be overridden.
  @override
  NodeBluePrint<T> copyWith({
    T? initialProduct,
    String? key,
    Iterable<String>? suppliers,
    Produce<T>? produce,
    bool? canBeSmart,
    List<String>? smartMaster,
    Duration? productionTimeout,
    bool? propagateOnChangeOnly,
    bool Function(T a, T b)? changeComparator,
  }) {
    if (produce != null) {
      return super.copyWith(
        initialProduct: initialProduct,
        key: key,
        suppliers: suppliers,
        produce: produce,
        canBeSmart: canBeSmart,
        smartMaster: smartMaster,
        productionTimeout: productionTimeout,
        propagateOnChangeOnly: propagateOnChangeOnly,
        changeComparator: changeComparator,
      );
    }

    return AnimatedNodeBluePrint<T>(
      key: key ?? this.key,
      initialProduct: initialProduct ?? this.initialProduct,
      suppliers: (suppliers ?? this.suppliers).toList(),
      totalFrames: totalFrames,
      curve: curve,
      lerp: lerp,
      equals: isEqual,
      documentation: documentation,
      canBeSmart: canBeSmart ?? this.canBeSmart,
      smartMaster: smartMaster ?? this.smartMaster,
      productionTimeout: productionTimeout ?? this.productionTimeout,
    );
  }

  // ...........................................................................
  /// Rewires the supplier while keeping the animation.
  ///
  /// Overridden so that framework paths rewiring blue prints (e.g.
  /// [ScopeBluePrint] connections and smart-node master replacement) do not
  /// silently replace the animation with hard value-forwarding.
  @override
  NodeBluePrint<T> connectSupplier(String supplier) =>
      copyWith(suppliers: [supplier]);

  // ...........................................................................
  /// The produce function installed on every [AnimatedNode]. Drives the
  /// animation by delegating to [AnimatedNode.advance].
  static S _produce<S>(
    List<dynamic> components,
    S previousProduct,
    Node<S> node,
  ) {
    if (node is! AnimatedNode<S>) {
      throw StateError(
        'An AnimatedNodeBluePrint must be instantiated as an AnimatedNode, '
        'but it is attached to a ${node.runtimeType} ("${node.path}"). '
        'This happens e.g. when the blue print is used as an insert or '
        'added to an existing plain node via addBluePrint.',
      );
    }
    return node.advance(components, previousProduct);
  }

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
    bool Function(int a, int b)? equals,
    String documentation = '',
  }) => AnimatedNodeBluePrint<int>(
    key: key,
    initialProduct: initialProduct,
    suppliers: suppliers,
    totalFrames: totalFrames,
    curve: curve,
    lerp: (a, b, t) => (a + (b - a) * t).round(),
    equals: equals,
    documentation: documentation,
  );
}

/// Exact equality with NaN treated equal to NaN.
///
/// NaN != NaN would make an animated node treat an unchanged NaN input as a
/// change on every production and restart its animation forever.
bool _defaultEquals<T>(T a, T b) =>
    a == b || (a is double && b is double && a.isNaN && b.isNaN);
