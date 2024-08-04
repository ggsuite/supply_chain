// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A customizer changes various aspects of a scope and its children
class CustomizerBluePrint {
  ///  Constructor
  const CustomizerBluePrint({
    required this.key,
  });

  /// Instantiates this customizer and it's children within the given hostScope
  ///
  /// - [hostScope]: The scope this customizer will be instantiated in
  /// - The callbacks below will be applied to the hostScope and all its
  ///   children
  Customizer instantiate({required Scope scope}) {
    return Customizer(bluePrint: this, scope: scope);
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
  // Child customizers

  /// A customizer can define customizers for child scopes
  ///
  /// - Returns: A list of child customizers
  List<CustomizerBluePrint> customizers({required Scope hostScope}) {
    return [];
  }

  // ...........................................................................
  /// Returns an example instance of the customizer
  static Customizer get example {
    return ExampleCustomizerBluePrint.example;
  }

  // ######################
  // Private
  // ######################

  /// The key of the customizer
  final String key;
}

// #############################################################################
/// An example customizer
class ExampleCustomizerBluePrint extends CustomizerBluePrint {
  /// The constructor
  const ExampleCustomizerBluePrint({super.key = 'exampleCustomizer'});

  // ...........................................................................
  /// Inserts

  /// Will add two inserts "add111" and "multiplyByTen" to all nodes
  /// starting with host
  @override
  List<NodeBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<int>) {
      return [
        NodeBluePrint<int>(
          key: 'add111',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct + 111;
          },
        ),
        NodeBluePrint<int>(
          key: 'multiplyBeTen',
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
  /// All scopes with key 'b' will get a child customizer
  @override
  List<CustomizerBluePrint> customizers({required Scope hostScope}) {
    return [
      if (hostScope.key == 'b') const ExampleChildCustomizerBluePrint(),
    ];
  }

  // ...........................................................................
  /// Returns an example instance of the ExampleCustomizer
  static Customizer get example {
    // The example applies inserts to all nodes with a key
    // starting with 'host'.

    // Let's create a node hiearchy with nodes starting with keys
    // starting with hosts
    final scope = Scope.example();

    scope.mockContent({
      'a': {
        'hostA': 0xA,
        'other': 1,
        'b': {
          'hostB': 0xB,
          'hostC': 0xC,
        },
      },
    });

    const ExampleCustomizerBluePrint().instantiate(scope: scope);

    // Apply the customizer to the scope
    scope.scm.testFlushTasks();
    return scope.customizers.first;
  }
}

// #############################################################################
/// An example customizer
class ExampleChildCustomizerBluePrint extends CustomizerBluePrint {
  /// The constructor
  const ExampleChildCustomizerBluePrint({super.key = 'exampleChildCustomizer'});

  // ...........................................................................
  /// Inserts

  /// Will an insert "diveByTwo" to all nodes starting with host
  @override
  List<NodeBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<int>) {
      return [
        NodeBluePrint<int>(
          key: 'multiplyByTwo',
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
