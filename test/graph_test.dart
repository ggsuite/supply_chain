// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final butterFly = ButterFlyExample(withScopes: true);

  final allScopeKeys = butterFly.x.scope.pathArray;
  final ButterFlyExample(
    :s111,
    :s11,
    :s10,
    :s01,
    :s00,
    :s1,
    :s0,
    :x,
    :c0,
    :c1,
    :c00,
    :c01,
    :c10,
    :c11,
    :c111,
    :level0,
    :level1,
    :level2,
    :level3,
  ) = butterFly;

  final allNodes =
      x.scope.scm.nodes.where((n) => !n.scope.isMetaScope).toList();
  final allScopes = butterFly.allScopes;
  final allNodeKeys = allNodes.map((n) => n.key).toList();
  assert(level2.key == 'level2');
  assert(level3.key == 'level3');

  const graph = Graph();

  void expectNodes(String result, List<Node<dynamic>> nodes) {
    for (final k in allNodeKeys) {
      final keys = nodes.map((n) => n.key);
      if (keys.contains(k)) {
        expect(result, contains('label = "$k"; // node'));
      } else {
        expect(result, isNot(contains('label = "$k"; // node')));
      }
    }
  }

  void expectScopes(String dot, List<Scope> scopes) {
    final expectedScopeKeys = scopes.map((s) => s.key);
    for (final k in allScopeKeys) {
      if (expectedScopeKeys.contains(k)) {
        expect(
          dot,
          contains('label = "$k"; // scope'),
        );
      } else {
        expect(
          dot,
          isNot(contains('label = "$k"; // scope')),
        );
      }
    }
  }

  void expectEdgeCount(String dot, int edgeCount) {
    final edges = dot.split('->');
    expect(
      edges.length - 1,
      edgeCount,
      reason: 'Expected $edgeCount edges, but found ${edges.length - 1}',
    );
  }

  void expectEdge(String dot, Node<dynamic> from, Node<dynamic> to) {
    expect(dot, matches(RegExp('"${from.key}_\\d+" -> "${to.key}_\\d+";')));
  }

  void expectHighlightedNodes(
    String dot,
    List<Node<dynamic>> highlightedNodes,
  ) {
    final expectedKeys = highlightedNodes.map((n) => n.key);

    RegExp regExp(String key) => RegExp(
          [
            // s0_3 [
            '\\s+${key}_\\d+ \\[\n',
            // label = "s01" // node
            '\\s+label = "$key"; // node\n',
            // style = filled;
            '\\s+style = filled;\n',
            // fillcolor = "#FFFFAA";
            '\\s+fillcolor = "#FFFFAA";\n',
          ].join(),
        );

    for (final key in allNodeKeys) {
      if (expectedKeys.contains(key)) {
        expect(dot, matches(regExp(key)));
      } else {
        expect(dot, isNot(matches(regExp(key))));
      }
    }
  }

  void expectHighlightedScopes(
    String dot,
    List<Scope> highlightedScopes,
  ) {
    final expectedKeys = highlightedScopes.map((n) => n.key);

    RegExp regExp(String key) => RegExp(
          [
            // s0_3 [
            '\\s+subgraph cluster_${key}_\\d+ \\{\n',
            // label = "s01" // node
            '\\s+label = "$key"; // scope\n',
            // style = filled;
            '\\s+style = filled;\n',
            // fillcolor = "#AAFFFF88";
            '\\s+fillcolor = "#AAFFFF88";\n',
          ].join(),
        );

    for (final key in allScopeKeys) {
      if (expectedKeys.contains(key)) {
        expect(
          dot,
          matches(regExp(key)),
          reason: 'Scope $key should be highlighted but it is not.',
        );
      } else {
        expect(
          dot,
          isNot(matches(regExp(key))),
          reason: 'Scope $key should not be highlighted but it is.',
        );
      }
    }
  }

  void expectEmptyScope(String dot, Scope scope) {
    expect(
      dot,
      matches(
        RegExp(
          'invisible[0-9]+ \\[label = "", shape = point, style=invis\\]; // ${scope.key}',
        ),
      ),
    );
  }

  Future<void> writeDotFile(String dot, String postfix) async {
    await graph.writeImageFile(
      dot: dot,
      path: 'test/graphs/graph_test_$postfix.svg',
    );

    await graph.writeImageFile(
      dot: dot,
      path: 'test/graphs/graph_test_$postfix.dot',
    );
  }

  group('GraphScopeItem', () {
    group('should throw', () {
      test('when nodeItems are not in scope', () {
        expect(
          () => GraphScopeItem(
            scope: x.scope,
            children: [],
            nodeItems: [
              GraphNodeItem(
                node: x.scm.nodes.first,
                shownCustomers: [],
              ),
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
          scope: x.scope,
          children: [],
          nodeItems: [],
        );
        expect(item.toString(), x.scope.key);
      });
    });
  });

  group('GraphNodeItem', () {
    group('toString', () {
      test('should return the node.key', () {
        final item = GraphNodeItem(
          node: x,
          shownCustomers: [],
        );
        expect(item.toString(), x.key);
      });
    });
  });

  group('Graph', () {
    group('tree, dot', () {
      group('treeForNode', () {
        group('should print a node', () {
          test(
            'with no suppliers and customers',
            () async {
              // Create the tree
              final tree = graph.treeForNode(node: x);

              // Create dot
              final dot = graph.dot(tree: tree);
              await writeDotFile(dot, '01');

              // Check tree
              expect(tree.isHighlighted, isFalse);
              expect(tree.nodeItems.length, 1);
              expect(tree.nodeItems.first.isHighlighted, false);

              // Check dot
              expectNodes(dot, [x]);
              expectScopes(dot, [level0]);
              expectEdgeCount(dot, 0);
            },
          );

          group('with direct suppliers', () {
            test('when supplierDepth == 1', () {
              // Create tree
              final tree = graph.treeForNode(node: x, supplierDepth: 1);

              // Create dot
              final dot = graph.dot(tree: tree);
              writeDotFile(dot, '02');

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 1
              expect(tree.scope, level1);
              expect(tree.nodeItems, hasLength(2));
              expect(tree.nodeItems[0].node, s1);
              expect(tree.nodeItems[1].node, s0);

              // Level 1 should have level 0 as child scope
              expect(tree.children, hasLength(1));
              expect(tree.children.first.scope, level0);

              // .........
              // Check dot
              expectNodes(dot, [x, s0, s1]);
              expectEdgeCount(dot, 2);
              expectEdge(dot, s1, x);
              expectEdge(dot, s0, x);
              expectScopes(dot, [level0, level1]);
            });
          });

          group('with direct customers', () {
            test('when customerDepth == 1', () {
              // Create tree
              final tree = graph.treeForNode(node: x, customerDepth: 1);

              // Create dot
              final dot = graph.dot(tree: tree);
              writeDotFile(dot, '03');

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 1
              expect(tree.scope, level1);
              expect(tree.nodeItems, hasLength(2));
              expect(tree.nodeItems[0].node, c0);
              expect(tree.nodeItems[1].node, c1);

              // Level 1 should have level 0 as child scope
              expect(tree.children, hasLength(1));
              expect(tree.children.first.scope, level0);

              // .........
              // Check dot
              expectNodes(dot, [x, c0, c1]);
              expectEdgeCount(dot, 2);
              expectEdge(dot, x, c0);
              expectEdge(dot, x, c1);
              expectScopes(dot, [level0, level1]);
            });
          });

          group('with direct customers and suppliers', () {
            test('when customerDepth == 1 and suppliersDepth == 1', () {
              // Create tree
              final tree = graph.treeForNode(
                node: x,
                customerDepth: 1,
                supplierDepth: 1,
              );

              // Create dot
              final dot = graph.dot(tree: tree);
              writeDotFile(dot, '05');

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 1
              expect(tree.scope, level1);
              expect(tree.nodeItems, hasLength(4));
              expect(tree.nodeItems[0].node, s1);
              expect(tree.nodeItems[1].node, s0);
              expect(tree.nodeItems[2].node, c0);
              expect(tree.nodeItems[3].node, c1);

              // Level 1 should have level 0 as child scope
              expect(tree.children, hasLength(1));
              expect(tree.children.first.scope, level0);

              // .........
              // Check dot
              expectNodes(dot, [x, s1, s0, c0, c1]);
              expectEdgeCount(dot, 4);
              expectEdge(dot, s1, x);
              expectEdge(dot, s0, x);
              expectEdge(dot, x, c0);
              expectEdge(dot, x, c1);
              expectScopes(dot, [level0, level1]);
            });
          });

          group('with all customers and suppliers', () {
            test('when customerDepth == -1 and suppliersDepth == -1', () {
              // Create tree
              final tree = graph.treeForNode(
                node: x,
                customerDepth: -1,
                supplierDepth: -1,
              );

              // Create dot
              final dot = graph.dot(tree: tree);
              writeDotFile(dot, '04');

              // ..........
              // Check tree
              expect(tree.children.length, 1);

              // First we expect level 3
              expect(tree.scope, level3);
              expect(tree.nodeItems, hasLength(2));
              expect(tree.nodeItems[0].node, s111);
              expect(tree.nodeItems[1].node, c111);

              // It should have a child of level 2
              expect(tree.children, hasLength(1));
              final l2 = tree.children.first;

              expect(l2.nodeItems, hasLength(8));
              expect(l2.nodeItems[0].node, s11);
              expect(l2.nodeItems[1].node, s10);
              expect(l2.nodeItems[2].node, s01);
              expect(l2.nodeItems[3].node, s00);
              expect(l2.nodeItems[4].node, c00);
              expect(l2.nodeItems[5].node, c01);
              expect(l2.nodeItems[6].node, c10);
              expect(l2.nodeItems[7].node, c11);

              // Level 2 should have a child of level 1
              expect(l2.children, hasLength(1));
              final l1 = l2.children.first;
              expect(l1.nodeItems, hasLength(4));
              expect(l1.nodeItems[0].node, s1);
              expect(l1.nodeItems[1].node, s0);
              expect(l1.nodeItems[2].node, c0);
              expect(l1.nodeItems[3].node, c1);

              // Level 1 should have level 0 as child scope
              expect(l1.children, hasLength(1));
              final l0 = l1.children.first;
              expect(l0.children, hasLength(0));
              expect(l0.nodeItems, hasLength(1));
              expect(l0.nodeItems[0].node, x);

              // .........
              // Check dot
              expectNodes(dot, butterFly.allNodes);
              expectEdgeCount(dot, 14);

              expectEdge(dot, s111, s11);
              expectEdge(dot, s11, s1);
              expectEdge(dot, s10, s1);
              expectEdge(dot, s01, s0);
              expectEdge(dot, s00, s0);
              expectEdge(dot, c11, c111);
              expectEdge(dot, s1, x);
              expectEdge(dot, s0, x);
              expectEdge(dot, c0, c00);
              expectEdge(dot, c0, c01);
              expectEdge(dot, c1, c10);
              expectEdge(dot, c1, c11);
              expectEdge(dot, x, c0);
              expectEdge(dot, x, c1);

              expectScopes(dot, [level0, level1, level2, level3]);
            });
          });

          group('with highlighted', () {
            test('nodes', () {
              final highlightedNodes = [s01, c1, c111];

              // Create a tree
              final tree = graph.treeForNode(
                node: x,
                customerDepth: -1,
                supplierDepth: -1,
                highlightedNodes: highlightedNodes,
              );

              // Create dot
              final dot = graph.dot(tree: tree);
              writeDotFile(dot, '06');

              // ..........
              // Check tree
              for (final node in allNodes) {
                final isHighlighted = highlightedNodes.contains(node);
                expect(
                  tree.findNodeItem(node)?.isHighlighted,
                  isHighlighted,
                );
              }

              // .........
              // Check dot
              expectHighlightedNodes(dot, highlightedNodes);
            });

            test('scopes', () {
              final highlightedScopes = [level0, level2];

              // Create a tree
              final tree = graph.treeForNode(
                node: x,
                customerDepth: -1,
                supplierDepth: -1,
                highlightedScopes: highlightedScopes,
              );

              // Create dot
              final dot = graph.dot(tree: tree);
              writeDotFile(dot, '07');

              // ..........
              // Check tree
              for (final scope in allScopes) {
                final isHighlighted = highlightedScopes.contains(scope);
                expect(
                  tree.findScopeItem(scope)?.isHighlighted ?? false,
                  isHighlighted,
                );
              }

              // .........
              // Check dot
              expectHighlightedScopes(dot, highlightedScopes);
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
                final tree = graph.treeForScope(scope: x.scope);

                // Create dot
                final dot = graph.dot(tree: tree);
                await writeDotFile(dot, '08');

                // Check tree
                expect(tree.scope, level0);
                expect(tree.children, isEmpty);

                expect(tree.nodeItems.length, 1);
                expect(tree.nodeItems.first.node, x);

                //// Check dot
                expectNodes(dot, [x]);
                expectScopes(dot, [level0]);
                expectEdgeCount(dot, 0);
              },
            );
          });

          group('with one parent scope', () {
            test(
              'when parentScopeDepth == 1',
              () async {
                // Create the tree
                final l1 = graph.treeForScope(
                  scope: level0,
                  parentScopeDepth: 1,
                );

                // Create dot
                final dot = graph.dot(tree: l1);
                await writeDotFile(dot, '09');

                // Check tree
                expect(l1.scope, level1);
                expect(l1.children, hasLength(1));
                expect(l1.nodeItems.length, 4);
                expect(l1.nodeItems.map((e) => e.node), [s1, s0, c0, c1]);

                final l0 = l1.children.first;
                expect(l0.scope, level0);
                expect(l0.children, isEmpty);
                expect(l0.nodeItems.length, 1);
                expect(l0.nodeItems.map((e) => e.node), [x]);

                // Check dot
                expectNodes(dot, [x, s1, s0, c0, c1]);
                expectScopes(dot, [level0, level1]);
                expectEdgeCount(dot, 4);
                expectEdge(dot, s1, x);
                expectEdge(dot, s0, x);
                expectEdge(dot, x, c0);
                expectEdge(dot, x, c1);
              },
            );
          });

          group('with one child scope', () {
            test(
              'when childScopeDepth == 1',
              () async {
                // Create the tree
                final l1 = graph.treeForScope(
                  scope: level1,
                  childScopeDepth: 1,
                );

                // Create dot
                final dot = graph.dot(tree: l1);
                await writeDotFile(dot, '10');

                // Check tree
                expect(l1.scope, level1);
                expect(l1.children, hasLength(1));
                expect(l1.nodeItems.length, 4);
                expect(l1.nodeItems.map((e) => e.node), [s1, s0, c0, c1]);

                final l0 = l1.children.first;
                expect(l0.scope, level0);
                expect(l0.children, isEmpty);
                expect(l0.nodeItems.length, 1);
                expect(l0.nodeItems.map((e) => e.node), [x]);

                // Check dot
                expectNodes(dot, [x, s1, s0, c0, c1]);
                expectScopes(dot, [level0, level1]);
                expectEdgeCount(dot, 4);
                expectEdge(dot, s1, x);
                expectEdge(dot, s0, x);
                expectEdge(dot, x, c0);
                expectEdge(dot, x, c1);
              },
            );
          });

          group('with all parent scopes', () {
            test(
              'when parentScopeDepth == -1',
              () async {
                // Create the tree
                final root = graph.treeForScope(
                  scope: level0,
                  parentScopeDepth: -1,
                );

                // Create dot
                final dot = graph.dot(tree: root);
                await writeDotFile(dot, '11');

                // Check tree
                expect(root.scope, level0.root);
                expect(root.children, hasLength(1));
                expect(root.nodeItems, isEmpty);

                final butterFly = root.children.first;

                final l3 = butterFly.children.first;
                expect(l3.scope, level3);
                expect(l3.children, hasLength(1));
                expect(l3.nodeItems.length, 2);
                expect(l3.nodeItems.map((e) => e.node), [s111, c111]);

                final l2 = l3.children.first;
                expect(l2.scope, level2);

                final l1 = l2.children.first;
                expect(l1.scope, level1);

                final l0 = l1.children.first;
                expect(l0.scope, level0);

                //// Check dot
                expectNodes(dot, allNodes);
                expectScopes(dot, [...allScopes, level0.root]);
                expectEdgeCount(dot, 14);
              },
            );
          });

          group('with all child scopes', () {
            test(
              'when childScopeDepth == -1',
              () async {
                final start = level0.root.children.first;

                // Create the tree
                final root = graph.treeForScope(
                  scope: start,
                  childScopeDepth: -1,
                );

                // Create dot
                final dot = graph.dot(tree: root);
                await writeDotFile(dot, '12');

                // Check tree
                expect(root.scope, start);
                expect(root.children, hasLength(1));
                expect(root.nodeItems, isEmpty);

                final l3 = root.children.first;
                expect(l3.scope, level3);
                expect(l3.children, hasLength(1));
                expect(l3.nodeItems.length, 2);
                expect(l3.nodeItems.map((e) => e.node), [s111, c111]);

                final l2 = l3.children.first;
                expect(l2.scope, level2);

                final l1 = l2.children.first;
                expect(l1.scope, level1);

                final l0 = l1.children.first;
                expect(l0.scope, level0);

                //// Check dot
                expectNodes(dot, allNodes);
                expectScopes(dot, allScopes);
                expectEdgeCount(dot, 14);
              },
            );
          });
        });

        group('should print shells of child scope', () {
          group('when the child scopes would exceed the childScopeDepth', () {
            group('with scope shells', () {
              test('when a scope exceeds the level', () async {
                final start = level1;

                // Create the tree with a childScopeDepth of 0.
                final graphNode = graph.treeForScope(
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

                // Print the dot graph
                final dot = graph.dot(tree: graphNode);
                await writeDotFile(dot, '18');
              });
            });
          });

          test('when the scopes are empty', () async {
            // Create a scope hierarchy without nodes

            final scopesWithoutNodes = Scope.example()
              ..mockContent(
                {
                  'a': {
                    'b': {'c': <String, dynamic>{}},
                  },
                },
              );

            // Create a graph
            final graphNode = graph.treeForScope(
              scope: scopesWithoutNodes,
              childScopeDepth: 2,
            );

            // The graph should contain the scopes
            expect(graphNode.children, hasLength(1));
            expect(graphNode.children.first.children, hasLength(1));

            // Print the dot graph
            final dot = graph.dot(tree: graphNode);
            await writeDotFile(dot, '19');
          });
        });
      });

      group('special cases', () {
        group('empty scopes', () {
          test('single', () {
            final emptyScope = Scope.example(key: 'empty');
            final tree = graph.treeForScope(
              scope: emptyScope,
              childScopeDepth: -1,
            );
            final dot = graph.dot(
              tree: tree,
            );
            writeDotFile(dot, '13');
            expectEmptyScope(dot, emptyScope);
          });

          test('multiple', () {
            final a = Scope.example(key: 'a');
            a.mockContent({
              'b': {
                'c': <String, dynamic>{},
              },
            });

            final b = a.findChildScope('b')!;
            final c = b.findChildScope('c')!;

            final tree = graph.treeForScope(
              scope: a,
              childScopeDepth: -1,
            );
            final dot = graph.dot(
              tree: tree,
            );
            writeDotFile(dot, '14');
            expectEmptyScope(dot, a);
            expectEmptyScope(dot, b);
            expectEmptyScope(dot, c);
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

          test('complete', () {
            final tree = graph.treeForScope(
              scope: triangle.triangle,
              childScopeDepth: -1,
            );

            // Create dot
            final dot = graph.dot(tree: tree);
            writeDotFile(dot, '15');

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

            // Check dot
            expectNodes(dot, triangle.allNodes);
            expectScopes(dot, triangle.allScopes);
            expectEdgeCount(dot, 3);
            expectEdge(dot, topNode, leftNode);
            expectEdge(dot, topNode, rightNode);
            expectEdge(dot, leftNode, rightNode);
          });

          test('sibling node as customer', () {
            final tree = graph.treeForNode(
              node: leftNode,
              customerDepth: 1,
            );

            // Create dot
            final dot = graph.dot(
              tree: tree,
            );
            writeDotFile(dot, '16');
          });

          test('sibling node as supplier', () {
            final tree = graph.treeForNode(
              node: rightNode,
              supplierDepth: 1,
            );

            // Create dot
            final dot = graph.dot(
              tree: tree,
            );
            writeDotFile(dot, '17');
          });
        });
      });
    });

    group('fixViewBox', () {
      test('should write width and height to the view box width and height',
          () {
        const svg =
            '<svg width="98pt" height="103pt" viewBox="0.00 0.00 94.00 99.00"';
        final fixed = Graph.fixSvgViewBox(svg);
        expect(fixed, contains('viewBox="0.00 0.00 98 103"'));
      });
    });
  });
}
