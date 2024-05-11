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
    SupplyChain.testRestIdCounter();
    chain = SupplyChain.example();

    node = chain.findOrCreateNode(
      NodeConfig(
        initialProduct: 0,
        produce: produce,
        key: 'Node',
      ),
    );
  });

  group('Chain', () {
    group('basic properties', () {
      test('example', () {
        expect(chain, isA<SupplyChain>());
      });

      test('scm', () {
        expect(chain.scm, Scm.testInstance);
      });

      test('key', () {
        expect(chain.key, 'Example');
      });

      test('children', () {
        expect(chain.children, isEmpty);
      });
    });

    group('findOrCreateNode()', () {
      test('should return an existing node when possible', () {
        expect(
          chain.findOrCreateNode(
            NodeConfig(
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
              () => chain.findOrCreateNode<int>(
                NodeConfig(
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
              () => chain.findOrCreateNode<String>(
                NodeConfig(
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

    group('findOrCreatedNodes(nodeConfigs)', () {
      test('should return a list of nodes', () {
        final nodeConfigs = [
          NodeConfig(
            initialProduct: 0,
            produce: produce,
            key: 'Node1',
          ),
          NodeConfig(
            initialProduct: 0,
            produce: produce,
            key: 'Node2',
          ),
          NodeConfig(
            initialProduct: 0,
            produce: produce,
            key: 'Node2',
          ),
        ];

        final nodes = chain.findOrCreateNodes(nodeConfigs);
        expect(nodes, hasLength(3));
        expect(nodes[0].key, 'Node1');
        expect(nodes[1].key, 'Node2');
        expect(nodes[2], nodes[1]);
      });
    });
    group('addNode()', () {
      test('should create a node and set the chain and SCM correctly', () {
        expect(node.chain, chain);
        expect(node.scm, chain.scm);
      });

      test('should throw if a node with the same key already exists', () {
        expect(
          () => chain.addNode(
            Node<int>(
              nodeConfig: NodeConfig<int>(
                initialProduct: 0,
                produce: (components, previousProduct) => previousProduct,
                key: 'Node',
              ),
              chain: chain,
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
        expect(chain.nodes, [node]);
      });
    });

    group('node.dispose(), removeNode()', () {
      test('should remove the node from the chain', () {
        expect(chain.nodes, isNotEmpty);
        node.dispose();
        expect(chain.nodes, isEmpty);
      });
    });

    group('createHierarchy()', () {
      test('should allow to create a hierarchy of chains', () {
        final scm = Scm.testInstance;
        final root = ExampleChainRoot(scm: scm);
        expect(root.nodes.map((n) => n.key), ['RootA', 'RootB']);
        for (var element in root.nodes) {
          scm.nominate(element);
        }
        expect(root.children.map((e) => e.key), ['ChildChainA', 'ChildChainB']);

        final childA = root.child('ChildChainA')!;
        final childB = root.child('ChildChainB')!;
        expect(childA.nodes.map((n) => n.key), ['ChildNodeA', 'ChildNodeB']);
        expect(childB.nodes.map((n) => n.key), ['ChildNodeA', 'ChildNodeB']);

        for (var element in childA.nodes) {
          scm.nominate(element);
        }

        for (var element in childB.nodes) {
          scm.nominate(element);
        }

        final grandChild = childA.child('GrandChildChain')!;
        for (final element in grandChild.nodes) {
          scm.nominate(element);
        }
        scm.tick();
        scm.testFlushTasks();
      });
    });

    group('graph', () {
      // .......................................................................
      void shouldMatchFile(SupplyChain chain, String fileName) {
        final cwd = Directory.current.path;
        final graphFile = File('$cwd/test/graphs/$fileName');
        final graphFileContent = (graphFile.readAsStringSync());
        expect(chain.equalsGraph(graphFileContent), isTrue);
      }

      // .......................................................................
      test('should print a simple graph correctly', () {
        initSupplierProducerCustomer();
        createSimpleChain();
        shouldMatchFile(chain, 'simple_graph.dot');
      });

      test('should print a more advanced graph correctly', () {
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
        shouldMatchFile(chain, 'advanced_graph.dot');
      });

      test('should print chains correctly', () {
        final root = ExampleChainRoot(scm: Scm.testInstance);
        root.initSuppliers();
        shouldMatchFile(root, 'graphs_with_chains.dot');
      });
    });

    group('findNode(key)', () {
      group('returns', () {
        group('the right node', () {
          late final ExampleChainRoot rootChain;

          setUpAll(() {
            rootChain = ExampleChainRoot(scm: Scm.testInstance);
          });

          test('when the node is contained in own chain', () {
            // Find a node directly contained in chain
            final rootA = rootChain.findNode<int>('RootA');
            expect(rootA?.key, 'RootA');

            final rootB = rootChain.findNode<int>('RootB');
            expect(rootB?.key, 'RootB');

            // Child nodes should find their own nodes
            final childChainA = rootChain.child('ChildChainA')!;
            final childNodeAFromChild = childChainA.findNode<int>('ChildNodeA');
            expect(childNodeAFromChild?.key, 'ChildNodeA');
          });

          test('when the node is contained in parent chain', () {
            // Should return nodes from parent chain
            final childChainA = rootChain.child('ChildChainA')!;
            final rootAFromChild = childChainA.findNode<int>('RootA');
            expect(rootAFromChild?.key, 'RootA');
          });

          test('when the node is contained in sibling chain', () {
            // Create a new chain
            final root = SupplyChain.example();

            // Create two child chains
            SupplyChain(key: 'ChildChainA', parent: root);
            final b = SupplyChain(key: 'ChildChainB', parent: root);

            // Add a NodeA to ChildChainA
            final nodeA = root.child('ChildChainA')!.findOrCreateNode<int>(
                  NodeConfig(
                    key: 'NodeA',
                    initialProduct: 0,
                    produce: (components, previous) => previous,
                  ),
                );

            // ChildChainB should find the node in ChildChainA
            final Node<int>? foundNodeA = b.findNode<int>('NodeA');
            expect(foundNodeA, nodeA);
          });

          test('when the node is contained somewhere else', () {
            final root = ExampleChainRoot(scm: Scm.testInstance);

            // Create a node somewhere deep in the hierarchy
            final grandChildChain =
                root.child('ChildChainA')!.child('GrandChildChain')!;

            final grandChildNodeX = Node<int>(
              nodeConfig: NodeConfig<int>(
                key: 'GrandChildNodeX',
                initialProduct: 0,
                produce: (components, previousProduct) => 0,
              ),
              chain: grandChildChain,
            );

            // Search the node from the root
            final foundGRandChildNodeX = root.findNode<int>('GrandChildNodeX');
            expect(foundGRandChildNodeX, grandChildNodeX);
          });
        });

        group('null', () {
          group('when node cannot be found', () {
            test('and throwIfNotFound is false or not defined', () {
              final unknownNode = chain.findNode<int>(
                'Unknown',
                throwIfNotFound: false,
              );
              expect(unknownNode, isNull);

              final unknownNode1 = chain.findNode<int>('Unknown');
              expect(unknownNode1, isNull);
            });
          });
        });
      });

      group('throws', () {
        test('if the type does not match', () {
          final rootChain = ExampleChainRoot(scm: Scm.testInstance);
          expect(
            () => rootChain.findNode<String>('RootA'),
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
          final supplyChain = SupplyChain.example();
          expect(
            () => supplyChain.findNode<int>('Unknown', throwIfNotFound: true),
            throwsA(
              predicate<ArgumentError>(
                (e) =>
                    e.toString().contains('Node with key "Unknown" not found'),
              ),
            ),
          );
        });

        test('if multiple nodes of the same key and type are found', () {
          final supplyChain = ExampleChainRoot(scm: Scm.testInstance);
          expect(
            () => supplyChain.findNode<int>('GrandChildNodeA'),
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
      test('should return true if the chain has a node with the given key', () {
        final rootChain = ExampleChainRoot(scm: Scm.testInstance);
        expect(rootChain.hasNode('RootA'), isTrue);
        expect(rootChain.hasNode('RootB'), isTrue);
        expect(rootChain.hasNode('Unknown'), isFalse);

        final childChain = rootChain.child('ChildChainA')!;
        expect(childChain.hasNode('ChildNodeA'), isTrue);
        expect(childChain.hasNode('ChildNodeB'), isTrue);
        expect(childChain.hasNode('Unknown'), isFalse);
        expect(childChain.hasNode('RootA'), isTrue);
      });
    });

    group('initSuppliers()', () {
      test(
        'should find and add the suppliers added on createNode(....)',
        () {
          final scm = Scm.testInstance;
          final rootChain = ExampleChainRoot(scm: scm);
          rootChain.initSuppliers();

          // The root node has no suppliers
          final rootA = rootChain.findNode<int>('RootA');
          final rootB = rootChain.findNode<int>('RootB');
          expect(rootA?.suppliers, isEmpty);
          expect(rootB?.suppliers, isEmpty);

          /// The child node a should have the root nodes as suppliers
          final childChainA = rootChain.child('ChildChainA')!;
          final childNodeA = childChainA.findNode<int>('ChildNodeA');
          final childNodeB = childChainA.findNode<int>('ChildNodeB');
          expect(childNodeA?.suppliers, hasLength(3));
          expect(childNodeA?.suppliers, contains(rootA));
          expect(childNodeA?.suppliers, contains(rootB));
          expect(childNodeA?.suppliers, contains(childNodeB));
        },
      );

      test('should throw if a supplier is not found', () {
        final scm = Scm.testInstance;
        final chain = SupplyChain.example(scm: scm);

        chain.findOrCreateNode<int>(
          NodeConfig(
            key: 'Node',
            suppliers: ['Unknown'],
            initialProduct: 0,
            produce: (components, previous) => previous,
          ),
        );

        expect(
          () => chain.initSuppliers(),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Chain "Example": Supplier with key "Unknown" not found.',
                  ),
            ),
          ),
        );
      });

      group('isAncestorOf(node)', () {
        test('should return true if the chain is an ancestor', () {
          final rootChain = ExampleChainRoot(scm: Scm.testInstance);
          final childChainA = rootChain.child('ChildChainA')!;
          final childChainB = rootChain.child('ChildChainB')!;
          final grandChildChain = childChainA.child('GrandChildChain')!;
          expect(rootChain.isAncestorOf(childChainA), isTrue);
          expect(rootChain.isAncestorOf(childChainB), isTrue);
          expect(childChainA.isAncestorOf(childChainB), isFalse);
          expect(childChainB.isAncestorOf(childChainA), isFalse);
          expect(rootChain.isAncestorOf(grandChildChain), isTrue);
        });
      });

      group('isDescendantOf(node)', () {
        test('should return true if the chain is a descendant', () {
          final rootChain = ExampleChainRoot(scm: Scm.testInstance);
          final childChainA = rootChain.child('ChildChainA')!;
          final childChainB = rootChain.child('ChildChainB')!;
          final grandChildChain = childChainA.child('GrandChildChain')!;
          expect(childChainA.isDescendantOf(rootChain), isTrue);
          expect(childChainB.isDescendantOf(rootChain), isTrue);
          expect(childChainA.isDescendantOf(childChainB), isFalse);
          expect(childChainB.isDescendantOf(childChainA), isFalse);
          expect(grandChildChain.isDescendantOf(rootChain), isTrue);
        });
      });
    });
  });
}
