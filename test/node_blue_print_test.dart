// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'my_type.dart';

void main() {
  group('NodeBluePrint', () {
    group('nbp', () {
      test('should create a node blue print', () {
        int produce(List<dynamic> components, int previous) => 0;
        final bp = nbp<int>(from: ['a'], to: 'b', init: 0, produce: produce);
        expect(bp.key, 'b');
        expect(bp.initialProduct, 0);
        expect(bp.suppliers, ['a']);
        expect(bp.produce, produce);
      });
    });
    group('example', () {
      test('with key', () {
        final bluePrint = NodeBluePrint.example(key: 'node');
        expect(bluePrint.key, 'node');
        expect(bluePrint.initialProduct, 0);
        expect(bluePrint.suppliers, <NodeBluePrint<dynamic>>[]);
        expect(bluePrint.produce([], 0), 1);
      });

      test('without key', () {
        final bluePrint = NodeBluePrint.example();
        expect(bluePrint.key, 'aaliyah');
        expect(bluePrint.initialProduct, 0);
        expect(bluePrint.suppliers, <NodeBluePrint<dynamic>>[]);
        expect(bluePrint.produce([], 0), 1);
      });
    });

    group('map(key, supplier, initialProduct)', () {
      test('returns a new instance', () {
        final bluePrint = NodeBluePrint<int>.map(
          supplier: 'supplier',
          toKey: 'node',
          initialProduct: 123,
        );

        expect(bluePrint.key, 'node');
        expect(bluePrint.initialProduct, 123);
        expect(bluePrint.suppliers, ['supplier']);

        /// Should just forward the original supplier's value
        expect(bluePrint.produce([456], 0), 456);
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

      test('asserts key being camel case', () {
        expect(
          () => const NodeBluePrint<int>(
            key: 'HelloWorld',
            initialProduct: 0,
            suppliers: [],
          ).check(),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              'The key must be in CamelCase',
            ),
          ),
        );
      });

      test('throws, when multiple suppliers have the same path', () {
        final bluePrint = NodeBluePrint<int>(
          key: 'node',
          initialProduct: 0,
          suppliers: ['supplier', 'supplier'],
          produce: (components, previousProduct) {
            return 0;
          },
        );

        expect(
          () => bluePrint.check(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'The suppliers must be unique.',
            ),
          ),
        );
      });
    });
    group('equals, hashCode', () {
      group('should return true', () {
        test('with same suppliers', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce,
          );
          expect(bluePrint1.equals(bluePrint2), true);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, true);
        });
      });

      group('should return false', () {
        test('when key is different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'node2',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce,
          );
          expect(bluePrint1 == bluePrint2, false);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, false);
        });

        test('when initialProduct is different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 1,
            suppliers: ['supplier'],
            produce: produce,
          );
          expect(bluePrint1 == bluePrint2, false);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, false);
        });

        test('when suppliers are different', () {
          int produce(List<dynamic> components, int previousProduct) =>
              previousProduct + 1;

          final bluePrint1 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier2'],
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
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce1,
          );
          final bluePrint2 = NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: produce2,
          );
          expect(bluePrint1 == bluePrint2, false);
          expect(bluePrint1.hashCode == bluePrint2.hashCode, false);
        });
      });
    });

    group('toString()', () {
      test('returns key', () {
        final bluePrint = NodeBluePrint.example(key: 'aaliyah');
        expect(bluePrint.toString(), 'aaliyah');
      });
    });

    group('toJson(val)', () {
      group('returns the value, if it has a trivial type', () {
        group('with type', () {
          test('int', () {
            expect(
              const NodeBluePrint<int>(key: 'k', initialProduct: 0).toJson(10),
              10,
            );
          });

          test('double', () {
            expect(
              const NodeBluePrint<double>(
                key: 'k',
                initialProduct: 0.0,
              ).toJson(5.1),
              5.1,
            );
          });

          test('String', () {
            expect(
              const NodeBluePrint<String>(
                key: 'k',
                initialProduct: 'Hello',
              ).toJson('World'),
              'World',
            );
          });

          test('bool', () {
            expect(
              const NodeBluePrint<bool>(
                key: 'k',
                initialProduct: true,
              ).toJson(false),
              false,
            );
          });

          test('Map', () {
            expect(
              const NodeBluePrint<Map<String, dynamic>>(
                key: 'k',
                initialProduct: {'hello': 'world'},
              ).toJson({'hello': 'berlin'}),
              {'hello': 'berlin'},
            );
          });

          test('List', () {
            expect(
              const NodeBluePrint<List<int>>(
                key: 'k',
                initialProduct: [5, 6],
              ).toJson([7, 8]),
              [7, 8],
            );
          });

          group('MyType', () {
            group('throws', () {
              test('when MyType has no toJson(...) method', () {
                var message = <String>[];

                try {
                  const NodeBluePrint<MyTypNoJson>(
                    key: 'k',
                    initialProduct: MyTypNoJson(10),
                  ).toJson(const MyTypNoJson(11));
                } catch (e) {
                  message = e.toString().split('\n');
                }

                expect(message, [
                  'Exception: No serializer registered for type '
                      'MyTypNoJson.',
                  'Either:',
                  ' - implement MyTypNoJson.toJson or',
                  ' - register a json serializer using '
                      'NodeBluePrint.addJsonSerializer'
                      '<MyTypNoJson>(serializer)',
                ]);
              });
            });

            group('converts to json', () {
              group('via toJson()', () {
                test('with Map<String, dynamic>', () {
                  expect(
                    const NodeBluePrint<MyType>(
                      key: 'k',
                      initialProduct: MyType(0),
                    ).toJson(const MyType(13)),
                    {'x': 13},
                  );
                });

                test('with List<int>', () {
                  expect(
                    const NodeBluePrint<List<int>>(
                      key: 'k',
                      initialProduct: [0],
                    ).toJson([1, 2, 3]),
                    [1, 2, 3],
                  );
                });
              });

              test('registered json parser', () {
                NodeBluePrint.addJsonSerializer<MyTypNoJson>((data) {
                  return {'k': data.x};
                });

                expect(
                  const NodeBluePrint<MyTypNoJson>(
                    key: 'k',
                    initialProduct: MyTypNoJson(0),
                  ).toJson(const MyTypNoJson(13)),
                  {'k': 13},
                );
              });
            });
          });
        });
      });
    });

    group('fromJson(val)', () {
      group('returns value itself if the type of the value matches T', () {
        test('int', () {
          expect(
            const NodeBluePrint<int>(key: 'k', initialProduct: 0).fromJson(10),
            10,
          );
        });
        test('double', () {
          expect(
            const NodeBluePrint<double>(
              key: 'k',
              initialProduct: 0.0,
            ).fromJson(5.1),
            5.1,
          );
        });
        test('String', () {
          expect(
            const NodeBluePrint<String>(
              key: 'k',
              initialProduct: 'Hello',
            ).fromJson('World'),
            'World',
          );
        });
        test('bool', () {
          expect(
            const NodeBluePrint<bool>(
              key: 'k',
              initialProduct: true,
            ).fromJson(false),
            false,
          );
        });
        test('T', () {
          const val = MyType(13);
          expect(
            const NodeBluePrint<MyType>(
              key: 'k',
              initialProduct: MyType(0),
            ).fromJson(val),
            same(val),
          );
        });

        test('List', () {
          expect(
            const NodeBluePrint<List<int>>(
              key: 'k',
              initialProduct: [5, 6],
            ).fromJson([7, 8]),
            [7, 8],
          );
        });
      });

      group('parses json on custom classes', () {
        test('Map', () {
          NodeBluePrint.addJsonParser(MyType.fromJson);

          expect(
            const NodeBluePrint<MyType>(
              key: 'k',
              initialProduct: MyType(0),
            ).fromJson({'x': 11}).x,
            11,
          );
        });
      });

      group('throws', () {
        test('when the value is not either a primitive type or a Map', () {
          var message = <String>[];

          try {
            const NodeBluePrint<MyTypNoJson>(
              key: 'k',
              initialProduct: MyTypNoJson(0),
            ).fromJson(DateTime(0));
          } catch (e) {
            message = e.toString().split('\n');
          }

          expect(message, [
            'Exception: Value "0000-01-01 00:00:00.000" is of type DateTime.',
            'But it must be either a primitive or a map.',
          ]);
        });

        test('when no json parser is registered for the type', () {
          expect(
            () => const NodeBluePrint<MyTypNoJson>(
              key: 'k',
              initialProduct: MyTypNoJson(0),
            ).fromJson({'x': 11}),
            throwsA(
              isA<Exception>().having(
                (p0) => p0.toString(),
                'message',
                'Exception: Please register a json parser using '
                    'NodeBluePrint.addJsonParser<MyTypNoJson>(parser).',
              ),
            ),
          );
        });
      });
    });

    group('instantiate(scope)', () {
      test('returns existing node', () {
        testSetNextKeyCounter(0);
        final bluePrint = NodeBluePrint.example();
        final scope = Scope.example();
        final node = Node<int>(bluePrint: bluePrint, scope: scope);
        expect(bluePrint.instantiate(scope: scope), node);
      });

      test('creates new node', () {
        final scope = Scope.example();
        final node = Node<int>(
          bluePrint: NodeBluePrint.example(),
          scope: scope,
        );
        expect(
          NodeBluePrint.example(key: 'node2').instantiate(scope: scope),
          isNot(node),
        );
      });
    });

    group('instantiateAsInsert(host, index)', () {
      test('returns a new instance', () {
        final insert = Insert.example();
        expect(insert, isNotNull);
      });
    });

    group('copyWith()', () {
      group('returns the same instance', () {
        test('when all parameters a null', () {
          final bluePrint = NodeBluePrint.example();
          final newBluePrint = bluePrint.copyWith();
          expect(newBluePrint, same(bluePrint));
        });

        test('when no parameter has changed', () {
          final bluePrint = NodeBluePrint.example();
          final newBluePrint = bluePrint.copyWith(
            initialProduct: bluePrint.initialProduct,
            key: bluePrint.key,
            suppliers: bluePrint.suppliers,
            produce: bluePrint.produce,
            canBeSmart: bluePrint.canBeSmart,
            smartMaster: bluePrint.smartMaster,
          );
          expect(newBluePrint, same(bluePrint));
        });

        test('when smart master list does not change', () {
          final bluePrint = NodeBluePrint.example().copyWith(
            smartMaster: ['a', 'b', 'c'],
          );
          final newBluePrint = bluePrint.copyWith(smartMaster: ['a', 'b', 'c']);
          expect(newBluePrint, same(bluePrint));
        });
      });

      group('returns a modified instance', () {
        test('when parameters have different values', () {
          final bluePrint = NodeBluePrint.example();
          final newBluePrint = bluePrint.copyWith(
            initialProduct: 1,
            key: 'node2',
            suppliers: ['supplier2'],
            produce: (components, previousProduct) => 2,
            canBeSmart: !bluePrint.canBeSmart,
            smartMaster: ['other'],
          );
          expect(newBluePrint.initialProduct, 1);
          expect(newBluePrint.key, 'node2');
          expect(newBluePrint.suppliers, ['supplier2']);
          expect(newBluePrint.produce([], 0), 2);
          expect(newBluePrint.canBeSmart, !bluePrint.canBeSmart);
          expect(newBluePrint.copyWith(canBeSmart: true).smartMaster, [
            'other',
          ]);
        });
      });

      test('should apply builders', () {
        final builder = ScBuilder.example();
        final scope = builder.scope;
        final newNode = const NodeBluePrint<int>(
          key: 'hostX',
          initialProduct: 0,
        ).instantiate(scope: scope);
        expect(newNode.inserts, isNotEmpty);
      });
    });

    group('forwardTo(key)', () {
      test('should forward the supplier to this node', () {
        const a = NodeBluePrint<int>(key: 'a', initialProduct: 5);
        final b = a.forwardTo('b');
        final scope = Scope.example();
        final nodeA = a.instantiate(scope: scope);
        final nodeB = b.instantiate(scope: scope);
        scope.scm.testFlushTasks();

        expect(b.key, 'b');
        expect(b.initialProduct, a.initialProduct);
        expect(b.suppliers, ['a']);
        expect(nodeA.product, nodeB.product);

        // A change of a should be forwarded to be
        nodeA.product = 12;
        scope.scm.testFlushTasks();
        expect(nodeB.product, 12);
      });
    });

    group('switchSupplier(supplier)', () {
      test('should forward the suppliers value to this node', () {
        final scope = Scope.example();
        final scm = scope.scm;
        scope.mockContent({
          'a': {
            'b': {
              'n0': const NodeBluePrint<int>(key: 'n0', initialProduct: 618),
            },
            'c': {
              // Here we are forwarding the value from b.n0 to c.n1
              'n1': const NodeBluePrint<int>(
                key: 'n1',
                initialProduct: 374,
              ).connectSupplier('b.n0'),
            },
          },
        });

        final n0 = scope.findNode<int>('n0')!;
        final n1 = scope.findNode<int>('n1')!;

        scm.testFlushTasks();

        // The value of n0 should be forwarded to n1
        expect(n0.product, 618);
        expect(n1.product, 618);

        // Change value of n0
        n0.product = 123;
        scm.testFlushTasks();
        expect(n1.product, 123);
      });
    });

    test('initSuppliers', () {
      final scope = Scope.example();
      final scm = scope.scm;
      scope.mockContent({
        'a': {
          'b': {
            'n0': const NodeBluePrint<int>(key: 'n0', initialProduct: 618),
            'n2': const NodeBluePrint<int>(key: 'n2', initialProduct: 618),
          },
          'c': {
            'n1': nbp<int>(
              from: ['b.n0', 'b.n2'],
              to: 'n1',
              init: 0,
              produce: (c, p) {
                return 0;
              },
            ),
          },
        },
      });
      scm.testFlushTasks();

      final n1 = scope.findNode<int>('n1')!;
      final suppliers = n1.suppliers;
      expect(suppliers, hasLength(2));

      final supplierMap = <String, Node<dynamic>>{};
      for (int i = 0; i < suppliers.length; i++) {
        final key = n1.bluePrint.suppliers.elementAt(i);
        supplierMap[key] = suppliers.elementAt(i);
      }

      n1.initSuppliers(supplierMap);
    });

    group('smart nodes', () {
      const node = NodeBluePrint<int>(key: 'node', initialProduct: 0);

      const smartNode = NodeBluePrint<int>(
        key: 'node',
        initialProduct: 0,
        smartMaster: ['x', 'y'],
      );

      group('smartMaster', () {
        group('returns an empty list', () {
          test('by default', () {
            expect(node.smartMaster, const <String>[]);
          });
        });
        test('returns the smart mather path handed over in constructor', () {
          expect(smartNode.smartMaster, ['x', 'y']);
        });
      });

      group('isSmartNode', () {
        test('returns false by default', () {
          expect(node.isSmartNode, false);
        });

        test('returns true when smartMaster is not empty', () {
          expect(smartNode.isSmartNode, true);
        });

        group('returns false when canBeSmart is set to false', () {
          test('anyway if a smart master is set or not', () {
            expect(node.copyWith(canBeSmart: false).isSmartNode, false);
            expect(smartNode.copyWith(canBeSmart: false).isSmartNode, false);
          });
        });
      });

      group('canBeSmart', () {
        test('make a node never be a smart node', () {
          final n = node.copyWith(canBeSmart: false);
          final s = smartNode.copyWith(canBeSmart: false);

          expect(n.canBeSmart, false);
          expect(n.isSmartNode, false);
          expect(n.smartMaster, isEmpty);

          expect(s.canBeSmart, false);
          expect(s.isSmartNode, false);
          expect(s.smartMaster, isEmpty);
        });
      });
    });

    group('addJsonParser, removeJsonParser, clearJsonParsers', () {
      test('should add a json parser for a type', () {
        NodeBluePrint.addJsonParser<MyType>(MyType.fromJson);
        const n = NodeBluePrint<MyType>(key: 'n', initialProduct: MyType(0));
        expect(n.fromJson({'x': 42}).x, 42);
        NodeBluePrint.clearJsonParsers();
        NodeBluePrint.removeJsonParser<MyType>();
      });

      test('should throw if a parser for the type is already registered', () {
        NodeBluePrint.addJsonParser<MyType>((json) => MyType.fromJson(json));
        expect(
          () => NodeBluePrint.addJsonParser<MyType>(
            (json) => MyType.fromJson(json),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              'Exception: A different json parser for type '
                  'MyType is already registered.',
            ),
          ),
        );

        NodeBluePrint.clearJsonParsers();
      });
    });
  });

  group('doNothing', () {
    test('returns previousProduct', () {
      expect(doNothing([], 11), 11);
    });
  });
}
