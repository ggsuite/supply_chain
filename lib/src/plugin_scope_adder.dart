// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Manages the scopes added by a plugin
class PluginScopeAdder {
  /// The constructor
  PluginScopeAdder({
    required this.plugin,
  }) {
    _init(plugin.scope);
  }

  // ...........................................................................
  /// Removes the added scopes again
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  /// The plugin this class belongs to
  final Plugin plugin;

  /// Returns an example instance for test purposes
  static PluginScopeAdder get example {
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

    final plugin = ExamplePluginAddingScopes().instantiate(scope: scope);
    scope.scm.testFlushTasks();
    return plugin.scopeAdder;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init(Scope scope) {
    // Deeply iterate through all child nodes and replace nodes
    _initScope(scope);

    for (final childScope in scope.children) {
      _init(childScope);
    }
  }

  // ...........................................................................
  void _initScope(Scope scope) {
    final bluePrints = plugin.bluePrint.addScopes(
      hostScope: scope,
    );

    // Make sure the scope does not already exist.
    for (final bluePrint in bluePrints) {
      final childScope = scope.child(bluePrint.key);
      if (childScope != null) {
        throw Exception(
          'Scope with key "${bluePrint.key}" already exists. '
          'Please use "PluginBluePrint:replaceScope" instead.',
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
class ExamplePluginAddingScopes extends PluginBluePrint {
  /// The constructor
  ExamplePluginAddingScopes() : super(key: 'example');

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
