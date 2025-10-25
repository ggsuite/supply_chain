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
        final rootScope = Scope.root(key: 'root', scm: Scm.example());
        final scopeBluePrint = ScopeBluePrint.example();
        final scope = scopeBluePrint.instantiate(scope: rootScope);
        final builtNode = scopeBluePrint.nodes[0];
        final dependency = scopeBluePrint.nodes[1];
        final builtScope = scopeBluePrint.children.first;
        final subScope = scopeBluePrint.children.last;
        final node = subScope.nodes.first as NodeBluePrint<int>;
        final nodeInstance = scope.findNode<int>('node')!;
        final customer = subScope.nodes.last as NodeBluePrint<int>;
        final customerNode = scope.findNode<int>('customer')!;
        expect(scopeBluePrint.toString(), scopeBluePrint.key);
        expect(builtNode.key, 'builtNode');
        expect(dependency.key, 'dependency');
        expect(builtScope.key, 'builtScope');
        expect(node.key, 'node');
        expect(customer.key, 'customer');
        expect(node.produce(<dynamic>[5], 0, nodeInstance), 6);
        expect(customer.produce(<dynamic>[6], 0, customerNode), 7);
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
              'c': {'x': 123},
            },
            'c': const ScopeBluePrint(key: 'c'),
            'numInt': 7 as num,
            'numDouble': 7.0 as num,
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
        expectNode(5, 'numInt', 7);
        expectNode(6, 'numDouble', 7.0);

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
              .children
              .first
              .children
              .first
              .nodes
              .first
              .initialProduct,
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
          'a': {'invalid': List<int>.empty()},
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
          'a': {'key': const ScopeBluePrint(key: 'otherKey')},
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
        test(
          'when build() returns a list of scope and node overrides',
          () async {
            // Create a scope blue print
            // which overrides the with key nodeConstructedByChildScope
            const overridenScope = ScopeBluePrint(
              key: 'childScopeConstructedByParent',
              nodes: [
                NodeBluePrint<int>(
                  key: 'nodeConstructedByChildScope',
                  initialProduct: 6,
                ),
              ],
            );

            // Instantiate ExampleScopeBluePrint
            // and override the childScopeConstructedByParent
            final bluePrint = ExampleScopeBluePrint(children: [overridenScope]);

            // Instantiate the scope blue print
            final rootScope = Scope.root(key: 'root', scm: Scm.example());
            final scope = bluePrint.instantiate(scope: rootScope);

            // Check if all nodes were instantiated
            expect(
              scope.findNode<int>('parentScope/nodeBuiltByParent'),
              isNotNull,
            );

            expect(
              scope.findChildScope('childScopeConstructedByParent')!.bluePrint,
              overridenScope,
            );

            expect(
              scope.findNode<int>('parentScope/nodeConstructedByParent'),
              isNotNull,
            );

            // Find nodeBuiltByChildScope
            expect(
              scope.findNode<int>(
                'parentScope/childScopeBuiltByParent/nodeBuiltByChildScope',
              ),
              isNotNull,
            );

            // Find childScopeConstructedByParent
            expect(
              scope.findNode<int>(
                'parentScope/childScopeConstructedByParent/'
                'nodeConstructedByChildScope',
              ),
              isNotNull,
            );

            // Write image
            await scope.writeImageFile(
              'test.graphs.example_scope_blue_print.dot',
            );
          },
        );

        test('and apply nodesFromConstructor when provided', () {
          const replacedBluePrint = NodeBluePrint<int>(
            key: 'nodeBuiltByParent',
            initialProduct: 111,
          );

          final rootScope = Scope.example();
          final scope = ExampleScopeBluePrint(
            nodes: [replacedBluePrint],
          ).instantiate(scope: rootScope);

          expect(
            scope.findNode<int>('parentScope/nodeBuiltByParent')!.bluePrint,
            replacedBluePrint,
          );
        });
      });
      group('should throw if blueprints contain nodes with the same key', () {
        test('when the keys are the same', () {
          const bluePrint = ScopeBluePrint(
            key: 'root',
            nodes: [
              NodeBluePrint<int>(key: 'node', initialProduct: 5),
              NodeBluePrint<int>(key: 'node', initialProduct: 6),
              NodeBluePrint<int>(key: 'node1', initialProduct: 5),
              NodeBluePrint<int>(key: 'node1', initialProduct: 6),
              NodeBluePrint<int>(key: 'node2', initialProduct: 6),
            ],
          );

          final rootScope = Scope.root(key: 'root', scm: Scm.example());
          expect(
            () => bluePrint.instantiate(scope: rootScope),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.toString(),
                'toString()',
                contains('Duplicate keys found: [node, node1]'),
              ),
            ),
          );
        });
      });

      group('should apply connections', () {
        test('and connect direct children to specified suppliers', () {
          // Create a scope providing a width and a height
          final wh0Bp = ScopeBluePrint.fromJson({
            'wh0': {
              'w': 100,
              'h': 200,
              'd': 250, // Not connected
            },
          });

          // Create a second scope also providing a width2 and the height2
          final wh1Bp = ScopeBluePrint.fromJson({
            'wh1': {'w': 300, 'h': 400, 'd': 450},
          });

          // Instantiate the second scope and connect the width2 and height2
          // to the width and height of the first scope.
          final root = Scope.example();
          final wh0 = wh0Bp.instantiate(scope: root);
          final wh1 = wh1Bp.instantiate(
            scope: root,
            connect: {
              'w': 'wh0/w',
              'h': 'wh0/h',
              // 'd': 'wh0/d', // Not connected
            },
          );

          // Changing width and height should change width2 and height2 too
          final scm = root.scm;
          scm.testFlushTasks();
          final wh0Width = wh0.node<num>('w')!;
          final wh0Height = wh0.node<num>('h')!;
          final wh0Depth = wh0.node<num>('d')!;
          final wh1Width = wh1.node<num>('w')!;
          final wh1Height = wh1.node<num>('h')!;
          final wh1Depth = wh1.node<num>('d')!;

          expect(wh0Width.product, 100);
          expect(wh0Height.product, 200);
          expect(wh0Depth.product, 250);
          expect(wh1Width.product, 100);
          expect(wh1Height.product, 200);
          expect(
            wh1Depth.product,
            450,
          ); // Not changed because it is not connected

          // Change the width and height of the first scope
          wh0Width.product = 101;
          wh0Height.product = 201;
          scm.testFlushTasks();

          // Check if the width and height of the second scope changed
          expect(wh1Width.product, 101);
          expect(wh1Height.product, 201);
        });

        test('and connect deep children to specified suppliers', () {
          // Create a scope providing a width and a height
          final wh0Bp = ScopeBluePrint.fromJson({
            'wh0': {
              'child': {
                'w': 100,
                'h': 200,
                'd': 250, // Not connected
              },
            },
          });

          // Create a second scope also providing a width2 and the height2
          final wh1Bp = ScopeBluePrint.fromJson({
            'wh1': {'w': 300, 'h': 400, 'd': 450},
          });

          // Instantiate the second scope and connect the width2 and height2
          // to the width and height of the first scope.
          final root = Scope.example();
          final wh0 = wh0Bp.instantiate(scope: root);
          final wh1 = wh1Bp.instantiate(
            scope: root,
            connect: {
              'w': 'wh0/child/w',
              'h': 'wh0/child/h',
              // 'child/d': 'wh0/child/d', // Not connected
            },
          );

          // Changing width and height should change width2 and height2 too
          final scm = root.scm;
          scm.testFlushTasks();
          final wh0Width = wh0.findNode<num>('child/w')!;
          final wh0Height = wh0.findNode<num>('child/h')!;
          final wh0Depth = wh0.findNode<num>('child/d')!;
          final wh1Width = wh1.findNode<num>('w')!;
          final wh1Height = wh1.findNode<num>('h')!;
          final wh1Depth = wh1.findNode<num>('d')!;

          expect(wh0Width.product, 100);
          expect(wh0Height.product, 200);
          expect(wh0Depth.product, 250);
          expect(wh1Width.product, 100);
          expect(wh1Height.product, 200);
          expect(
            wh1Depth.product,
            450,
          ); // Not changed because it is not connected

          // Change the width and height of the first scope
          wh0Width.product = 101;
          wh0Height.product = 201;
          scm.testFlushTasks();

          // Check if the width and height of the second scope changed
          expect(wh1Width.product, 101);
          expect(wh1Height.product, 201);
        });

        test('and connect a complete scope', () {
          // Create a scope providing a width and a height
          final parentBp = ScopeBluePrint.fromJson({
            'parent': {
              'wh0': {
                'child': {'w': 300, 'h': 400},
              },
            },
          });

          // Create another scope providing a width2 and the height2
          final wh1Bp = ScopeBluePrint.fromJson({
            'wh1': {
              'child': {'w': 700, 'h': 800},
            },
          });

          // Instantiate the second scope and connect the width2 and height2
          // to the width and height of the first scope.
          final root = Scope.example();
          final parent = parentBp.instantiate(scope: root);

          final wh1 = wh1Bp.instantiate(
            scope: root,
            connect: {
              'wh1': 'parent/wh0', // The complete scope is connected
            },
          );
          final wh0 = parent.findChildScope('wh0')!;

          // Changing width and height should change width2 and height2 too
          final scm = root.scm;
          scm.testFlushTasks();
          final wh0Width = wh0.findNode<num>('child/w')!;
          final wh0Height = wh0.findNode<num>('child/h')!;
          final wh1Width = wh1.findNode<num>('child/w')!;
          final wh1Height = wh1.findNode<num>('child/h')!;

          expect(wh0Width.product, 300);
          expect(wh0Height.product, 400);

          expect(wh1Width.product, 300);
          expect(wh1Height.product, 400);

          // Change the width and height of the first scope
          wh0Width.product = 101;
          wh0Height.product = 201;
          scm.testFlushTasks();

          // Check if the width and height of the second scope changed
          expect(wh1Width.product, 101);
          expect(wh1Height.product, 201);
        });

        test('and connect complete child scopes', () {
          // Create a scope providing a width and a height
          final wh0Bp = ScopeBluePrint.fromJson({
            'wh0': {
              'child': {'w': 300, 'h': 400},
            },
          });

          // Create another scope providing a width2 and the height2
          final wh1Bp = ScopeBluePrint.fromJson({
            'wh1': {
              'child': {'w': 700, 'h': 800},
            },
          });

          // Instantiate the second scope and connect the width2 and height2
          // to the width and height of the first scope.
          final root = Scope.example();
          final wh0 = wh0Bp.instantiate(scope: root);

          final wh1 = wh1Bp.instantiate(
            scope: root,
            connect: {'child': 'wh0/child'},
          );

          // Changing width and height should change width2 and height2 too
          final scm = root.scm;
          scm.testFlushTasks();
          final wh0Width = wh0.findNode<num>('child/w')!;
          final wh0Height = wh0.findNode<num>('child/h')!;
          final wh1Width = wh1.findNode<num>('child/w')!;
          final wh1Height = wh1.findNode<num>('child/h')!;

          expect(wh0Width.product, 300);
          expect(wh0Height.product, 400);

          expect(wh1Width.product, 300);
          expect(wh1Height.product, 400);

          // Change the width and height of the first scope
          wh0Width.product = 101;
          wh0Height.product = 201;
          scm.testFlushTasks();

          // Check if the width and height of the second scope changed
          expect(wh1Width.product, 101);
          expect(wh1Height.product, 201);
        });

        test('and connect deeper child nodes to specified suppliers', () {
          // Create a deeper scope providing a width and a height
          final wh0Bp = ScopeBluePrint.fromJson({
            'wh0': {
              'w': 100,
              'h': 200,
              'child': {'w': 300, 'h': 400},
            },
          });

          // Create another deeper scope providing a width2 and the height2
          final wh1Bp = ScopeBluePrint.fromJson({
            'wh1': {
              'w': 500,
              'h': 600,
              'child': {'w': 700, 'h': 800},
            },
          });

          // Instantiate the second scope and connect the width2 and height2
          // to the width and height of the first scope.
          final root = Scope.example();
          final wh0 = wh0Bp.instantiate(scope: root);
          final wh1 = wh1Bp.instantiate(
            scope: root,
            connect: {'child/w': 'wh0/child/w', 'child/h': 'wh0/child/h'},
          );

          // Changing width and height should change width2 and height2 too
          final scm = root.scm;
          scm.testFlushTasks();
          final wh0Width = wh0.findNode<num>('child/w')!;
          final wh0Height = wh0.findNode<num>('child/h')!;
          final wh1Width = wh1.findNode<num>('child/w')!;
          final wh1Height = wh1.findNode<num>('child/h')!;

          expect(wh0Width.product, 300);
          expect(wh0Height.product, 400);

          expect(wh1Width.product, 300);
          expect(wh1Height.product, 400);

          // Change the width and height of the first scope
          wh0Width.product = 101;
          wh0Height.product = 201;
          scm.testFlushTasks();

          // Check if the width and height of the second scope changed
          expect(wh1Width.product, 101);
          expect(wh1Height.product, 201);
        });

        test('and throw if a connection could not be established', () {
          final wh0Bp = ScopeBluePrint.fromJson({
            'wh0': {
              'w': 100,
              'h': 200,
              'child': {'w': 300, 'h': 400},
            },
          });

          expect(
            () =>
                wh0Bp.instantiate(scope: Scope.example(), connect: {'x': 'y'}),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.toString(),
                'toString()',
                contains(
                  'The following connections could not be applied: {x: y}',
                ),
              ),
            ),
          );
        });
      });

      test('should apply builders', () {
        final builder = ScBuilder.example();
        final scope = builder.scope;
        expect(scope.builders.first, builder);

        // See ScBuilder tests for more details
      });

      group('should throw', () {
        test('when a smart scope is instantiated in a smart scope', () {
          final host = Scope.example(smartMaster: ['x', 'y']);
          const smartScope = ScopeBluePrint(
            key: 'smartScope',
            smartMaster: ['x', 'y'],
          );
          expect(
            () => smartScope.instantiate(scope: host),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains(
                  'Smart scopes must not be instantiated in smart scopes.',
                ),
              ),
            ),
          );
        });
      });
    });

    group('saveGraphToFile', () {
      test('should print a simple graph correctly', () async {
        final bluePrint = ScopeBluePrint.example();
        final parentScope = Scope.root(key: 'outer', scm: Scm.example());
        bluePrint.instantiate(scope: parentScope);

        await parentScope.writeImageFile('test/graphs/scope_blue_print.dot');
      });
    });

    group('node(key)', () {
      test('should return null if no key with node is found', () {
        final bluePrint = ScopeBluePrint.example();
        final node = bluePrint.node<int>('Unknown');
        expect(node, isNull);
      });

      test('should return the node with the given key', () {
        final bluePrint = ScopeBluePrint.example().children.last;
        final node = bluePrint.node<int>('node');
        expect(node, isNotNull);
      });

      test('should throw if the type does not match', () {
        final bluePrint = ScopeBluePrint.example().children.last;

        expect(
          () => bluePrint.node<String>('node'),
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

    group('findItem(path), findNode(path), findPath(path)', () {
      final bluePrint = ScopeBluePrint.fromJson({
        'a': {
          'n': 0,
          'b': {
            'c': {'d': 5},
          },
        },
      });
      group('with path containing only one segment', () {
        group('should return null', () {
          test('when no node with the given key is found at all', () {
            var (node, path) = bluePrint.findItem('x');
            expect(node, isNull);
            expect(path, isNull);

            node = bluePrint.findNode<int>('x');
            path = bluePrint.absoluteNodePath('x');
            expect(node, isNull);
            expect(path, isNull);
          });
        });

        group('should return the node', () {
          test('when it exists directly in the root', () {
            var (node, path) = bluePrint.findItem('n');
            expect(node?.key, 'n');
            expect(path, 'a/n');

            node = bluePrint.findNode<num>('n');
            path = bluePrint.absoluteNodePath('n');
            expect(node?.key, 'n');
            expect(path, 'a/n');
          });
          test('when it exists somewhere deeper', () {
            var (node, path) = bluePrint.findItem('d');
            expect(node?.key, 'd');
            expect(path, 'a/b/c/d');

            node = bluePrint.findNode<num>('d');
            path = bluePrint.absoluteNodePath('d');
            expect(node?.key, 'd');
            expect(path, 'a/b/c/d');
          });
        });

        group('should return the scope', () {
          test('when the path segment matches a scope', () {
            var (item, path) = bluePrint.findItem('a');
            expect(item, isNotNull);
            expect(path, 'a');
            expect(item, isA<ScopeBluePrint>());
            expect(item.key, 'a');

            (item, path) = bluePrint.findItem('b');
            expect(path, 'a/b');
            expect(item, isA<ScopeBluePrint>());
            expect(item.key, 'b');

            (item, path) = bluePrint.findItem('c');
            expect(path, 'a/b/c');
            expect(item, isA<ScopeBluePrint>());
            expect(item.key, 'c');
          });
        });

        group('should throw', () {
          test('when multiple nodes with the same path exist', () {
            final bluePrint = ScopeBluePrint.fromJson({
              'a': {
                'k': 0,
                'b': {'n': 1},
                'c': {'n': 1},
              },
            });

            expect(
              () => bluePrint.findItem('n'),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.toString(),
                  'toString()',
                  contains('Multiple nodes with path "n" found.'),
                ),
              ),
            );

            expect(
              () => bluePrint.findNode<num>('n'),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.toString(),
                  'toString()',
                  contains('Multiple nodes with path "n" found.'),
                ),
              ),
            );
          });
        });
      });

      group('with path containing multiple segments', () {
        group('should return null', () {
          test('when no node matches the given path', () {
            var (node, path) = bluePrint.findItem('b/c/x');
            expect(node, isNull);
            expect(path, isNull);

            node = bluePrint.findNode<int>('b/c/x');
            expect(node, isNull);
          });

          test('when a path segment is missed', () {
            var (node, path) = bluePrint.findItem('b/d');
            expect(node, isNull);
            expect(path, isNull);

            node = bluePrint.findNode<int>('b/d');
            expect(node, isNull);
          });
        });
        group('should return the node', () {
          test('when the path matches', () {
            var (node, path) = bluePrint.findItem('b/c/d');
            expect(node, isNotNull);
            expect(path, 'a/b/c/d');

            node = bluePrint.findNode<num>('b/c/d');
            path = bluePrint.absoluteNodePath('b/c/d');
            expect(node, isNotNull);
            expect(path, 'a/b/c/d');
          });

          test('when the path contains the name of the root node', () {
            var (node, path) = bluePrint.findItem('a/b/c/d');
            expect(node, isNotNull);
            expect(path, 'a/b/c/d');

            node = bluePrint.findNode<num>('a/b/c/d');
            path = bluePrint.absoluteNodePath('a/b/c/d');
            expect(node, isNotNull);
            expect(path, 'a/b/c/d');
          });
        });
      });
    });

    group('allNodePathes', () {
      final bluePrint = ScopeBluePrint.fromJson({
        'a': {
          'n': 0,
          'b': {
            'c': {'d': 5},
          },
        },
      });

      group('with appendRootScopeKey == true', () {
        test('should return all node pathes', () {
          final pathes = bluePrint.allNodePathes(appendRootScopeKey: true);
          expect(pathes, ['a/n', 'a/b/c/d']);
        });
      });

      group('with appendRootScopeKey == fale', () {
        test('should return all node pathes without root scope', () {
          final pathes = bluePrint.allNodePathes(appendRootScopeKey: false);
          expect(pathes, ['n', 'b/c/d']);
        });
      });
    });

    group('copyWith', () {
      group('returns the same instance', () {
        test('when no parameter is provided', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith();
          expect(copy, same(bluePrint));
        });

        test('when given parameters are not changes', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(
            key: bluePrint.key,
            modifiedNodes: bluePrint.nodes,
            modifiedScopes: bluePrint.children,
            builders: bluePrint.builders,
            aliases: bluePrint.aliases,
            connections: bluePrint.connections,
            smartMaster: bluePrint.smartMaster,
            canBeSmart: bluePrint.canBeSmart,
          );
          expect(copy, same(bluePrint));
        });

        test('when modifiedNodes and scopes are empty', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(
            modifiedNodes: [],
            modifiedScopes: [],
            connections: {},
          );
          expect(copy, same(bluePrint));
        });
      });

      group('returns a modified instance', () {
        test('with overridden properties', () {
          final bluePrint = ScopeBluePrint.example();
          const node = NodeBluePrint<int>(key: 'node', initialProduct: 5);
          final scope = ScopeBluePrint.example(key: 'scope');
          const builders = [ScBuilderBluePrint(key: 'builder')];
          final aliases = ['alias'];
          final connections = {'a': 'b'};
          final smartMaster = ['a', 'b', 'c'];
          const canBeSmart = false;

          final copy = bluePrint.copyWith(
            key: 'copy',
            modifiedNodes: [node],
            modifiedScopes: [scope],
            builders: builders,
            aliases: aliases,
            connections: connections,
            smartMaster: smartMaster,
            canBeSmart: canBeSmart,
          );

          expect(copy.key, 'copy');
          expect(copy.node<int>('node'), node);
          expect(copy.children.last, scope);
          expect(copy.builders, builders);
          expect(copy.aliases, aliases);
          expect(copy.connections, connections);
          expect(copy.copyWith(canBeSmart: true).smartMaster, smartMaster);
          expect(copy.canBeSmart, canBeSmart);
        });
      });

      group('should return a copy of the ScopeBluePrint', () {
        test('with the given key', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(key: 'copy');
          expect(copy.key, 'copy');
        });

        test('with the given nodes', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(modifiedNodes: []);
          expect(copy.nodes, bluePrint.nodes);
        });

        test('with the given subScopes', () {
          final bluePrint = ScopeBluePrint.example();
          final otherSubScopes = <ScopeBluePrint>[];
          final copy = bluePrint.copyWith(modifiedScopes: otherSubScopes);
          expect(copy.children, bluePrint.children);
        });

        test('with the given overrides', () {
          final bluePrint = ScopeBluePrint.example().children.first;
          const overriddenNode = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 5,
          );
          final copy = bluePrint.copyWith(modifiedNodes: [overriddenNode]);
          expect(copy.node<int>('node'), overriddenNode);
        });

        test('with given smartMaster', () {
          final bluePrint = ScopeBluePrint.example();
          final copy = bluePrint.copyWith(smartMaster: ['a', 'b', 'c']);
          expect(copy.smartMaster, ['a', 'b', 'c']);
        });
      });
    });

    group('aliases', () {
      test('should return the aliases of the scope', () {
        const bluePrint = _ScopeBluePrintWithBuildAliases(
          key: 'test',
          aliases: ['hello'],
        );
        expect(bluePrint.aliases, ['extraAlias', 'hello']);
        expect(bluePrint.buildAliases(), ['extraAlias', 'hello']);
        expect(bluePrint.matchesKey('extraAlias'), isTrue);
        expect(bluePrint.matchesKey('hello'), isTrue);
      });
    });

    group('connections', () {
      test('should return the connections of the scope', () {
        const bluePrint = ScopeBluePrint(key: 'test', connect: {'a': 'b'});
        expect(bluePrint.connections, const {'a': 'b'});
        expect(bluePrint.buildConnections(), const {'a': 'b'});
      });
    });

    group('mergeNodes(original, overrides)', () {
      final a0 = NodeBluePrint.example(key: 'a');
      final a1 = NodeBluePrint.example(key: 'a');
      final b0 = NodeBluePrint.example(key: 'b');
      final b1 = NodeBluePrint.example(key: 'b');
      final c = NodeBluePrint.example(key: 'c');

      final all0 = [a0, b0];
      final all1 = [a1, b1];

      test('should return the original when overrides is null', () {
        expect(
          ScopeBluePrint.mergeNodes(original: all0, overrides: null),
          same(all0),
        );

        expect(
          ScopeBluePrint.mergeNodes(original: all1, overrides: null),
          same(all1),
        );
      });

      test('should return the original, when overrides is empty', () {
        expect(
          ScopeBluePrint.mergeNodes(original: all0, overrides: []),
          same(all0),
        );

        expect(
          ScopeBluePrint.mergeNodes(original: all1, overrides: []),
          same(all1),
        );
      });

      test('should replace the original with the overrides', () {
        final result = ScopeBluePrint.mergeNodes(
          original: all0,
          overrides: all1,
        );
        expect(result, all1);

        final result1 = ScopeBluePrint.mergeNodes(
          original: all0,
          overrides: [b1],
        );
        expect(result1, [a0, b1]);
      });

      test('should add overrides that are not part of the original', () {
        final result = ScopeBluePrint.mergeNodes(
          original: all0,
          overrides: [c],
        );
        expect(result, [a0, b0, c]);
      });
    });

    group('mergeScopes(original, overrides)', () {
      final a0 = ScopeBluePrint.example(key: 'a');
      final a1 = ScopeBluePrint.example(key: 'a');
      final b0 = ScopeBluePrint.example(key: 'b');
      final b1 = ScopeBluePrint.example(key: 'b');
      final c = ScopeBluePrint.example(key: 'c');

      final all0 = [a0, b0];
      final all1 = [a1, b1];

      test('should return the original when overrides is null', () {
        expect(
          ScopeBluePrint.mergeScopes(original: all0, overrides: null),
          same(all0),
        );

        expect(
          ScopeBluePrint.mergeScopes(original: all1, overrides: null),
          same(all1),
        );
      });

      test('should return the original, when overrides is empty', () {
        expect(
          ScopeBluePrint.mergeScopes(original: all0, overrides: []),
          same(all0),
        );

        expect(
          ScopeBluePrint.mergeScopes(original: all1, overrides: []),
          same(all1),
        );
      });

      test('should replace the original with the overrides', () {
        final result = ScopeBluePrint.mergeScopes(
          original: all0,
          overrides: all1,
        );
        expect(result, all1);

        final result1 = ScopeBluePrint.mergeScopes(
          original: all0,
          overrides: [b1],
        );
        expect(result1, [a0, b1]);
      });

      test('should add overrides that are not part of the original', () {
        final result = ScopeBluePrint.mergeScopes(
          original: all0,
          overrides: [c],
        );
        expect(result, [a0, b0, c]);
      });
    });

    group('onInstantiate, onDispose', () {
      test('is called when scope is instantiated and disposed', () {
        Scope? onInstantiateCalled;
        Scope? onDisposeCalled;

        final bluePrint = ScopeBluePrint(
          key: 'test',
          onInstantiate: (scope) {
            onInstantiateCalled = scope;
          },
          onDispose: (scope) {
            onDisposeCalled = scope;
          },
        );

        final rootScope = Scope.root(key: 'root', scm: Scm.example());
        final scope = bluePrint.instantiate(scope: rootScope);
        expect(onInstantiateCalled, scope);

        scope.dispose();
        expect(onDisposeCalled, scope);
      });
    });

    group('isSmartScope', () {
      final bluePrint = ScopeBluePrint.example().copyWith(
        smartMaster: ['a', 'b'],
      );

      group('returns true', () {
        test('if a smartMaster is set', () {
          expect(bluePrint.isSmartScope, isTrue);
          expect(bluePrint.smartMaster, ['a', 'b']);
        });
      });

      group('returns false', () {
        test('if node is not a smart scope', () {
          expect(bluePrint.copyWith(smartMaster: []).isSmartScope, isFalse);
        });

        test('if not is a smart node but canBeSmart is set to false', () {
          expect(bluePrint.copyWith(canBeSmart: false).isSmartScope, isFalse);
        });
      });
    });
  });
}

// #############################################################################
class _ScopeBluePrintWithBuildAliases extends ScopeBluePrint {
  const _ScopeBluePrintWithBuildAliases({required super.key, super.aliases});

  @override
  List<String> buildAliases() {
    return ['extraAlias', ...super.buildAliases()];
  }
}
