// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:supply_chain/supply_chain.dart';

NodeBluePrint<dynamic> _dontModifyMode(
  Scope scope,
  NodeBluePrint<dynamic> node,
) =>
    node;

ScopeBluePrint _dontModifyScope(
  Scope parentScope,
  ScopeBluePrint scope,
) =>
    scope;

/// A function that allows to modify a node
typedef ModifyNode = NodeBluePrint<dynamic> Function(
  Scope scope,
  NodeBluePrint<dynamic> node,
);

/// A function that allows to modify a node
typedef ModifyScope = ScopeBluePrint Function(
  Scope parentScope,
  ScopeBluePrint scope,
);

/// A scope blue print is a collection of related node blue prints.
/// that can form or build a scope.
///
/// - [key]: The key of the blue print
/// - [nodesFromConstructor]: Allows to override or extend the nodes built
///   by buildNodes().
/// - [childrenFromConstructor]: Allows to override or extend nodes built
///   by buildScopes().
class ScopeBluePrint {
  // ...........................................................................
  /// Constructor of the scope
  const ScopeBluePrint({
    required this.key,
    List<NodeBluePrint<dynamic>> nodes = const [],
    List<ScopeBluePrint> children = const [],
    this.aliases = const [],
    this.connections = const {},
    this.documentation = '',
    ModifyNode modifyChildNode = _dontModifyMode,
    ModifyScope modifyChildScope = _dontModifyScope,
  })  : _modifyChildScope = modifyChildScope,
        _modifyChildNode = modifyChildNode,
        _nodesFromConstructor = nodes,
        _childrenFromConstructor = children;

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
  /// Override this method to perform actions or checks before instantiation
  void willInstantiate() {}

  // ...........................................................................
  /// Creates a copy of the scope with the given changes
  ScopeBluePrint copyWith({
    String? key,
    List<NodeBluePrint<dynamic>>? modifiedNodes,
    List<ScopeBluePrint>? modifiedScopes,
    List<String>? aliases,
    ModifyNode? modifyChildNode,
    ModifyScope? modifyChildScope,
  }) {
    // Merge the node overrides
    final mergedNodes = _mergeNodes(
      _nodesFromConstructor,
      modifiedNodes,
    );

    final mergedScopes = _mergeScopes(
      _childrenFromConstructor,
      modifiedScopes,
    );

    return ScopeBluePrint._private(
      key: key ?? this.key,
      aliases: aliases ?? this.aliases,
      nodes: mergedNodes,
      children: mergedScopes,
      connections: connections,
      documentation: documentation,
      modifyChildNode: modifyChildNode ?? _modifyChildNode,
      modifyChildScope: modifyChildScope ?? _modifyChildScope,
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

  /// Override this method in sub classes to define the child scopes
  List<ScopeBluePrint> buildScopes() {
    return [];
  }

  /// Override this method in sub classes to replace single nodes by others
  @mustCallSuper
  NodeBluePrint<dynamic> modifyChildNode(
    Scope scope,
    NodeBluePrint<dynamic> node,
  ) =>
      _modifyChildNode(scope, node);

  /// Override this method in sub classes to replace single scopes by others
  @mustCallSuper
  ScopeBluePrint modifyChildScope(
    Scope parentScope,
    ScopeBluePrint scope,
  ) =>
      _modifyChildScope(parentScope, scope);

  // ...........................................................................
  /// The key of the scope
  final String key;

  /// Returns true if the key matches the given key or one of the aliases
  bool matchesKey(String key) => key == this.key || aliases.contains(key);

  /// The nodes of the scope
  List<NodeBluePrint<dynamic>> get nodes =>
      _mergeNodes(buildNodes(), _nodesFromConstructor);

  /// The children of the scope
  List<ScopeBluePrint> get children =>
      _mergeScopes(buildScopes(), _childrenFromConstructor);

  /// The list of key aliases
  final List<String> aliases;

  /// Allows to connect scopes and nodes to sources from the outside
  final Map<String, String> connections;

  // ...........................................................................
  /// Returns a documentation for the node
  final String documentation;

  // ...........................................................................
  /// Returns the node for a given key
  NodeBluePrint<T>? node<T>(String key) => _findNodeByKey<T>(key, nodes);

  /// Returns the node for a given path
  NodeBluePrint<T>? findNode<T>(String path) {
    return _findNode<T>(path.split('.'), []);
  }

  /// Returns the absolute path of the node with path or null if not found
  String? absolutePath(String path) {
    final absolutePath = <String>[];
    final node = _findNode<dynamic>(path.split('.'), absolutePath);
    if (node == null) {
      return null;
    }
    return absolutePath.join('.');
  }

  // ...........................................................................
  /// Turns the blue print into a scope and adds it to the parent scope.
  Scope instantiate({
    required Scope scope,
    Map<String, String> connections = const {},
  }) {
    willInstantiate();
    connections = {...this.connections, ...connections};

    // Apply connections
    final self = _applyConnections(this, {...connections});

    // Allow parents to modify this child scope before instantiation
    final modifiedScope = _modifyScopeByParents(
      parentScopeOfModifiedScope: scope,
      currentParentScope: scope,
      scope: self,
    );

    // Create an inner scope
    final innerScope = Scope(parent: scope, bluePrint: modifiedScope);

    // Instantiate the nodes of the scope
    final modifiedNodes = self.nodes.map((n) {
      // Allow parents to modify this child node before instantiation
      final modifiedNode = _modifyNodeByParents(
        scopeOfNode: innerScope,
        currentScope: innerScope,
        node: n,
      );
      assert(
        modifiedNode.key == n.key,
        'The key of the node must not be changed.',
      );
      return modifiedNode;
    }).toList();

    // Make sure there are no duplicate keys
    _checkForDuplicateKeys(modifiedNodes);

    // Create node
    innerScope.findOrCreateNodes(modifiedNodes);

    // Init sub scopes
    for (final child in self.children) {
      child.instantiate(
        scope: innerScope,
      );
    }

    /// Returns the created exampleScope
    return innerScope;
  }

  // ...........................................................................
  /// Creates an example instance for test purposes
  factory ScopeBluePrint.example({String key = 'scope'}) {
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
      key: key,
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
    required List<NodeBluePrint<dynamic>> nodes,
    required List<ScopeBluePrint> children,
    required this.connections,
    required this.documentation,
    required ModifyNode modifyChildNode,
    required ModifyScope modifyChildScope,
  })  : _modifyChildScope = modifyChildScope,
        _modifyChildNode = modifyChildNode,
        _nodesFromConstructor = nodes,
        _childrenFromConstructor = children;

  // ...........................................................................
  final List<NodeBluePrint<dynamic>> _nodesFromConstructor;
  final List<ScopeBluePrint> _childrenFromConstructor;

  // ...........................................................................
  /// Set this method to override single nodes of a scope
  final ModifyNode _modifyChildNode;

  /// Override this method in sub classes to replace scope blue prints by
  /// other ones.
  final ModifyScope _modifyChildScope;

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

  // ...........................................................................
  List<NodeBluePrint<dynamic>> _mergeNodes(
    List<NodeBluePrint<dynamic>> original,
    List<NodeBluePrint<dynamic>>? overrides,
  ) {
    // If there are no other overrides, return the current ones
    if (overrides == null || overrides.isEmpty) {
      return original;
    }

    // If current overrides are empty, return the new ones
    if (original.isEmpty) {
      return overrides;
    }

    // Iterate all new overrides and merge them with the current ones
    final mergedOverrides = [...original];
    for (final newOverride in overrides) {
      final index = mergedOverrides
          .indexWhere((element) => element.key == newOverride.key);

      // Original element with same key existing? Replace it.
      if (index != -1) {
        mergedOverrides[index] = newOverride;
      }

      // No original element with same key existing? Add it.
      else {
        mergedOverrides.add(newOverride);
      }
    }

    return mergedOverrides;
  }

  // ...........................................................................
  List<ScopeBluePrint> _mergeScopes(
    List<ScopeBluePrint> original,
    List<ScopeBluePrint>? overrides,
  ) {
    // If there are no other overrides, return the current ones
    if (overrides == null || overrides.isEmpty) {
      return original;
    }

    // If current overrides are empty, return the new ones
    if (original.isEmpty) {
      return overrides;
    }

    // Iterate all new overrides and merge them with the current ones
    final mergedOverrides = [...original];
    for (final newOverride in overrides) {
      final index = mergedOverrides
          .indexWhere((element) => element.key == newOverride.key);

      // Original element with same key existing? Replace it.
      if (index != -1) {
        mergedOverrides[index] = newOverride;
      }

      // No original element with same key existing? Add it.
      else {
        mergedOverrides.add(newOverride);
      }
    }

    return mergedOverrides;
  }

  // ...........................................................................
  static ScopeBluePrint _applyConnection(
    ScopeBluePrint scope,
    List<String> path,
    String supplier,
  ) {
    // Apply to node
    if (path.length == 1) {
      final n = scope.node<dynamic>(path.first)!;
      final modifiedN = n.connectSupplier(supplier);
      return scope.copyWith(
        modifiedNodes: [modifiedN],
      );
    }

    // Apply to child scope
    final childScope = scope.children.firstWhere(
      (element) => element.key == path.first,
    );
    final modifiedScope = _applyConnection(
      childScope,
      path.sublist(1),
      supplier,
    );

    final result = scope.copyWith(
      modifiedScopes: [modifiedScope],
    );
    return result;
  }

  // ...........................................................................
  ScopeBluePrint _applyConnections(
    ScopeBluePrint scope,
    Map<String, String> connections,
  ) {
    if (connections.isEmpty) {
      return scope;
    }

    // Remaining connections
    final modifiedNodes = <NodeBluePrint<dynamic>>[];
    var modifiedSelf = this;

    // .............
    // Connect nodes
    for (final connection in {...connections}.entries) {
      final key = connection.key;
      final supplier = connection.value;

      // ..........................
      // Find the node in own nodes
      final node = scope.node<dynamic>(key);
      if (node != null) {
        // Connect the node to the specified supplier
        final modifiedNode = node.connectSupplier(supplier);

        // Add the node to modified nodes
        modifiedNodes.add(modifiedNode);

        // Mark the connection as being applied
        connections.remove(key);

        continue;
      }

      // .............................
      // Find the node in child scopes
      final absolutePath = scope.absolutePath(key);
      if (absolutePath != null) {
        final segments = absolutePath.split('.');
        modifiedSelf = _applyConnection(
          modifiedSelf,
          segments.sublist(1),
          supplier,
        );

        connections.remove(key);
      }
    }

    // Throw if not all connections could be applied
    if (connections.isNotEmpty) {
      throw ArgumentError(
        'The following connections could not be applied: $connections',
      );
    }

    return modifiedSelf.copyWith(
      modifiedNodes: modifiedNodes,
    );
  }

  // ...........................................................................
  NodeBluePrint<dynamic> _modifyNodeByParents({
    required Scope scopeOfNode,
    required Scope currentScope,
    required NodeBluePrint<dynamic> node,
  }) {
    final modifiedNode = modifyChildNode(scopeOfNode, node);

    final newModifyingParentScope = currentScope.parent;

    final nodeModifiedByParentScope =
        newModifyingParentScope?.bluePrint._modifyNodeByParents(
      scopeOfNode: scopeOfNode,
      currentScope: newModifyingParentScope,
      node: modifiedNode,
    );

    return nodeModifiedByParentScope ?? modifiedNode;
  }

  // ...........................................................................
  ScopeBluePrint _modifyScopeByParents({
    required Scope parentScopeOfModifiedScope,
    required Scope? currentParentScope,
    required ScopeBluePrint scope,
  }) {
    final modifiedScope = modifyChildScope(parentScopeOfModifiedScope, scope);

    assert(
      modifiedScope.key == scope.key,
      'The key of the scope must not be changed.',
    );

    final scopeModifiedByParentScope =
        currentParentScope?.bluePrint._modifyScopeByParents(
      parentScopeOfModifiedScope: parentScopeOfModifiedScope,
      currentParentScope: currentParentScope.parent,
      scope: modifiedScope,
    );

    return scopeModifiedByParentScope ?? modifiedScope;
  }

  // ...........................................................................
  NodeBluePrint<T>? _findNode<T>(
    List<String> path,
    List<String> absolutePath, {
    bool isFirstSegment = true,
  }) {
    NodeBluePrint<T>? result;

    if (key != path[0]) {
      absolutePath.add(key);
    }

    // Only one segment? Find the node in the current scope
    if (path.length == 1) {
      result = _findNodeByKey<T>(path[0], nodes);

      if (result != null) {
        absolutePath.add(result.key);
        return result;
      }

      if (!isFirstSegment) {
        return null;
      }
    }

    // Find the child scope that matches the first segment
    final childScope = key == path[0]
        ? this
        : children.firstWhereOrNull(
            (element) => element.key == path[0],
          );

    // Continue searching in the child scope
    final remainingPath = path.sublist(1);
    final subPath = <String>[];
    if (childScope != null) {
      result = childScope._findNode<T>(
        remainingPath,
        subPath,
        isFirstSegment: false,
      );
    }
    if (result != null) {
      absolutePath.addAll(subPath);
      return result;
    }

    if (!isFirstSegment) {
      return null;
    }

    // Start searching deeper
    subPath.clear();
    final foundNodes = <NodeBluePrint<T>>[];
    for (final child in children) {
      result = child._findNode<T>(
        path,
        subPath,
        isFirstSegment: true,
      );
      if (result != null) {
        foundNodes.add(result);
      }
    }

    if (foundNodes.length > 1) {
      throw ArgumentError(
        'Multiple nodes with path "${path.join('.')}" found.',
      );
    }

    absolutePath.addAll(subPath);
    return foundNodes.isNotEmpty ? foundNodes.first : null;
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
    List<NodeBluePrint<dynamic>> nodes = const [],
    List<ScopeBluePrint> childrenFromConstructor = const [],
    super.documentation,
    ModifyNode? modifyChildNode,
    ModifyScope? modifyChildScope,
  }) : super(
          nodes: [
            const NodeBluePrint<int>(
              key: 'nodeConstructedByParent',
              initialProduct: 0,
              suppliers: [],
            ),
            ...nodes,
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
            ...childrenFromConstructor,
          ],

          // Modify the node with the key 'nodeToBeReplaced'
          modifyChildNode: modifyChildNode ??
              (Scope scope, NodeBluePrint<dynamic> node) {
                return switch (node.key) {
                  'nodeToBeReplaced' => node.copyWith(initialProduct: 807),
                  _ => node,
                };
              },

          // Modify the scope with the key 'scopeToBeReplaced'
          modifyChildScope: modifyChildScope ??
              (Scope parentScope, ScopeBluePrint scope) {
                return switch (scope.key) {
                  'scopeToBeReplaced' =>
                    scope.copyWith(aliases: ['replacedScope']),
                  _ => scope,
                };
              },
        );

  @override
  List<NodeBluePrint<dynamic>> buildNodes() {
    return [
      const NodeBluePrint<int>(
        key: 'nodeBuiltByParent',
        initialProduct: 0,
        suppliers: [],
      ),
      const NodeBluePrint<int>(
        key: 'nodeToBeReplaced',
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
      ScopeBluePrint.example(key: 'scopeToBeReplaced'),
    ];
  }
}
