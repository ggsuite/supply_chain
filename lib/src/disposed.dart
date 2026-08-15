// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the disposal of resources.
class Disposed {
  /// Constructor
  Disposed({required this.scm});

  // ...........................................................................
  /// The related supply chain manager
  final Scm scm;

  // ...........................................................................
  /// Disposed scopes
  Iterable<Scope> get scopes => _scopes;

  /// Disposed nodes
  Iterable<Node<dynamic>> get nodes => _nodes;

  // ...........................................................................
  /// Called by a node when it is disposed.
  void addNode(Node<dynamic> node) {
    assert(node.isDisposed);
    _nodes.add(node);
  }

  // ...........................................................................
  /// Called by a node when it is erased.
  void removeNode(Node<dynamic> node) => _nodes.remove(node);

  // ...........................................................................
  /// Called by a scope when it is disposed.
  void addScope(Scope scope) {
    assert(scope.isDisposed);
    _scopes.add(scope);
  }

  /// Called by a scope when it is erased or undisposed.
  void removeScope(Scope scope) => _scopes.remove(scope);

  // ...........................................................................
  /// Returns an example instance of this class.
  static Disposed get example => Scm.example().disposedItems;

  // ######################
  // Private
  // ######################

  // Sets (insertion-ordered) instead of lists: removeNode/removeScope are
  // called once per erased item; with lists each removal is a linear scan.
  final Set<Scope> _scopes = {};

  final Set<Node<dynamic>> _nodes = {};
}
