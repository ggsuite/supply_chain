// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the scopes added by a customizer
class CustomizerScopeAdder {
  /// The constructor
  CustomizerScopeAdder({
    required this.customizer,
  }) {
    init(customizer.scope);
  }

  // ...........................................................................
  /// Removes the added scopes again
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  /// The customizer this class belongs to
  final Customizer customizer;

  /// Returns an example instance for test purposes
  static CustomizerScopeAdder get example {
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

    final customizer =
        ExampleCustomizerAddingScopes().instantiate(scope: scope);
    scope.scm.testFlushTasks();
    return customizer.scopeAdder;
  }

  // ...........................................................................
  /// Deeply iterate through all child nodes and replace nodes
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
    final bluePrints = customizer.bluePrint.addScopes(
      hostScope: scope,
    );

    // Make sure the scope does not already exist.
    for (final bluePrint in bluePrints) {
      final childScope = scope.child(bluePrint.key);
      if (childScope != null) {
        throw Exception(
          'Scope with key "${bluePrint.key}" already exists. '
          'Please use "CustomizerBluePrint:replaceScope" instead.',
        );
      }
    }

    // Add the child scopes to the host scope
    final addedScopes = scope.addChildren(bluePrints);

    // On dispose, we will also dispose all added scopes
    _dispose.add(() {
      for (final addedScope in addedScopes) {
        addedScope.dispose();
      }
    });
  }

  // ######################
  // Private
  // ######################

  final List<void Function()> _dispose = [];
}

// #############################################################################
/// An example node adder for test purposes
class ExampleCustomizerAddingScopes extends CustomizerBluePrint {
  /// The constructor
  ExampleCustomizerAddingScopes() : super(key: 'example');

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
