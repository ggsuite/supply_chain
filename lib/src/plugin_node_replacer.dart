// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the nodes of a plugin
class PluginNodeReplacer {
  /// The constructor
  PluginNodeReplacer({
    required this.plugin,
  }) {
    _init(plugin.scope);
  }

  // ...........................................................................
  /// Disposes the nodes and removes it from the scope
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  /// The plugin this class belongs to
  final Plugin plugin;

  /// Returns an example instance for test purposes
  static PluginNodeReplacer get example {
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

    final plugin = ReplaceIntNodesBy42().instantiate(scope: scope);
    return plugin.nodeReplacer;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init(Scope scope) {
    // Deeply iterate through all child nodes and replace nodes
    _initScope(scope);

    for (final childScope in scope.children) {
      _init(childScope);
    }
  }

  // ...........................................................................
  void _initScope(Scope scope) {
    for (final node in scope.nodes) {
      // Get the replacement for the node from the plugin
      final newBluePrint = plugin.bluePrint.replaceNode(
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
/// An example plugin replacing a node
class ReplaceIntNodesBy42 extends PluginBluePrint {
  /// The constructor
  ReplaceIntNodesBy42() : super(key: 'example');

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
