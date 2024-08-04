// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the nodes added by a customizer
class CustomizerNodeReplacer {
  /// The constructor
  CustomizerNodeReplacer({
    required this.customizer,
  }) {
    init(customizer.scope);
  }

  // ...........................................................................
  /// Disposes the nodes and removes it from the scope
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  /// The customizer this class belongs to
  final Customizer customizer;

  /// Returns an example instance for test purposes
  static CustomizerNodeReplacer get example {
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

    final customizer =
        ExampleCustomizerReplacingIntNodes().instantiate(scope: scope);
    return customizer.nodeReplacer;
  }

  // ...........................................................................
  /// Deeply iterate through all child nodes and replace nodes
  void init(Scope scope) {
    _initScope(scope);

    for (final childScope in scope.children) {
      init(childScope);
    }
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _initScope(Scope scope) {
    for (final node in scope.nodes) {
      // Get the replacement for the node from the customizer
      final newBluePrint = customizer.bluePrint.replaceNode(
        hostScope: scope,
        nodeToBeReplaced: node,
      );

      // No change? Continue
      if (newBluePrint == node.bluePrint) {
        continue;
      }

      // Replace the blue print
      node.addBluePrint(newBluePrint);

      // On dispose we will revert the replacement
      _dispose.add(() {
        node.removeBluePrint(newBluePrint);
      });
    }
  }

  // ######################
  // Private
  // ######################

  final List<void Function()> _dispose = [];
}

// #############################################################################
/// An example customizer replacing a node
class ExampleCustomizerReplacingIntNodes extends CustomizerBluePrint {
  /// The constructor
  ExampleCustomizerReplacingIntNodes() : super(key: 'example');

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
