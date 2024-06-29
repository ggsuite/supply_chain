// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A plugin changes various aspects of a scope and its children
class PluginBluePrint {
  ///  Constructor
  const PluginBluePrint({
    required this.key,
  });

  /// Instantiates this plugin and it's children within the given hostScope
  ///
  /// - [hostScope]: The scope this plugin will be instantiated in
  /// - The callbacks below will be applied to the hostScope and all its
  ///   children
  Plugin instantiate({required Scope scope}) {
    return Plugin(bluePrint: this, scope: scope);
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
    required NodeBluePrint<dynamic> nodeToBeReplaced,
  }) {
    return nodeToBeReplaced;
  }

  // ...........................................................................
  // Inserts

  /// Override this method to add inserts into a given node
  ///
  /// - [hostNode]: The host node the returned inserts will be added to
  List<InsertBluePrint<dynamic>> inserts({
    required Node<dynamic> hostNode,
  }) {
    return [];
  }

  // ...........................................................................
  // Child plugins

  /// Override this method to add child plugins to this plugin
  ///
  /// - Returns: A list of child plugins
  List<PluginBluePrint> get children {
    return [];
  }

  // ...........................................................................
  /// Returns an example instance of the plugin
  static Plugin get example {
    return ExamplePluginBluePrint.example;
  }

  // ######################
  // Private
  // ######################

  /// The key of the plugin
  final String key;
}

// #############################################################################
/// An example plugin
class ExamplePluginBluePrint extends PluginBluePrint {
  /// The constructor
  const ExamplePluginBluePrint({super.key = 'examplePlugin'});

  // ...........................................................................
  /// Inserts

  /// Will add two inserts "add111" and "multiplyByTen" to all nodes
  /// starting with host
  @override
  List<InsertBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<int>) {
      return [
        InsertBluePrint<int>(
          key: 'add111',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct + 111;
          },
        ),
        InsertBluePrint<int>(
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
  /// Child plugins
  @override
  List<PluginBluePrint> get children {
    return [
      const ExampleChildPluginBluePrint(),
    ];
  }

  // ...........................................................................
  /// Returns an example instance of the ExamplePlugin
  static Plugin get example {
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

    // Apply the plugin to the scope
    final plugin = const ExamplePluginBluePrint().instantiate(scope: scope);
    plugin.scope.scm.testFlushTasks();
    return plugin;
  }
}

// #############################################################################
/// An example plugin
class ExampleChildPluginBluePrint extends PluginBluePrint {
  /// The constructor
  const ExampleChildPluginBluePrint({super.key = 'exampleChildPlugin'});

  // ...........................................................................
  /// Inserts

  /// Will an insert "diveByTwo" to all nodes starting with host
  @override
  List<InsertBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<int>) {
      return [
        InsertBluePrint<int>(
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
