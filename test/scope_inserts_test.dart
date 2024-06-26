// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  late Scope scope;

  setUp(() {
    scope = Scope.example();
  });

  group('ScopeInsert', () {
    test('example', () {
      expect(ScopeInserts.example(), isNotNull);
    });
    group('inserts', () {
      group('addInsert(insert)', () {
        group('should throw', () {
          test('if the insert is already added', () {
            const insert = ScopeInserts(overrides: {}, key: 'insert');
            insert.instantiate(scope: scope);
            expect(
              () => insert.instantiate(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Insert already added.',
                      ),
                ),
              ),
            );
          });

          test('when there are multiple node inserts with the same key', () {
            final insert0 = ScopeInserts(
              key: 'insert0',
              overrides: {
                'node0': InsertBluePrint.example(key: 'key'),
                'node1': InsertBluePrint.example(key: 'key'),
              },
            );

            expect(
              () => insert0.instantiate(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Found multiple node inserts with key "key"',
                      ),
                ),
              ),
            );
          });
          test('when host nodes cannot be found', () {
            final insert = ScopeInserts(
              key: 'insert0',
              overrides: {
                'unknown0': InsertBluePrint.example(key: 'unknown'),
                'unknown1': InsertBluePrint.example(key: 'unknown1'),
              },
            );
            expect(
              () => insert.instantiate(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Host nodes not found: unknown0, unknown1',
                      ),
                ),
              ),
            );
          });

          test('when types of host nodes and insert nodes do not match', () {
            final scope = Scope.example();
            scope.mockContent({
              'node0': 'string',
            });

            const insert = ScopeInserts(
              key: 'insert0',
              overrides: {
                'node0':
                    InsertBluePrint<int>(key: 'insert0', initialProduct: 0),
              },
            );

            expect(
              () => insert.instantiate(scope: scope),
              throwsA(
                predicate<Error>(
                  (e) => e.toString().contains(
                        '\'Node<String>\' is not a subtype of type '
                        '\'Node<int>\' of \'host\'',
                      ),
                ),
              ),
            );
          });
        });

        test('should add the insert to the list of inserts', () {
          const insert = ScopeInserts(
            overrides: {},
            key: 'insert0',
          );
          insert.instantiate(scope: scope);
          expect(scope.inserts, [insert]);
        });

        test('should add the node inserts to their corresponding hosts', () {
          // Define an existing node and scope hierarchy
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'n0': 0,
              },
              'c': {
                'n1': 0,
              },
            },
          });

          // Get the two nodes we want to add inserts to
          final node0 = scope.findNode<int>('a.b.n0')!;
          final node1 = scope.findNode<int>('a.c.n1')!;

          // Define a node insert that modifies the two nodes
          final scopeInsert = ScopeInserts(
            key: 'insert0',
            overrides: {
              'b.n0': InsertBluePrint<int>(
                key: 'byTwo',
                initialProduct: 0,
                produce: (components, previousProduct) =>
                    (components.first as int) * 2,
              ),
              'a.c.n1': InsertBluePrint<int>(
                key: 'byThree',
                initialProduct: 0,
                produce: (components, previousProduct) =>
                    (components.first as int) * 3,
              ),
            },
          );

          // Add the insert to the scope
          scopeInsert.instantiate(scope: scope);

          // The inserts should have been added to the nodes
          expect(node0.inserts, hasLength(1));
          expect(node0.inserts.first.key, 'byTwo');
          expect(node1.inserts, hasLength(1));
          expect(node1.inserts.first.key, 'byThree');

          // Remove the insert from the scope
          scopeInsert.dispose(scope: scope);

          // The inserts should have been removed from the nodes
          expect(node0.inserts, isEmpty);
          expect(node1.inserts, isEmpty);
        });
      });

      group('removeInsert(insert)', () {
        group('should throw', () {
          test('if the insert is not added', () {
            const insert = ScopeInserts(
              key: 'insert0',
              overrides: {},
            );
            expect(
              () => insert.dispose(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Insert "insert0" not found.',
                      ),
                ),
              ),
            );
          });
        });

        test('should remove the insert from the list of inserts', () {
          const insert = ScopeInserts(
            key: 'insert0',
            overrides: {},
          );
          insert.instantiate(scope: scope);
          insert.dispose(scope: scope);
          expect(scope.inserts, isEmpty);
        });

        test('should remove the node inserts from it\'s hosts', () {
          // Is tested in addInsert()
        });
      });

      group('instantiate', () {
        test('should override build() nodes with nodes in overrides', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'node0': 0,
              },
            },
          });

          ExampleScopeInsert(
            overrides: {
              'node0': InsertBluePrint.example(key: 'insert0Override'),
            },
          ).instantiate(scope: scope);

          expect(scope.inserts, hasLength(1));
        });

        test('should add additional nodes with overrides', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'node0': 0,
              },
              'c': {
                'node1': 1,
              },
            },
          });

          final node0 = scope.findNode<int>('a.b.node0')!;
          final node1 = scope.findNode<int>('a.c.node1')!;

          ExampleScopeInsert(
            // Replace node1 by node1Override
            overrides: {
              'node1': InsertBluePrint.example(key: 'insert1Override'),
            },
          ).instantiate(scope: scope);

          expect(node0.inserts, hasLength(1));
          expect(node0.inserts.first.key, 'insert0');

          expect(node1.inserts, hasLength(1));
          expect(node1.inserts.first.key, 'insert1Override');
        });
      });
    });
  });
}
