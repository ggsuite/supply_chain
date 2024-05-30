// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'sample_nodes.dart';

enum TestEnum {
  a,
  b,
  c,
}

void main() {
  late Node<int> node;

  int produce(List<dynamic> components, int previousProduct) => previousProduct;

  setUp(() {
    Node.testResetIdCounter();
    Scope.testRestIdCounter();
    scm = Scm.example();
    scope = Scope.example(scm: scm);

    node = scope.findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: produce,
        key: 'node',
      ),
    );
  });

  group('Scope', () {
    group('basic properties', () {
      test('example', () {
        expect(scope, isA<Scope>());
      });

      test('scm', () {
        expect(scope.scm, scm);
      });

      test('key', () {
        expect(scope.key, 'example');
      });

      test('children', () {
        expect(scope.children, isEmpty);
      });

      test('string', () {
        expect(scope.toString(), scope.key);
      });
    });

    group('dispose', () {
      test('should remove the scope from its parent', () {
        // Before dispose the scope belongs to it's parent
        expect(scope.parent!.children, contains(scope));

        // Dispose the scope
        scope.dispose();

        // After dispose the scope is removed from it's parent
        expect(scope.parent!.children, isNot(contains(scope)));
      });

      test('should dispose all nodes', () {
        // Before dispose the scope has nodes.
        // These nodes are part of the scm
        expect(scope.nodes, isNotEmpty);
        for (final node in scope.nodes) {
          expect(scm.nodes, contains(node));
        }

        // Dispose the scope
        scope.dispose();

        // After dispose the scope's nodes are removed
        // from the scope and also the SCM
        expect(scope.nodes, isEmpty);
        for (final node in scope.nodes) {
          expect(scm.nodes, isNot(contains(node)));
        }
      });
    });

    group('path', () {
      test('should return the path of the scope', () {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        final childScopeA = root.child('childScopeA')!;
        final grandChildScope = childScopeA.child('grandChildScope')!;
        expect(root.path, 'exampleRoot');
        expect(childScopeA.path, 'exampleRoot.childScopeA');
        expect(grandChildScope.path, 'exampleRoot.childScopeA.grandChildScope');
      });
    });

    group('node(key)', () {
      test('should return the node with the given key', () {
        expect(scope.node<int>(key: 'node'), node);
      });

      test('should return null if the node does not exist', () {
        expect(scope.node<int>(key: 'unknown'), isNull);
      });

      test('should throw if the type does not match', () {
        expect(
          () => scope.node<String>(key: 'node'),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Node with key "node" is not of type String',
                  ),
            ),
          ),
        );
      });
    });

    group('findScope(path)', () {
      group('should return the scope with the given path', () {
        test('when the path has the name of the scope', () {
          final scope = Scope.example();
          expect(scope.findScope('example'), scope);
        });
        test('when the path has the name of a child node', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'c': 0,
              },
            },
          });
          expect(scope.findScope('a')?.key, 'a');
          expect(scope.findScope('b')?.key, 'b');
          expect(scope.findScope('c')?.key, null);
        });
        test('when the path contains multiple path segments', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'c': {
                  'd': 0,
                },
              },
            },
          });
          expect(scope.findScope('a.b')?.key, 'b');
          expect(scope.findScope('a.b.c')?.key, 'c');
          expect(scope.findScope('a.b.c.d'), isNull);
        });
      });
      group('should return null', () {
        test('if the scope does not exist', () {
          final root = ExampleScopeRoot(scm: Scm.testInstance);
          expect(root.findScope('unknown'), isNull);
        });
        test('if the key is empty', () {
          final root = ExampleScopeRoot(scm: Scm.testInstance);
          expect(root.findScope(''), isNull);
        });
      });

      test('should throw if multiple scopes with the path exist', () {
        final scope = Scope.example();
        scope.mockContent(
          {
            'a': {
              'duplicate': {
                'c': 0,
                'duplicate': {
                  'd': 0,
                },
              },
            },
          },
        );
      });
    });

    group('findOrCreateNode()', () {
      test('should return an existing node when possible', () {
        expect(
          scope.findOrCreateNode(
            NodeBluePrint(
              initialProduct: 0,
              produce: produce,
              key: 'node',
            ),
          ),
          node,
        );
      });

      group('should throw', () {
        group('when existing node exists', () {
          test('but have a different produce method', () {
            expect(
              () => scope.findOrCreateNode<int>(
                NodeBluePrint(
                  initialProduct: 0,
                  produce: (components, previousProduct) => 0,
                  key: 'node',
                ),
              ),
              throwsA(
                predicate<AssertionError>(
                  (e) => e.toString().contains(
                        'Node with key "example" already exists '
                        'with different configuration',
                      ),
                ),
              ),
            );
          });

          test('but has a different type', () {
            expect(
              () => scope.findOrCreateNode<String>(
                NodeBluePrint(
                  initialProduct: 'hello',
                  produce: (components, previousProduct) => 'world',
                  key: 'node',
                ),
              ),
              throwsA(
                predicate<AssertionError>(
                  (e) => e.toString().contains(
                        'Node with key "example" already exists '
                        'with different configuration',
                      ),
                ),
              ),
            );
          });
        });
      });
    });

    group('findOrCreateNodes', () {
      test('should return a list of nodes', () {
        final bluePrint = ScopeBluePrint.example().childScopes.first;
        final nodes = scope.findOrCreateNodes(bluePrint.nodes);
        expect(nodes, hasLength(2));
        expect(nodes[0].key, 'node');
        expect(nodes[1].key, 'customer');
      });
    });
    group('addNode()', () {
      test('should create a node and set the scope and SCM correctly', () {
        expect(node.scope, scope);
        expect(node.scm, scope.scm);
      });

      test('should throw if a node with the same key already exists', () {
        expect(
          () => scope.addNode(
            Node<int>(
              bluePrint: NodeBluePrint<int>(
                initialProduct: 0,
                produce: (components, previousProduct) => previousProduct,
                key: 'node',
              ),
              scope: scope,
            ),
          ),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains('already exists'),
            ),
          ),
        );
      });

      test('should add the node to the chain\'s nodes', () {
        expect(scope.nodes, [node]);
      });
    });

    group('replaceNode()', () {
      test('should replace the node with the given key', () {
        final newNode = NodeBluePrint<int>(
          initialProduct: 0,
          produce: (components, previousProduct) => previousProduct,
          key: 'node',
        );

        scope.replaceNode(newNode);
        expect(scope.node<int>(key: 'node')?.bluePrint, newNode);
      });

      test('should throw if the node does not exist', () {
        final newNode = NodeBluePrint<int>(
          initialProduct: 0,
          produce: (components, previousProduct) => previousProduct,
          key: 'unknown',
        );

        expect(
          () => scope.replaceNode(newNode),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Node with key "unknown" does not exist in scope "example"',
                  ),
            ),
          ),
        );
      });
    });
    group('removeNode()', () {
      test('should remove the node with the given key', () {
        expect(scope.node<int>(key: 'node'), isNotNull);
        scope.removeNode('node');
        expect(scope.node<int>(key: 'node'), isNull);
      });

      test('should do nothing if node does not exist', () {
        expect(
          () => scope.removeNode('Unknown'),
          returnsNormally,
        );
      });
    });
    group('node.dispose(), removeNode()', () {
      test('should remove the node from the chain', () {
        expect(scope.nodes, isNotEmpty);
        node.dispose();
        expect(scope.nodes, isEmpty);
      });
    });

    group('initSuppliers()', () {
      test('should allow to create a hierarchy of scopes', () {
        final scm = Scm.testInstance;
        final root = ExampleScopeRoot(scm: scm);
        expect(root.nodes.map((n) => n.key), ['rootA', 'rootB']);
        for (var element in root.nodes) {
          scm.nominate(element);
        }
        expect(root.children.map((e) => e.key), ['childScopeA', 'childScopeB']);
        expect(root.path, 'exampleRoot');

        final childA = root.child('childScopeA')!;
        final childB = root.child('childScopeB')!;
        expect(childA.nodes.map((n) => n.key), ['childNodeA', 'childNodeB']);
        expect(childB.nodes.map((n) => n.key), ['childNodeA', 'childNodeB']);

        expect(childA.path, 'exampleRoot.childScopeA');
        expect(childB.path, 'exampleRoot.childScopeB');

        for (var element in childA.nodes) {
          scm.nominate(element);
        }

        for (var element in childB.nodes) {
          scm.nominate(element);
        }

        final grandChild = childA.child('grandChildScope')!;
        for (final element in grandChild.nodes) {
          scm.nominate(element);
        }
        expect(grandChild.path, 'exampleRoot.childScopeA.grandChildScope');
        expect(
          grandChild.nodes.first.path,
          'exampleRoot.childScopeA.grandChildScope.grandChildNodeA',
        );

        scm.tick();
        scm.testFlushTasks();
      });
    });

    group('graph, saveGraphToFile', () {
      // .......................................................................
      Future<void> updateGraphFile(Scope chain, String fileName) async {
        final cwd = Directory.current.path;
        final graphFile = '$cwd/test/graphs/$fileName';

        // Save dot file
        await chain.saveGraphToFile(graphFile);

        // Save webp file
        final svgFile = graphFile.replaceAll('.dot', '.svg');
        await chain.saveGraphToFile(svgFile);
      }

      // .......................................................................
      test('should print a simple graph correctly', () async {
        initSupplierProducerCustomer();
        createSimpleChain();
        await updateGraphFile(scope, 'simple_graph.dot');
      });

      test('should print a more advanced graph correctly', () async {
        initMusicExampleNodes();

        // .................................
        // Create the following supply chain
        //  key
        //   |-synth
        //   |  |-audio (realtime)
        //   |
        //   |-screen
        //   |  |-grid
        key.addCustomer(synth);
        key.addCustomer(screen);
        synth.addCustomer(audio);
        screen.addCustomer(grid);
        await updateGraphFile(scope, 'advanced_graph.dot');
      });

      test('should print scopes correctly', () async {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        root.initSuppliers();
        await updateGraphFile(root, 'graphs_with_scopes.dot');
      });
    });

    group('findNode(key)', () {
      group('without scope in key', () {
        group('returns', () {
          group('the right node', () {
            late final ExampleScopeRoot rootScope;

            setUpAll(() {
              rootScope = ExampleScopeRoot(scm: Scm.testInstance);
            });

            test('when the node is contained in own scope', () {
              // Find a node directly contained in chain
              final rootA = rootScope.findNode<int>('rootA');
              expect(rootA?.key, 'rootA');

              final rootB = rootScope.findNode<int>('rootB');
              expect(rootB?.key, 'rootB');

              // Child nodes should find their own nodes
              final childScopeA = rootScope.child('childScopeA')!;
              final childNodeAFromChild =
                  childScopeA.findNode<int>('childNodeA');
              expect(childNodeAFromChild?.key, 'childNodeA');
            });

            test('when the node is contained in parent chain', () {
              // Should return nodes from parent chain
              final childScopeA = rootScope.child('childScopeA')!;
              final rootAFromChild = childScopeA.findNode<int>('rootA');
              expect(rootAFromChild?.key, 'rootA');
            });

            test('when the node is contained in sibling chain', () {
              // Create a new chain
              final root = Scope.example();

              // Create two child scopes
              Scope(key: 'childScopeA', parent: root);
              final b = Scope(key: 'childScopeB', parent: root);

              // Add a NodeA to ChildScopeA
              final nodeA = root.child('childScopeA')!.findOrCreateNode<int>(
                    NodeBluePrint(
                      key: 'nodeA',
                      initialProduct: 0,
                      produce: (components, previous) => previous,
                    ),
                  );

              // ChildScopeB should find the node in ChildScopeA
              final Node<int>? foundNodeA = b.findNode<int>('nodeA');
              expect(foundNodeA, nodeA);
            });

            test('when the node is contained somewhere else', () {
              final root = ExampleScopeRoot(scm: Scm.testInstance);

              // Create a node somewhere deep in the hierarchy
              final grandChildScope =
                  root.child('childScopeA')!.child('grandChildScope')!;

              final grandChildNodeX = Node<int>(
                bluePrint: NodeBluePrint<int>(
                  key: 'grandChildNodeX',
                  initialProduct: 0,
                  produce: (components, previousProduct) => 0,
                ),
                scope: grandChildScope,
              );

              // Search the node from the root
              final foundGRandChildNodeX =
                  root.findNode<int>('grandChildNodeX');
              expect(foundGRandChildNodeX, grandChildNodeX);
            });
          });

          group('null', () {
            group('when node cannot be found', () {
              test('and throwIfNotFound is false or not defined', () {
                final unknownNode = scope.findNode<int>(
                  'Unknown',
                  throwIfNotFound: false,
                );
                expect(unknownNode, isNull);

                final unknownNode1 = scope.findNode<int>('Unknown');
                expect(unknownNode1, isNull);
              });
            });
          });
        });
      });

      group('with scope in key', () {
        group('return', () {
          group('the right node', () {
            test('when the node is contained in own scope', () {
              final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
              final childScopeA = rootScope.child('childScopeA')!;
              final grandChildScope = childScopeA.child('grandChildScope')!;
              final grandChildNodeAExpected = grandChildScope.findNode<int>(
                'grandChildNodeA',
              );

              final grandChildNodeReal = grandChildScope.findNode<int>(
                'childScopeA.grandChildScope.grandChildNodeA',
              );
              expect(grandChildNodeReal, grandChildNodeAExpected);
            });

            test('when the node is contained in parent scope', () {
              final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
              final childScopeA = rootScope.child('childScopeA')!;
              final grandChildScope = childScopeA.child('grandChildScope')!;
              final childNodeAExpected = childScopeA.findNode<int>(
                'childNodeA',
              );

              final childNodeAReal = grandChildScope.findNode<int>(
                'childScopeA.childNodeA',
              );
              expect(childNodeAReal, childNodeAExpected);
            });

            test('when the node is contained in sibling scope', () {
              final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
              final childScopeA = rootScope.child('childScopeA')!;
              final grandChildScope = childScopeA.child('grandChildScope')!;
              final grandChildNodeBExpected = grandChildScope.findNode<int>(
                'grandChildNodeB',
              );

              final grandChildNodeReal = grandChildScope.findNode<int>(
                'childScopeA/grandChildScope/grandChildNodeB',
              );
              expect(grandChildNodeReal, grandChildNodeBExpected);
            });
          });
        });
      });

      group('throws', () {
        test('if the type does not match', () {
          final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
          expect(
            () => rootScope.findNode<String>('rootA'),
            throwsA(
              predicate<ArgumentError>(
                (e) => e
                    .toString()
                    .contains('Node with key "rootA" is not of type String'),
              ),
            ),
          );
        });

        test('if throwIfNotFound is true and node is not found', () {
          final supplyScope = Scope.example();
          expect(
            () => supplyScope.findNode<int>('unknown', throwIfNotFound: true),
            throwsA(
              predicate<ArgumentError>(
                (e) =>
                    e.toString().contains('Node with key "unknown" not found'),
              ),
            ),
          );
        });

        test('if multiple nodes of the same key and type are found', () {
          final supplyScope = ExampleScopeRoot(scm: Scm.testInstance);
          expect(
            () => supplyScope.findNode<int>('grandChildNodeA'),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.toString().contains(
                      'More than one node with key "grandChildNodeA" and '
                      'Type<int> found.',
                    ),
              ),
            ),
          );
        });
      });
    });

    group('hasNode(key)', () {
      test('should return true if the scope has a node with the given key', () {
        final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
        expect(rootScope.hasNode('rootA'), isTrue);
        expect(rootScope.hasNode('rootB'), isTrue);
        expect(rootScope.hasNode('Unknown'), isFalse);

        final childScope = rootScope.child('childScopeA')!;
        expect(childScope.hasNode('childNodeA'), isTrue);
        expect(childScope.hasNode('childNodeB'), isTrue);
        expect(childScope.hasNode('Unknown'), isFalse);
        expect(childScope.hasNode('rootA'), isTrue);
      });
    });

    group('initSuppliers()', () {
      test(
        'should find and add the suppliers added on createNode(....)',
        () {
          final scm = Scm.testInstance;
          final rootScope = ExampleScopeRoot(scm: scm);
          rootScope.initSuppliers();

          // The root node has no suppliers
          final rootA = rootScope.findNode<int>('rootA');
          final rootB = rootScope.findNode<int>('rootB');
          expect(rootA?.suppliers, isEmpty);
          expect(rootB?.suppliers, isEmpty);

          /// The child node a should have the root nodes as suppliers
          final childScopeA = rootScope.child('childScopeA')!;
          final childNodeA = childScopeA.findNode<int>('childNodeA');
          final childNodeB = childScopeA.findNode<int>('childNodeB');
          expect(childNodeA?.suppliers, hasLength(3));
          expect(childNodeA?.suppliers, contains(rootA));
          expect(childNodeA?.suppliers, contains(rootB));
          expect(childNodeA?.suppliers, contains(childNodeB));
        },
      );

      test('should throw if a supplier is not found', () {
        final scm = Scm.testInstance;
        final scope = Scope.example(scm: scm);

        scope.findOrCreateNode<int>(
          NodeBluePrint(
            key: 'node',
            suppliers: ['unknown'],
            initialProduct: 0,
            produce: (components, previous) => previous,
          ),
        );

        expect(
          () => scope.initSuppliers(),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Scope "example": Supplier with key "unknown" not found.',
                  ),
            ),
          ),
        );
      });

      group('isAncestorOf(node)', () {
        test('should return true if the scope is an ancestor', () {
          final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
          final childScopeA = rootScope.child('childScopeA')!;
          final childScopeB = rootScope.child('childScopeB')!;
          final grandChildScope = childScopeA.child('grandChildScope')!;
          expect(rootScope.isAncestorOf(childScopeA), isTrue);
          expect(rootScope.isAncestorOf(childScopeB), isTrue);
          expect(childScopeA.isAncestorOf(childScopeB), isFalse);
          expect(childScopeB.isAncestorOf(childScopeA), isFalse);
          expect(rootScope.isAncestorOf(grandChildScope), isTrue);
        });
      });

      group('isDescendantOf(node)', () {
        test('should return true if the scope is a descendant', () {
          final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
          final childScopeA = rootScope.child('childScopeA')!;
          final childScopeB = rootScope.child('childScopeB')!;
          final grandChildScope = childScopeA.child('grandChildScope')!;
          expect(childScopeA.isDescendantOf(rootScope), isTrue);
          expect(childScopeB.isDescendantOf(rootScope), isTrue);
          expect(childScopeA.isDescendantOf(childScopeB), isFalse);
          expect(childScopeB.isDescendantOf(childScopeA), isFalse);
          expect(grandChildScope.isDescendantOf(rootScope), isTrue);
        });
      });
    });

    group('mockContent', () {
      test('should create a mock content', () {
        final scope = Scope.example();
        scope.mockContent({
          'a': {
            'int': 5,
            'b': {
              'int': 10,
              'double': 3.14,
              'string': 'hello',
              'bool': true,
              'enum': const NodeBluePrint<TestEnum>(
                key: 'enum',
                initialProduct: TestEnum.a,
              ),
            },
          },
        });

        expect(scope.findNode<int>('a.int')?.product, 5);
        expect(scope.findNode<int>('a.b.int')?.product, 10);
        expect(scope.findNode<double>('a.b.double')?.product, 3.14);
        expect(scope.findNode<bool>('a.b.bool')?.product, true);
        expect(scope.findNode<TestEnum>('a.b.enum')?.product, TestEnum.a);
      });

      test('should throw if an unsupported type is mocked', () {
        final scope = Scope.example();
        expect(
          () => scope.mockContent({
            'a': {
              'unsupported': TestEnum.a,
            },
          }),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Type TestEnum not supported. '
                    'Use NodeBluePrint<TestEnum> instead.',
                  ),
            ),
          ),
        );
      });
    });
  });
}
