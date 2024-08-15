// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

// #############################################################################
/// An example node adder for test purposes
class _AddExistingNodeScBuilder extends ScBuilderBluePrint {
  /// The constructor
  _AddExistingNodeScBuilder() : super(key: 'addExistingNodeScBuilder');

  @override
  List<NodeBluePrint<dynamic>> addNodes({
    required Scope hostScope,
  }) {
    // Try to add the already existing node "existing" to the host scope
    // Will throw.
    return const [
      NodeBluePrint<int>(
        key: 'existing',
        initialProduct: 12,
      ),
    ];
  }
}

// ###########################################################################
void main() {
  group('ScBuilderNodeAdder', () {
    group('instantiate, dispose()', () {
      test('should add and remove the added nodes', () {
        // Create the node adder
        final builderNodeAdder = ScBuilderNodeAdder.example;

        // Get the scope
        final scope = builderNodeAdder.builder.scope;
        expect(scope.key, 'example');

        // Did ExampleScBuilderAddingNodes add k and j to the example scope?
        final k = scope.node<int>('k');
        expect(k, isNotNull);
        expect(k!.product, 12);

        final j = scope.node<int>('j');
        expect(j, isNotNull);
        expect(j!.product, 367);

        // Did ExampleScBuilderAddingNodes add x and y to scope c?
        final scopeC = scope.findScope('c')!;
        final x = scopeC.node<int>('x');
        expect(x, isNotNull);
        expect(x!.product, 966);

        final y = scopeC.node<int>('y');
        expect(y, isNotNull);
        expect(y!.product, 767);

        // Dispose the builder -> Added nodes should be removed again
        builderNodeAdder.dispose();
        expect(scope.node<int>('k'), isNull);
        expect(scope.node<int>('j'), isNull);
        expect(scopeC.node<int>('x'), isNull);
        expect(scopeC.node<int>('y'), isNull);

        // Added nodes should also be disposed
        expect(k.isDisposed, isTrue);
        expect(j.isDisposed, isTrue);
        expect(x.isDisposed, isTrue);
        expect(y.isDisposed, isTrue);
      });

      group('should throw', () {
        test('when the builder adds a node already existing', () {
          // Create an example scope containing one node
          final scope = Scope.example();
          expect(scope.nodes, hasLength(0));

          // Add a node "existing" to the scope
          scope.findOrCreateNode<int>(
            const NodeBluePrint<int>(key: 'existing', initialProduct: 12),
          );

          // Create a builder trying to add the already existing node
          // "existing". Should throw.
          expect(
            () => _AddExistingNodeScBuilder().instantiate(scope: scope),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'toString',
                contains(
                  'Node with key "existing" already exists. '
                  'Please use "ScBuilderBluePrint:replaceNode" instead.',
                ),
              ),
            ),
          );
        });
      });
    });
  });
}
