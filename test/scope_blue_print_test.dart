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
        final subScope = scopeBluePrint.children.first;
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

    group('fromJson', () {
      test('should create a scope blue print from a JSON map', () {
        final json = {
          'a': {
            'int': 5,
            'double': 6.0,
            'string': 'Hello',
            'bool': true,
            'bluePrint': const NodeBluePrint<int>(
              key: 'bluePrint',
              initialProduct: 8,
            ),
            'b': {
              'c': {
                'x': 123,
              },
            },
            'c': const ScopeBluePrint(key: 'c'),
          },
        };

        final scopeBluePrint = ScopeBluePrint.fromJson(json);
        expect(scopeBluePrint.key, 'a');

        void expectNode(int i, String key, dynamic value) {
          expect(scopeBluePrint.nodes[i].key, key);
          expect(scopeBluePrint.nodes[i].initialProduct, value);
        }

        expectNode(0, 'int', 5);
        expectNode(1, 'double', 6.0);
        expectNode(2, 'string', 'Hello');
        expectNode(3, 'bool', true);
        expectNode(4, 'bluePrint', 8);

        expect(scopeBluePrint.children.length, 2);
        expect(scopeBluePrint.children.first.key, 'b');
        expect(scopeBluePrint.children.first.children.length, 1);
        expect(scopeBluePrint.children.first.children.first.key, 'c');
        expect(scopeBluePrint.children.last.key, 'c');

        expect(
          scopeBluePrint.children.first.children.first.nodes.first.key,
          'x',
        );

        expect(
          scopeBluePrint
              .children.first.children.first.nodes.first.initialProduct,
          123,
        );
      });

      test('should assert that the key of a node and JSON are equal', () {
        final json = {
          'a': {
            'int': const NodeBluePrint<int>(key: 'otherKey', initialProduct: 5),
          },
        };

        expect(
          () => ScopeBluePrint.fromJson(json),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.toString(),
              'toString()',
              contains('The key of the node "otherKey" must be "int".'),
            ),
          ),
        );
      });

      test('should throw when in invalid type is provided', () {
        final json = {
          'a': {
            'invalid': List<int>.empty(),
          },
        };

        expect(
          () => ScopeBluePrint.fromJson(json),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'toString()',
              contains(
                'List<int>> not supported. '
                'Use NodeBluePrint<_Map<String, List<int>>> instead.',
              ),
            ),
          ),
        );
      });

      test('should assert that the key of a scope and JSON are equal', () {
        final json = {
          'a': {
            'key': const ScopeBluePrint(key: 'otherKey'),
          },
        };

        expect(
          () => ScopeBluePrint.fromJson(json),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.toString(),
              'toString()',
              contains('The key of the node "otherKey" must be "key".'),
            ),
          ),
        );
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
              .writeImageFile('test.graphs.example_scope_blue_print.dot');
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

        await parentScope.writeImageFile('test/graphs/scope_blue_print.dot');
      });
    });

    group('findNode(key)', () {
      test('should return null if no key with node is found', () {
        final bluePrint = ScopeBluePrint.example();
        final node = bluePrint.findNode<int>('Unknown');
        expect(node, isNull);
      });

      test('should return the node with the given key', () {
        final bluePrint = ScopeBluePrint.example().children.first;
        final node = bluePrint.findNode<int>('node');
        expect(node, isNotNull);
      });

      test('should throw if the type does not match', () {
        final bluePrint = ScopeBluePrint.example().children.first;

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
          expect(copy.children, same(otherSubScopes));
        });

        test('with the given overrides', () {
          final bluePrint = ScopeBluePrint.example().children.first;
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
