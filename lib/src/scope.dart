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
  }) {
    final node = Node<T>(
      initialProduct: initialProduct,
      produce: produce,
      scope: this,
      name: name,
    );

    return node;
  }

  // ...........................................................................
  /// Adds an existing node to the scope
  void addNode(Node<dynamic> node) {
    // Throw if node with name already exists
    if (_nodes.containsKey(node.name)) {
      throw ArgumentError(
        'Node with name ${node.name} already exists in scope "$key"',
      );
    }

    _nodes[node.name] = node;
  }

  // ...........................................................................
  /// Remove the node from the scope
  void removeNode(Node<dynamic> node) {
    _nodes.remove(node.name);
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
    }
  }

  // ######################
  // Private
  // ######################

  final Map<String, Scope> _children = {};
  final Map<String, Node<dynamic>> _nodes = {};
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
      produce: (node) {},
      name: 'RootA',
    );

    createNode(
      initialProduct: 0,
      produce: (node) {},
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
      produce: (node) {},
      name: 'ChildNodeA',
    );

    createNode(
      initialProduct: 0,
      produce: (node) {},
      name: 'ChildNodeB',
    );

    return [];
  }
}
