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
        testSetNextCounter(0);
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
  });

  group('doNothing', () {
    test('returns previousProduct', () {
      expect(doNothing([], 11), 11);
    });
  });
}
