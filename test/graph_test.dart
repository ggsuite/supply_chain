// @license
// Copyright (c) 2019 - 2024 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'test_graphs.dart';

void main() {
  late TestGraphs t;

  setUp(() {
    t = TestGraphs();
  });

  group('GraphScopeItem', () {
    group('should throw', () {
      test('when nodeItems are not in scope', () {
        expect(
          () => GraphScopeItem(
            scope: t.x.scope,
            children: [],
            nodeItems: [
              GraphNodeItem(node: t.x.scm.nodes.first, shownCustomers: []),
            ],
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('All nodes must be in the given scope.'),
            ),
          ),
        );
      });
    });
    group('toString', () {
      test('should return the scope.key', () {
        final item = GraphScopeItem(
          scope: t.x.scope,
          children: [],
          nodeItems: [],
        );
        expect(item.toString(), t.x.scope.key);
      });
    });
  });

  group('GraphNodeItem', () {
    group('toString', () {
      test('should return the node.key', () {
        final item = GraphNodeItem(node: t.x, shownCustomers: []);
        expect(item.toString(), t.x.key);
      });
    });
  });

  group('Graph', () {
    group('dot, mermaid, writeImageFile', () {
      test('generates dot graphs and writes image files', () async {
        // Create the tree
        final graph = t.graph.treeForNode(node: t.x);

        // Test dot
        expect(Graph.dot(graph: graph), isNotEmpty);
        await Graph.writeImageFile(
          graph: graph,
          path: 'test/graphs/graph_test/graph_test_01.dot',
        );

        // Test mermaid
        expect(Graph.mermaid(graph: graph), isNotEmpty);
        await Graph.writeImageFile(
          graph: graph,
          path: 'test/graphs/graph_test/graph_test_01.mmd',
        );
      });
    });
    group('tree', () {
      group('treeForNode', () {
        group('should print a node', () {
          test('with no suppliers and customers', () async {
            // Create the tree
            final tree = t.graph.treeForNode(node: t.x);

            // Check tree
            expect(tree.isHighlighted, isFalse);
            expect(tree.nodeItems.length, 1);
            expect(tree.nodeItems.first.isHighlighted, false);
          });

          group('with direct suppliers', () {
            test('when supplierDepth == 1', () {
              // Create tree
              final tree = t.graph.treeForNode(node: t.x, supplierDepth: 1);

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 1
              expect(tree.scope, t.level1);
              expect(tree.nodeItems, hasLength(2));
              expect(tree.nodeItems[0].node, t.s1);
              expect(tree.nodeItems[1].node, t.s0);

              // Level 1 should have level 0 as child scope
              expect(tree.children, hasLength(1));
              expect(tree.children.first.scope, t.level0);
            });
          });

          group('with direct customers', () {
            test('when customerDepth == 1', () {
              // Create tree
              final tree = t.graph.treeForNode(node: t.x, customerDepth: 1);

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 1
              expect(tree.scope, t.level1);
              expect(tree.nodeItems, hasLength(2));
              expect(tree.nodeItems[0].node, t.c0);
              expect(tree.nodeItems[1].node, t.c1);

              // Level 1 should have level 0 as child scope
              expect(tree.children, hasLength(1));
              expect(tree.children.first.scope, t.level0);
            });
          });

          group('with direct customers and suppliers', () {
            test('when customerDepth == 1 and suppliersDepth == 1', () {
              // Create tree
              final tree = t.graph.treeForNode(
                node: t.x,
                customerDepth: 1,
                supplierDepth: 1,
              );

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 1
              expect(tree.scope, t.level1);
              expect(tree.nodeItems, hasLength(4));
              expect(tree.nodeItems[0].node, t.s1);
              expect(tree.nodeItems[1].node, t.s0);
              expect(tree.nodeItems[2].node, t.c0);
              expect(tree.nodeItems[3].node, t.c1);

              // Level 1 should have level 0 as child scope
              expect(tree.children, hasLength(1));
              expect(tree.children.first.scope, t.level0);
            });
          });

          group('with all customers and suppliers', () {
            test('when customerDepth == -1 and suppliersDepth == -1', () {
              // Create tree
              final tree = t.graph.treeForNode(
                node: t.x,
                customerDepth: -1,
                supplierDepth: -1,
              );

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 3
              expect(tree.scope, t.level3);
              expect(tree.nodeItems, hasLength(2));
              expect(tree.nodeItems[0].node, t.s111);
              expect(tree.nodeItems[1].node, t.c111);

              // It should have a child of level 2
              expect(tree.children, hasLength(1));
              final l2 = tree.children.first;

              expect(l2.nodeItems, hasLength(8));
              expect(l2.nodeItems[0].node, t.s11);
              expect(l2.nodeItems[1].node, t.s10);
              expect(l2.nodeItems[2].node, t.s01);
              expect(l2.nodeItems[3].node, t.s00);
              expect(l2.nodeItems[4].node, t.c00);
              expect(l2.nodeItems[5].node, t.c01);
              expect(l2.nodeItems[6].node, t.c10);
              expect(l2.nodeItems[7].node, t.c11);

              // Level 2 should have a child of level 1
              expect(l2.children, hasLength(1));
              final l1 = l2.children.first;
              expect(l1.nodeItems, hasLength(4));
              expect(l1.nodeItems[0].node, t.s1);
              expect(l1.nodeItems[1].node, t.s0);
              expect(l1.nodeItems[2].node, t.c0);
              expect(l1.nodeItems[3].node, t.c1);

              // Level 1 should have level 0 as child scope
              expect(l1.children, hasLength(1));
              final l0 = l1.children.first;
              expect(l0.children, hasLength(0));
              expect(l0.nodeItems, hasLength(1));
              expect(l0.nodeItems[0].node, t.x);
            });
          });

          group('with highlighted', () {
            test('nodes', () {
              final highlightedNodes = [t.s01, t.c1, t.c111];

              // Create a tree
              final tree = t.graph.treeForNode(
                node: t.x,
                customerDepth: -1,
                supplierDepth: -1,
                highlightedNodes: highlightedNodes,
              );

              // ..........
              // Check tree
              for (final node in t.allNodes) {
                final isHighlighted = highlightedNodes.contains(node);
                expect(tree.findNodeItem(node)?.isHighlighted, isHighlighted);
              }

              // .........
            });

            test('scopes', () {
              final highlightedScopes = [t.level0, t.level2];

              // Create a tree
              final tree = t.graph.treeForNode(
                node: t.x,
                customerDepth: -1,
                supplierDepth: -1,
                highlightedScopes: highlightedScopes,
              );

              // ..........
              // Check tree
              for (final scope in t.allScopes) {
                final isHighlighted = highlightedScopes.contains(scope);
                expect(
                  tree.findScopeItem(scope)?.isHighlighted ?? false,
                  isHighlighted,
                );
              }
            });
          });
        });
      });

      group('treeForScope', () {
        group('should print a scope', () {
          group('with no additional scopes', () {
            test(
              'when parentScopeDepth == 0 and childScopeDepth == 0',
              () async {
                // Create the tree
                final tree = t.graph.treeForScope(scope: t.x.scope);

                // Check tree
                expect(tree.scope, t.level0);
                expect(tree.children, isEmpty);

                expect(tree.nodeItems.length, 1);
                expect(tree.nodeItems.first.node, t.x);

                //
              },
            );
          });

          group('with one parent scope', () {
            test('when parentScopeDepth == 1', () async {
              // Create the tree
              final l1 = t.graph.treeForScope(
                scope: t.level0,
                parentScopeDepth: 1,
              );

              // Check tree
              expect(l1.scope, t.level1);
              expect(l1.children, hasLength(1));
              expect(l1.nodeItems.length, 4);
              expect(l1.nodeItems.map((e) => e.node), [t.s1, t.s0, t.c0, t.c1]);

              final l0 = l1.children.first;
              expect(l0.scope, t.level0);
              expect(l0.children, isEmpty);
              expect(l0.nodeItems.length, 1);
              expect(l0.nodeItems.map((e) => e.node), [t.x]);
            });
          });

          group('with one child scope', () {
            test('when childScopeDepth == 1', () async {
              // Create the tree
              final l1 = t.graph.treeForScope(
                scope: t.level1,
                childScopeDepth: 1,
              );

              // Check tree
              expect(l1.scope, t.level1);
              expect(l1.children, hasLength(1));
              expect(l1.nodeItems.length, 4);
              expect(l1.nodeItems.map((e) => e.node), [t.s1, t.s0, t.c0, t.c1]);

              final l0 = l1.children.first;
              expect(l0.scope, t.level0);
              expect(l0.children, isEmpty);
              expect(l0.nodeItems.length, 1);
              expect(l0.nodeItems.map((e) => e.node), [t.x]);
            });
          });

          group('with all parent scopes', () {
            test('when parentScopeDepth == -1', () async {
              // Create the tree
              final root = t.graph.treeForScope(
                scope: t.level0,
                parentScopeDepth: -1,
              );

              // Check tree
              expect(root.scope, t.level0.root);
              expect(root.children, hasLength(1));
              expect(root.nodeItems, isEmpty);

              final butterFly = root.children.first;

              final l3 = butterFly.children.first;
              expect(l3.scope, t.level3);
              expect(l3.children, hasLength(1));
              expect(l3.nodeItems.length, 2);
              expect(l3.nodeItems.map((e) => e.node), [t.s111, t.c111]);

              final l2 = l3.children.first;
              expect(l2.scope, t.level2);

              final l1 = l2.children.first;
              expect(l1.scope, t.level1);

              final l0 = l1.children.first;
              expect(l0.scope, t.level0);

              //
            });
          });

          group('with all child scopes', () {
            test('when childScopeDepth == -1', () async {
              final start = t.level0.root.children.first;

              // Create the tree
              final root = t.graph.treeForScope(
                scope: start,
                childScopeDepth: -1,
              );

              // Check tree
              expect(root.scope, start);
              expect(root.children, hasLength(1));
              expect(root.nodeItems, isEmpty);

              final l3 = root.children.first;
              expect(l3.scope, t.level3);
              expect(l3.children, hasLength(1));
              expect(l3.nodeItems.length, 2);
              expect(l3.nodeItems.map((e) => e.node), [t.s111, t.c111]);

              final l2 = l3.children.first;
              expect(l2.scope, t.level2);

              final l1 = l2.children.first;
              expect(l1.scope, t.level1);

              final l0 = l1.children.first;
              expect(l0.scope, t.level0);

              //
            });
          });
        });

        group('should print shells of child scope', () {
          group('when the child scopes would exceed the childScopeDepth', () {
            group('with scope shells', () {
              test('when a scope exceeds the level', () async {
                final start = t.level1;

                // Create the tree with a childScopeDepth of 0.
                final graphNode = t.graph.treeForScope(
                  scope: start,
                  childScopeDepth: 0,
                );

                // The nodes of the graphNode should be shown
                expect(graphNode.nodeItems, hasLength(4));

                // But also the direct child node should be shown.
                expect(graphNode.children, hasLength(1));

                // But the child node should be shown without and children.
                final firstChild = graphNode.children.first;
                expect(firstChild.children, isEmpty);
                expect(firstChild.nodeItems, isEmpty);
              });
            });
          });

          test('when the scopes are empty', () async {
            // Create a scope hierarchy without nodes

            final scopesWithoutNodes = Scope.example()
              ..mockContent({
                'a': {
                  'b': {'c': <String, dynamic>{}},
                },
              });

            // Create a graph
            final graphNode = t.graph.treeForScope(
              scope: scopesWithoutNodes,
              childScopeDepth: 2,
            );

            // The graph should contain the scopes
            expect(graphNode.children, hasLength(1));
            expect(graphNode.children.first.children, hasLength(1));
          });
        });
      });

      group('special cases', () {
        group('triangle', () {
          // Create the tree
          final triangle = TriangleExample();

          final TriangleExample(
            :leftNode,
            :rightNode,
            :topNode,
            :leftScope,
            :rightScope,
            :topScope,
          ) = triangle;

          test('complete', () {
            triangle.triangle.scm.flush();

            final tree = t.graph.treeForScope(
              scope: triangle.triangle,
              childScopeDepth: -1,
            );

            // Check tree
            final top = tree;
            expect(top.scope, topScope);
            expect(top.nodeItems, hasLength(1));
            expect(top.nodeItems.first.node, topNode);
            expect(tree.children, hasLength(2));

            final left = tree.children.first;
            expect(left.scope, leftScope);
            expect(left.nodeItems.first.node, leftNode);

            final right = tree.children.last;
            expect(right.scope, rightScope);
            expect(right.nodeItems.first.node, rightNode);

            expect(tree.nodeItems.first.node, topNode);
          });
        });
      });
    });
  });
}
