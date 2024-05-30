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
        final dependency = scopeBluePrint.nodes.first;
        final subScope = scopeBluePrint.childScopes.first;
        final node = subScope.nodes.first as NodeBluePrint<int>;
        final customer = subScope.nodes.last as NodeBluePrint<int>;
        expect(scopeBluePrint.toString(), scopeBluePrint.key);
        expect(dependency.key, 'dependency');
        expect(node.key, 'node');
        expect(customer.key, 'customer');
        expect(node.produce(<dynamic>[5], 0), 6);
        expect(customer.produce(<dynamic>[6], 0), 7);
      });
    });

    group('instantiate(scope)', () {
      group('should instantiate scopes and nodes returned in build()', () {
        test('when build() returns a list of scopes and nodes', () async {
          final bluePrint = ExampleScopeBluePrint();
          final rootScope = Scope.root(key: 'root', scm: Scm.example());
          final scope = bluePrint.instantiate(scope: rootScope);

          // Check if all nodes were instantiated
          expect(
            scope.findNode<int>('parentScope.nodeBuiltByParent'),
            isNotNull,
          );

          expect(
            scope.findNode<int>('parentScope.nodeConstructedByParent'),
            isNotNull,
          );

          expect(
            scope.findNode<int>(
              'parentScope.childScopeBuiltByParent.nodeBuiltByChildScope',
            ),
            isNotNull,
          );

          expect(
            scope.findNode<int>(
              'parentScope.childScopeConstructedByParent.'
              'nodeConstructedByChildScope',
            ),
            isNotNull,
          );

          await scope
              .saveGraphToFile('test.graphs.example_scope_blue_print.svg');
        });
      });
    });

    group('saveGraphToFile', () {
      test('should print a simple graph correctly', () async {
        final bluePrint = ScopeBluePrint.example();
        final parentScope = Scope.root(key: 'outer', scm: Scm.example());
        bluePrint.instantiate(
          scope: parentScope,
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
        final bluePrint = ScopeBluePrint.example().childScopes.first;
        final node = bluePrint.findNode<int>('node');
        expect(node, isNotNull);
      });

      test('should throw if the type does not match', () {
        final bluePrint = ScopeBluePrint.example().childScopes.first;

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

        test('with the given subScopes', () {
          final bluePrint = ScopeBluePrint.example();
          final otherSubScopes = <ScopeBluePrint>[];
          final copy = bluePrint.copyWith(subScopes: otherSubScopes);
          expect(copy.childScopes, same(otherSubScopes));
        });

        test('with the given overrides', () {
          final bluePrint = ScopeBluePrint.example().childScopes.first;
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
