// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A scope blue print is a collection of related node blue prints.
/// that can form or build a scope.
class ScopeBluePrint {
  // ...........................................................................
  /// Constructor of the scope
  const ScopeBluePrint({
    required this.key,
    required this.nodes,
    required this.dependencies,
  });

  // ...........................................................................
  /// Creates a copy of the scope with the given changes
  ScopeBluePrint copyWith({
    String? key,
    List<NodeBluePrint<dynamic>>? nodes,
    List<NodeBluePrint<dynamic>>? dependencies,
    List<NodeBluePrint<dynamic>> overrides = const [],
  }) {
    nodes = nodes ?? this.nodes;
    nodes = _replaceNodes(nodes, overrides);

    return ScopeBluePrint._private(
      key: key ?? this.key,
      nodes: nodes,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  // ...........................................................................
  @override
  String toString() {
    return key;
  }

  // ...........................................................................
  /// The key of the scope
  final String key;

  /// The nodes of the scope
  final List<NodeBluePrint<dynamic>> nodes;

  /// The dependencies of the scope.
  final List<NodeBluePrint<dynamic>> dependencies;

  // ...........................................................................
  /// Returns the node for a given key
  NodeBluePrint<T>? findNode<T>(String key) => _findNodeByKey<T>(key, nodes);

  // ...........................................................................
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
      parentScope.findOrCreateNodes(scopeBluePrint.dependencies);
    }

    // Create an inner scope
    final innerScope =
        createOwnScope ? Scope(parent: parentScope, key: key) : parentScope;

    // Add nodes to the inner scope
    innerScope.findOrCreateNodes(scopeBluePrint.nodes);

    // Init suppliers
    innerScope.initSuppliers();

    /// Returns the created exampleScope
    return innerScope;
  }

  // ...........................................................................
  /// Creates an example instance for test purposes
  factory ScopeBluePrint.example() {
    /// Fake an external dependency
    const dependency = NodeBluePrint<int>(
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
      dependencies: [dependency],
    );
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  /// Private constructor
  ScopeBluePrint._private({
    required this.key,
    required this.nodes,
    required this.dependencies,
  });

  // ...........................................................................
  /// Finds a node with a given key in a given list of nodes.
  /// Returns null if no one is found
  static NodeBluePrint<T>? _findNodeByKey<T>(
    String key,
    List<NodeBluePrint<dynamic>> nodes,
  ) {
    for (final node in nodes) {
      if (node.key == key) {
        if (node is NodeBluePrint<T>) {
          return node;
        } else {
          throw ArgumentError('Node with key "$key" is not of type $T.');
        }
      }
    }
    return null;
  }

  // ...........................................................................
  /// Replaces nodes in a list of nodes with the given overrides
  static List<NodeBluePrint<dynamic>> _replaceNodes(
    List<NodeBluePrint<dynamic>> nodes,
    List<NodeBluePrint<dynamic>> overrides,
  ) {
    if (overrides.isEmpty) return nodes;
    if (nodes.isEmpty) return overrides;

    final result = <NodeBluePrint<dynamic>>[];
    for (final node in nodes) {
      final override = _findNodeByKey<dynamic>(node.key, overrides);
      if (override != null) {
        result.add(override);
      } else {
        result.add(node);
      }
    }
    return result;
  }
}
