// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A builder changes various aspects of a scope and its children
class ScBuilderBluePrint {
  ///  Constructor
  const ScBuilderBluePrint({
    required this.key,
    this.needsUpdateSuppliers = const [],
  });

  /// Instantiates this builder and it's children within the given hostScope
  ///
  /// - [hostScope]: The scope this builder will be instantiated in
  /// - The callbacks below will be applied to the hostScope and all its
  ///   children
  ScBuilder instantiate({required Scope scope}) {
    return ScBuilder(bluePrint: this, scope: scope);
  }

  // ...........................................................................
  // Modify scopes

  /// Override this method to add scopes to the given host scope
  ///
  /// - [hostScope]: The host scope the returned scopes will be added to
  /// - Returns: A list of scopes to be added to the host scope
  List<ScopeBluePrint> addScopes({
    required Scope hostScope,
  }) {
    return [];
  }

  /// Override this method to replace scopes in the given host scope
  ///
  /// - [hostScope]: The host scope the replaced scope is coming from
  /// - [scopeToBeReplaced]: The original version of the scope to be replaced
  /// - returns: The replaced version of [scopeToBeReplaced]
  ScopeBluePrint replaceScope({
    required Scope hostScope,
    required ScopeBluePrint scopeToBeReplaced,
  }) {
    return scopeToBeReplaced;
  }

  // ...........................................................................
  // Modify nodes

  /// Override this method to add nodes to a given host scope
  ///
  /// - [hostScope]: The host scope the returned nodes will be added to
  /// - Returns: A list of nodes to be added to the host scope
  List<NodeBluePrint<dynamic>> addNodes({
    required Scope hostScope,
  }) {
    return [];
  }

  /// Override this method to replace a scope in a given host scope
  ///
  /// - [hostScope]: The host scope the replaced node is coming from
  /// - [nodeToBeReplaced]: The original version of the node to be replaced
  /// - Returns: The replaced version of [nodeToBeReplaced]
  NodeBluePrint<dynamic> replaceNode({
    required Scope hostScope,
    required Node<dynamic> nodeToBeReplaced,
  }) {
    return nodeToBeReplaced.bluePrint;
  }

  // ...........................................................................
  // Inserts

  /// Override this method to add inserts into a given node
  ///
  /// - [hostNode]: The host node the returned inserts will be added to
  List<NodeBluePrint<dynamic>> inserts({
    required Node<dynamic> hostNode,
  }) {
    return [];
  }

  // ...........................................................................
  // Child builders

  /// A builder can define builders for child scopes
  ///
  /// Child builders are instantiated before parent builders.
  /// I.e. the parent's builders will be applied after the child builders.
  ///
  ///
  /// - Returns: A list of child builders
  List<ScBuilderBluePrint> children({required Scope hostScope}) {
    return [];
  }

  // ...........................................................................
  /// Returns an example instance of the builder
  static ScBuilder get example {
    return ExampleScBuilderBluePrint.example;
  }

  /// The key of the builder
  final String key;

  // ...........................................................................
  /// When one of these suppliers change, the rebuild method will be called
  final List<String> needsUpdateSuppliers;

  /// Override this method to react to do something when one of the suppliers
  /// in [needsUpdateSuppliers] has a new product.
  ///
  /// [hostScope]: The scope this builder is instantiated in
  /// [components]: The latest components of the suppliers
  void needsUpdate({
    required Scope hostScope,
    required List<dynamic> components,
  }) {}
}

// #############################################################################
/// An example builder
class ExampleScBuilderBluePrint extends ScBuilderBluePrint {
  /// The constructor
  ExampleScBuilderBluePrint({
    super.key = 'exampleScBuilder',
    super.needsUpdateSuppliers,
  });

  // ...........................................................................
  /// Inserts

  /// Will add two inserts "add111" and "p1MultiplyByTen" to all nodes
  /// starting with host
  @override
  List<NodeBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<int>) {
      return [
        NodeBluePrint<int>(
          key: 'p0Add111',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct + 111;
          },
        ),
        NodeBluePrint<int>(
          key: 'p1MultiplyByTen',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct * 10;
          },
        ),
      ];
    }

    return super.inserts(hostNode: hostNode);
  }

  // ...........................................................................
  /// All scopes with key 'b' will get a child builder
  @override
  List<ScBuilderBluePrint> children({required Scope hostScope}) {
    return [
      if (hostScope.key == 'b') const ExampleChildScBuilderBluePrint(),
    ];
  }

  // ...........................................................................
  /// Returns an example instance of the ExampleScBuilder
  static ScBuilder get example {
    // The example applies inserts to all nodes with a key
    // starting with 'host'.

    // Let's create a node hiearchy with nodes starting with keys
    // starting with hosts
    final scope = Scope.example(
      builders: [
        ExampleScBuilderBluePrint(
          needsUpdateSuppliers: [
            'a.other',
          ],
        ),
      ],
      children: [
        ScopeBluePrint.fromJson({
          'a': {
            'hostA': 0xA,
            'other': 1,
            'b': {
              'hostB': 0xB,
              'hostC': 0xC,
            },
          },
        }),
      ],
    );

    // Apply the builder to the scope
    scope.scm.testFlushTasks();
    return scope.builders.first;
  }

  /// Returns how often needsUpdate was called
  Iterable<(Scope, List<dynamic> components)> get needsUpdateCalls =>
      _needsUpdateCalls;

  final List<(Scope, List<dynamic> components)> _needsUpdateCalls = [];

  // ...........................................................................
  @override
  void needsUpdate({
    required Scope hostScope,
    required List<dynamic> components,
  }) {
    super.needsUpdate(hostScope: hostScope, components: components);
    _needsUpdateCalls.add((hostScope, components));
  }
}

// #############################################################################
/// An example builder
class ExampleChildScBuilderBluePrint extends ScBuilderBluePrint {
  /// The constructor
  const ExampleChildScBuilderBluePrint({super.key = 'exampleChildScBuilder'});

  // ...........................................................................
  /// Inserts

  /// Will an insert "c0MultiplyByTwo" to all nodes starting with host
  @override
  List<NodeBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<int>) {
      return [
        NodeBluePrint<int>(
          key: 'c0MultiplyByTwo',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct * 2;
          },
        ),
      ];
    }

    return super.inserts(hostNode: hostNode);
  }
}
