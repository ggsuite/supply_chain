// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final butterFly = ButterFlyExample(withScopes: true);

  group('Graph', () {
    group('writeScopeToFile(scope)', () {
      group('default', () {
        test('should write all nodes of the current scope', () async {
          await const Graph().writeScopeToFile(
            butterFly.x.scope,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 0,
            customerDepth: 0,
            'test/graphs/graph_test/scope_nodes_.dot',
          );
        });
      });
    });

    group('writeNodeToFile(node)', () {
      group('with suppliers only', () {
        group('- supplier depth 0', () {
          test('with parent scope depth 0', () async {
            await const Graph().writeNodeToFile(
              butterFly.x,
              childScopeDepth: 0,
              parentScopeDepth: 0,
              supplierDepth: 0,
              customerDepth: 0,
              'test/graphs/graph_test/single_node_with_supplier_depth_0__parent_scope_depth_0.dot',
            );
          });

          test('with parent scope depth 0', () async {
            await const Graph().writeNodeToFile(
              butterFly.x,
              childScopeDepth: 0,
              parentScopeDepth: 2,
              supplierDepth: 0,
              customerDepth: 0,
              'test/graphs/graph_test/single_node_with_supplier_depth_0__parent_scope_depth_2.dot',
            );
          });
        });

        test('- supplier depth 1', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 1,
            customerDepth: 0,
            'test/graphs/graph_test/single_node_with_supplier_depth_1.dot',
          );
        });

        test('- supplier depth 2', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 2,
            customerDepth: 0,
            'test/graphs/graph_test/single_node_with_supplier_depth_2.dot',
          );
        });

        test('- supplier depth 10', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 10,
            customerDepth: 0,
            'test/graphs/graph_test/single_node_with_supplier_depth_10.dot',
          );
        });
      });

      group('with customers only', () {
        test('- customer depth 0', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 0,
            customerDepth: 0,
            'test/graphs/graph_test/single_node_with_customer_depth_0.dot',
          );
        });

        test('- customer depth 1', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 0,
            customerDepth: 1,
            'test/graphs/graph_test/single_node_with_customer_depth_1.dot',
          );
        });

        test('- customer depth 2', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 0,
            customerDepth: 2,
            'test/graphs/graph_test/single_node_with_customer_depth_2.dot',
          );
        });

        test('- customer depth 10', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 0,
            customerDepth: 10,
            'test/graphs/graph_test/single_node_with_customer_depth_10.dot',
          );
        });
      });

      group('with customers and suppliers', () {
        test('- customer and supplier depth 2', () async {
          await const Graph().writeNodeToFile(
            butterFly.x,
            childScopeDepth: 0,
            parentScopeDepth: 0,
            supplierDepth: 2,
            customerDepth: 2,
            'test/graphs/graph_test/single_node_with_customer_and_supplier_depth_2.dot',
          );
        });
      });
    });

    group('fromNode()', () {});

    group('fromScope()', () {
      test('should write all nodes of the current scope', () {
        final graph = const Graph().fromScope(
          butterFly.x.scope,
          childScopeDepth: 0,
          parentScopeDepth: 0,
          supplierDepth: 0,
          customerDepth: 0,
        );

        expect(graph, isNotNull);
      });
    });

    group('fromNode()', () {
      test('should write one node', () {
        final graph = const Graph().fromNode(
          butterFly.x,
          childScopeDepth: 0,
          parentScopeDepth: 0,
          supplierDepth: 0,
          customerDepth: 0,
        );

        expect(graph, isNotNull);
      });
    });
  });
}
