// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the inserts of a plugin
///
/// - Deeply iterates all nodes of the plugin's scope
/// - Creates scopes for the inserts
/// - Creates the insert nodes for each child
class Inserts {
  /// The constructor
  Inserts({
    required this.plugin,
  }) {
    _init(plugin.scope);
  }

  /// The plugin this inserts belongs to
  final Plugin plugin;

  // ...........................................................................
  /// Disposes the insert and removes it from the scope
  void dispose() {
    for (final scope in _scopes) {
      scope.dispose();
    }
  }

  // ...........................................................................
  /// Returns an example instance
  factory Inserts.example() {
    final plugin = Plugin.example();
    final inserts = plugin.inserts;
    return inserts;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init(Scope scope) {
    // Deeply iterate through all child nodes and init the inserts
    _initScope(scope);

    for (final childScope in scope.children) {
      _init(childScope);
    }
  }

  // ...........................................................................
  void _initScope(Scope scope) {
    // Iterare all nodes and child nodes and apply the insert
    for (final node in scope.nodes) {
      // Get the inserts for the node
      final insertsForNode = plugin.bluePrint.inserts(hostNode: node);
      if (insertsForNode.isEmpty) {
        continue;
      }

      // Create a scope hosting all the inserts of the current plugin
      final Scope scopeForInsertsOfPlugin =
          scope.findOrCreateChild(plugin.bluePrint.key);
      _scopes.add(scopeForInsertsOfPlugin);

      // Each node can have multiple inserts.
      // Therefore create a scope for each node
      Scope scopeForInsertsOfNode =
          scopeForInsertsOfPlugin.findOrCreateChild('${node.key}Inserts');

      // Add the inserts to the node
      for (final insertNodeBluePrint in insertsForNode) {
        insertNodeBluePrint.instantiateAsInsert(
          host: node,
          scope: scopeForInsertsOfNode,
        );
      }
    }
  }

  final Set<Scope> _scopes = {};
}
