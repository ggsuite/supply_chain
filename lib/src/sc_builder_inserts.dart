// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the inserts of a builder
///
/// - Deeply iterates all nodes of the builder's scope
/// - Creates scopes for the inserts
/// - Creates the insert nodes for each child
class ScBuilderInserts {
  /// The constructor
  ScBuilderInserts({
    required this.builder,
  });

  /// The builder this inserts belongs to
  final ScBuilder builder;

  // ...........................................................................
  /// Disposes the insert and removes it from the scope
  void dispose() {
    for (final scope in _scopes) {
      scope.dispose();
    }
  }

  // ...........................................................................
  /// Returns an example instance
  factory ScBuilderInserts.example() {
    final builder = ScBuilder.example();
    final inserts = builder.inserts;
    return inserts;
  }

  // ...........................................................................
  /// Deeply iterate through all child nodes and init the inserts
  void applyToScope(Scope scope) {
    if (!builder.bluePrint.shouldDigInto(scope)) {
      return;
    }

    _applyToScope(scope);

    for (final childScope in scope.children) {
      applyToScope(childScope);
    }
  }

  // ...........................................................................
  /// Deeply iterate through all child nodes and init the inserts
  void applyToNode(Node<dynamic> node) {
    _applyToNode(node);
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _applyToScope(Scope scope) {
    // Iterare all nodes and child nodes and apply the insert
    for (final node in scope.nodes) {
      _applyToNode(node);
    }
  }

  // ...........................................................................
  void _applyToNode(Node<dynamic> node) {
    // Get the inserts for the node
    final insertsForNode = builder.bluePrint.inserts(hostNode: node);
    if (insertsForNode.isEmpty) {
      return;
    }

    // Create a scope hosting all the inserts of the current builder
    final Scope scopeForInsertsOfScBuilder =
        node.scope.findOrCreateChild(builder.bluePrint.key);
    _scopes.add(scopeForInsertsOfScBuilder);

    // Each node can have multiple inserts.
    // Therefore create a scope for each node
    Scope scopeForInsertsOfNode =
        scopeForInsertsOfScBuilder.findOrCreateChild('${node.key}Inserts');

    // Add the inserts to the node
    for (final insertNodeBluePrint in insertsForNode) {
      insertNodeBluePrint.instantiateAsInsert(
        host: node,
        scope: scopeForInsertsOfNode,
      );
    }
  }

  final Set<Scope> _scopes = {};
}
