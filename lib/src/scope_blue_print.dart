// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A scope blue print is a collection of related node blue prints.
/// that can form or build a scope.
class ScopeBluePrint {
  /// Constructor of the scope
  ScopeBluePrint({
    required this.key,
    required this.nodes,
    required this.fakeDependencies,
  });

  /// The key of the scope
  final String key;

  /// The nodes of the scope
  final List<NodeBluePrint<dynamic>> nodes;

  /// The dependencies of the scope.
  final List<NodeBluePrint<dynamic>> fakeDependencies;

  /// Creates an example instance for test purposes
  factory ScopeBluePrint.example() {
    /// Fake an external dependency
    final dependency = NodeBluePrint<int>(
      key: 'Dependency',
      initialProduct: 0,
      suppliers: [],
    );

    /// Create a node that depends on the external dependency
    final node = NodeBluePrint<int>(
      key: 'Node',
      initialProduct: 1,
      suppliers: ['Dependency'],
      produce: (components, previousProduct) {
        final [int dependency] = components;
        return dependency + 1;
      },
    );

    /// Create a customer that depends on the external dependency
    final customer = NodeBluePrint<int>(
      key: 'Customer',
      initialProduct: 1,
      suppliers: ['Node'],
      produce: (components, previousProduct) {
        final [int node0] = components;
        return node0 + 1;
      },
    );

    /// return the result
    return ScopeBluePrint(
      key: 'Example',
      nodes: [node, customer],
      fakeDependencies: [dependency],
    );
  }

  /// Turns the blue print into a scope and adds it to the parent scope.
  Scope instantiate({
    required Scope parentScope,
    bool fakeMissingDependencies = false,
    bool createOwnScope = true,
  }) {
    // Get the example blue print
    final scopeBluePrint = this;

    // Add dependencies to the outer scope
    if (fakeMissingDependencies) {
      parentScope.findOrCreateNodes(scopeBluePrint.fakeDependencies);
    }

    // Create an inner scope
    final innerScope =
        createOwnScope ? Scope(parent: parentScope, key: 'Inner') : parentScope;

    // Add nodes to the inner scope
    innerScope.findOrCreateNodes(scopeBluePrint.nodes);

    /// Returns the created exampleScope
    return innerScope;
  }
}
