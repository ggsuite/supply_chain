// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Todo: Remove when unit tests are complete
// ignore_for_file: unused_local_variable

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  late Disposed disposed;
  late Scm scm;
  late Scope scope;

  late Scope s0;
  late Scope s1;
  late Scope s2;

  late Scope i0;
  late Scope i1;
  late Scope i2;

  late Scope c0;
  late Scope c1;
  late Scope c2;

  late Node<int> supplier;
  late Node<int> intermediate;
  late Node<int> customer;

  setUp(() {
    disposed = Disposed.example;
    scm = disposed.scm;
    scope = Scope.example(scm: scm);
    scope.mockContent(
      {
        // Create a supplier node
        's0': {
          's1': {
            's2': {
              'supplier': 0,
            },
          },
        },

        // Create a intermeidate node with a supplier
        // forwarding its product to the customer node.
        'i0': {
          'i1': {
            'i2': {
              'intermediate': NodeBluePrint.map(
                supplier: 's0.s1.s2.supplier',
                toKey: 'intermediate',
                initialProduct: 0,
              ),
            },
          },
        },

        // Create a customer node that receives the product from the
        // intermediate node.
        'c0': {
          'c1': {
            'c2': {
              'customer': NodeBluePrint.map(
                supplier: 'i0.i1.i2.intermediate',
                toKey: 'customer',
                initialProduct: 0,
              ),
            },
          },
        },
      },
    );

    scm.testFlushTasks();
    s0 = scope.findScope('s0')!;
    s1 = scope.findScope('s1')!;
    s2 = scope.findScope('s2')!;

    i0 = scope.findScope('i0')!;
    i1 = scope.findScope('i1')!;
    i2 = scope.findScope('i2')!;

    c0 = scope.findScope('c0')!;
    c1 = scope.findScope('c1')!;
    c2 = scope.findScope('c2')!;

    supplier = s2.findNode('supplier')!;
    intermediate = i2.findNode('intermediate')!;
    customer = c2.findNode('customer')!;

    expect(supplier.suppliers, isEmpty);
    expect(supplier.customers, isNotEmpty);
    expect(intermediate.suppliers, isNotEmpty);
    expect(intermediate.customers, isNotEmpty);
    expect(customer.customers, isEmpty);
    expect(customer.suppliers, isNotEmpty);
  });

  group('Disposed', () {
    group('scm', () {
      test('should return related supply chain manager', () {
        expect(disposed.scm, isA<Scm>());
      });
    });

    group('scopes', () {
      test('should return the disposed scopes', () {
        expect(disposed.scopes, isA<Iterable<Scope>>());
        expect(disposed.scopes, isEmpty);
      });
    });

    group('nodes', () {
      test('should return the disposed nodes', () {
        expect(disposed.nodes, isA<Iterable<Node<dynamic>>>());
        expect(disposed.nodes, isEmpty);
      });
    });

    group('addNode', () {
      test('should be called when a node is disposed', () {
        // Dispose the supplier node
        // It should be added to disposed.nodes
        supplier.dispose();
        expect(supplier.isDisposed, isTrue);
        expect(supplier.isErased, isFalse);
        expect(disposed.nodes, [supplier]);
      });
    });

    group('removeNode', () {
      test('should be called when a node is erased', () {
        // Dispose the supplier node
        // It should be added to disposed.nodes
        supplier.dispose();
        expect(disposed.nodes, [supplier]);

        // Dispose intermediate and customer
        // supplier will be erased too and removed from disposed nodes
        intermediate.dispose();
        customer.dispose();

        // supplier should be removed from disposed.nodes
        expect(disposed.nodes, isEmpty);
      });
    });

    group('addScope', () {
      test('should be called when a scope is disposed', () {
        // Dispose the supplier scope.
        // The scope will not be erased because
        // supplier has still customers
        s2.dispose();

        // The scope should be added to disposed.scopes
        expect(disposed.scopes, [s2]);
      });
    });

    group('removeScope', () {
      test('should be called when a scope is erased', () {
        // Dispose the supplier scope.
        // The scope will not be erased because
        // supplier has still customers
        s2.dispose();

        // The scope should be added to disposed.scopes
        expect(disposed.scopes, [s2]);

        // Dispose intermediate and customer
        // supplier will be erased too and removed from disposed nodes
        intermediate.dispose();
        customer.dispose();

        // supplier scope should be removed from disposed.scopes
        expect(disposed.scopes, isEmpty);
      });
      test('should be called when a scope is undisposed', () {
        // Dispose the supplier scope.
        // The scope will not be erased because
        // supplier has still customers
        s2.dispose();

        // The scope should be added to disposed.scopes
        expect(disposed.scopes, [s2]);

        // Readd a fresh node to s2 which will undispose the scope
        supplier.bluePrint.instantiate(scope: supplier.scope);

        // supplier scope should be removed from disposed.scopes
        expect(disposed.scopes, isEmpty);
      });
    });
  });
}
