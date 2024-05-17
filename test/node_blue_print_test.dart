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
        final nodeConfig = NodeBluePrint.example(key: 'Node');
        expect(nodeConfig.key, 'Node');
        expect(nodeConfig.initialProduct, 0);
        expect(nodeConfig.suppliers, ['Supplier']);
        expect(nodeConfig.produce([], 0), 1);
      });

      test('without key', () {
        final nodeConfig = NodeBluePrint.example();
        expect(nodeConfig.key, 'Aaliyah');
        expect(nodeConfig.initialProduct, 0);
        expect(nodeConfig.suppliers, ['Supplier']);
        expect(nodeConfig.produce([], 0), 1);
      });
    });

    group('operator==, hashCode', () {
      group('should return true', () {
        test('with same suppliers', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final nodeConfig1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final nodeConfig2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          expect(nodeConfig1 == nodeConfig2, true);
          expect(nodeConfig1.hashCode == nodeConfig2.hashCode, true);
        });
      });

      group('should return false', () {
        test('when key is different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final nodeConfig1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final nodeConfig2 = NodeBluePrint<int>(
            key: 'Node2',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          expect(nodeConfig1 == nodeConfig2, false);
          expect(nodeConfig1.hashCode == nodeConfig2.hashCode, false);
        });

        test('when initialProduct is different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final nodeConfig1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final nodeConfig2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 1,
            suppliers: ['Supplier'],
            produce: produce,
          );
          expect(nodeConfig1 == nodeConfig2, false);
          expect(nodeConfig1.hashCode == nodeConfig2.hashCode, false);
        });

        test('when suppliers are different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final nodeConfig1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce,
          );
          final nodeConfig2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier2'],
            produce: produce,
          );
          expect(nodeConfig1 == nodeConfig2, false);
          expect(nodeConfig1.hashCode == nodeConfig2.hashCode, false);
        });

        test('when produce is different', () {
          int produce1(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;
          int produce2(List<dynamic> components, int previousProduct) =>
              previousProduct + 2;

          final nodeConfig1 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce1,
          );
          final nodeConfig2 = NodeBluePrint<int>(
            key: 'Node',
            initialProduct: 0,
            suppliers: ['Supplier'],
            produce: produce2,
          );
          expect(nodeConfig1 == nodeConfig2, false);
          expect(nodeConfig1.hashCode == nodeConfig2.hashCode, false);
        });
      });
    });
  });

  group('doNothing', () {
    test('returns previousProduct', () {
      expect(doNothing([], 11), 11);
    });
  });
}
