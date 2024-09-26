// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

// #############################################################################
/// An example node adder for test purposes
class _AddExistingScopeScBuilder extends ScBuilderBluePrint {
  /// The constructor
  _AddExistingScopeScBuilder() : super(key: 'addExistingScopeScBuilder');

  @override
  bool shouldStopProcessingAfter(Scope scope) {
    return false;
  }

  @override
  List<ScopeBluePrint> addScopes({
    required Scope hostScope,
  }) {
    // Try to add the already existing scope "existing" to the host scope
    // Will throw.
    if (hostScope.matchesKey('example')) {
      return const [
        ScopeBluePrint(
          key: 'existing',
        ),
      ];
    }

    return super.addScopes(hostScope: hostScope);
  }
}

// #############################################################################
class _AddScopesToEveryScopeBuilder extends ScBuilderBluePrint {
  /// The constructor
  _AddScopesToEveryScopeBuilder() : super(key: 'addScopesToEveryScopeBuilder');

  @override
  bool shouldStopProcessingAfter(Scope scope) {
    return false;
  }

  @override
  List<ScopeBluePrint> addScopes({
    required Scope hostScope,
  }) {
    // Try to add the already existing node "existing" to the host scope
    // Will throw.

    return const [
      ScopeBluePrint(
        key: 'someNode',
      ),
    ];
  }
}

// ###########################################################################
void main() {
  group('ScBuilderScopeAdder', () {
    group('instantiate, dispose()', () {
      test('should add and remove the added nodes', () {
        // Create the scope adder builder
        final builderNodeAdder = ScBuilderScopeAdder.example;
        expect(builderNodeAdder.managedScopes, hasLength(4));

        // Get the scope
        final scope = builderNodeAdder.builder.scope;
        expect(scope.key, 'example');

        // Did ExampleScBuilderAddingScopes add scope k and j to the
        // example scope?
        final k = scope.child('k')!;
        final kv = k.node<int>('kv')!;
        expect(kv.product, 767);

        final j = scope.child('j')!;
        final jv = j.node<int>('jv')!;
        expect(jv.product, 171);

        // Did ExampleScBuilderAddingScopes add scope x and y to scope c?
        final scopeC = scope.findChildScope('c')!;
        final x = scopeC.child('x')!;
        final xv = x.node<int>('xv')!;
        expect(xv.product, 530);

        final y = scopeC.child('y')!;
        final yv = y.node<int>('yv')!;
        expect(yv.product, 543);

        // Try to apply the builder to one of the scopes created by the builder.
        // This should have no effect
        final scopeCreatedByBuilder = builderNodeAdder.managedScopes.first;
        builderNodeAdder.applyToScope(scopeCreatedByBuilder);
        expect(builderNodeAdder.managedScopes, hasLength(4));

        // Dispose one of the scopes created by the builder.
        // The builder should be informed and remove the scope from the
        // managed scopes.
        scopeCreatedByBuilder.dispose();
        expect(builderNodeAdder.managedScopes, hasLength(3));

        // Dispose the builder -> Added scopes and their nodes should
        // be removed again
        builderNodeAdder.dispose();
        expect(scope.child('k'), isNull);
        expect(scope.child('j'), isNull);
        expect(scopeC.child('x'), isNull);
        expect(scopeC.child('y'), isNull);

        // Managed scopes should be empty
        expect(builderNodeAdder.managedScopes, isEmpty);

        // Added scopes should also be disposed
        expect(k.isDisposed, isTrue);
        expect(j.isDisposed, isTrue);
        expect(x.isDisposed, isTrue);
        expect(y.isDisposed, isTrue);

        // Also the nodes of the added scopes should be disposed
        expect(xv.isDisposed, isTrue);
        expect(yv.isDisposed, isTrue);
      });

      group('should throw', () {
        test('when the builder adds a scope already existing', () {
          // Create an example scope containing one node
          final scope = Scope.example();
          expect(scope.nodes, hasLength(0));

          // Add a node "existing" to the scope
          scope.findOrCreateChild('existing');

          // Create a builder trying to add the existing scope "existing".
          // Should throw.
          expect(
            () => _AddExistingScopeScBuilder().instantiate(scope: scope),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'toString',
                contains(
                  'Scope with key "existing" already exists. '
                  'Please use "ScBuilderBluePrint:replaceScope" instead.',
                ),
              ),
            ),
          );
        });

        test('when addScopes() adds scopes to all scopes', () {
          // Create an example scope containing one node
          final scope = Scope.example();
          expect(scope.nodes, hasLength(0));

          // Create a builder trying to add the scope "someNode" to all scopes.
          // Should throw.
          expect(
            () => _AddScopesToEveryScopeBuilder().instantiate(scope: scope),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'toString',
                contains(
                  'ScScopeBluePrint.addScopes(hostScope) must evaluate '
                  'the hostScope and not add scopes to all scopes',
                ),
              ),
            ),
          );
        });
      });
    });
  });
}
