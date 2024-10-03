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

  late Scope sSingle;
  late Scope sA;
  late Scope sB;

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

  late Node<int> single;
  late Node<int> a;
  late Node<int> b;

  setUp(() {
    disposed = Disposed.example;
    scm = disposed.scm;
    scope = Scope.example(scm: scm);
    scope.mockContent(
      {
        // .........................
        // Single node
        'sSingle': {
          'single': 0,
        },

        // .........................
        // Single connection a -> b
        'sA': {
          'a': 0,
        },
        'sB': {
          'b': NodeBluePrint.map(
            supplier: 'sA.a',
            toKey: 'b',
            initialProduct: 0,
          ),
        },

        // ...............................................
        // connection supplier -> intermediate -> customer
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
    sA = scope.findScope('sA')!;
    sSingle = scope.findScope('sSingle')!;

    i0 = scope.findScope('i0')!;
    i1 = scope.findScope('i1')!;
    i2 = scope.findScope('i2')!;
    sB = scope.findScope('sB')!;

    c0 = scope.findScope('c0')!;
    c1 = scope.findScope('c1')!;
    c2 = scope.findScope('c2')!;

    single = scope.findNode<int>('single')!;
    a = scope.findNode('sA.a')!;
    b = scope.findNode('sB.b')!;

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

    group('scenarios', () {
      group('single scope & node', () {
        group('dispose single node without customers and suppliers ', () {
          test('erases the node immediately', () {
            single.dispose();
            expect(single.isDisposed, isTrue);
            expect(single.isErased, isTrue);
            expect(disposed.nodes, isEmpty);
          });
        });

        group(
            'dispose scope containing single node '
            'without customers and suppliers', () {
          test('erases the scope and the node immediately', () {
            c2.dispose();
            expect(c2.isDisposed, isTrue);
            expect(c2.isErased, isTrue);
            expect(disposed.scopes, isEmpty);
            expect(customer.isDisposed, isTrue);
            expect(customer.isErased, isTrue);
          });
        });
      });

      group('single connection a -> b', () {
        group('dispose node a', () {
          test('does not erase b because a is supplier of b', () {
            a.dispose();
            expect(a.isDisposed, isTrue);
            expect(a.isErased, isFalse);
            expect(b.isDisposed, isFalse);
            expect(b.isErased, isFalse);
            expect(disposed.nodes, [a]);
          });
        });

        group('recreate node a', () {
          group('after disposing node a', () {
            test('should undispose containing scopeA', () {
              sA.dispose();
              expect(disposed.nodes, [a]);
              expect(disposed.scopes, [sA]);
              expect(sA.isDisposed, isTrue);
              a.bluePrint.instantiate(scope: sA);
              expect(sA.isDisposed, isFalse);
              expect(disposed.nodes, isEmpty);
              expect(disposed.scopes, isEmpty);
            });
          });
        });
        group('dispose node b', () {
          test('does erase b because b has no customers', () {
            b.dispose();
            expect(b.isDisposed, isTrue);
            expect(b.isErased, isTrue);
            expect(disposed.nodes, isEmpty);
          });

          test('does not erase the containing scope sB', () {
            b.dispose();
            expect(sB.isDisposed, isFalse);
          });
        });

        group('dispose scope sA', () {
          group('will dispose but not erase both scope sA as well node a', () {
            test('because a has customers', () {
              sA.dispose();
              expect(sA.isDisposed, isTrue);
              expect(sA.isErased, isFalse);
              expect(a.isDisposed, isTrue);
              expect(a.isErased, isFalse);
              expect(disposed.scopes, [sA]);
              expect(disposed.nodes, [a]);
            });
          });

          group('and recreate scope node a', () {
            test(
                'should undispose scope sA '
                'and remove old node a from disposed nodes', () {
              sA.dispose();
              expect(disposed.scopes, [sA]);
              expect(disposed.nodes, [a]);
              expect(sA.isDisposed, isTrue);
              a.bluePrint.instantiate(scope: sA);
              expect(sA.isDisposed, isFalse);
              expect(disposed.scopes, isEmpty);
              expect(disposed.nodes, isEmpty);
            });
          });
        });

        group('dispose scope sB', () {
          group('should erase both scope sB as well node b', () {
            test('because b has no customers', () {
              sB.dispose();
              expect(sB.isDisposed, isTrue);
              expect(sB.isErased, isTrue);
              expect(b.isDisposed, isTrue);
              expect(b.isErased, isTrue);
              expect(disposed.scopes, isEmpty);
              expect(disposed.nodes, isEmpty);
            });
          });
        });
      });

      group('connection supplier -> intermediate -> customer', () {
        group('dispose supplier', () {
          test(
              'does not erase supplier '
              'because supplier is supplier of intermediate', () {
            supplier.dispose();
            expect(supplier.isDisposed, isTrue);
            expect(supplier.isErased, isFalse);
            expect(intermediate.isDisposed, isFalse);
            expect(intermediate.isErased, isFalse);
            expect(disposed.nodes, [supplier]);
          });
        });

        group('recreate supplier after disposing', () {
          test('should move the customers from old to new supplier', () {
            supplier.dispose();
            expect(intermediate.suppliers.first, supplier);
            final newSupplier = supplier.bluePrint.instantiate(scope: s2);
            expect(intermediate.suppliers.first, newSupplier);
          });
        });

        group('dispose intermediate', () {
          test(
              'does not erase customer '
              'because intermediate is supplier of customer', () {
            intermediate.dispose();
            expect(intermediate.isDisposed, isTrue);
            expect(intermediate.isErased, isFalse);
            expect(customer.isDisposed, isFalse);
            expect(customer.isErased, isFalse);
            expect(disposed.nodes, [intermediate]);
          });
        });

        group('recreate intermediate after disposing', () {
          test('should move the customers from old to new intermediate', () {
            final bluePrint = intermediate.bluePrint;
            intermediate.dispose();
            expect(customer.suppliers.first, intermediate);
            final newIntermediate = bluePrint.instantiate(scope: i2);
            scm.testFlushTasks();
            expect(customer.suppliers.first, newIntermediate);
            expect(newIntermediate.suppliers.first, supplier);
          });
        });

        group('dispose customer', () {
          test('does erase customer because customer has no customers', () {
            customer.dispose();
            expect(customer.isDisposed, isTrue);
            expect(customer.isErased, isTrue);
            expect(disposed.nodes, isEmpty);
          });
        });
      });

      group('deletion of scopes that are referenced in scope blue prints', () {
        late Scope panel;
        late Node<int> cornerCount;

        setUp(
          () {
            // Create a panels scope
            // The scope contains a number of corners node
            panel = Scope.example(key: 'panel');
            cornerCount =
                const NodeBluePrint<int>(key: 'cornerCount', initialProduct: 2)
                    .instantiate(scope: panel);

            // Create a first builder that adds a corners scope to the panel
            // scope containing one corner scope and node for each corner.
            final cornersBuilder = ScBuilderBluePrint(
              key: 'corners',
              shouldStopProcessingAfter: (scope) => scope == panel,
              needsUpdateSuppliers: ['cornerCount'],
              needsUpdate: ({required components, required hostScope}) {
                // Remove old corners scope
                hostScope.child('corners')?.dispose();

                // Add a new corners scope
                final cornersScope = const ScopeBluePrint(key: 'corners')
                    .instantiate(hostScope: hostScope);

                // Add a subscope and a node for each corner
                final [int cornerCount] = components;
                for (int i = 0; i < cornerCount; i++) {
                  final cornerScope =
                      ScopeBluePrint(key: 'corner$i').instantiate(
                    hostScope: cornersScope,
                  );
                  NodeBluePrint<int>(key: 'cValue', initialProduct: i)
                      .instantiate(scope: cornerScope);
                }
              },
            )..instantiate(scope: panel);

            // Create a second builder that adds a faces scope to the panel
            // scope containing one face for each corner.
            // Each face has a node referencing to the corner node.
            final panelBuilder = ScBuilderBluePrint(
              key: 'panel',
              shouldStopProcessingAfter: (scope) => scope == panel,
              needsUpdateSuppliers: ['cornerCount'],
              needsUpdate: ({required components, required hostScope}) {
                // Remove old faces scope
                hostScope.child('faces')?.dispose();

                // Add a new faces scope
                final facesScope = const ScopeBluePrint(key: 'faces')
                    .instantiate(hostScope: hostScope);

                // Add a subscope and a node for each face
                final [int cornerCount] = components;
                for (int i = 0; i < cornerCount; i++) {
                  final faceScope = ScopeBluePrint(key: 'face$i').instantiate(
                    hostScope: facesScope,
                  );
                  NodeBluePrint<int>.map(
                    supplier: 'corners.corner$i.cValue',
                    toKey: 'fValue',
                    initialProduct: 0,
                  ).instantiate(scope: faceScope);
                }
              },
            )..instantiate(scope: panel);

            panel.scm.testFlushTasks();
          },
        );

        test('should work', () {
          // Check the initial configuration
          expect(
            panel.findNode<int>('panel.corners.corner0.cValue')!.product,
            0,
          );
          expect(
            panel.findNode<int>('panel.corners.corner1.cValue')!.product,
            1,
          );

          expect(panel.findNode<int>('panel.faces.face0.fValue')!.product, 0);
          expect(panel.findNode<int>('panel.faces.face1.fValue')!.product, 1);

          // Decrease the number of corners.
          cornerCount.product = 1;
          panel.scm.testFlushTasks();
          expect(
            panel.findNode<int>('panel.corners.corner0.cValue'),
            isNotNull,
          );
        });
      });
    });
  });
}
