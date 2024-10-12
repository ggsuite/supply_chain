// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the nodes added by a builder
class ScBuilderNodeReplacer {
  /// The constructor
  ScBuilderNodeReplacer({
    required this.builder,
  });

  // ...........................................................................
  /// Disposes the nodes and removes it from the scope
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  /// The builder this class belongs to
  final ScBuilder builder;

  /// Returns an example instance for test purposes
  static ScBuilderNodeReplacer get example {
    final scope = Scope.example();

    scope.mockContent({
      'a': 1,
      'b': 2,
      'c': {
        'd': 4,
        'e': 5,
        'f': 'f',
      },
    });

    final builder =
        ExampleScBuilderReplacingIntNodes().instantiate(scope: scope);
    return builder.nodeReplacer;
  }

  // ...........................................................................
  /// Deeply iterate through all child nodes and replace nodes
  void applyToScope(Scope scope) {
    if (!builder.bluePrint.shouldProcessScope(scope)) return;
    _applyToScope(scope);

    for (final childScope in scope.children) {
      applyToScope(childScope);
    }
  }

  /// Apply the builder to a node
  void applyToNode(Node<dynamic> node) {
    _applyToNode(node);
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _applyToScope(Scope scope) {
    for (final node in scope.nodes) {
      _applyToNode(node);
    }
  }

  // ...........................................................................
  void _applyToNode(Node<dynamic> node) {
    // Get the smartNode for the node from the builder
    final newBluePrint = builder.bluePrint.replaceNode(
      hostScope: node.scope,
      nodeToBeReplaced: node,
    );

    // No change? Continue
    if (newBluePrint == node.bluePrint) {
      return;
    }

    // Replace the blue print
    node.addBluePrint(newBluePrint);

    // On dispose we will revert the smartNode
    _dispose.add(() {
      node.removeBluePrint(newBluePrint);
    });
  }

  // ######################
  // Private
  // ######################

  final List<void Function()> _dispose = [];
}

// #############################################################################
/// An example builder replacing a node
class ExampleScBuilderReplacingIntNodes extends ScBuilderBluePrint {
  /// The constructor
  ExampleScBuilderReplacingIntNodes() : super(key: 'example');

  @override
  bool shouldProcessScope(Scope scope) {
    return true;
  }

  @override
  NodeBluePrint<dynamic> replaceNode({
    required Scope hostScope,
    required Node<dynamic> nodeToBeReplaced,
  }) {
    if (nodeToBeReplaced is Node<int>) {
      return nodeToBeReplaced.bluePrint.copyWith(
        produce: (components, previous) => 42,
      );
    }

    return super.replaceNode(
      hostScope: hostScope,
      nodeToBeReplaced: nodeToBeReplaced,
    );
  }
}
