// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('NodeBluePrint', () {
    group('example', () {
      test('with key', () {
        final bluePrint = NodeBluePrint.example(key: 'Node');
        expect(bluePrint.key, 'Node');
        expect(bluePrint.initialProduct, 0);
        expect(bluePrint.suppliers, ['Supplier']);
        expect(bluePrint.produce([], 0), 1);
      });

      test('without key', () {
        final bluePrint = NodeBluePrint.example();
        expect(bluePrint.key, 'Aaliyah');
        expect(bluePrint.initialProduct, 0);
        expect(bluePrint.suppliers, ['Supplier']);
        expect(bluePrint.produce([], 0), 1);
      });
    });

    group('check', () {
      test('asserts that key is not empty', () {
        expect(
          () => const NodeBluePrint<int>(
            key: '',
            initialProduct: 0,
            suppliers: [],
          ).check(),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              'The key must not be empty',
            ),
          ),
        );
      });

      test('asserts key being pascal case', () {
        expect(
          () => const NodeBluePrint<int>(
            key: 'helloWorld',
            initialProduct: 0,
            suppliers: [],
          ).check(),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              'The key must be in PascalCase',
            ),
          ),
        );
      });

      test('asserts that produce is provided if suppliers are not empty', () {
        expect(
          () => const NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: null,
          ).check(),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains(
                'If suppliers are not empty, '
                'a produce function must be provided',
              ),
            ),
          ),
        );
      });
    });
    group('operator==, hashCode', () {
      group('should return true', () {
        test('with same suppliers', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          expect(bluePrint1 == bluePrint2, true);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, true);
        });
      });

      group('should return false', () {
        test('when key is different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'Node2',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          expect(bluePrint1 == bluePrint2, false);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, false);
        });

        test('when initialProduct is different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 1,
            suppliers: ['Supplier'],
            produce: produce,
          );
          expect(bluePrint1 == bluePrint2, false);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, false);
        });

        test('when suppliers are different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier2'],
            produce: produce,
          );
          expect(bluePrint1 == bluePrint2, false);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, false);
        });

        test('when produce is different', () {
          int produce1(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;
          int produce2(List<dynamic> components, int previousProduct) =>
              previousProduct + 2;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce1,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce2,
          );
          expect(bluePrint1 == bluePrint2, false);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, false);
        });
      });
    });

    group('toString()', () {
      test('returns key', () {
        final bluePrint = NodeBluePrint.example(key: 'Aaliyah');
        expect(bluePrint.toString(), 'Aaliyah');
      });
    });
    group('findOrCreateNode(scope)', () {
      test('returns existing node', () {
        testSetNextKeyCounter(0);
        final bluePrint = NodeBluePrint.example();
        final scope = Scope.example();
        final node = Node<int>(
          bluePrint: bluePrint,
          scope: scope,
        );
        expect(bluePrint.instantiate(scope: scope), node);
      });

      test('creates new node', () {
        final scope = Scope.example();
        final node = Node<int>(
          bluePrint: NodeBluePrint.example(),
          scope: scope,
        );
        expect(
          NodeBluePrint.example(key: 'Node2').instantiate(scope: scope),
          isNot(node),
        );
      });
    });

    group('copyWith()', () {
      test('returns a new instance with the given values', () {
        final bluePrint = NodeBluePrint.example();
        final newBluePrint = bluePrint.copyWith(
          initialProduct: 1,
          key: 'Node2',
          suppliers: ['Supplier2'],
          produce: (components, previousProduct) => 2,
        );
        expect(newBluePrint.initialProduct, 1);
        expect(newBluePrint.key, 'Node2');
        expect(newBluePrint.suppliers, ['Supplier2']);
        expect(newBluePrint.produce([], 0), 2);
      });

      test('returns a new instance with the same values', () {
        final bluePrint = NodeBluePrint.example();
        final newBluePrint = bluePrint.copyWith();
        expect(newBluePrint.initialProduct, bluePrint.initialProduct);
        expect(newBluePrint.key, bluePrint.key);
        expect(newBluePrint.suppliers, bluePrint.suppliers);
        expect(newBluePrint.produce([], 0), 1);
      });
    });
  });

  group('doNothing', () {
    test('returns previousProduct', () {
      expect(doNothing([], 11), 11);
    });
  });
}
