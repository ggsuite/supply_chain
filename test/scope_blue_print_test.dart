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
        expect(dependency.key, 'dependency');
        expect(node0.key, 'node');
        expect(node1.key, 'customer');
        expect(node0.produce(<dynamic>[5], 0), 6);
        expect(node1.produce(<dynamic>[6], 0), 7);
      });
    });

    group('instantiate(scope)', () {
      group('should instantiate the scope', () {
        group('with fake dependencies', () {
          test('when fakeMissingDependencies == false', () {
            final bluePrint = ScopeBluePrint.example();
            final parentScope = Scope.root(key: 'root', scm: Scm.example());
            expect(
              () => bluePrint.instantiate(parentScope: parentScope),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.toString(),
                  'toString()',
                  contains(
                    'Scope "example": Supplier with key "dependency" not '
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
            final parentScope = Scope.root(key: 'root', scm: Scm.example());
            final scope = bluePrint.instantiate(
              parentScope: parentScope,
              fakeMissingDependencies: true,
            );
            final node = scope.findNode<int>('dependency');
            expect(node, isNotNull);
          });
        });

        group('without creating an inner scope', () {
          test('when createOwnScope is false', () {
            final bluePrint = ScopeBluePrint.example();
            final parentScope = Scope.root(key: 'root', scm: Scm.example());
            bluePrint.instantiate(
              parentScope: parentScope,
              createOwnScope: false,
              fakeMissingDependencies: true,
            );
            final node = parentScope.findNode<int>('node');
            expect(node, isNotNull);
          });
        });
      });

      group('should instantiate scopes and nodes returned in build()', () {
        test('when build() returns a list of scopes and nodes', () async {
          final bluePrint = ExampleScopeBluePrint();
          final rootScope = Scope.root(key: 'root', scm: Scm.example());
          final scope = bluePrint.instantiate(parentScope: rootScope);

          // Check if all nodes were instantiated
          expect(
            scope.findNode<int>('parentScope/nodeBuiltByParent'),
            isNotNull,
          );

          expect(
            scope.findNode<int>('parentScope/nodeConstructedByParent'),
            isNotNull,
          );

          expect(
            scope.findNode<int>(
              'parentScope/childScopeBuiltByParent/nodeBuiltByChildScope',
            ),
            isNotNull,
          );

          expect(
            scope.findNode<int>(
              'parentScope/childScopeConstructedByParent/nodeConstructedByChildScope',
            ),
            isNotNull,
          );

          await scope
              .saveGraphToFile('test/graphs/example_scope_blue_print.svg');
        });
      });
    });

    group('saveGraphToFile', () {
      test('should print a simple graph correctly', () async {
        final bluePrint = ScopeBluePrint.example();
        final parentScope = Scope.root(key: 'outer', scm: Scm.example());
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
        final node = bluePrint.findNode<int>('node');
        expect(node, isNotNull);
      });

      test('should throw if the type does not match', () {
        final bluePrint = ScopeBluePrint.example();

        expect(
          () => bluePrint.findNode<String>('node'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'toString()',
              contains('Node with key "node" is not of type String.'),
            ),
          ),
        );
      });
    });

    group('copyWith', () {
      group('should return a copy of the ScopeBluePrint', () {
        test('with the given key', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(key: 'copy');
          expect(copy.key, 'copy');
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
            key: 'node',
            initialProduct: 5,
          );
          final copy = bluePrint.copyWith(overrides: [overriddenNode]);
          expect(copy.findNode<int>('node'), overriddenNode);
        });
      });
    });
  });
}
