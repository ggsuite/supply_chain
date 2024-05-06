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

    group('node.dispose()', () {
      test('should remove the node from the scope', () {
        expect(scope.nodes, isNotEmpty);
        node.dispose();
        expect(scope.nodes, isEmpty);
      });
    });
  });
}
