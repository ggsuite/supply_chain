// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the inserts of a customizer
///
/// - Deeply iterates all nodes of the customizer's scope
/// - Creates scopes for the inserts
/// - Creates the insert nodes for each child
class CustomizerInserts {
  /// The constructor
  CustomizerInserts({
    required this.customizer,
  }) {
    init(customizer.scope);
  }

  /// The customizer this inserts belongs to
  final Customizer customizer;

  // ...........................................................................
  /// Disposes the insert and removes it from the scope
  void dispose() {
    for (final scope in _scopes) {
      scope.dispose();
    }
  }

  // ...........................................................................
  /// Returns an example instance
  factory CustomizerInserts.example() {
    final customizer = Customizer.example();
    final inserts = customizer.inserts;
    return inserts;
  }

  // ...........................................................................
  /// Deeply iterate through all child nodes and init the inserts
  void init(Scope scope) {
    _initScope(scope);

    for (final childScope in scope.children) {
      init(childScope);
    }
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _initScope(Scope scope) {
    // Iterare all nodes and child nodes and apply the insert
    for (final node in scope.nodes) {
      // Get the inserts for the node
      final insertsForNode = customizer.bluePrint.inserts(hostNode: node);
      if (insertsForNode.isEmpty) {
        continue;
      }

      // Create a scope hosting all the inserts of the current customizer
      final Scope scopeForInsertsOfCustomizer =
          scope.findOrCreateChild(customizer.bluePrint.key);
      _scopes.add(scopeForInsertsOfCustomizer);

      // Each node can have multiple inserts.
      // Therefore create a scope for each node
      Scope scopeForInsertsOfNode =
          scopeForInsertsOfCustomizer.findOrCreateChild('${node.key}Inserts');

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
