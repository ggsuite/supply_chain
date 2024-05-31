// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A supply scope is a container for connected nodes
class Scope {
  // ...........................................................................
  /// Creates a scope with a key. Key must be lower camel case.
  Scope({
    required this.key,
    required this.parent,
  })  : scm = parent!.scm,
        assert(key.isCamelCase) {
    _init();
  }

  /// Create a root supply scope having no parent
  Scope.root({
    required this.key,
    required this.scm,
  })  : parent = null,
        assert(key.isCamelCase) {
    _init();
  }

  /// Disposes the scope
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }

    _dispose.clear();
  }

  /// Returns true if the scope is disposed
  bool get isDisposed => _dispose.isEmpty;

  // ...........................................................................
  /// Returns the node as string
  @override
  String toString() => key;

  // ...........................................................................
  /// The supply scope manager
  final Scm scm;

  /// The key of the scope
  final String key;

  /// The path of the scope
  String get path => _path;

  /// The path of the scope as array
  List<String> get pathArray => _pathArray;

  /// The uinquie id of the scope
  final int id = _idCounter++;

  /// Reset id counter for test purposes
  static void testRestIdCounter() => _idCounter = 0;

  // ...........................................................................
  /// Returns the child scopes
  Iterable<Scope> get children => _children.values;

  /// Returns
  /// - empty array when depth = 0
  /// - direct children when depth = 1
  /// - direct children and children of children when depth = 2
  /// - all nodes when depth = -1
  Iterable<Scope> deepChildren({int depth = 1}) {
    if (depth == 0) {
      return [];
    }

    final result = <Scope>[...children];

    for (final child in children) {
      result.addAll(child.deepChildren(depth: depth - 1));
    }
    return result;
  }

  /// Returns
  /// - empty array when depth = 0 || parent == null
  /// - direct parent when depth = 1
  /// - parent and parent of parent when depth = 2
  /// - all parents = -1
  Iterable<Scope> deepParents({int depth = 1}) {
    if (parent == null || depth == 0) {
      return <Scope>[];
    }

    final result = <Scope>[parent!];

    final parents = parent!.deepParents(depth: depth - 1);
    result.addAll(parents);

    return result;
  }

  /// Returns the child scope with the given key
  Scope? child(String key) => _children[key];

  /// The nodes of this scope
  Iterable<Node<dynamic>> get nodes => _nodes.values;

  /// Returns the own node for a given key or null if not found
  Node<T>? node<T>({required String key}) => _findNodeInOwnScope<T>(key, []);

  // ...........................................................................
  /// Returns the node with key. If not available in scope the node is created.
  Node<T> findOrCreateNode<T>(NodeBluePrint<T> bluePrint) {
    // Return existing node when already existing
    final existingNode = _nodes[bluePrint.key];
    if (existingNode != null) {
      assert(
        existingNode.bluePrint == bluePrint,
        'Node with key "$key" already exists with different configuration',
      );
      return existingNode as Node<T>;
    }

    // Create a new node
    final node = Node<T>(
      bluePrint: bluePrint,
      scope: this,
    );

    return node;
  }

  // ...........................................................................
  /// Returns the node with key. If not available in scope the node is created.
  List<Node<dynamic>> findOrCreateNodes(
    List<NodeBluePrint<dynamic>> bluePrints,
  ) {
    final result = <Node<dynamic>>[];
    for (final bluePrint in bluePrints) {
      final newNode = bluePrint.instantiate(scope: this);
      result.add(newNode);
    }
    return result;
  }

  // ...........................................................................
  /// Returns the first scope with the given path.
  /// Throws if multiple scopes with the same path exist.
  Scope? findScope(String path) {
    return _findScope(path.split('.'));
  }

  // ...........................................................................
  /// The parent supply scope
  Scope? parent;

  /// Returns the root scope of this scope
  Scope get root {
    var result = this;
    while (result.parent != null) {
      result = result.parent!;
    }
    return result;
  }

  /// Returns the common root of this and the other scope
  ///
  /// Throws if no common parent is found.
  Scope commonParent(Scope other) {
    if (other == this) {
      return this;
    }

    late final Scope a;
    late final Scope b;

    if (other.pathArray.length > pathArray.length) {
      a = this;
      b = other;
    } else {
      a = other;
      b = this;
    }

    var result = a;
    while (!result.isAncestorOf(b)) {
      if (result.parent == null) {
        throw ArgumentError('No common parent found.');
      }

      result = result.parent!;
    }
    return result;
  }

  // ...........................................................................
  /// Adds an existing node to the scope
  void addNode<T>(Node<T> node) {
    assert(node.runtimeType != Node<dynamic>);
    // Throw if node with key already exists
    if (_nodes.containsKey(node.key)) {
      throw ArgumentError(
        'Node with key ${node.key} already exists in scope "$key"',
      );
    }

    _nodes[node.key] = node;
  }

  // ...........................................................................
  /// Remove the node from the scope
  void removeNode(String key) {
    _nodes.remove(key);
  }

  // ...........................................................................
  /// Replace an existing node with the same key
  void replaceNode(NodeBluePrint<dynamic> bluePrint) {
    final existingNode = _nodes[bluePrint.key];
    if (existingNode == null) {
      throw ArgumentError(
        'Node with key "${bluePrint.key}" does not exist in scope "$key"',
      );
    }

    existingNode.update(bluePrint);
  }

  // ...........................................................................
  /// Adds a child scope
  Scope addChild(ScopeBluePrint bluePrint) {
    return bluePrint.instantiate(scope: this);
  }

  /// Removes the scope from it's parent scope
  void remove() {
    dispose();
  }

  /// Replaces a scope with a new scope
  void replaceChild(
    ScopeBluePrint replacement, {
    String? path,
  }) {
    path ??= replacement.key;
    final oldScope = findScope(path);

    if (oldScope == null) {
      throw ArgumentError('Scope with path "$path" not found.');
    }

    // ................................
    // Existing scope has the same key?
    // Update the nodes in the old scope
    if (oldScope.key == replacement.key) {
      _updateNodesInScope(oldScope, replacement);

      // Remove all children not existing in replacement anymore
      final removedChildren = oldScope.children
          .where(
            (element) => !replacement.children.any((c) => c.key == element.key),
          )
          .toList();

      for (final child in removedChildren.toList()) {
        child.dispose();
      }

      // Also replace child scopes
      for (final newChildScope in replacement.children) {
        // Get the associated oldChildScope
        final oldChildScope = oldScope.child(newChildScope.key);

        // If no old child scope exists, instantiate the new child scope
        if (oldChildScope == null) {
          newChildScope.instantiate(scope: oldScope);
        }

        // If the old scope exists, replace it
        else {
          oldChildScope.replaceChild(
            newChildScope,
          );
        }
      }
    }

    // ....................................................
    // Replacement has a different key than the old scope?
    // Delete the old scope.
    else {
      replacement.instantiate(scope: oldScope.parent!);
      oldScope.dispose();
    }
  }

  // ...........................................................................
  /// Returns true if this scope is an ancestor of the given scope
  bool isAncestorOf(Scope scope) {
    if (_children.containsKey(scope.key)) {
      return true;
    }

    for (final child in _children.values) {
      if (child.isAncestorOf(scope)) {
        return true;
      }
    }

    return false;
  }

  /// Returns true if this scope is a descendant of the given scope
  bool isDescendantOf(Scope scope) {
    if (scope._children.containsKey(key)) {
      return true;
    }

    for (final child in scope._children.values) {
      if (isDescendantOf(child)) {
        return true;
      }
    }

    return false;
  }

  // ...........................................................................
  /// Returns true if a node with the given key exists in this or a
  /// parent supply scope
  bool hasNode(String key) {
    if (_nodes.containsKey(key)) {
      return true;
    }

    return parent?.hasNode(key) ?? false;
  }

  // ...........................................................................
  /// Returns the node of key in this or any parent nodes
  Node<T>? findNode<T>(
    String key, {
    bool throwIfNotFound = false,
  }) {
    final keyParts = key.split('.');
    final nodeKey = keyParts.last;
    final scopePath = keyParts.sublist(0, keyParts.length - 1);

    final node = _findNodeInOwnScope<T>(nodeKey, scopePath) ??
        _findNodeNodeInParentScopes(nodeKey, scopePath) ??
        _findNodeInDirectSiblingScopes(nodeKey, scopePath) ??
        _findAnyUniqueNode<T>(nodeKey, scopePath);

    if (node == null && throwIfNotFound) {
      throw ArgumentError('Node with key "$key" not found.');
    }

    return node;
  }

  // Print graph

  // ...........................................................................
  /// Returns a graph that can be turned into svg using graphviz
  String graph({
    int childScopeDepth = 0,
    int parentScopeDepth = 0,
    int supplierDepth = -1,
    int customerDepth = 0,
  }) {
    return const Graph().fromScope(
      this,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      supplierDepth: -supplierDepth,
      customerDepth: customerDepth,
    );
  }

  /// Save the graph to a file
  ///
  /// The format can be
  /// bmp canon cgimage cmap cmapx cmapx_np dot dot_json eps exr fig gd gd2 gif
  /// gv icns ico imap imap_np ismap jp2 jpe jpeg jpg json json0 kitty kittyz
  /// mp pct pdf pic pict plain plain-ext png pov ps ps2 psd sgi svg svgz tga
  /// tif tiff tk vrml vt vt-24bit wbmp webp xdot xdot1.2 xdot1.4 xdot_json
  Future<void> saveGraphToFile(
    String path, {
    int childScopeDepth = 0,
    int parentScopeDepth = 0,
    int supplierDepth = -1,
    int customerDepth = 0,
    bool highLightScope = false,
  }) async {
    await const Graph().writeScopeToFile(
      this,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      path,
      highLightScope: highLightScope,
    );
  }

  // Test helpers

  // ...........................................................................
  /// Creates an example instance of Scope
  factory Scope.example({
    Scm? scm,
    String key = 'example',
  }) {
    scm ??= Scm.example();
    return Scope.root(key: key, scm: scm);
  }

  // ...........................................................................
  /// Allows to mock the content of the scope
  ///
  /// ```dart
  /// final scope = Scope.example();
  /// scope.mockContent({
  ///   'a': {
  ///     'int': 5,
  ///     'b': {
  ///       'int': 10,
  ///       'double': 3.14,
  ///       'string': 'hello',
  ///       'bool': true,
  ///       'enum': const NodeBluePrint<TestEnum>(
  ///         key: 'enum',
  ///         initialProduct: TestEnum.a,
  ///       ),
  ///     },
  ///     'c': [
  ///       const ScopeBluePrint(key: 'd'),
  ///       const ScopeBluePrint(key: 'e'),
  ///       const ScopeBluePrint(key: 'f'),
  ///     ],
  ///   },
  /// });
  ///
  /// ```
  void mockContent(Map<String, dynamic> content) {
    // Iterate all entries of the map
    for (final key in content.keys) {
      final value = content[key];

      // If the entry is a map, create a child scope
      if (value is Map<String, dynamic>) {
        final bluePrint = ScopeBluePrint(key: key);
        final child = bluePrint.instantiate(scope: this);

        // Forward child content to child
        child.mockContent(value);
      }

      // If value is a NodeBluePrint, create a child node
      else if (value is NodeBluePrint) {
        value.instantiate(scope: this);
      }

      // If value is a ScopeBluePrint, instantiate the scope
      else if (value is ScopeBluePrint) {
        assert(value.key == key);
        value.instantiate(scope: this);
      }

      // If value is a ScopeBluePrint, instantiate the scope
      else if (value is List) {
        final scope = ScopeBluePrint(key: key).instantiate(scope: this);

        for (final item in value) {
          if (item is ScopeBluePrint) {
            item.instantiate(scope: scope);
          } else {
            throw ArgumentError(
              'Lists must only contain ScopeBluePrints.',
            );
          }
        }
      }

      // If value is a basic type, create a node
      else {
        final bluePrint = switch (value.runtimeType) {
          const (int) => NodeBluePrint<int>(
              key: key,
              initialProduct: value as int,
            ),
          const (double) => NodeBluePrint<double>(
              initialProduct: value as double,
              key: key,
            ),
          const (String) => NodeBluePrint<String>(
              initialProduct: value as String,
              key: key,
            ),
          const (bool) => NodeBluePrint<bool>(
              initialProduct: value as bool,
              key: key,
            ),
          _ => throw ArgumentError(
              'Type ${value.runtimeType} not supported. '
              'Use NodeBluePrint<${value.runtimeType}> instead.',
            ),
        };

        bluePrint.instantiate(scope: this);
      }
    }
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  final List<void Function()> _dispose = [];
  late final String _path;
  late final List<String> _pathArray;

  // ...........................................................................
  final Map<String, Scope> _children = {};
  final Map<String, Node<dynamic>> _nodes = {};
  static int _idCounter = 0;

  // ...........................................................................
  void _init() {
    _initParent();
    _initPath();
    _initNodes();
    _initChildren();
  }

  void _initParent() {
    if (parent == null) {
      return;
    }

    // Add scope to parent scope
    parent!._children[key] = this;

    // Remove scope from parent scope on dispose
    _dispose.add(() {
      parent!._children.remove(key);
    });
  }

  void _initNodes() {
    // On dispose, all nodes should be disposed
    _dispose.add(() {
      for (final node in [..._nodes.values]) {
        node.dispose();
      }
    });
  }

  void _initChildren() {
    _dispose.add(() {
      for (final child in children.toList()) {
        child.dispose();
      }
    });
  }

  void _initPath() {
    _pathArray = parent == null ? [key] : [...parent!._pathArray, key];
    _path = parent == null ? key : '${parent!.path}.$key';
  }

  // ...........................................................................
  Node<T>? _findNodeInOwnScope<T>(String nodeKey, List<String> scopePath) {
    final node = _nodes[nodeKey];
    if (node == null) {
      return null;
    }

    if (scopePath.isNotEmpty) {
      if (!node.scope.path.endsWith(scopePath.join('.'))) {
        return null;
      }
    }

    if (node is! Node<T>) {
      throw ArgumentError('Node with key "$nodeKey" is not of type $T');
    }

    return node;
  }

  Node<T>? _findNodeNodeInParentScopes<T>(String key, List<String> scopePath) {
    return parent?._findNodeInOwnScope<T>(key, scopePath) ??
        parent?._findNodeNodeInParentScopes<T>(key, scopePath);
  }

  Node<T>? _findNodeInDirectSiblingScopes<T>(
    String key,
    List<String> scopePath,
  ) {
    if (parent == null) {
      return null;
    }

    for (final sibling in parent!._children.values) {
      final node = sibling._findNodeInOwnScope<T>(key, scopePath);
      if (node != null) {
        return node;
      }
    }

    return null;
  }

  Node<T>? _findAnyUniqueNode<T>(String key, List<String> scopePath) {
    final scopePathString = scopePath.join('.');
    final nodes = scm.nodesWithKey<T>(key).where(
          (element) => element.scope.path.endsWith(scopePathString),
        );
    if (nodes.length == 1) {
      return nodes.first;
    }

    if (nodes.length > 1) {
      throw ArgumentError(
        'More than one node with key "$key" and Type<$T> found.',
      );
    }

    return null;
  }

  Scope? _findScope(List<String> path) {
    if (path.isEmpty) {
      return null;
    }

    if (path.length == 1 && path.first == key) {
      return this;
    }

    if (path.first == key) {
      return _findScope(path.sublist(1));
    }

    for (final child in _children.values) {
      final result = child._findScope(path);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  // ...........................................................................
  void _updateNodesInScope(Scope previous, ScopeBluePrint current) {
    // ....................
    // Estimate added nodes
    final addedNodes =
        current.nodes.where((c) => !previous.nodes.any((p) => c.key == p.key));

    // Estimate removed nodes
    final removedNodes =
        previous.nodes.where((p) => !current.nodes.any((c) => c.key == p.key));

    // Estimate changed nodes
    final changedNodes = current.nodes.where(
      (c) => previous.nodes.any(
        (p) => c.key == p.key && c != p.bluePrint,
      ),
    );

    // .....................
    // Dispose removed nodes
    for (final removedNodeBluePrint in removedNodes.toList()) {
      final removedNode = previous.node<dynamic>(key: removedNodeBluePrint.key);
      assert(removedNode != null);
      removedNode?.dispose();
    }

    // Instantiate added nodes
    for (final addedNode in addedNodes) {
      addedNode.instantiate(scope: previous);
    }

    // Update changed nodes
    for (final changedNodeBluePrint in changedNodes) {
      previous.replaceNode(
        changedNodeBluePrint,
      );
    }
  }
}

// #############################################################################
// Example scopes for test purposes

// .............................................................................
/// An example root scope
class ExampleScopeRoot extends Scope {
  /// Constructor
  ExampleScopeRoot({
    required super.scm,
    super.key = 'exampleRoot',
  }) : super.root() {
    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) => previous + 1, // coverage:ignore-line
        key: 'rootA',
      ),
    );

    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) => previous + 1, // coverage:ignore-line
        key: 'rootB',
      ),
    );

    ExampleChildScope(key: 'childScopeA', parent: this);
    ExampleChildScope(key: 'childScopeB', parent: this);
  }
}

// .............................................................................
/// An example child scope
class ExampleChildScope extends Scope {
  /// Constructor
  ExampleChildScope({
    required super.key,
    required super.parent,
  }) {
    /// Create a node
    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) => previous + 1,
        key: 'childNodeA',
        suppliers: ['rootA', 'rootB', 'childScopeA.childNodeB'],
      ),
    );

    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) => previous + 1,
        key: 'childNodeB',
      ),
    );

    /// Create two example child scopes
    ExampleGrandChildScope(
      key: 'grandChildScope',
      parent: this,
    );
  }
}

// .............................................................................
/// An example child scope
class ExampleGrandChildScope extends Scope {
  /// Constructor
  ExampleGrandChildScope({
    required super.key,
    required super.parent,
  }) {
    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) => previous + 1,
        key: 'grandChildNodeA',
        suppliers: [
          'rootA',
        ],
      ),
    );
  }
}
