// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Maps a host node address to a node blueprint describing the insert
typedef InsertMap = Map<String, NodeBluePrint<dynamic>>;

/// A scope insert defines a list of node inserts that modify a scope.
class ScopeInserts {
  /// Constructor
  const ScopeInserts({
    required this.key,
    this.overrides = const {},
  });

  /// Returns the node inserts
  final InsertMap overrides;

  /// The key of the insert
  final String key;

  // ...........................................................................
  /// Disposes the insert and removes it from the scope
  void dispose({required Scope scope}) {
    if (!scope.inserts.contains(this)) {
      throw ArgumentError('Insert "$key" not found.');
    }

    // Get the insert scope
    final insertScope = scope.child(key)!;
    insertScope.dispose();

    scope.scopeInsertRemove(this);
  }

  // ...........................................................................
  /// Instantiates the insert in the scope
  void instantiate({required Scope scope}) {
    if (scope.inserts.contains(this)) {
      throw ArgumentError('Insert already added.');
    }

    final (hostNodes, nodeInserts) = _hostNodes(scope);

    // Create a scope for the insert
    final insertScopeBluePrint = ScopeBluePrint(key: key);
    final insertScope = scope.addChild(insertScopeBluePrint);

    // Add the inserts to each node
    for (var i = 0; i < hostNodes.length; i++) {
      final hostNode = hostNodes[i];
      final insertBluePrint = nodeInserts[i];
      insertBluePrint.instantiateAsInsert(
        host: hostNode,
        scope: insertScope,
      );
    }

    // Add the scope insert to the list of scope inserts
    scope.scopeInsertAdd(this);
  }

  // ...........................................................................
  /// Override this method in derived subclasses to build the insert map
  InsertMap build() {
    return overrides;
  }

  // ...........................................................................
  (List<Node<dynamic>> hostNodes, List<NodeBluePrint<dynamic>> inserts)
      _hostNodes(
    Scope scope,
  ) {
    // Make sure all inserts have uinique keys
    final foundKeys = <String>{};

    final inserts = {...build()};

    for (final item in overrides.entries) {
      inserts[item.key] = item.value;
    }

    for (final nodeInsert in inserts.values) {
      if (foundKeys.contains(nodeInsert.key)) {
        throw ArgumentError(
          'Found multiple node inserts with key "${nodeInsert.key}":\n',
        );
      }
      foundKeys.add(nodeInsert.key);
    }

    // Find host nodes
    final hostAddresses = inserts.keys;
    final hostNodes = <Node<dynamic>>[];
    final nodeInserts = inserts.values.toList();
    final invalidAddresses = <String>[];
    for (final address in hostAddresses) {
      final node = scope.findNode<dynamic>(address);
      if (node != null) {
        hostNodes.add(node);
      } else {
        invalidAddresses.add(address);
      }
    }

    // Throw if not all host nodes are found
    if (invalidAddresses.isNotEmpty) {
      throw ArgumentError(
        'Host nodes not found: ${invalidAddresses.join(', ')}',
      );
    }

    return (hostNodes, nodeInserts);
  }

  // ...........................................................................
  /// Example innstance
  factory ScopeInserts.example({
    String key = 'scopeInsert',
  }) =>
      ScopeInserts(
        key: key,
        overrides: {
          'node0': const NodeBluePrint<int>(
            key: 'insert0',
            initialProduct: 238,
          ),
        },
      );
}

// .............................................................................
/// An example insert class
class ExampleScopeInsert extends ScopeInserts {
  /// Constructor
  const ExampleScopeInsert({
    super.key = 'exampleScopeInsert',
    super.overrides,
  });

  @override
  InsertMap build() {
    return {
      'node0': const NodeBluePrint<int>(key: 'insert0', initialProduct: 822),
    };
  }
}
