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
  List<ScopeBluePrint> addScopes({
    required Scope hostScope,
  }) {
    // Try to add the already existing scope "existing" to the host scope
    // Will throw.
    return const [
      ScopeBluePrint(
        key: 'existing',
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

        // Dispose the builder -> Added scopes and their nodes should
        // be removed again
        builderNodeAdder.dispose();
        expect(scope.child('k'), isNull);
        expect(scope.child('j'), isNull);
        expect(scopeC.child('x'), isNull);
        expect(scopeC.child('y'), isNull);

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
      });
    });
  });
}
