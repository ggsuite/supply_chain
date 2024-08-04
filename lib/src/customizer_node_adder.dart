// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the nodes added by a customizer
class CustomizerNodeAdder {
  /// The constructor
  CustomizerNodeAdder({
    required this.customizer,
  });

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
  static CustomizerNodeAdder get example {
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

    final customizer = ExampleCustomizerAddingNodes().instantiate(scope: scope);
    return customizer.nodeAdder;
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
    final bluePrints = customizer.bluePrint.addNodes(
      hostScope: scope,
    );

    // Make sure the node does not already exist.
    for (final bluePrint in bluePrints) {
      final node = scope.node<dynamic>(bluePrint.key);
      if (node != null) {
        throw Exception(
          'Node with key "${bluePrint.key}" already exists. '
          'Please use "CustomizerBluePrint:replaceNode" instead.',
        );
      }
    }

    // Add the nodes to the scope
    final addedNodes = scope.findOrCreateNodes(bluePrints);

    // On dispose, we will dispose also all added nodes
    _dispose.add(() {
      for (final node in addedNodes) {
        node.dispose();
      }
    });
  }

  // ######################
  // Private
  // ######################

  final List<void Function()> _dispose = [];
}

// #############################################################################
/// An example node adder for test purposes
class ExampleCustomizerAddingNodes extends CustomizerBluePrint {
  /// The constructor
  ExampleCustomizerAddingNodes() : super(key: 'example');

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
