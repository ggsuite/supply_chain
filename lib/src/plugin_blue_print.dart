// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A plugin changes various aspects of a scope and its children
class PluginBluePrint {
  ///  Constructor
  PluginBluePrint({
    required this.key,
  });

  /// Instantiates this plugin within the given hostScope
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
  // Modify inserts

  /// Override this method to add inserts into a given node
  ///
  /// - [hostNode]: The host node the returned inserts will be added to
  List<ScopeInserts> inserts() {
    return [];
  }

  // ...........................................................................
  /// Returns an example instance of the plugin
  factory PluginBluePrint.example({
    String? key,
  }) {
    return PluginBluePrint(key: key ?? 'example');
  }

  // ######################
  // Private
  // ######################

  /// The key of the plugin
  final String key;
}
