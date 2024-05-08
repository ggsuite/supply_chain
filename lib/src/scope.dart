// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../supply_chain.dart';
import 'scm_node_interface.dart';

/// A scope is a container for nodes
class Scope {
  /// Creates a scope with a key. Key must be lower camel case.
  Scope({
    required this.key,
    required this.scm,
  }) : assert(key.isPascalCase);

  // ...........................................................................
  /// The supply chain manager
  final ScmNodeInterface scm;

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
  /// Adds a node to the scope
  Node<T> createNode<T>({
    required T initialProduct,
    required Produce<T> produce,
    required String name,
    Iterable<String> suppliers = const [],
  }) {
    final node = Node<T>(
      initialProduct: initialProduct,
      produce: produce,
      scope: this,
      key: name,
    );

    if (suppliers.isNotEmpty) {
      _supplierStrings[node.key] = suppliers;
    }

    return node;
  }

  // ...........................................................................
  /// Adds an existing node to the scope
  void addNode(Node<dynamic> node) {
    // Throw if node with name already exists
    if (_nodes.containsKey(node.key)) {
      throw ArgumentError(
        'Node with name ${node.key} already exists in scope "$key"',
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
  factory Scope.example({ScmNodeInterface? scm}) => Scope(
        key: 'Example',
        scm: scm ?? Scm.testInstance,
      );

  // ...........................................................................
  /// Overide this method to build the nodes belonging to this scope
  Iterable<Scope> build() => [];

  // ...........................................................................
  /// Call this method to create child hierarchies
  void createHierarchy() {
    for (final child in build()) {
      _children[child.key] = child;
      child.createHierarchy();
      child._parent = this;
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
      final suppliers = _supplierStrings[node.key];
      if (suppliers != null) {
        _addSuppliers(node, suppliers);
      }
    }

    for (final child in _children.values) {
      child.initSuppliers();
    }
  }

  // ...........................................................................
  /// Returns the node of name in this or any parent nodes
  Node<dynamic>? findNode(String name) {
    final node = _nodes[name];
    if (node != null) {
      return node;
    }

    return _parent?.findNode(name);
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

  // ######################
  // Private
  // ######################

  final Map<String, Scope> _children = {};
  Scope? _parent;
  final Map<String, Node<dynamic>> _nodes = {};
  final Map<String, Iterable<String>> _supplierStrings = {};
  static int _idCounter = 0;

  // ...........................................................................
  // Graph
  String get _graph {
    {
      var result = '';

      final scopeId = '${key}_${this.id}';

      // Create a cluster for this scope
      result += 'subgraph cluster_$scopeId { ';
      result += 'label = "$key"; ';

      // Write the child scopes
      for (final childScope in children) {
        result += childScope._graph;
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
      final supplier = findNode(supplierName);
      if (supplier == null) {
        throw ArgumentError(
          'Scope "$key": Supplier with name "$supplierName" not found.',
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
  ExampleScopeRoot({required super.scm, super.key = 'ExampleRoot'});

  @override
  Iterable<Scope> build() {
    createNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1, // coveralls:ignore-line
      name: 'RootA',
    );

    createNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1, // coveralls:ignore-line
      name: 'RootB',
    );

    return [
      ExampleChildScope(key: 'ChildScopeA', scm: scm),
      ExampleChildScope(key: 'ChildScopeB', scm: scm),
    ];
  }
}

// .............................................................................
/// An example child scope
class ExampleChildScope extends Scope {
  /// Constructor
  ExampleChildScope({required super.scm, required super.key});

  @override
  Iterable<Scope> build() {
    createNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1,
      name: 'ChildNodeA',
      suppliers: ['RootA', 'RootB', 'ChildNodeB'],
    );

    createNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1,
      name: 'ChildNodeB',
    );

    return [ExampleGrandChildScope(key: 'GrandChildScope', scm: scm)];
  }
}

// .............................................................................
/// An example child scope
class ExampleGrandChildScope extends Scope {
  /// Constructor
  ExampleGrandChildScope({required super.scm, required super.key});

  @override
  Iterable<Scope> build() {
    createNode(
      initialProduct: 0,
      produce: (components, previous) => previous + 1,
      name: 'GrandChildNodeA',
      suppliers: [
        'RootA',
      ],
    );

    return [];
  }
}
