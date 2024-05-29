// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A scope blue print is a collection of related node blue prints.
/// that can form or build a scope.
///
/// - [key]: The key of the blue print
/// - [nodes]: The nodes of the blue print.
///   Can also be specified in build()
/// - [children]: The children of the blue print.
///   Can also be specified in build().
class ScopeBluePrint {
  // ...........................................................................
  /// Constructor of the scope
  const ScopeBluePrint({
    required this.key,
    this.nodes = const [],
    this.subScopes = const [],
    required this.dependencies,
  });

  // ...........................................................................
  /// Creates a copy of the scope with the given changes
  ScopeBluePrint copyWith({
    String? key,
    List<NodeBluePrint<dynamic>>? nodes,
    List<NodeBluePrint<dynamic>>? dependencies,
    List<ScopeBluePrint>? subScopes,
    List<NodeBluePrint<dynamic>> overrides = const [],
  }) {
    nodes = nodes ?? this.nodes;
    nodes = _replaceNodes(nodes, overrides);

    return ScopeBluePrint._private(
      key: key ?? this.key,
      nodes: nodes,
      subScopes: subScopes ?? this.subScopes,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  // ...........................................................................
  @override
  String toString() {
    return key;
  }

  // ...........................................................................
  /// Override this method in sub classes to define the nodes and the children
  /// of the scope.
  (
    List<NodeBluePrint<dynamic>> nodes,
    List<ScopeBluePrint> subScopes,
  ) build() {
    return ([], []);
  }

  // ...........................................................................
  /// The key of the scope
  final String key;

  /// The nodes of the scope
  final List<NodeBluePrint<dynamic>> nodes;

  /// The children of the scope
  final List<ScopeBluePrint> subScopes;

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

    final (
      List<NodeBluePrint<dynamic>> additionalNodes,
      List<ScopeBluePrint> additionalSubScopes
    ) = build();

    // Add nodes to the inner scope
    final allNodes = <NodeBluePrint<dynamic>>[...nodes, ...additionalNodes];
    innerScope.findOrCreateNodes(allNodes);

    // Init sub scopes
    final allSubScopes = [...subScopes, ...additionalSubScopes];
    for (final subScope in allSubScopes) {
      subScope.instantiate(
        parentScope: innerScope,
        fakeMissingDependencies: fakeMissingDependencies,
        createOwnScope: createOwnScope,
      );
    }

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
      key: 'dependency',
      initialProduct: 0,
      suppliers: [],
    );

    /// Create a node that depends on the external dependency
    final node = NodeBluePrint<int>(
      key: 'node',
      initialProduct: 1,
      suppliers: ['dependency'],
      produce: (components, previousProduct) {
        final [int dependency] = components;
        return dependency + 1;
      },
    );

    /// Create a customer that depends on the external dependency
    final customer = NodeBluePrint<int>(
      key: 'customer',
      initialProduct: 1,
      suppliers: ['node'],
      produce: (components, previousProduct) {
        final [int node0] = components;
        return node0 + 1;
      },
    );

    /// return the result
    return ScopeBluePrint(
      key: 'example',
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
    required this.subScopes,
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

// #############################################################################
/// An example scope blue print.
///
/// Hierarchy:
/// ```
///     |-parentScope
///        |- nodeConstructedByParent
///        |
///        |- nodeBuiltByParent
///        |
///        |- childScopeConstructedByParent
///        |  |- nodeConstructedByChildScope
///        |
///        |- childScopeBuiltByParent
///        |  |- nodeBuiltByChildScope
/// ```
///
class ExampleScopeBluePrint extends ScopeBluePrint {
  /// Constructor
  ExampleScopeBluePrint({
    super.key = 'parentScope',
    super.dependencies = const [],
  }) : super(
          nodes: [
            const NodeBluePrint<int>(
              key: 'nodeConstructedByParent',
              initialProduct: 0,
              suppliers: [],
            ),
          ],
          subScopes: [
            const ScopeBluePrint(
              key: 'childScopeConstructedByParent',
              dependencies: [],
              nodes: [
                NodeBluePrint<int>(
                  key: 'nodeConstructedByChildScope',
                  initialProduct: 0,
                  suppliers: [],
                ),
              ],
            ),
          ],
        );

  @override
  (List<NodeBluePrint<dynamic>>, List<ScopeBluePrint>) build() {
    return (
      [
        const NodeBluePrint<int>(
          key: 'nodeBuiltByParent',
          initialProduct: 0,
          suppliers: [],
        ),
      ],
      [
        const ScopeBluePrint(
          key: 'childScopeBuiltByParent',
          dependencies: [],
          nodes: [
            NodeBluePrint<int>(
              key: 'nodeBuiltByChildScope',
              initialProduct: 0,
              suppliers: [],
            ),
          ],
        ),
      ]
    );
  }
}
