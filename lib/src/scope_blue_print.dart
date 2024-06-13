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
    this.children = const [],
    this.aliases = const [],
    this.documentation = '',
  });

  // ...........................................................................
  /// Creates a blue print with children from JSON
  ///
  /// The JSON map must have exactly one key.
  /// The value of the map must be a map.
  /// The keys of the value map are the keys of the nodes.
  /// The values of the value map are the initial products of the nodes.
  /// If the value of the value map is a map, it is a child scope.
  /// If the value of the value map is a node blue print, it is a node.
  factory ScopeBluePrint.fromJson(Map<String, dynamic> json) {
    // Iterate all entries of the map

    assert(json.keys.length == 1, 'Only one key is allowed in the root map.');
    assert(
      json.values.first is Map<String, dynamic>,
      'The value of the root map must be a map.',
    );
    final key = json.keys.first;
    final value = json.values.first as Map<String, dynamic>;
    final nodes = <NodeBluePrint<dynamic>>[];
    final children = <ScopeBluePrint>[];
    for (final subKey in value.keys) {
      final subValue = value[subKey];

      // Parse children
      if (subValue is Map<String, dynamic>) {
        final child = ScopeBluePrint.fromJson({subKey: subValue});
        children.add(child);
        continue;
      }

      if (subValue is ScopeBluePrint) {
        assert(
          subValue.key == subKey,
          'The key of the node "${subValue.key}" must be "$subKey".',
        );
        children.add(subValue);
        continue;
      }

      // Parse node blue prints
      if (subValue is NodeBluePrint) {
        assert(
          subValue.key == subKey,
          'The key of the node "${subValue.key}" must be "$subKey".',
        );
        nodes.add(subValue);
        continue;
      }

      // Parse nodes
      final nodeBluePrint = switch (subValue.runtimeType) {
        const (int) => NodeBluePrint<int>(
            key: subKey,
            initialProduct: subValue as int,
          ),
        const (double) => NodeBluePrint<double>(
            initialProduct: subValue as double,
            key: subKey,
          ),
        const (String) => NodeBluePrint<String>(
            initialProduct: subValue as String,
            key: subKey,
          ),
        const (bool) => NodeBluePrint<bool>(
            initialProduct: subValue as bool,
            key: subKey,
          ),
        _ => throw ArgumentError(
            'Type ${value.runtimeType} not supported. '
            'Use NodeBluePrint<${value.runtimeType}> instead.',
          )
      };

      nodes.add(nodeBluePrint);
    }

    return ScopeBluePrint(
      key: key,
      nodes: nodes,
      children: children,
    );
  }

  // ...........................................................................
  /// Creates a copy of the scope with the given changes
  ScopeBluePrint copyWith({
    String? key,
    List<NodeBluePrint<dynamic>>? nodes,
    List<ScopeBluePrint>? subScopes,
    List<NodeBluePrint<dynamic>> overrides = const [],
    List<String>? aliases,
  }) {
    nodes = nodes ?? this.nodes;
    nodes = _replaceNodes(nodes, overrides);

    return ScopeBluePrint._private(
      key: key ?? this.key,
      aliases: aliases ?? this.aliases,
      nodes: nodes,
      children: subScopes ?? children,
      documentation: documentation,
    );
  }

  // ...........................................................................
  @override
  String toString() {
    return key;
  }

  // ...........................................................................
  /// Override this method in sub classes to define the nodes of the scope
  List<NodeBluePrint<dynamic>> buildNodes() {
    return [];
  }

  // ...........................................................................
  /// Override this method in sub classes to define the child scopes
  List<ScopeBluePrint> buildScopes() {
    return [];
  }

  // ...........................................................................
  /// The key of the scope
  final String key;

  /// Returns true if the key matches the given key or one of the aliases
  bool matchesKey(String key) => key == this.key || aliases.contains(key);

  /// The nodes of the scope
  final List<NodeBluePrint<dynamic>> nodes;

  /// The children of the scope
  final List<ScopeBluePrint> children;

  /// The list of key aliases
  final List<String> aliases;

  // ...........................................................................
  /// Returns a documentation for the node
  final String documentation;

  // ...........................................................................
  /// Returns the node for a given key
  NodeBluePrint<T>? findNode<T>(String key) => _findNodeByKey<T>(key, nodes);

  // ...........................................................................
  /// Turns the blue print into a scope and adds it to the parent scope.
  Scope instantiate({
    required Scope scope,
  }) {
    // Create an inner scope
    final innerScope = Scope(parent: scope, bluePrint: this);

    final additionalNodes = buildNodes();
    final additionalSubScopes = buildScopes();

    // Add nodes to the inner scope
    final allNodes = <NodeBluePrint<dynamic>>[...nodes, ...additionalNodes];

    // Make sure there no duplicate keys
    _checkForDuplicateKeys(allNodes);

    // Create node
    innerScope.findOrCreateNodes(allNodes);

    // Init sub scopes
    final allSubScopes = [...children, ...additionalSubScopes];
    for (final subScope in allSubScopes) {
      subScope.instantiate(
        scope: innerScope,
      );
    }

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
      key: 'scope',
      nodes: [
        dependency,
      ],
      children: [
        ScopeBluePrint(
          key: 'childScope',
          nodes: [
            node,
            customer,
          ],
        ),
      ],
    );
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  /// Private constructor
  ScopeBluePrint._private({
    required this.key,
    required this.aliases,
    required this.nodes,
    required this.children,
    required this.documentation,
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

  // ...........................................................................
  void _checkForDuplicateKeys(List<NodeBluePrint<dynamic>> nodes) {
    final keys = nodes.map(
      (e) => e.key,
    );
    var occurrences = <dynamic, int>{};
    for (var element in keys) {
      occurrences.update(element, (value) => value + 1, ifAbsent: () => 1);
    }

    var duplicates = <dynamic>[];
    occurrences.forEach((key, value) {
      if (value > 1) {
        duplicates.add(key);
      }
    });

    if (duplicates.isNotEmpty) {
      throw ArgumentError('Duplicate keys found: $duplicates');
    }
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
  }) : super(
          nodes: [
            const NodeBluePrint<int>(
              key: 'nodeConstructedByParent',
              initialProduct: 0,
              suppliers: [],
            ),
          ],
          children: [
            const ScopeBluePrint(
              key: 'childScopeConstructedByParent',
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
  List<NodeBluePrint<dynamic>> buildNodes() {
    return [
      const NodeBluePrint<int>(
        key: 'nodeBuiltByParent',
        initialProduct: 0,
        suppliers: [],
      ),
    ];
  }

  @override
  List<ScopeBluePrint> buildScopes() {
    return [
      const ScopeBluePrint(
        key: 'childScopeBuiltByParent',
        nodes: [
          NodeBluePrint<int>(
            key: 'nodeBuiltByChildScope',
            initialProduct: 0,
            suppliers: [],
          ),
        ],
      ),
    ];
  }
}
