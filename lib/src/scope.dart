// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_is_github/gg_is_github.dart';
import 'package:supply_chain/supply_chain.dart';

/// A supply scope is a container for connected nodes
class Scope {
  // ...........................................................................
  /// Creates a scope with a key. Key must be lower camel case.
  Scope({
    required this.key,
    required this.parent,
  })  : scm = parent!.scm,
        assert(key.isPascalCase) {
    parent!._children[key] = this;
  }

  // ...........................................................................
  /// Create a root supply scope having no parent
  Scope.root({
    required this.key,
    required this.scm,
  })  : parent = null,
        assert(key.isPascalCase);

  // ...........................................................................
  /// The supply scope manager
  final Scm scm;

  /// The key of the scope
  final String key;

  /// The uinquie id of the scope
  final int id = _idCounter++;

  /// Reset id counter for test purposes
  static void testRestIdCounter() => _idCounter = 0;

  // ...........................................................................
  /// Returns the child scopes
  Iterable<Scope> get children => _children.values;

  /// Returns the child scope with the given key
  Scope? child(String key) => _children[key];

  /// The nodes of this scope
  Iterable<Node<dynamic>> get nodes => _nodes.values;

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
      result.add(bluePrint.instantiate(scope: this));
    }
    return result;
  }

  // ...........................................................................
  /// The parent supply scope
  Scope? parent;

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
  void removeNode(Node<dynamic> node) {
    _nodes.remove(node.key);
  }

  // ...........................................................................
  /// Creates an example instance of Scope
  factory Scope.example({Scm? scm}) {
    scm ??= Scm.testInstance;

    return Scope(
      key: 'Example',
      parent: Scope.root(key: 'Root', scm: scm),
    );
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

  // ...........................................................................
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
  /// Call this method to init the suppliers.
  /// But not before the whole hierarchy has been created
  void initSuppliers() {
    for (final node in _nodes.values) {
      final suppliers = node.bluePrint.suppliers;
      if (suppliers.isNotEmpty) {
        _addSuppliers(node, suppliers);
      }
    }

    for (final child in _children.values) {
      child.initSuppliers();
    }
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
    final node = _findNodeInOwnNode<T>(key) ??
        _findNodeNodeInParentNodes(key) ??
        _findNodeInDirectSiblingNodes(key) ??
        _findAnyUniqueNode<T>(key);

    if (node == null && throwIfNotFound) {
      throw ArgumentError('Node with key "$key" not found.');
    }

    return node;
  }

  // ...........................................................................
  Node<T>? _findNodeInOwnNode<T>(String key) {
    final node = _nodes[key];
    if (node == null) {
      return null;
    }

    if (node is! Node<T>) {
      throw ArgumentError('Node with key "$key" is not of type $T');
    }

    return node;
  }

  // ...........................................................................
  Node<T>? _findNodeNodeInParentNodes<T>(String key) {
    return parent?._findNodeInOwnNode<T>(key) ??
        parent?._findNodeNodeInParentNodes<T>(key);
  }

  // ...........................................................................
  Node<T>? _findNodeInDirectSiblingNodes<T>(String key) {
    if (parent == null) {
      return null;
    }

    for (final sibling in parent!._children.values) {
      final node = sibling._findNodeInOwnNode<T>(key);
      if (node != null) {
        return node;
      }
    }

    return null;
  }

  // ...........................................................................
  Node<T>? _findAnyUniqueNode<T>(String key) {
    final nodes = scm.nodesWithKey<T>(key);
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

  // ...........................................................................
  // Print graph

  /// Returns a graph that can be turned into svg using graphviz
  String get graph {
    var result = '';
    result += 'digraph unix { ';
    result += _graphNodes;
    result += _graphEdges;
    result += '}';
    return result;
  }

  /// Save the graph to a file
  ///
  /// The format can be
  /// bmp canon cgimage cmap cmapx cmapx_np dot dot_json eps exr fig gd gd2 gif
  /// gv icns ico imap imap_np ismap jp2 jpe jpeg jpg json json0 kitty kittyz
  /// mp pct pdf pic pict plain plain-ext png pov ps ps2 psd sgi svg svgz tga
  /// tif tiff tk vrml vt vt-24bit wbmp webp xdot xdot1.2 xdot1.4 xdot_json
  Future<void> saveGraphToFile(
    String path,
  ) async {
    final format = path.split('.').last;

    final content = graph;
    final file = File(path);
    if (format == 'dot') {
      await file.writeAsString(content);
      return;
    }
    // coveralls:ignore-start
    else {
      if (!isGitHub) {
        // Write dot file to tmp
        final fileName = path.split('/').last;
        final tempDir = await Directory.systemTemp.createTemp();
        final tempPath = '${tempDir.path}/$fileName.dot';
        final tempFile = File(tempPath);
        tempFile.writeAsStringSync(content);

        // Convert dot file to target format
        final process = await Process.run(
          'dot',
          ['-T$format', tempPath, '-o$path'],
        );
        await tempDir.delete(recursive: true);
        assert(process.exitCode == 0, process.stderr);
      }
    }
    // coveralls:ignore-end
  }

  // ######################
  // Private
  // ######################

  final Map<String, Scope> _children = {};
  final Map<String, Node<dynamic>> _nodes = {};
  static int _idCounter = 0;

  // ...........................................................................
  String _nodeId(Node<dynamic> node) => '${node.key}_${node.id}';

  // ...........................................................................
  // Graph
  String get _graphNodes {
    {
      var result = '';

      final scopeId = '${key}_$id';

      // Create a cluster for this scope
      result += 'subgraph cluster_$scopeId { ';
      result += 'label = "$key"; ';

      // Write the child scopes
      for (final childScope in children) {
        result += childScope._graphNodes;
      }

      // Write each node
      for (final node in nodes) {
        final nodeId = _nodeId(node);
        result += '$nodeId [label="${node.key}"]; ';
      }

      result += '}'; // cluster

      return result;
    }
  }

  // ...........................................................................
  String get _graphEdges {
    {
      var result = '';

      // Write dependencies
      for (final node in nodes) {
        for (final customer in node.customers) {
          final from = _nodeId(node);
          final to = _nodeId(customer);

          result += '"$from" -> "$to"; ';
        }
      }

      // Write the child scopes
      for (final childScope in children) {
        result += childScope._graphEdges;
      }

      return result;
    }
  }

  // ...........................................................................
  void _addSuppliers(Node<dynamic> node, Iterable<String> suppliers) {
    for (final supplierName in suppliers) {
      final supplier = findNode<dynamic>(supplierName);
      if (supplier == null) {
        throw ArgumentError(
          'Scope "$key": Supplier with key "$supplierName" not found.',
        );
      }

      node.addSupplier(supplier);
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
    super.key = 'ExampleRoot',
  }) : super.root() {
    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) =>
            previous + 1, // coveralls:ignore-line
        key: 'RootA',
      ),
    );

    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) =>
            previous + 1, // coveralls:ignore-line
        key: 'RootB',
      ),
    );

    ExampleChildScope(key: 'ChildScopeA', parent: this);
    ExampleChildScope(key: 'ChildScopeB', parent: this);
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
        key: 'ChildNodeA',
        suppliers: ['RootA', 'RootB', 'ChildNodeB'],
      ),
    );

    findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: (components, previous) => previous + 1,
        key: 'ChildNodeB',
      ),
    );

    /// Create two example child scopes
    ExampleGrandChildScope(
      key: 'GrandChildScope',
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
        key: 'GrandChildNodeA',
        suppliers: [
          'RootA',
        ],
      ),
    );
  }
}
