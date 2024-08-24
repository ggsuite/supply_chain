// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:collection/collection.dart';
import 'package:supply_chain/supply_chain.dart';

/// A scope blue print is a collection of related node blue prints.
/// that can form or build a scope.
///
/// - [key]: The key of the blue print
/// - [nodesFromConstructor]: Allows to override or extend the nodes built
///   by buildNodes().
/// - [scopes]: Allows to override or extend nodes built
///   by buildScopes().
class ScopeBluePrint {
  // coverage:ignore-start
  // ...........................................................................
  /// Constructor of the scope
  const ScopeBluePrint({
    required this.key,
    List<NodeBluePrint<dynamic>> nodes = const [],
    List<ScopeBluePrint> children = const [],
    List<String> aliases = const [],
    Map<String, String> connect = const {},
    List<ScBuilderBluePrint> builders = const [],
  })  : _aliases = aliases,
        _builders = builders,
        _connections = connect,
        _nodes = nodes,
        _children = children;

  // ...........................................................................
  /// Constructor of the scope
  const ScopeBluePrint.fat({
    required this.key,
    List<NodeBluePrint<dynamic>> nodes = const [],
    List<ScopeBluePrint> children = const [],
    List<String> aliases = const [],
    Map<String, String> connections = const {},
    List<ScBuilderBluePrint> builders = const [],
  })  : _connections = connections,
        _aliases = aliases,
        _builders = builders,
        _nodes = nodes,
        _children = children;

  // coverage:ignore-end

  // ...........................................................................
  // coverage:ignore-start
  /// Constructor of the scope
  const ScopeBluePrint.old({
    required this.key,
    List<NodeBluePrint<dynamic>> nodes = const [],
    List<ScopeBluePrint> children = const [],
    List<String> aliases = const [],
    Map<String, String> connections = const {},
    List<ScBuilderBluePrint> builders = const [],
  })  : _connections = connections,
        _aliases = aliases,
        _builders = builders,
        _nodes = nodes,
        _children = children;
  // coverage:ignore-end

  // ...........................................................................
  /// Creates a blue print with children from JSON
  ///
  /// The JSON map must have exactly one key.
  /// The value of the map must be a map.
  /// The keys of the value map are the keys of the nodes.
  /// The values of the value map are the initial products of the nodes.
  /// If the value of the value map is a map, it is a child scope.
  /// If the value of the value map is a node blue print, it is a node.
  factory ScopeBluePrint.fromJson(
    Map<String, dynamic> json, {
    Map<String, String> connect = const {},
  }) {
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
      connect: connect,
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
    List<ScBuilderBluePrint>? builders,
    List<String>? aliases,
    Map<String, String>? connections,
  }) {
    // Merge the node overrides
    final mergedNodes = _mergeNodes(
      nodes,
      modifiedNodes,
    );

    final mergedScopes = _mergeScopes(
      children,
      modifiedScopes,
    );

    final mergedConnections = {..._connections, ...connections ?? {}};

    return ScopeBluePrint._private(
      key: key ?? this.key,
      aliases: aliases ?? _aliases,
      nodes: mergedNodes,
      children: mergedScopes,
      connections: mergedConnections,
      builders: builders ?? this.builders,
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
    return _nodes;
  }

  /// Override this method in sub classes to define the child scopes
  List<ScopeBluePrint> buildScopes() {
    return _children;
  }

  /// Override this method in sub classes to modify the builders
  List<ScBuilderBluePrint> buildScBuilders() {
    return _builders;
  }

  /// Override this method in sub classes to define the aliases of the scope
  List<String> buildAliases() {
    return _aliases;
  }

  /// Override this method in sub classes to define the connections of the scope
  Map<String, String> buildConnections() {
    return _connections;
  }

  // ...........................................................................
  /// Merge nodes with overrides
  static List<NodeBluePrint<dynamic>> mergeNodes({
    required List<NodeBluePrint<dynamic>> original,
    required List<NodeBluePrint<dynamic>>? overrides,
  }) =>
      _mergeNodes(original, overrides);

  // ...........................................................................
  /// Merge scopes with overrides
  static List<ScopeBluePrint> mergeScopes({
    required List<ScopeBluePrint> original,
    required List<ScopeBluePrint>? overrides,
  }) =>
      _mergeScopes(original, overrides);

  // ...........................................................................
  /// The key of the scope
  final String key;

  /// Returns the aliases of the scope
  List<String> get aliases => buildAliases();

  /// Returns true if the key matches the given key or one of the aliases
  bool matchesKey(String key) => key == this.key || _aliases.contains(key);

  /// The nodes of the scope
  List<NodeBluePrint<dynamic>> get nodes => buildNodes();

  /// The children of the scope
  List<ScopeBluePrint> get children => buildScopes();

  /// The child with a given key or null if not found
  ScopeBluePrint? child(String key) {
    for (final child in children) {
      if (child.key == key) {
        return child;
      }
    }
    return null;
  }

  /// Allows to connect scopes and nodes to sources from the outside
  Map<String, String> get connections => buildConnections();

  /// The builders that are installed when the scope is instantiated.
  List<ScBuilderBluePrint> get builders => buildScBuilders();

  // ...........................................................................
  /// Returns the node for a given key
  NodeBluePrint<T>? node<T>(String key) => _nodeWithKey<T>(key, nodes);

  /// Returns the node or the scope
  /// and its absolute path for a given search path
  (dynamic, String?) findItem(String searchPath) {
    final absolutePath = <String>[];
    final item = _findItem<dynamic>(searchPath.split('.'), absolutePath);
    return (item, item != null ? absolutePath.join('.') : null);
  }

  /// Returns the node for a given path
  NodeBluePrint<T>? findNode<T>(String path) {
    final item = _findItem<T>(path.split('.'), [], matchAlsoScopes: false);
    return item is NodeBluePrint<T> ? item : null;
  }

  /// Returns the absolute path of the node with path or null if not found
  String? absoluteNodePath(String path) {
    final absolutePath = <String>[];
    final node = _findItem<dynamic>(path.split('.'), absolutePath);
    if (node == null) {
      return null;
    }
    return absolutePath.join('.');
  }

  /// Returns the pathes of all nodes belonging to this scope
  List<String> allNodePathes({
    bool appendRootScopeKey = false,
  }) =>
      _allNodePathes(this, appendRootScopeKey: appendRootScopeKey);

  // ...........................................................................
  /// Turns the blue print into a scope and adds it to the parent scope.
  Scope instantiate({
    required Scope scope,
    Map<String, String> connect = const {},
    bool initScBuilders = true,
    Owner<Scope>? owner,
  }) {
    willInstantiate();
    final connections = {..._connections, ...connect};

    // Connect nodes of this scopes to suppliers from the outside.
    // I.e. connected nodes will forward the value of the supplier.
    final self = _applyConnections(this, {...connections});

    // Create an inner scope
    final innerScope = Scope(parent: scope, bluePrint: self, owner: owner);

    // Make sure there are no duplicate keys
    _checkForDuplicateKeys(self.nodes);

    // Create node
    innerScope.findOrCreateNodes(
      self.nodes,

      /// ScBuilders are initialized after all nodes are created
      applyScBuilders: false,
    );

    // Init sub scopes
    for (final child in self.children) {
      child.instantiate(
        scope: innerScope,

        /// ScBuilders are initialized after all nodes are created
        initScBuilders: false,
      );
    }

    // Add builders
    for (final builder in builders) {
      builder.instantiate(scope: innerScope);
    }

    // Apply parent builders
    _applyParentScBuilders(scope: innerScope);

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
    return ExampleScopeBluePrintSimple(
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
    required List<String> aliases,
    required List<NodeBluePrint<dynamic>> nodes,
    required List<ScopeBluePrint> children,
    required List<ScBuilderBluePrint> builders,
    required Map<String, String> connections,
  })  : _connections = connections,
        _aliases = aliases,
        _nodes = nodes,
        _children = children,
        _builders = builders;

  // ...........................................................................
  final List<NodeBluePrint<dynamic>> _nodes;
  final List<ScopeBluePrint> _children;
  final List<ScBuilderBluePrint> _builders;
  final List<String> _aliases;
  final Map<String, String> _connections;

  // ...........................................................................
  /// Finds a node with a given key in a given list of nodes.
  /// Returns null if no one is found
  static NodeBluePrint<T>? _nodeWithKey<T>(
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
  static List<NodeBluePrint<dynamic>> _mergeNodes(
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
  static List<ScopeBluePrint> _mergeScopes(
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
  static ScopeBluePrint _connectNodeToSupplier(
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
    final modifiedScope = _connectNodeToSupplier(
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
  static List<String> _allNodePathes(
    ScopeBluePrint scope, {
    bool isFirstSegment = true,
    bool appendRootScopeKey = false,
  }) {
    final pathes = <String>[];
    final firstSegmentName =
        isFirstSegment && appendRootScopeKey ? '${scope.key}.' : '';

    for (final node in scope.nodes) {
      pathes.add('$firstSegmentName${node.key}');
    }

    for (final child in scope.children) {
      final childPathes = _allNodePathes(
        child,
        isFirstSegment: false,
        appendRootScopeKey: false,
      );

      pathes.addAll(
        childPathes
            .map((childPath) => '$firstSegmentName${child.key}.$childPath'),
      );
    }

    return pathes;
  }

  // ...........................................................................
  static (
    Map<String, String> mappedConnections,
    Map<String, String> missingConnections
  ) _convertScopePathToNodePathes(
    ScopeBluePrint scope,
    Map<String, String> connections,
  ) {
    // Iterate all connections
    final processedConnections = <String, String>{};
    final missingConnections = {...connections};

    for (final connection in connections.entries) {
      final path = connection.key;
      final supplier = connection.value;

      // Get the item belonging to the path
      final (item, absolutePath) = scope.findItem(path);

      if (item == null) {
        continue;
      }

      missingConnections.remove(path);

      // If item is a node, replace the path by the absolute path of the node
      if (item is NodeBluePrint) {
        processedConnections[absolutePath!] = supplier;
      }

      // If item is a scope, iterate all nodes of the scope and
      // replace the path by the absolute path of the node
      if (item is ScopeBluePrint) {
        missingConnections.remove(path);
        final nodePathes = _allNodePathes(item);
        for (final nodePath in nodePathes) {
          processedConnections[nodePath] = '$supplier.$nodePath';
        }
      }
    }

    return (processedConnections, missingConnections);
  }

  // ...........................................................................
  ScopeBluePrint _applyConnections(
    ScopeBluePrint scope,
    Map<String, String> connections,
  ) {
    if (connections.isEmpty) {
      return scope;
    }

    // Replace connected scopes by its connected nodes
    final (mappedConnections, missingConnections) =
        _convertScopePathToNodePathes(scope, connections);

    // Remaining connections
    final modifiedNodes = <NodeBluePrint<dynamic>>[];
    var modifiedSelf = this;

    // .............
    // Connect nodes
    for (final connection in [...mappedConnections.entries]) {
      final key = connection.key;
      final supplier = connection.value;

      final absolutePath = scope.absoluteNodePath(key);
      if (absolutePath != null) {
        final segments = absolutePath.split('.');
        modifiedSelf = _connectNodeToSupplier(
          modifiedSelf,
          segments.sublist(1),
          supplier,
        );

        mappedConnections.remove(key);
      }
    }

    // Throw if not all connections could be applied
    if (missingConnections.isNotEmpty) {
      throw ArgumentError(
        'The following connections could not be applied: $missingConnections',
      );
    }

    return modifiedSelf.copyWith(
      modifiedNodes: modifiedNodes,
    );
  }

  // ...........................................................................
  void _applyParentScBuilders({
    required Scope scope,
  }) {
    var parent = scope.parent;

    while (parent != null) {
      for (final builder in parent.builders) {
        builder.applyToScope(scope);
      }
      parent = parent.parent;
    }
  }

  // ...........................................................................
  Object? _findItem<T>(
    List<String> path,
    List<String> absolutePath, {
    bool isFirstSegment = true,
    bool matchAlsoScopes = true,
  }) {
    Object? result;

    if (key != path[0]) {
      absolutePath.add(key);
    }

    // Only one segment?
    if (path.length == 1) {
      // Return the node with the given key
      final foundNode = node<T>(path[0]);

      if (foundNode != null) {
        absolutePath.add(foundNode.key);
        return foundNode;
      }

      if (matchAlsoScopes) {
        // Return the own scope if it matches the key
        if (key == path[0]) {
          absolutePath.add(key);
          return this;
        }

        // Return the child scope if it matches the key
        final foundChildScope = child(path[0]);
        if (foundChildScope != null) {
          absolutePath.add(foundChildScope.key);
          return foundChildScope;
        }
      }

      // If we are in the middle of a search, return null
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
      result = childScope._findItem<T>(
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
    final foundItems = <Object>[];
    for (final child in children) {
      result = child._findItem<T>(
        path,
        subPath,
        isFirstSegment: true,
      );
      if (result != null) {
        foundItems.add(result);
      }
    }

    if (foundItems.length > 1) {
      throw ArgumentError(
        'Multiple nodes with path "${path.join('.')}" found.',
      );
    }

    absolutePath.addAll(subPath);
    return foundItems.isNotEmpty ? foundItems.first : null;
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
    List<ScopeBluePrint> children = const [],
  }) : super.fat(
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
            ...children,
          ],
        );

  @override
  List<NodeBluePrint<dynamic>> buildNodes() {
    return ScopeBluePrint.mergeNodes(
      original: [
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
      ],
      overrides: super.buildNodes(),
    );
  }

  @override
  List<ScopeBluePrint> buildScopes() {
    return ScopeBluePrint.mergeScopes(
      original: [
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
      ],
      overrides: super.buildScopes(),
    );
  }
}

/// A very simple derived scope blue print.
/// It adds one node and one scope using the override mechanism.
class ExampleScopeBluePrintSimple extends ScopeBluePrint {
  /// Constructor
  ExampleScopeBluePrintSimple({
    super.key = 'example',
    super.nodes,
    super.children,
  });

  @override
  List<NodeBluePrint<dynamic>> buildNodes() {
    return ScopeBluePrint.mergeNodes(
      original: [
        const NodeBluePrint<int>(
          key: 'builtNode',
          initialProduct: 0,
          suppliers: [],
        ),
      ],
      overrides: super.buildNodes(),
    );
  }

  @override
  List<ScopeBluePrint> buildScopes() {
    return ScopeBluePrint.mergeScopes(
      original: [
        const ScopeBluePrint(
          key: 'builtScope',
          nodes: [
            NodeBluePrint<int>(
              key: 'builtNodeInScope',
              initialProduct: 0,
              suppliers: [],
            ),
          ],
        ),
      ],
      overrides: super.buildScopes(),
    );
  }
}
