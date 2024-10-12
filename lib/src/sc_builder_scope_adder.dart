// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the scopes added by a builder
class ScBuilderScopeAdder {
  /// The constructor
  ScBuilderScopeAdder({
    required this.builder,
  }) {
    _check();
    _initOwner();
  }

  // ...........................................................................
  /// Removes the added scopes again
  void dispose() {
    for (final scope in [...managedScopes]) {
      scope.dispose();
    }
  }

  /// The builder this class belongs to
  final ScBuilder builder;

  /// Returns an example instance for test purposes
  static ScBuilderScopeAdder get example {
    final scope = Scope.example();

    scope.mockContent({
      'a': 1,
      'b': 2,
      'c': {
        'd': 4,
        'e': 5,
        'f': 'f',
      },
    });

    final builder = ExampleScBuilderAddingScopes().instantiate(scope: scope);
    scope.scm.testFlushTasks();
    return builder.scopeAdder;
  }

  // ...........................................................................
  /// Deeply iterate through all child nodes and replace nodes
  void applyToScope(Scope scope) {
    // We will not apply this builder to scopes created by this builder
    if (scope.owner == _owner) {
      return;
    }

    _applyToScope(scope);

    if (!builder.bluePrint.shouldProcessChildren(scope)) {
      return;
    }

    for (final childScope in scope.children) {
      applyToScope(childScope);
    }
  }

  /// Returns the added scopes
  List<Scope> managedScopes = [];

  // ######################
  // Private
  // ######################

  // ...........................................................................
  late final Owner<Scope> _owner;

  // ...........................................................................
  void _initOwner() {
    _owner = Owner<Scope>(
      willErase: (p0) => managedScopes.remove(p0),
    );
  }

  // ...........................................................................
  void _check() {
    final scopes = builder.bluePrint.addScopes(hostScope: ScBuilder.testScope);
    if (scopes.isNotEmpty) {
      throw Exception('ScScopeBluePrint.addScopes(hostScope) '
          'must evaluate the hostScope and not add scopes to all scopes.');
    }
  }

  // ...........................................................................
  void _applyToScope(Scope scope) {
    if (!builder.bluePrint.shouldProcessScope(scope)) return;

    // Add the scopes to the host scope
    final bluePrints = builder.bluePrint.addScopes(
      hostScope: scope,
    );

    // Make sure the scope does not already exist.
    for (final bluePrint in bluePrints) {
      final childScope = scope.child(bluePrint.key);
      if (childScope != null) {
        throw Exception(
          'Scope with key "${bluePrint.key}" already exists. '
          'Please use "ScBuilderBluePrint:replaceScope" instead.',
        );
      }
    }

    // Add the child scopes to the host scope
    final addedScopes = scope.addChildren(
      bluePrints,
      owner: _owner,
    );

    // Remember created scopes
    managedScopes.addAll(addedScopes);
  }

  // ######################
  // Private
  // ######################
}

// #############################################################################
/// An example node adder for test purposes
class ExampleScBuilderAddingScopes extends ScBuilderBluePrint {
  /// The constructor
  ExampleScBuilderAddingScopes() : super(key: 'example');

  @override
  bool shouldProcessChildren(Scope scope) {
    return true;
  }

  @override
  bool shouldProcessScope(Scope scope) {
    return true;
  }

  @override
  List<ScopeBluePrint> addScopes({
    required Scope hostScope,
  }) {
    // Add k,j to example scope
    if (hostScope.key == 'example') {
      return [
        ScopeBluePrint.fromJson({
          'k': {'kv': 767},
        }),
        ScopeBluePrint.fromJson({
          'j': {'jv': 171},
        }),
      ];
    }
    // Add x,y to c scope
    if (hostScope.key == 'c') {
      return [
        ScopeBluePrint.fromJson({
          'x': {'xv': 530},
        }),
        ScopeBluePrint.fromJson({
          'y': {'yv': 543},
        }),
      ];
    } else {
      return []; // coverage:ignore-line
    }
  }
}
