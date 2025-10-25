// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('Insert', () {
    group('example', () {
      test('should work', () {
        final insert = Insert.example(key: 'insert');

        final host = insert.host;

        expect(host.inserts, [insert]);
        expect(insert.input, host);
        expect(insert.output, host);
        expect(insert, isNotNull);
      });
    });

    test('should add and remove inserts correctly', () {
      // Create insert2
      final host = Node.example(key: 'host');
      final scope = host.scope;
      final scm = host.scope.scm;

      final customer0 = host.bluePrint
          .forwardTo('customer0')
          .instantiate(scope: scope);

      final customer1 = host.bluePrint
          .forwardTo('customer1')
          .instantiate(scope: scope);

      // Check the initial product
      scm.flush();
      expect(host.product, 1);
      expect(customer0.product, 1);
      expect(customer1.product, 1);

      // Insert a first insert 2, adding 2 to the original product
      final insert2 = Insert.example(
        key: 'insert2',
        produce: (components, previousProduct, node) => previousProduct + 2,
        host: host,
      );

      scm.flush();
      expect(host.inserts, [insert2]);
      expect(insert2.input, host);
      expect(insert2.output, host);
      expect(insert2, isNotNull);
      expect(host.originalProduct, 1);
      expect(host.product, 1 + 2);
      expect(customer0.product, 1 + 2);
      expect(customer1.product, 1 + 2);

      // Add insert0 before insert2, multiplying by 3
      final insert0 = Insert.example(
        key: 'insert0',
        produce: (components, previousProduct, node) => previousProduct * 3,
        host: host,
        index: 0,
      );
      scm.flush();

      expect(host.inserts, [insert0, insert2]);
      expect(insert0.input, host);
      expect(insert0.output, insert2);
      expect(host.originalProduct, 1);
      expect(host.product, 1 * 3 + 2);
      expect(customer0.product, 1 * 3 + 2);
      expect(customer1.product, 1 * 3 + 2);

      // Add insert1 between insert0 and insert2
      // The insert multiplies the previous result by 4
      final insert1 = Insert.example(
        key: 'insert1',
        produce: (components, previousProduct, node) => previousProduct * 4,
        host: host,
        index: 1,
      );
      scm.flush();
      expect(host.inserts, [insert0, insert1, insert2]);
      expect(insert0.input, host);
      expect(insert0.output, insert1);
      expect(insert1.input, insert0);
      expect(insert1.output, insert2);
      expect(insert2.input, insert1);
      expect(insert2.output, host);
      expect(host.originalProduct, 1);
      expect(host.product, (1 * 3 * 4) + 2);
      expect(customer0.product, (1 * 3 * 4) + 2);
      expect(customer1.product, (1 * 3 * 4) + 2);

      // Add insert3 after insert2 adding ten
      final insert3 = Insert.example(
        key: 'insert3',
        produce: (components, previousProduct, node) => previousProduct + 10,
        host: host,
        index: 3,
      );
      scm.flush();
      expect(host.inserts, [insert0, insert1, insert2, insert3]);
      expect(insert0.input, host);
      expect(insert0.output, insert1);
      expect(insert1.input, insert0);
      expect(insert1.output, insert2);
      expect(insert2.input, insert1);
      expect(insert2.output, insert3);
      expect(insert3.input, insert2);
      expect(insert3.output, host);
      expect(host.originalProduct, 1);
      expect(host.product, (1 * 3 * 4) + 2 + 10);
      expect(customer0.product, (1 * 3 * 4) + 2 + 10);
      expect(customer1.product, (1 * 3 * 4) + 2 + 10);

      // Remove insert node in the middle
      insert1.dispose();
      scm.flush();
      expect(host.inserts, [insert0, insert2, insert3]);
      expect(insert0.input, host);
      expect(insert0.output, insert2);
      expect(insert2.input, insert0);
      expect(insert2.output, insert3);
      expect(insert3.input, insert2);
      expect(insert3.output, host);
      expect(host.originalProduct, 1);
      expect(host.product, (1 * 3) + 2 + 10);
      expect(customer0.product, (1 * 3) + 2 + 10);
      expect(customer1.product, (1 * 3) + 2 + 10);

      // Remove first insert node
      insert0.dispose();
      scm.flush();
      expect(host.inserts, [insert2, insert3]);
      expect(insert2.input, host);
      expect(insert2.output, insert3);
      expect(insert3.input, insert2);
      expect(insert3.output, host);
      expect(host.originalProduct, 1);
      expect(host.product, 1 + 2 + 10);
      expect(customer0.product, 1 + 2 + 10);
      expect(customer1.product, 1 + 2 + 10);

      // Remove last insert node
      insert3.dispose();
      scm.flush();
      expect(host.inserts, [insert2]);
      expect(insert2.input, host);
      expect(insert2.output, host);
      expect(host.originalProduct, 1);
      expect(host.product, 1 + 2);
      expect(customer0.product, 1 + 2);
      expect(customer1.product, 1 + 2);

      // Remove last remaining insert node
      insert2.dispose();
      scm.flush();
      expect(host.inserts, <Insert<dynamic>>[]);
      expect(host.originalProduct, 1);
      expect(host.product, 1);
      expect(customer0.product, 1);
      expect(customer1.product, 1);
    });

    group('should apply inserts correctly', () {
      test('with one insert', () {
        final scope = Scope.example();
        final scm = scope.scm;

        final host = const NodeBluePrint(
          key: 'host',
          initialProduct: 1,
        ).instantiate(scope: scope);

        final insert = NodeBluePrint(
          key: 'insert0',
          initialProduct: 0,
          produce: (components, previousProduct, node) {
            return previousProduct * 10;
          },
        ).instantiateAsInsert(host: host);

        // The product of the host should be multiplied by 10
        scm.flush();
        expect(insert.product, 10);
        expect(host.originalProduct, 1);
        expect(host.product, 10);

        // Change the host product
        host.product = 2;
        scm.flush();
        expect(insert.product, 20);
        expect(host.originalProduct, 2);
        expect(host.product, 20);
      });

      test('with two inserts', () {
        final scope = Scope.example();
        final scm = scope.scm;
        final host = const NodeBluePrint(
          key: 'host',
          initialProduct: 1,
        ).instantiate(scope: scope);

        final insert0 = NodeBluePrint(
          key: 'insert0',
          initialProduct: 0,
          produce: (components, previousProduct, node) {
            return previousProduct * 10;
          },
        ).instantiateAsInsert(host: host);

        final insert1 = NodeBluePrint(
          key: 'insert1',
          initialProduct: 0,
          produce: (components, previousProduct, node) {
            return previousProduct * 10;
          },
        ).instantiateAsInsert(host: host);

        // The product of the host should be multiplied by 10
        scm.flush();
        expect(insert0.product, 10);
        expect(insert1.product, 100);
        expect(host.originalProduct, 1);
        expect(host.product, 100);

        // Change the host product
        host.product = 2;
        scm.flush();
        expect(insert0.product, 20);
        expect(insert1.product, 200);
        expect(host.originalProduct, 2);
        expect(host.product, 200);
      });

      test('with a insert that has suppliers', () {
        final scope = Scope.example();
        final scm = scope.scm;

        // Create a host node
        final host = const NodeBluePrint(
          key: 'host',
          initialProduct: 1,
        ).instantiate(scope: scope);

        // Add a customer to the host node
        final customer = host.bluePrint
            .forwardTo('customer')
            .instantiate(scope: scope);

        // Create a supplier that delivers a factor
        final factor = const NodeBluePrint(
          key: 'factor',
          initialProduct: 10,
        ).instantiate(scope: scope);

        // Create a insert that multiplies the product with the factor
        final insert0 = NodeBluePrint(
          key: 'insert0',
          initialProduct: 0,
          suppliers: ['factor'],
          produce: (components, previousProduct, node) {
            final factor = components.first as int;
            return previousProduct * factor;
          },
        ).instantiateAsInsert(host: host);

        // Initially the product of the host should be multiplied by 10
        // because the factor is 10
        scm.flush();
        expect(host.customers, [customer]);
        expect(insert0.product, 10);
        expect(host.originalProduct, 1);
        expect(host.product, 10);
        expect(customer.product, 10);

        // Change the host's original product
        host.product = 2;
        scm.flush();
        expect(insert0.product, 20);
        expect(host.originalProduct, 2);
        expect(host.product, 20);
        expect(customer.product, 20);

        // Change the factor which will modify the way, the insert calculates
        factor.product = 100;
        scm.flush();
        expect(insert0.product, 200);
        expect(host.originalProduct, 2);
        expect(host.product, 200);
        expect(customer.product, 200);
      });
    });

    group('should throw', () {
      test('when index is too big', () {
        final host = Node.example();
        NodeBluePrint.example(key: 'insert0').instantiateAsInsert(host: host);

        expect(
          () => NodeBluePrint.example(
            key: 'insert1',
          ).instantiateAsInsert(host: host, index: 2),
          throwsA(
            isA<ArgumentError>().having(
              (p0) {
                return p0.message;
              },
              'message',
              'Insert index 2 is out of range.',
            ),
          ),
        );
      });
      test('when index is too small', () {
        final host = Node.example();

        expect(
          () => NodeBluePrint.example(
            key: 'insert0',
          ).instantiateAsInsert(host: host, index: -1),
          throwsA(
            isA<ArgumentError>().having(
              (p0) {
                return p0.message;
              },
              'message',
              'Insert index -1 is out of range.',
            ),
          ),
        );
      });
    });
  });
}
