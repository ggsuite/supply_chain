// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  late Scope scope;
  late Node<int> node;

  setUp(() {
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
  });
}
