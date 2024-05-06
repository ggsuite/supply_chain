// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'sample_nodes.dart';

void main() {
  late Node<int> node;

  setUp(() {
    Node.testRestIdCounter();
    Scope.testRestIdCounter();
    scope = Scope.example();

    node = scope.createNode(
      initialProduct: 0,
      produce: (node) {},
      name: 'Node',
    );
  });

  group('Scope', () {
    group('basic properties', () {
      test('example', () {
        expect(scope, isA<Scope>());
      });

      test('scm', () {
        expect(scope.scm, Scm.testInstance);
      });

      test('key', () {
        expect(scope.key, 'Example');
      });

      test('children', () {
        expect(scope.children, isEmpty);
      });
    });

    group('createNode(), addNode()', () {
      test('should create a node and set the scope and SCM correctly', () {
        expect(node.scope, scope);
        expect(node.scm, scope.scm);
      });

      test('should throw if a node with the same name already exists', () {
        expect(
          () => scope.createNode(
            initialProduct: 0,
            produce: (node) {},
            name: 'Node',
          ),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains('already exists'),
            ),
          ),
        );
      });

      test('should add the node to the scope\'s nodes', () {
        expect(scope.nodes, [node]);
      });
    });

    group('node.dispose(), removeNode()', () {
      test('should remove the node from the scope', () {
        expect(scope.nodes, isNotEmpty);
        node.dispose();
        expect(scope.nodes, isEmpty);
      });
    });

    group('createHierarchy()', () {
      test('should allow to create a hierarchy of scopes', () {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        root.createHierarchy();
        expect(root.nodes.map((n) => n.name), ['RootA', 'RootB']);
        for (var element in root.nodes) {
          element.produce();
        }
        expect(root.children.map((e) => e.key), ['ChildScopeA', 'ChildScopeB']);

        final childA = root.child('ChildScopeA')!;
        final childB = root.child('ChildScopeB')!;
        expect(childA.nodes.map((n) => n.name), ['ChildNodeA', 'ChildNodeB']);
        expect(childB.nodes.map((n) => n.name), ['ChildNodeA', 'ChildNodeB']);

        for (var element in childA.nodes) {
          element.produce();
        }

        for (var element in childB.nodes) {
          element.produce();
        }
      });
    });

    group('build', () {
      test('should return an empty array by default', () {
        expect(scope.build(), isEmpty);
      });
    });

    group('graph', () {
      test('should print a simple graph correctly', () {
        initSupplierProducerCustomer();
        createSimpleChain();
        final graph = scope.graph;
        expect(
          graph,
          'digraph unix { '
          'subgraph cluster_Example_0 '
          '{ label = "Example"; '
          'Node_0 [label="Node"]; '
          'Supplier_1 [label="Supplier"]; '
          'Producer_2 [label="Producer"]; '
          'Customer_3 [label="Customer"]; '
          '"Supplier_1" -> "Producer_2"; '
          '"Producer_2" -> "Customer_3"; }}',
        );
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
        final graph = scope.graph;
        expect(
          graph,
          'digraph unix { '
          'subgraph cluster_Example_0 { '
          'label = "Example";'
          ' Node_0 [label="Node"];'
          ' Key_1 [label="Key"];'
          ' Synth_2 [label="Synth"];'
          ' Audio_3 [label="Audio"];'
          ' Screen_4 [label="Screen"];'
          ' Grid_5 [label="Grid"]; '
          '"Key_1" -> "Synth_2";'
          ' "Key_1" -> "Screen_4";'
          ' "Synth_2" -> "Audio_3";'
          ' "Screen_4" -> "Grid_5";'
          ' }}',
        );
      });

      test('should print scopes correctly', () {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        root.createHierarchy();
        final graph = root.graph;
        expect(
          graph,
          'digraph unix { '
          'subgraph cluster_ExampleRoot_1 { '
          'label = "ExampleRoot"; subgraph cluster_ChildScopeA_2 { '
          'label = "ChildScopeA"; ChildNodeA_3 [label="ChildNodeA"]; '
          'ChildNodeB_4 [label="ChildNodeB"]; '
          '}subgraph cluster_ChildScopeB_3 '
          '{ label = "ChildScopeB"; '
          'ChildNodeA_5 [label="ChildNodeA"]; '
          'ChildNodeB_6 [label="ChildNodeB"]; '
          '}RootA_1 [label="RootA"]; '
          'RootB_2 [label="RootB"]; }}',
        );
      });
    });
  });
}
