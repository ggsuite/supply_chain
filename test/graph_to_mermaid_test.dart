// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'test_graphs.dart';

void main() {
  late TestGraphs t;

  setUp(() {
    t = TestGraphs();
  });

  Future<void> writeFile(String mermaid, String postfix) async {
    final path = 'test/graphs/graph_test_$postfix.mmd';
    await File(path).writeAsString(mermaid);
  }

  void expectNodes(String result, List<Node<dynamic>> nodes) {
    for (final k in t.allNodeKeys) {
      final keys = nodes.map((n) => n.key);
      if (keys.contains(k)) {
        expect(result, contains('["$k"]'));
      } else {
        expect(result, isNot(contains('["$k"]')));
      }
    }
  }

  void expectScopes(String mermaid, List<Scope> scopes) {
    final expectedScopeKeys = scopes.map((s) => s.key);
    for (final k in t.allScopeKeys) {
      if (expectedScopeKeys.contains(k)) {
        expect(mermaid, contains('["$k"]'));
      } else {
        expect(mermaid, isNot(contains('["$k"]')));
      }
    }
  }

  void expectEdgeCount(String mermaid, int edgeCount) {
    final edges = mermaid.split('->');
    expect(
      edges.length - 1,
      edgeCount,
      reason: 'Expected $edgeCount edges, but found ${edges.length - 1}',
    );
  }

  void expectEdge(String mermaid, Node<dynamic> from, Node<dynamic> to) {
    expect(mermaid, matches(RegExp('${from.key}_\\d+ --> ${to.key}_\\d+;')));
  }

  void expectHighlightedNodes(
    String mermaid,
    List<Node<dynamic>> highlightedNodes,
  ) {
    final expectedKeys = highlightedNodes.map((n) => n.key);

    RegExp regExp(String key) =>
        RegExp('\\s+${key}_\\d+\\["$key"\\]:::highlight');

    for (final key in t.allNodeKeys) {
      if (expectedKeys.contains(key)) {
        expect(mermaid, matches(regExp(key)));
      } else {
        expect(mermaid, isNot(matches(regExp(key))));
      }
    }
  }

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
    group('tree, mermaid', () {
      group('treeForNode', () {
        group('should print a node', () {
          test('with no suppliers and customers', () async {
            // Create the tree
            final tree = t.graph.treeForNode(node: t.x);

            // Create mermaid
            final mermaid = t.graph.mermaid(tree: tree);
            await writeFile(mermaid, '01');

            // Check mermaid
            expectNodes(mermaid, [t.x]);
            expectScopes(mermaid, [t.level0]);
            expectEdgeCount(mermaid, 0);
          });

          group('with direct suppliers', () {
            test('when supplierDepth == 1', () async {
              // Create tree
              final tree = t.graph.treeForNode(node: t.x, supplierDepth: 1);

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: tree);
              await writeFile(mermaid, '02');

              // .........
              // Check mermaid
              expectNodes(mermaid, [t.x, t.s0, t.s1]);
              expectEdgeCount(mermaid, 2);
              expectEdge(mermaid, t.s1, t.x);
              expectEdge(mermaid, t.s0, t.x);
              expectScopes(mermaid, [t.level0, t.level1]);
            });
          });

          group('with direct customers', () {
            test('when customerDepth == 1', () async {
              // Create tree
              final tree = t.graph.treeForNode(node: t.x, customerDepth: 1);

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: tree);
              await writeFile(mermaid, '03');

              // .........
              // Check mermaid
              expectNodes(mermaid, [t.x, t.c0, t.c1]);
              expectEdgeCount(mermaid, 2);
              expectEdge(mermaid, t.x, t.c0);
              expectEdge(mermaid, t.x, t.c1);
              expectScopes(mermaid, [t.level0, t.level1]);
            });
          });

          group('with direct customers and suppliers', () {
            test('when customerDepth == 1 and suppliersDepth == 1', () async {
              // Create tree
              final tree = t.graph.treeForNode(
                node: t.x,
                customerDepth: 1,
                supplierDepth: 1,
              );

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: tree);
              await writeFile(mermaid, '05');

              // .........
              // Check mermaid
              expectNodes(mermaid, [t.x, t.s1, t.s0, t.c0, t.c1]);
              expectEdgeCount(mermaid, 4);
              expectEdge(mermaid, t.s1, t.x);
              expectEdge(mermaid, t.s0, t.x);
              expectEdge(mermaid, t.x, t.c0);
              expectEdge(mermaid, t.x, t.c1);
              expectScopes(mermaid, [t.level0, t.level1]);
            });
          });

          group('with all customers and suppliers', () {
            test('when customerDepth == -1 and suppliersDepth == -1', () async {
              // Create tree
              final tree = t.graph.treeForNode(
                node: t.x,
                customerDepth: -1,
                supplierDepth: -1,
              );

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: tree);
              await writeFile(mermaid, '04');

              // .........
              // Check mermaid
              expectNodes(mermaid, t.butterFly.allNodes);
              expectEdgeCount(mermaid, 14);

              expectEdge(mermaid, t.s111, t.s11);
              expectEdge(mermaid, t.s11, t.s1);
              expectEdge(mermaid, t.s10, t.s1);
              expectEdge(mermaid, t.s01, t.s0);
              expectEdge(mermaid, t.s00, t.s0);
              expectEdge(mermaid, t.c11, t.c111);
              expectEdge(mermaid, t.s1, t.x);
              expectEdge(mermaid, t.s0, t.x);
              expectEdge(mermaid, t.c0, t.c00);
              expectEdge(mermaid, t.c0, t.c01);
              expectEdge(mermaid, t.c1, t.c10);
              expectEdge(mermaid, t.c1, t.c11);
              expectEdge(mermaid, t.x, t.c0);
              expectEdge(mermaid, t.x, t.c1);

              expectScopes(mermaid, [t.level0, t.level1, t.level2, t.level3]);
            });
          });

          group('with highlighted', () {
            test('nodes', () async {
              final highlightedNodes = [t.s01, t.c1, t.c111];

              // Create a tree
              final tree = t.graph.treeForNode(
                node: t.x,
                customerDepth: -1,
                supplierDepth: -1,
                highlightedNodes: highlightedNodes,
              );

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: tree);
              await writeFile(mermaid, '06');

              // .........
              // Check mermaid
              expectHighlightedNodes(mermaid, highlightedNodes);
            });

            test('scopes', () async {
              // Mermaid does not support highlighted subgraph
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

                // Create mermaid
                final mermaid = t.graph.mermaid(tree: tree);
                await writeFile(mermaid, '08');

                //// Check mermaid
                expectNodes(mermaid, [t.x]);
                expectScopes(mermaid, [t.level0]);
                expectEdgeCount(mermaid, 0);
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

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: l1);
              await writeFile(mermaid, '09');

              // Check mermaid
              expectNodes(mermaid, [t.x, t.s1, t.s0, t.c0, t.c1]);
              expectScopes(mermaid, [t.level0, t.level1]);
              expectEdgeCount(mermaid, 4);
              expectEdge(mermaid, t.s1, t.x);
              expectEdge(mermaid, t.s0, t.x);
              expectEdge(mermaid, t.x, t.c0);
              expectEdge(mermaid, t.x, t.c1);
            });
          });

          group('with one child scope', () {
            test('when childScopeDepth == 1', () async {
              // Create the tree
              final l1 = t.graph.treeForScope(
                scope: t.level1,
                childScopeDepth: 1,
              );

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: l1);
              await writeFile(mermaid, '10');

              // Check mermaid
              expectNodes(mermaid, [t.x, t.s1, t.s0, t.c0, t.c1]);
              expectScopes(mermaid, [t.level0, t.level1]);
              expectEdgeCount(mermaid, 4);
              expectEdge(mermaid, t.s1, t.x);
              expectEdge(mermaid, t.s0, t.x);
              expectEdge(mermaid, t.x, t.c0);
              expectEdge(mermaid, t.x, t.c1);
            });
          });

          group('with all parent scopes', () {
            test('when parentScopeDepth == -1', () async {
              // Create the tree
              final root = t.graph.treeForScope(
                scope: t.level0,
                parentScopeDepth: -1,
              );

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: root);
              await writeFile(mermaid, '11');

              //// Check mermaid
              expectNodes(mermaid, t.allNodes);
              expectScopes(mermaid, [...t.allScopes, t.level0.root]);
              expectEdgeCount(mermaid, 14);
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

              // Create mermaid
              final mermaid = t.graph.mermaid(tree: root);
              await writeFile(mermaid, '12');

              //// Check mermaid
              expectNodes(mermaid, t.allNodes);
              expectScopes(mermaid, t.allScopes);
              expectEdgeCount(mermaid, 14);
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

                // Print the mermaid graph
                final mermaid = t.graph.mermaid(tree: graphNode);
                await writeFile(mermaid, '18');
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

            // Print the mermaid graph
            final mermaid = t.graph.mermaid(tree: graphNode);
            await writeFile(mermaid, '19');
          });
        });
      });

      group('special cases', () {
        group('empty scopes', () {
          test('single', () async {
            final emptyScope = Scope.example(key: 'empty');
            final tree = t.graph.treeForScope(
              scope: emptyScope,
              childScopeDepth: -1,
            );
            final mermaid = t.graph.mermaid(tree: tree);
            await writeFile(mermaid, '13');
          });

          test('multiple', () async {
            final a = Scope.example(key: 'a');
            a.mockContent({
              'b': {'c': <String, dynamic>{}},
            });

            final tree = t.graph.treeForScope(scope: a, childScopeDepth: -1);
            final mermaid = t.graph.mermaid(tree: tree);
            await writeFile(mermaid, '14');
          });
        });

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

          test('complete', () async {
            triangle.triangle.scm.testFlushTasks();

            final tree = t.graph.treeForScope(
              scope: triangle.triangle,
              childScopeDepth: -1,
            );

            // Create mermaid
            final mermaid = t.graph.mermaid(tree: tree);
            await writeFile(mermaid, '15');

            // Check mermaid
            expectNodes(mermaid, triangle.allNodes);
            expectScopes(mermaid, triangle.allScopes);
            expectEdgeCount(mermaid, 3);
            expectEdge(mermaid, topNode, leftNode);
            expectEdge(mermaid, topNode, rightNode);
            expectEdge(mermaid, leftNode, rightNode);
          });

          test('sibling node as customer', () async {
            final tree = t.graph.treeForNode(node: leftNode, customerDepth: 1);

            // Create mermaid
            final mermaid = t.graph.mermaid(tree: tree);
            await writeFile(mermaid, '16');
          });

          test('sibling node as supplier', () async {
            final tree = t.graph.treeForNode(node: rightNode, supplierDepth: 1);

            // Create mermaid
            final mermaid = t.graph.mermaid(tree: tree);
            await writeFile(mermaid, '17');
          });
        });
      });
    });
  });
}
