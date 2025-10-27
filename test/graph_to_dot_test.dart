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

  void expectNodes(String result, List<Node<dynamic>> nodes) {
    for (final k in t.allNodeKeys) {
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
    for (final k in t.allScopeKeys) {
      if (expectedScopeKeys.contains(k)) {
        expect(dot, contains('label = "$k"; // scope'));
      } else {
        expect(dot, isNot(contains('label = "$k"; // scope')));
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
        // t.s0_3 [
        '\\s+${key}_\\d+ \\[\n',
        // label = "s01" // node
        '\\s+label = "$key"; // node\n',
        // style = filled;
        '\\s+style = filled;\n',
        // fillcolor = "#FFFFAA";
        '\\s+fillcolor = "#FFFFAA";\n',
      ].join(),
    );

    for (final key in t.allNodeKeys) {
      if (expectedKeys.contains(key)) {
        expect(dot, matches(regExp(key)));
      } else {
        expect(dot, isNot(matches(regExp(key))));
      }
    }
  }

  void expectHighlightedScopes(String dot, List<Scope> highlightedScopes) {
    final expectedKeys = highlightedScopes.map((n) => n.key);

    RegExp regExp(String key) => RegExp(
      [
        // t.s0_3 [
        '\\s+subgraph cluster_${key}_\\d+ \\{\n',
        // label = "s01" // node
        '\\s+label = "$key"; // scope\n',
        // style = filled;
        '\\s+style = filled;\n',
        // fillcolor = "#AAFFFF88";
        '\\s+fillcolor = "#AAFFFF88";\n',
      ].join(),
    );

    for (final key in t.allScopeKeys) {
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
    if (GraphToDot.testSvgAndPngExport) {
      await GraphToDot.writeImageFile(
        dot: dot,
        path: 'test/graphs/graph_test_$postfix.svg',
      );
    }

    await GraphToDot.writeImageFile(
      dot: dot,
      path: 'test/graphs/graph_test_$postfix.dot',
    );
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
    group('tree, dot', () {
      group('treeForNode', () {
        group('should print a node', () {
          test('with no suppliers and customers', () async {
            // Create the tree
            final tree = t.graph.treeForNode(node: t.x);

            // Create dot
            final dot = Graph.dot(graph: tree);
            await writeDotFile(dot, '01');

            // Check dot
            expectNodes(dot, [t.x]);
            expectScopes(dot, [t.level0]);
            expectEdgeCount(dot, 0);
          });

          group('with direct suppliers', () {
            test('when supplierDepth == 1', () {
              // Create tree
              final tree = t.graph.treeForNode(node: t.x, supplierDepth: 1);

              // Create dot
              final dot = Graph.dot(graph: tree);
              writeDotFile(dot, '02');

              // .........
              // Check dot
              expectNodes(dot, [t.x, t.s0, t.s1]);
              expectEdgeCount(dot, 2);
              expectEdge(dot, t.s1, t.x);
              expectEdge(dot, t.s0, t.x);
              expectScopes(dot, [t.level0, t.level1]);
            });
          });

          group('with direct customers', () {
            test('when customerDepth == 1', () {
              // Create tree
              final tree = t.graph.treeForNode(node: t.x, customerDepth: 1);

              // Create dot
              final dot = Graph.dot(graph: tree);
              writeDotFile(dot, '03');

              // .........
              // Check dot
              expectNodes(dot, [t.x, t.c0, t.c1]);
              expectEdgeCount(dot, 2);
              expectEdge(dot, t.x, t.c0);
              expectEdge(dot, t.x, t.c1);
              expectScopes(dot, [t.level0, t.level1]);
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

              // Create dot
              final dot = Graph.dot(graph: tree);
              writeDotFile(dot, '05');

              // .........
              // Check dot
              expectNodes(dot, [t.x, t.s1, t.s0, t.c0, t.c1]);
              expectEdgeCount(dot, 4);
              expectEdge(dot, t.s1, t.x);
              expectEdge(dot, t.s0, t.x);
              expectEdge(dot, t.x, t.c0);
              expectEdge(dot, t.x, t.c1);
              expectScopes(dot, [t.level0, t.level1]);
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

              // Create dot
              final dot = Graph.dot(graph: tree);
              writeDotFile(dot, '04');

              // .........
              // Check dot
              expectNodes(dot, t.butterFly.allNodes);
              expectEdgeCount(dot, 14);

              expectEdge(dot, t.s111, t.s11);
              expectEdge(dot, t.s11, t.s1);
              expectEdge(dot, t.s10, t.s1);
              expectEdge(dot, t.s01, t.s0);
              expectEdge(dot, t.s00, t.s0);
              expectEdge(dot, t.c11, t.c111);
              expectEdge(dot, t.s1, t.x);
              expectEdge(dot, t.s0, t.x);
              expectEdge(dot, t.c0, t.c00);
              expectEdge(dot, t.c0, t.c01);
              expectEdge(dot, t.c1, t.c10);
              expectEdge(dot, t.c1, t.c11);
              expectEdge(dot, t.x, t.c0);
              expectEdge(dot, t.x, t.c1);

              expectScopes(dot, [t.level0, t.level1, t.level2, t.level3]);
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

              // Create dot
              final dot = Graph.dot(graph: tree);
              writeDotFile(dot, '06');

              // .........
              // Check dot
              expectHighlightedNodes(dot, highlightedNodes);
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

              // Create dot
              final dot = Graph.dot(graph: tree);
              writeDotFile(dot, '07');

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
                final tree = t.graph.treeForScope(scope: t.x.scope);

                // Create dot
                final dot = Graph.dot(graph: tree);
                await writeDotFile(dot, '08');

                //// Check dot
                expectNodes(dot, [t.x]);
                expectScopes(dot, [t.level0]);
                expectEdgeCount(dot, 0);
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

              // Create dot
              final dot = Graph.dot(graph: l1);
              await writeDotFile(dot, '09');

              // Check dot
              expectNodes(dot, [t.x, t.s1, t.s0, t.c0, t.c1]);
              expectScopes(dot, [t.level0, t.level1]);
              expectEdgeCount(dot, 4);
              expectEdge(dot, t.s1, t.x);
              expectEdge(dot, t.s0, t.x);
              expectEdge(dot, t.x, t.c0);
              expectEdge(dot, t.x, t.c1);
            });
          });

          group('with one child scope', () {
            test('when childScopeDepth == 1', () async {
              // Create the tree
              final l1 = t.graph.treeForScope(
                scope: t.level1,
                childScopeDepth: 1,
              );

              // Create dot
              final dot = Graph.dot(graph: l1);
              await writeDotFile(dot, '10');

              // Check dot
              expectNodes(dot, [t.x, t.s1, t.s0, t.c0, t.c1]);
              expectScopes(dot, [t.level0, t.level1]);
              expectEdgeCount(dot, 4);
              expectEdge(dot, t.s1, t.x);
              expectEdge(dot, t.s0, t.x);
              expectEdge(dot, t.x, t.c0);
              expectEdge(dot, t.x, t.c1);
            });
          });

          group('with all parent scopes', () {
            test('when parentScopeDepth == -1', () async {
              // Create the tree
              final root = t.graph.treeForScope(
                scope: t.level0,
                parentScopeDepth: -1,
              );

              // Create dot
              final dot = Graph.dot(graph: root);
              await writeDotFile(dot, '11');

              //// Check dot
              expectNodes(dot, t.allNodes);
              expectScopes(dot, [...t.allScopes, t.level0.root]);
              expectEdgeCount(dot, 14);
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

              // Create dot
              final dot = Graph.dot(graph: root);
              await writeDotFile(dot, '12');

              //// Check dot
              expectNodes(dot, t.allNodes);
              expectScopes(dot, t.allScopes);
              expectEdgeCount(dot, 14);
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

                // Print the dot graph
                final dot = Graph.dot(graph: graphNode);
                await writeDotFile(dot, '18');
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

            // Print the dot graph
            final dot = Graph.dot(graph: graphNode);
            await writeDotFile(dot, '19');
          });
        });
      });

      group('special cases', () {
        group('empty scopes', () {
          test('single', () {
            final emptyScope = Scope.example(key: 'empty');
            final tree = t.graph.treeForScope(
              scope: emptyScope,
              childScopeDepth: -1,
            );
            final dot = Graph.dot(graph: tree);
            writeDotFile(dot, '13');
            expectEmptyScope(dot, emptyScope);
          });

          test('multiple', () {
            final a = Scope.example(key: 'a');
            a.mockContent({
              'b': {'c': <String, dynamic>{}},
            });

            final b = a.findChildScope('b')!;
            final c = b.findChildScope('c')!;

            final tree = t.graph.treeForScope(scope: a, childScopeDepth: -1);
            final dot = Graph.dot(graph: tree);
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
            triangle.triangle.scm.flush();

            final tree = t.graph.treeForScope(
              scope: triangle.triangle,
              childScopeDepth: -1,
            );

            // Create dot
            final dot = Graph.dot(graph: tree);
            writeDotFile(dot, '15');

            // Check dot
            expectNodes(dot, triangle.allNodes);
            expectScopes(dot, triangle.allScopes);
            expectEdgeCount(dot, 3);
            expectEdge(dot, topNode, leftNode);
            expectEdge(dot, topNode, rightNode);
            expectEdge(dot, leftNode, rightNode);
          });

          test('sibling node as customer', () {
            final tree = t.graph.treeForNode(node: leftNode, customerDepth: 1);

            // Create dot
            final dot = Graph.dot(graph: tree);
            writeDotFile(dot, '16');
          });

          test('sibling node as supplier', () {
            final tree = t.graph.treeForNode(node: rightNode, supplierDepth: 1);

            // Create dot
            final dot = Graph.dot(graph: tree);
            writeDotFile(dot, '17');
          });
        });
      });
    });

    group('fixViewBox', () {
      test('should write width and height to the view box', () {
        const svg =
            '<svg width="98pt" height="103pt" viewBox="0.00 0.00 94.00 99.00"';
        final fixed = GraphToDot.fixSvgViewBox(svg);
        expect(fixed, contains('viewBox="0.00 0.00 98 103"'));
      });
    });
  });
}
