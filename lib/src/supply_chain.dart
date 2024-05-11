// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A supply chain is a container for connected nodes
class SupplyChain {
  // ...........................................................................
  /// Creates a chain with a key. Key must be lower camel case.
  SupplyChain({
    required this.key,
    required this.parent,
  })  : scm = parent!.scm,
        assert(key.isPascalCase) {
    parent!._children[key] = this;
  }

  // ...........................................................................
  /// Create a root supply chain having no parent
  SupplyChain.root({
    required this.key,
    required this.scm,
  })  : parent = null,
        assert(key.isPascalCase);

  // ...........................................................................
  /// The supply chain manager
  final Scm scm;

  /// The key of the chain
  final String key;

  /// The uinquie id of the chain
  final int id = _idCounter++;

  /// Reset id counter for test purposes
  static void testRestIdCounter() => _idCounter = 0;

  // ...........................................................................
  /// Returns the child chains
  Iterable<SupplyChain> get children => _children.values;

  /// Returns the child chain with the given key
  SupplyChain? child(String key) => _children[key];

  /// The nodes of this chain
  Iterable<Node<dynamic>> get nodes => _nodes.values;

  // ...........................................................................
  /// Returns the node with key. If not available in chain the node is created.
  Node<T> findOrCreateNode<T>({
    required T initialProduct,
    required Produce<T> produce,
    required String key,
    Iterable<String> suppliers = const [],
  }) {
    // Return existing node when already existing
    final existingNode = _nodes[key];
    if (existingNode != null) {
      assert(existingNode is Node<T>, 'Existing node is of differnt type');
      final result = existingNode as Node<T>;
      assert(
        result.nodeConfig.produce == produce,
        'Existing node has different production method',
      );
      return result;
    }

    // Create a new node
    final node = Node<T>(
      nodeConfig: NodeConfig(
        initialProduct: initialProduct,
        produce: produce,
        key: key,
        suppliers: suppliers,
      ),
      chain: this,
    );

    return node;
  }

  // ...........................................................................
  /// The parent supply chain
  SupplyChain? parent;

  // ...........................................................................
  /// Adds an existing node to the chain
  void addNode(Node<dynamic> node) {
    // Throw if node with key already exists
    if (_nodes.containsKey(node.key)) {
      throw ArgumentError(
        'Node with key ${node.key} already exists in chain "$key"',
      );
    }

    _nodes[node.key] = node;
  }

  // ...........................................................................
  /// Remove the node from the chain
  void removeNode(Node<dynamic> node) {
    _nodes.remove(node.key);
  }

  // ...........................................................................
  /// Creates an example instance of Chain
  factory SupplyChain.example({Scm? scm}) {
    scm ??= Scm.testInstance;

    return SupplyChain(
      key: 'Example',
      parent: SupplyChain.root(key: 'Root', scm: scm),
    );
  }

  // ...........................................................................
  /// Returns true if this chain is an ancestor of the given chain
  bool isAncestorOf(SupplyChain chain) {
    if (_children.containsKey(chain.key)) {
      return true;
    }

    for (final child in _children.values) {
      if (child.isAncestorOf(chain)) {
        return true;
      }
    }

    return false;
  }

  // ...........................................................................
  /// Returns true if this chain is a descendant of the given chain
  bool isDescendantOf(SupplyChain chain) {
    if (chain._children.containsKey(key)) {
      return true;
    }

    for (final child in chain._children.values) {
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
      final suppliers = node.nodeConfig.suppliers;
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
  /// parent supply chain
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
    result += _graph;
    result += '}';
    return result;
  }

  // ...........................................................................
  /// Returns true if the given graph is equal to the graph of this chain
  bool equalsGraph(String graph) {
    String reduce(String s) => s
        .replaceAll('\n', '')
        .replaceAll(' ', '')
        .replaceAll(';', '')
        .replaceAll(RegExp(r'_\d+'), '');

    final a = reduce(this.graph);
    final b = reduce(graph);
    return a == b;
  }

  // ######################
  // Private
  // ######################

  final Map<String, SupplyChain> _children = {};
  final Map<String, Node<dynamic>> _nodes = {};
  static int _idCounter = 0;

  // ...........................................................................
  // Graph
  String get _graph {
    {
      var result = '';

      final chainId = '${key}_${this.id}';

      // Create a cluster for this chain
      result += 'subgraph cluster_$chainId { ';
      result += 'label = "$key"; ';

      // Write the child chains
      for (final childChain in children) {
        result += childChain._graph;
      }

      String id(Node<dynamic> node) => '${node.key}_${node.id}';

      // Write each node
      for (final node in nodes) {
        final nodeId = id(node);
        result += '$nodeId [label="${node.key}"]; ';
      }

      // Write dependencies
      for (final node in nodes) {
        for (final customer in node.customers) {
          final from = id(node);
          final to = id(customer);

          result += '"$from" -> "$to"; ';
        }
      }

      result += '}'; // cluster

      return result;
    }
  }

  // ...........................................................................
  void _addSuppliers(Node<dynamic> node, Iterable<String> suppliers) {
    for (final supplierName in suppliers) {
      final supplier = findNode<dynamic>(supplierName);
      if (supplier == null) {
        throw ArgumentError(
          'Chain "$key": Supplier with key "$supplierName" not found.',
        );
      }

      node.addSupplier(supplier);
    }
  }
}

// #############################################################################
// Example chains for test purposes

// .............................................................................
/// An example root chain
class ExampleChainRoot extends SupplyChain {
  /// Constructor
  ExampleChainRoot({
    required super.scm,
    super.key = 'ExampleRoot',
  }) : super.root() {
    findOrCreateNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1, // coveralls:ignore-line
      key: 'RootA',
    );

    findOrCreateNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1, // coveralls:ignore-line
      key: 'RootB',
    );

    ExampleChildChain(key: 'ChildChainA', parent: this);
    ExampleChildChain(key: 'ChildChainB', parent: this);
  }
}

// .............................................................................
/// An example child chain
class ExampleChildChain extends SupplyChain {
  /// Constructor
  ExampleChildChain({
    required super.key,
    required super.parent,
  }) {
    /// Create a node
    findOrCreateNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1,
      key: 'ChildNodeA',
      suppliers: ['RootA', 'RootB', 'ChildNodeB'],
    );

    findOrCreateNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1,
      key: 'ChildNodeB',
    );

    /// Create two example child chains
    ExampleGrandChildChain(
      key: 'GrandChildChain',
      parent: this,
    );
  }
}

// .............................................................................
/// An example child chain
class ExampleGrandChildChain extends SupplyChain {
  /// Constructor
  ExampleGrandChildChain({
    required super.key,
    required super.parent,
  }) {
    findOrCreateNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1,
      key: 'GrandChildNodeA',
      suppliers: [
        'RootA',
      ],
    );
  }
}
