// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the nodes added by a plugin
class PluginNodeAdder {
  /// The constructor
  PluginNodeAdder({
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
  static PluginNodeAdder get example {
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

    final plugin = ExamplePluginAddingNodes().instantiate(scope: scope);
    return plugin.nodeAdder;
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
    final bluePrints = plugin.bluePrint.addNodes(
      hostScope: scope,
    );

    // Make sure the node does not already exist.
    for (final bluePrint in bluePrints) {
      final node = scope.node<dynamic>(bluePrint.key);
      if (node != null) {
        throw Exception(
          'Node with key "${bluePrint.key}" already exists. '
          'Please use "PluginBluePrint:replaceNode" instead.',
        );
      }
    }

    // Replace the blue print
    scope.findOrCreateNodes(bluePrints);

    // On dispose, we will remove the added nodes again
    _dispose.add(() {
      scope.removeNodes(bluePrints);
    });
  }

  // ######################
  // Private
  // ######################

  final List<void Function()> _dispose = [];
}

// #############################################################################
/// An example node adder for test purposes
class ExamplePluginAddingNodes extends PluginBluePrint {
  /// The constructor
  ExamplePluginAddingNodes() : super(key: 'example');

  @override
  List<NodeBluePrint<dynamic>> addNodes({
    required Scope hostScope,
  }) {
    // Add k,j to example scope
    if (hostScope.key == 'example') {
      return const [
        NodeBluePrint<int>(
          key: 'k',
          initialProduct: 12,
        ),
        NodeBluePrint<int>(
          key: 'j',
          initialProduct: 367,
        ),
      ];
    }
    // Add x,y to c scope
    if (hostScope.key == 'c') {
      return const [
        NodeBluePrint<int>(
          key: 'x',
          initialProduct: 966,
        ),
        NodeBluePrint<int>(
          key: 'y',
          initialProduct: 767,
        ),
      ];
    } else {
      return []; // coverage:ignore-line
    }
  }
}
