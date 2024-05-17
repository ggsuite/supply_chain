// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'sample_nodes.dart';

void main() {
  late Node<int> node;

  int produce(List<dynamic> components, int previousProduct) => previousProduct;

  setUp(() {
    Node.testRestIdCounter();
    Scope.testRestIdCounter();
    scm = Scm.example();
    scope = Scope.example(scm: scm);

    node = scope.findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: produce,
        key: 'Node',
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
        expect(scope.key, 'Example');
      });

      test('children', () {
        expect(scope.children, isEmpty);
      });
    });

    group('findOrCreateNode()', () {
      test('should return an existing node when possible', () {
        expect(
          scope.findOrCreateNode(
            NodeBluePrint(
              initialProduct: 0,
              produce: produce,
              key: 'Node',
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
                  key: 'Node',
                ),
              ),
              throwsA(
                predicate<AssertionError>(
                  (e) => e.toString().contains(
                        'Node with key "Example" already exists '
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
                  key: 'Node',
                ),
              ),
              throwsA(
                predicate<AssertionError>(
                  (e) => e.toString().contains(
                        'Node with key "Example" already exists '
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
        final bluePrint = ScopeBluePrint.example();
        final nodes = scope.findOrCreateNodes(bluePrint.nodes);
        expect(nodes, hasLength(2));
        expect(nodes[0].key, 'Node');
        expect(nodes[1].key, 'Customer');
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
                key: 'Node',
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

    group('node.dispose(), removeNode()', () {
      test('should remove the node from the chain', () {
        expect(scope.nodes, isNotEmpty);
        node.dispose();
        expect(scope.nodes, isEmpty);
      });
    });

    group('createHierarchy()', () {
      test('should allow to create a hierarchy of chains', () {
        final scm = Scm.testInstance;
        final root = ExampleScopeRoot(scm: scm);
        expect(root.nodes.map((n) => n.key), ['RootA', 'RootB']);
        for (var element in root.nodes) {
          scm.nominate(element);
        }
        expect(root.children.map((e) => e.key), ['ChildScopeA', 'ChildScopeB']);

        final childA = root.child('ChildScopeA')!;
        final childB = root.child('ChildScopeB')!;
        expect(childA.nodes.map((n) => n.key), ['ChildNodeA', 'ChildNodeB']);
        expect(childB.nodes.map((n) => n.key), ['ChildNodeA', 'ChildNodeB']);

        for (var element in childA.nodes) {
          scm.nominate(element);
        }

        for (var element in childB.nodes) {
          scm.nominate(element);
        }

        final grandChild = childA.child('GrandChildScope')!;
        for (final element in grandChild.nodes) {
          scm.nominate(element);
        }
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

      test('should print chains correctly', () async {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        root.initSuppliers();
        await updateGraphFile(root, 'graphs_with_scopes.dot');
      });
    });

    group('findNode(key)', () {
      group('returns', () {
        group('the right node', () {
          late final ExampleScopeRoot rootScope;

          setUpAll(() {
            rootScope = ExampleScopeRoot(scm: Scm.testInstance);
          });

          test('when the node is contained in own chain', () {
            // Find a node directly contained in chain
            final rootA = rootScope.findNode<int>('RootA');
            expect(rootA?.key, 'RootA');

            final rootB = rootScope.findNode<int>('RootB');
            expect(rootB?.key, 'RootB');

            // Child nodes should find their own nodes
            final childScopeA = rootScope.child('ChildScopeA')!;
            final childNodeAFromChild = childScopeA.findNode<int>('ChildNodeA');
            expect(childNodeAFromChild?.key, 'ChildNodeA');
          });

          test('when the node is contained in parent chain', () {
            // Should return nodes from parent chain
            final childScopeA = rootScope.child('ChildScopeA')!;
            final rootAFromChild = childScopeA.findNode<int>('RootA');
            expect(rootAFromChild?.key, 'RootA');
          });

          test('when the node is contained in sibling chain', () {
            // Create a new chain
            final root = Scope.example();

            // Create two child chains
            Scope(key: 'ChildScopeA', parent: root);
            final b = Scope(key: 'ChildScopeB', parent: root);

            // Add a NodeA to ChildScopeA
            final nodeA = root.child('ChildScopeA')!.findOrCreateNode<int>(
                  NodeBluePrint(
                    key: 'NodeA',
                    initialProduct: 0,
                    produce: (components, previous) => previous,
                  ),
                );

            // ChildScopeB should find the node in ChildScopeA
            final Node<int>? foundNodeA = b.findNode<int>('NodeA');
            expect(foundNodeA, nodeA);
          });

          test('when the node is contained somewhere else', () {
            final root = ExampleScopeRoot(scm: Scm.testInstance);

            // Create a node somewhere deep in the hierarchy
            final grandChildScope =
                root.child('ChildScopeA')!.child('GrandChildScope')!;

            final grandChildNodeX = Node<int>(
              bluePrint: NodeBluePrint<int>(
                key: 'GrandChildNodeX',
                initialProduct: 0,
                produce: (components, previousProduct) => 0,
              ),
              scope: grandChildScope,
            );

            // Search the node from the root
            final foundGRandChildNodeX = root.findNode<int>('GrandChildNodeX');
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

      group('throws', () {
        test('if the type does not match', () {
          final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
          expect(
            () => rootScope.findNode<String>('RootA'),
            throwsA(
              predicate<ArgumentError>(
                (e) => e
                    .toString()
                    .contains('Node with key "RootA" is not of type String'),
              ),
            ),
          );
        });

        test('if throwIfNotFound is true and node is not found', () {
          final supplyScope = Scope.example();
          expect(
            () => supplyScope.findNode<int>('Unknown', throwIfNotFound: true),
            throwsA(
              predicate<ArgumentError>(
                (e) =>
                    e.toString().contains('Node with key "Unknown" not found'),
              ),
            ),
          );
        });

        test('if multiple nodes of the same key and type are found', () {
          final supplyScope = ExampleScopeRoot(scm: Scm.testInstance);
          expect(
            () => supplyScope.findNode<int>('GrandChildNodeA'),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.toString().contains(
                      'More than one node with key "GrandChildNodeA" and '
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
        expect(rootScope.hasNode('RootA'), isTrue);
        expect(rootScope.hasNode('RootB'), isTrue);
        expect(rootScope.hasNode('Unknown'), isFalse);

        final childScope = rootScope.child('ChildScopeA')!;
        expect(childScope.hasNode('ChildNodeA'), isTrue);
        expect(childScope.hasNode('ChildNodeB'), isTrue);
        expect(childScope.hasNode('Unknown'), isFalse);
        expect(childScope.hasNode('RootA'), isTrue);
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
          final rootA = rootScope.findNode<int>('RootA');
          final rootB = rootScope.findNode<int>('RootB');
          expect(rootA?.suppliers, isEmpty);
          expect(rootB?.suppliers, isEmpty);

          /// The child node a should have the root nodes as suppliers
          final childScopeA = rootScope.child('ChildScopeA')!;
          final childNodeA = childScopeA.findNode<int>('ChildNodeA');
          final childNodeB = childScopeA.findNode<int>('ChildNodeB');
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
            key: 'Node',
            suppliers: ['Unknown'],
            initialProduct: 0,
            produce: (components, previous) => previous,
          ),
        );

        expect(
          () => scope.initSuppliers(),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Scope "Example": Supplier with key "Unknown" not found.',
                  ),
            ),
          ),
        );
      });

      group('isAncestorOf(node)', () {
        test('should return true if the scope is an ancestor', () {
          final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
          final childScopeA = rootScope.child('ChildScopeA')!;
          final childScopeB = rootScope.child('ChildScopeB')!;
          final grandChildScope = childScopeA.child('GrandChildScope')!;
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
          final childScopeA = rootScope.child('ChildScopeA')!;
          final childScopeB = rootScope.child('ChildScopeB')!;
          final grandChildScope = childScopeA.child('GrandChildScope')!;
          expect(childScopeA.isDescendantOf(rootScope), isTrue);
          expect(childScopeB.isDescendantOf(rootScope), isTrue);
          expect(childScopeA.isDescendantOf(childScopeB), isFalse);
          expect(childScopeB.isDescendantOf(childScopeA), isFalse);
          expect(grandChildScope.isDescendantOf(rootScope), isTrue);
        });
      });
    });
  });
}
