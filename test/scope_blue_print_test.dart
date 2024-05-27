// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('ScopeBluePrint', () {
    group('example', () {
      test('should provide a blue print with to nodes and one dependency', () {
        final scopeBluePrint = ScopeBluePrint.example();
        final [node0 as NodeBluePrint<int>, node1 as NodeBluePrint<int>] =
            scopeBluePrint.nodes;
        final [dependency as NodeBluePrint<int>] = scopeBluePrint.dependencies;
        expect(scopeBluePrint.toString(), scopeBluePrint.key);
        expect(dependency.key, 'Dependency');
        expect(node0.key, 'Node');
        expect(node1.key, 'Customer');
        expect(node0.produce(<dynamic>[5], 0), 6);
        expect(node1.produce(<dynamic>[6], 0), 7);
      });
    });

    group('instantiate(scope)', () {
      group('should instantiate the scope', () {
        group('with fake dependencies', () {
          test('when fakeMissingDependencies == false', () {
            final bluePrint = ScopeBluePrint.example();
            final parentScope = Scope.root(key: 'Root', scm: Scm.example());
            expect(
              () => bluePrint.instantiate(parentScope: parentScope),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.toString(),
                  'toString()',
                  contains(
                    'Scope "Example": Supplier with key "Dependency" not '
                    'found.',
                  ),
                ),
              ),
            );
          });
        });

        group('without fake dependencies', () {
          test('when fakeMissingDependencies == true', () {
            final bluePrint = ScopeBluePrint.example();
            final parentScope = Scope.root(key: 'Root', scm: Scm.example());
            final scope = bluePrint.instantiate(
              parentScope: parentScope,
              fakeMissingDependencies: true,
            );
            final node = scope.findNode<int>('Dependency');
            expect(node, isNotNull);
          });
        });

        group('without creating an inner scope', () {
          test('when createOwnScope is false', () {
            final bluePrint = ScopeBluePrint.example();
            final parentScope = Scope.root(key: 'Root', scm: Scm.example());
            bluePrint.instantiate(
              parentScope: parentScope,
              createOwnScope: false,
              fakeMissingDependencies: true,
            );
            final node = parentScope.findNode<int>('Node');
            expect(node, isNotNull);
          });
        });
      });
    });

    group('saveGraphToFile', () {
      test('should print a simple graph correctly', () async {
        final bluePrint = ScopeBluePrint.example();
        final parentScope = Scope.root(key: 'Outer', scm: Scm.example());
        bluePrint.instantiate(
          parentScope: parentScope,
          fakeMissingDependencies: true,
        );
        parentScope.initSuppliers();

        await parentScope.saveGraphToFile('test/graphs/scope_blue_print.svg');
      });
    });

    group('findNode(key)', () {
      test('should return null if no key with node is found', () {
        final bluePrint = ScopeBluePrint.example();
        final node = bluePrint.findNode<int>('Unknown');
        expect(node, isNull);
      });

      test('should return the node with the given key', () {
        final bluePrint = ScopeBluePrint.example();
        final node = bluePrint.findNode<int>('Node');
        expect(node, isNotNull);
      });

      test('should throw if the type does not match', () {
        final bluePrint = ScopeBluePrint.example();

        expect(
          () => bluePrint.findNode<String>('Node'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'toString()',
              contains('Node with key "Node" is not of type String.'),
            ),
          ),
        );
      });
    });

    group('copyWith', () {
      group('should return a copy of the ScopeBluePrint', () {
        test('with the given key', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(key: 'Copy');
          expect(copy.key, 'Copy');
        });

        test('with the given nodes', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(nodes: []);
          expect(copy.nodes, isEmpty);
        });

        test('with the given dependencies', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(dependencies: []);
          expect(copy.dependencies, isEmpty);
        });

        test('with the given overrides', () {
          final bluePrint = ScopeBluePrint.example();
          const overriddenNode = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 5,
          );
          final copy = bluePrint.copyWith(overrides: [overriddenNode]);
          expect(copy.findNode<int>('Node'), overriddenNode);
        });
      });
    });
  });
}
