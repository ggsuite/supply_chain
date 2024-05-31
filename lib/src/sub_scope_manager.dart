// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:mocktail/mocktail.dart';
import 'package:supply_chain/supply_chain.dart';

/// Creates or removes sub-scopes depending on components provided by suppliers
class SubScopeManager extends Node<List<ScopeBluePrint>> {
  /// Constructor
  SubScopeManager({
    required super.bluePrint,
    required super.scope,
  }) {
    ownPriority = Priority.structure;
  }

  // ...........................................................................
  @override
  void produce({bool announce = true}) {
    final previousScopes = product;
    super.produce(announce: false);
    final currentScopes = product;

    // Assert currentScopes have different keys
    assert(
      currentScopes.map((s) => s.key).toSet().length == currentScopes.length,
    );

    // .....................
    // Estimate added scopes
    final addedScopes = currentScopes
        .where((s) => !previousScopes.map((e) => e.key).contains(s.key));

    // Estimate removed scopes
    final removedScopes =
        previousScopes.where((p) => !currentScopes.any((c) => c.key == p.key));

    // Estimate changed scopes
    final changedScopes = currentScopes
        .where((c) => previousScopes.any((p) => c.key == p.key && c != p));

    // ......................
    // Dispose removed scopes
    for (final removedScopeBluePrint in removedScopes) {
      final removedScope = scope.child(removedScopeBluePrint.key);
      removedScope?.remove();
    }

    // Add added scopes
    for (final addedScope in addedScopes) {
      scope.addChild(addedScope);
    }

    // Update changed scopes
    for (final changedScope in changedScopes) {
      scope.replaceChild(
        changedScope,
      );
    }

    if (announce) {
      scm.hasNewProduct(this);
    }
  }

  // ...........................................................................
  /// Example instance for test purposes.
  /// See documentation of [SubScopeManagerBluePrint.example]
  factory SubScopeManager.example() {
    // Create a root scope
    final scope = Scope.root(key: 'table', scm: Scm.example());

    // Create a blue print for row heights
    const rowHeightsBluePrint = NodeBluePrint<List<int>>(
      key: 'rowHeights',
      initialProduct: [],
    );

    // Add a node providing row heights for each row
    Node<List<int>>(
      scope: scope,
      bluePrint: rowHeightsBluePrint,
    );

    // Add a sub scope manager creating a row for each row height
    return SubScopeManager(
      bluePrint: SubScopeManagerBluePrint.example(),
      scope: scope,
    );
  }
}

/// Mock for [SubScopeManager]
class MockSubScopeManager extends Mock implements SubScopeManager {}
