// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'sample_nodes.dart';

enum TestEnum {
  a,
  b,
  c,
}

void main() {
  late Node<int> node;

  int produce(List<dynamic> components, int previousProduct) => previousProduct;

  setUp(() {
    Node.testResetIdCounter();
    Scope.testRestIdCounter();
    scm = Scm.example();
    scope = Scope.example(scm: scm);

    node = scope.findOrCreateNode(
      NodeBluePrint(
        initialProduct: 0,
        produce: produce,
        key: 'node',
      ),
    );
  });

  group('Scope', () {
    group('basic properties', () {
      test('example', () {
        expect(scope, isA<Scope>());
      });

      test('scm', () {
        expect(scope.scm, scm);
      });

      test('key', () {
        expect(scope.key, 'example');
      });

      test('children', () {
        expect(scope.children, isEmpty);
      });

      group('deepChildren, deepParents', () {
        final scope = Scope.example()
          ..mockContent({
            'p2': {
              'p1': {
                'p0': {
                  'x': {
                    'c0': {
                      'c00': {
                        'c000': 0,
                      },
                      'c01': {
                        'c010': 0,
                      },
                    },
                    'c1': {
                      'c10': {
                        'c100': 0,
                      },
                      'c11': {
                        'c110': 0,
                      },
                    },
                  },
                },
              },
            },
          });

        final x = scope.findChildScope('x')!;

        test('should return empty array, when depth = 0', () {
          final parents = x.deepParents(depth: 0).map((e) => e.key);
          expect(parents, <Scope>[]);

          final children = x.deepChildren(depth: 0).map((e) => e.key);
          expect(children, <Scope>[]);
        });

        group('should only return the direct parent / children', () {
          test('when depth = 0', () {
            final parents = x.deepParents(depth: 1).map((e) => e.key);
            expect(parents, ['p0']);

            final children = x.deepChildren(depth: 1).map((e) => e.key);
            expect(children, ['c0', 'c1']);
          });
        });

        group('should return parent of parents, children of children', () {
          test('when depth = 1', () {
            final parents = x.deepParents(depth: 2).map((e) => e.key).toList();
            expect(parents, ['p0', 'p1']);

            final children =
                x.deepChildren(depth: 2).map((e) => e.key).toList();
            expect(children, ['c0', 'c1', 'c00', 'c01', 'c10', 'c11']);
          });
        });

        group('should return all parents / children', () {
          test('when depth = -1 or 1000', () {
            var parents = x.deepParents(depth: 1000).map((e) => e.key).toList();
            expect(parents, ['p0', 'p1', 'p2', 'example', 'root']);

            parents = x.deepParents(depth: -1).map((e) => e.key).toList();
            expect(parents, ['p0', 'p1', 'p2', 'example', 'root']);

            var children =
                x.deepChildren(depth: 1000).map((e) => e.key).toList();
            expect(children, ['c0', 'c1', 'c00', 'c01', 'c10', 'c11']);

            children = x.deepChildren(depth: -1).map((e) => e.key).toList();
            expect(children, ['c0', 'c1', 'c00', 'c01', 'c10', 'c11']);
          });
        });
      });

      group('allScopes', () {
        test('should provide an iterator iterating over all scopes recursively',
            () {
          final scope = Scope.example()
            ..mockContent({
              'a': {
                'b': {
                  'c': {
                    'd': 0,
                  },
                },
              },
              'x': {
                'y': {
                  'z': {
                    'w': 0,
                  },
                },
              },
            });

          final allScopes = scope.allScopes.map((e) => e.key).toList();
          expect(allScopes, ['example', 'a', 'b', 'c', 'x', 'y', 'z']);
        });
      });
    });

    test('string', () {
      expect(scope.toString(), scope.key);
    });

    group('reset', () {
      test('should reset all nodes in this and child scopes', () {
        final scope = Scope.example();
        scope.mockContent({
          'a': {
            'b': {
              'n0': 10,
              'c': {
                'n1': 11,
              },
            },
          },
        });

        final n0 = scope.findNode<int>('a.b.n0')!;
        final n1 = scope.findNode<int>('a.b.c.n1')!;

        // Initally we have the following products
        scope.scm.testFlushTasks();
        expect(n0.product, 10);
        expect(n1.product, 11);

        // Let's change the products
        n0.product = 20;
        n1.product = 21;
        scope.scm.testFlushTasks();

        // Reset
        scope.reset();
        scope.scm.testFlushTasks();

        // The products should be reset to their initial values
        expect(n0.product, 10);
        expect(n1.product, 11);
      });
    });

    group('root', () {
      test('should return the scope itself, if scope is the root', () {
        final root = Scope.example().root;
        expect(root.root.root, root);
      });

      test('should return the root node', () {
        final root = Scope.example().root;
        root.mockContent({
          'a': {
            'b': {
              'c': {
                'd': 0,
              },
            },
          },
        });
        final c = root.findChildScope('a.b.c')!;
        expect(c.root, root);
      });
    });

    group(
      'commonParent(scope)',
      () {
        test('should return the scope itself when the other scope is scope',
            () {
          final root = ExampleScopeRoot(scm: Scm.testInstance);
          final childScopeA = root.child('childScopeA')!;
          expect(childScopeA.commonParent(childScopeA), childScopeA);
        });

        test('should return the common parent scope', () {
          final root = ExampleScopeRoot(scm: Scm.testInstance);
          final childScopeA = root.child('childScopeA')!;
          final childScopeB = root.child('childScopeB')!;
          final grandChildScope = childScopeA.child('grandChildScope')!;
          final grandChildNodeA =
              grandChildScope.findNode<int>('grandChildNodeA')!;

          var commonScope = root.commonParent(grandChildNodeA.scope);
          expect(commonScope, root);

          commonScope = childScopeA.commonParent(grandChildScope);
          expect(commonScope, childScopeA);

          commonScope = grandChildScope.commonParent(childScopeA);
          expect(commonScope, childScopeA);

          commonScope = grandChildScope.commonParent(root);
          expect(commonScope, root);

          commonScope = childScopeA.commonParent(childScopeB);
          expect(commonScope, root);
        });

        test('should throw if no common parent is found', () {
          final scope = Scope.example().root;
          final scopeB = Scope.example().root;
          expect(
            () => scopeB.commonParent(scope),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'No common parent found.',
              ),
            ),
          );
        });
      },
    );

    group('dispose', () {
      late Scope scope;
      late Scm scm;
      late Scope a;
      late Scope b;
      late Node<int> supplier;
      late Scope d;
      late Node<int> customer;

      setUp(() {
        scope = Scope.example();
        scm = scope.scm;

        // Define a supplier a.b.c that has a customer a.d.e;
        scope.mockContent({
          'a': {
            'b': {
              'supplier': 0,
            },
            'd': {
              'customer': NodeBluePrint.map(
                supplier: 'b.supplier',
                toKey: 'customer',
                initialProduct: 0,
              ),
            },
          },
        });

        a = scope.findScope('a')!;
        b = scope.findScope('a.b')!;
        supplier = scope.findNode<int>('a.b.supplier')!;
        d = scope.findScope('a.d')!;
        customer = scope.findNode<int>('a.d.customer')!;
      });

      test('should deeply dispose all scopes and nodes', () {
        // Nothing is disposed
        expect(a.isDisposed, isFalse);
        expect(b.isDisposed, isFalse);
        expect(supplier.isDisposed, isFalse);
        expect(d.isDisposed, isFalse);
        expect(customer.isDisposed, isFalse);

        // Dispsoe the root scope
        scope.dispose();

        // All scopes and nodes are disposed
        expect(a.isDisposed, isTrue);
        expect(b.isDisposed, isTrue);
        expect(supplier.isDisposed, isTrue);
        expect(d.isDisposed, isTrue);
        expect(customer.isDisposed, isTrue);
      });

      group('should erase the scope', () {
        test('when the scope has no children and no nodes', () {
          // Before dispose the scope belongs to it's parent
          final scope = Scope.example();
          expect(scope.children, isEmpty);
          expect(scope.nodes, isEmpty);
          expect(scope.parent!.children, contains(scope));

          // Dispose the scope
          // After dispose the scope is removed from it's parent
          scope.dispose();
          expect(scope.parent!.children, isEmpty);
          expect(scope.isDisposed, isTrue);
          expect(scope.isErased, isTrue);
        });

        test('when the last customer is removed from a scope', () {
          scope.scm.testFlushTasks();

          // Dispose the supplier scope.
          // The supplier will not be erased, because it has a customer
          b.dispose();
          expect(b.isErased, isFalse);
          expect(supplier.isErased, isFalse);

          // Dispose the customer scope
          // Now the supplier will be erased because it has no customers
          customer.dispose();
          expect(b.isErased, isTrue);
          expect(supplier.isErased, isTrue);
        });
      });

      group('should not erase the scope', () {
        test('until the last child scope or node is erased', () {
          scope.scm.testFlushTasks();

          // Dispose the supplier scope.
          b.dispose();
          expect(b.isDisposed, isTrue);
          expect(supplier.isDisposed, isTrue);

          // The supplier will not be erased, because it has a customer
          expect(b.isErased, isFalse);
          expect(supplier.isErased, isFalse);

          // Dispose the customer scope
          customer.dispose();
          expect(b.isErased, isTrue);
          expect(supplier.isErased, isTrue);
        });

        test('until the last customer is connected to a meta node', () {
          // Connect the customer to a meta scope node
          // by connecting it to a scope and not a node
          customer.addBluePrint(
            const NodeBluePrint<int>(
              key: 'customer',
              suppliers: [
                'a.b.on.change', // This is a meta scope node
              ],
              initialProduct: 5,
            ),
          );
          scope.scm.testFlushTasks();

          // The customer should be connected to the meta scope node
          final onChange = scope.findNode<Scope>('a.b.on.change')!;
          expect(onChange.customers, contains(customer));
          expect(b.isErased, isFalse);

          // Dispose the supplier scope b.
          b.dispose();

          // The scope is not erased
          // because a customer is connected to a meta node
          expect(onChange.isDisposed, isTrue);
          expect(onChange.isErased, isFalse);
          expect(b.isDisposed, isTrue);
          expect(b.isErased, isFalse);

          // Dispose the customer
          customer.dispose();

          // The supplier shoul be erased now
          // because it has no customers anymore
          expect(onChange.customers, isEmpty);
          expect(b.isErased, isTrue);
          expect(onChange.isErased, isTrue);
        });
      });

      group('should dispose and erase all nodes', () {
        test('when the nodes have no customers', () {
          // Before dispose the scope has nodes.
          // These nodes are part of the scm
          expect(b.nodes, isNotEmpty);
          for (final node in b.nodes) {
            expect(scm.nodes, contains(node));
          }

          // Dispose the scope
          scope.dispose();

          // After dispose the scope's nodes are removed
          // from the scope and also the SCM
          expect(b.nodes, isEmpty);
          for (final node in b.nodes) {
            expect(scm.nodes, isNot(contains(node)));
            expect(node.isDisposed, isTrue);
            expect(node.isErased, isTrue);
          }
        });
      });
    });

    group('path, pathArray, pathDepth', () {
      test('should return the path of the scope', () {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        final childScopeA = root.child('childScopeA')!;
        final grandChildScope = childScopeA.child('grandChildScope')!;
        expect(root.path, 'exampleRoot');
        expect(childScopeA.path, 'exampleRoot.childScopeA');
        expect(childScopeA.pathArray, ['exampleRoot', 'childScopeA']);
        expect(grandChildScope.path, 'exampleRoot.childScopeA.grandChildScope');
        expect(
          grandChildScope.pathArray,
          ['exampleRoot', 'childScopeA', 'grandChildScope'],
        );
        expect(grandChildScope.depth, 3);
      });
    });

    group('matchesPath(path), matchesPathArry(pathArray)', () {
      group('with aliases', () {
        test('should return true if path matches', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'c0|c1|c2': {
                  'd': 0,
                },
              },
            },
          });

          final c = scope.findChildScope('a.b.c0')!;
          expect(c.matchesPath('a.b.c0'), isTrue);
          expect(c.matchesPath('a.b.c1'), isTrue);
          expect(c.matchesPath('a.b.c2'), isTrue);
          expect(c.matchesPath('a.b.c3'), isFalse);

          final b = scope.findChildScope('a.b')!;
          expect(b.matchesPath('c0'), isFalse);
        });
      });
    });

    group('addChild(child), addChildren(children)', () {
      test('should instantiate and add the child to the scope', () {
        final scope = Scope.example();
        const c0 = ScopeBluePrint(key: 'child0');
        const c1 = ScopeBluePrint(key: 'child1');
        final children = scope.addChildren([c0, c1]);
        expect(scope.children, hasLength(2));
        expect(scope.children.first, children.first);
        expect(scope.children.last, children.last);

        children.first.dispose();
        children.last.dispose();
        expect(children.first.isDisposed, isTrue);
        expect(children.last.isDisposed, isTrue);
        expect(scope.children, isEmpty);
      });

      group('should reactivate a disposed scope and its parents', () {
        late Scope scope;
        late Scope s0;
        late Scope s1;
        late Node<int> supplier;
        setUp(
          () {
            scope = Scope.example();
            scope.mockContent({
              // Define a supplier within scopes a.s0.s1
              'a': {
                's0': {
                  's1': {
                    'supplier': 0,
                  },
                },

                // Define a customer within scopes a.c
                'c': {
                  'customer': NodeBluePrint.map(
                    supplier: 's0.s1.supplier',
                    toKey: 'customer',
                    initialProduct: 0,
                  ),
                },
              },
            });

            scope.scm.testFlushTasks();

            s0 = scope.findScope('a.s0')!;
            s1 = scope.findScope('a.s0.s1')!;
            supplier = scope.findNode<int>('a.s0.s1.supplier')!;
          },
        );

        test('when a fresh node is added to the disposed scope', () {
          // Dispose scope s.
          s0.dispose();

          // s0 and its children are disposed but not erased
          expect(s0.isDisposed, isTrue);
          expect(s0.isErased, isFalse);
          expect(s1.isDisposed, isTrue);
          expect(s1.isErased, isFalse);
          expect(supplier.isDisposed, isTrue);
          expect(supplier.isErased, isFalse);

          // Now add supplier again.
          final newSupplier =
              supplier.bluePrint.instantiate(scope: supplier.scope);

          // The previous supplier should be erased now
          expect(supplier.isErased, isTrue);
          expect(newSupplier.isDisposed, isFalse);

          // The supplier's scope should be reactivated
          // and not be disposed
          expect(s1.isDisposed, isFalse);
          expect(s1.isErased, isFalse);

          // Also the parents of the supplier's scope should be reactivated
          // and not be disposed anymore
          expect(s0.isDisposed, isFalse);
          expect(s0.isErased, isFalse);
        });

        test('when a fresh child scope is added to the disposed scope', () {
          // Dispose scope s.
          s0.dispose();

          // s0 and its children are disposed but not erased
          expect(s0.isDisposed, isTrue);
          expect(s0.isErased, isFalse);
          expect(s1.isDisposed, isTrue);
          expect(s1.isErased, isFalse);
          expect(supplier.isDisposed, isTrue);
          expect(supplier.isErased, isFalse);

          // Now add a fresh scope
          final newChildScope =
              const ScopeBluePrint(key: 'freshScope').instantiate(scope: s1);
          expect(newChildScope.isDisposed, isFalse);
          expect(newChildScope.isErased, isFalse);

          // The new child scope's scope should be reactivated
          // and not be disposed
          expect(s1.isDisposed, isFalse);
          expect(s1.isErased, isFalse);

          // Also the parents of the supplier's scope should be reactivated
          // and not be disposed anymore
          expect(s0.isDisposed, isFalse);
          expect(s0.isErased, isFalse);
        });
      });

      test('should throw if the scope is erased', () {});
    });

    group('findOrCreateChild(key)', () {
      test('should create a child scope with key or return an existing one',
          () {
        final scope = Scope.example();
        final childScopeA = scope.findOrCreateChild('child');
        final childScopeB = scope.findOrCreateChild('child');
        expect(childScopeA, same(childScopeB));
      });
    });

    group('node(key)', () {
      test('should return the node with the given key', () {
        expect(scope.node<int>('node'), node);
      });

      test('should return null if the node does not exist', () {
        expect(scope.node<int>('unknown'), isNull);
      });

      test('should throw if the type does not match', () {
        expect(
          () => scope.node<String>('node'),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Node with key "node" is not of type String',
                  ),
            ),
          ),
        );
      });
    });

    group('findChildScope(path)', () {
      group('should return the scope with the given path', () {
        test('when the path has the name of the scope', () {
          final scope = Scope.example();
          expect(scope.findChildScope('example'), scope);
        });

        test('when the path has the name of an alias', () {
          final scope = Scope.example(aliases: ['x', 'y', 'z']);
          expect(scope.findChildScope('x'), scope);
          expect(scope.findChildScope('y'), scope);
          expect(scope.findChildScope('z'), scope);
          expect(scope.findChildScope('u'), isNull);
        });
        test('when the path has the name of a child node', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'c': 0,
              },
            },
          });
          expect(scope.findChildScope('a')?.key, 'a');
          expect(scope.findChildScope('b')?.key, 'b');
          expect(scope.findChildScope('c')?.key, null);
        });
        test('when the path contains multiple path segments', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'c': {
                  'd': 0,
                },
              },
            },
          });
          expect(scope.findChildScope('a.b')?.key, 'b');
          expect(scope.findChildScope('a.b.c')?.key, 'c');
          expect(scope.findChildScope('a.b.c.d'), isNull);
        });

        test('when the scope name is repated down the hiearchy', () {
          final scope = Scope.example();
          scope.mockContent({
            'corpus': {
              'panels': {
                'left': {
                  'faces': {
                    'right': {
                      'x': 0,
                    },
                  },
                },
                'right': {
                  'faces': {
                    'right': {
                      'x': 0,
                    },
                  },
                },
              },
            },
          });

          final corpus = scope.findChildScope('corpus')!;
          final right = corpus.findChildScope('corpus.panels.right')!;
          expect(right.path, 'root.example.corpus.panels.right');
        });
      });
      group('should return null', () {
        test('if the scope does not exist', () {
          final root = ExampleScopeRoot(scm: Scm.testInstance);
          expect(root.findChildScope('unknown'), isNull);
        });
        test('if the key is empty', () {
          final root = ExampleScopeRoot(scm: Scm.testInstance);
          expect(root.findChildScope(''), isNull);
        });
      });

      test('should throw if multiple scopes with the path exist', () {
        final scope = Scope.example();
        scope.mockContent(
          {
            'a': {
              'duplicate': {
                'c': 0,
                'duplicate': {
                  'd': 0,
                },
              },
            },
          },
        );
      });
    });

    group('replaceScope(newScope, path)', () {
      group('should throw', () {
        test('when the path does not exist', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'c': 0,
              },
            },
          });

          expect(
            () => scope.replaceChild(
              const ScopeBluePrint(key: 'd'),
              path: 'a.b.d',
            ),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.toString().contains(
                      'Scope with path "a.b.d" not found.',
                    ),
              ),
            ),
          );
        });
      });

      group('should replace the old scope', () {
        group('when a path is given', () {
          test('and the path ends with a different key', () {
            final scope = Scope.example();
            scope.mockContent({
              'a': {
                'b': {
                  'c': 0,
                },
              },
            });

            final c = scope.findNode<int>('a.b.c')!;
            final newScope = ScopeBluePrint.fromJson({
              'x': {
                'y': {
                  'z': 0,
                },
              },
            });

            scope.replaceChild(newScope, path: 'a');
            expect(scope.children, hasLength(1));
            expect(scope.children.first.key, 'x');
            expect(c.isDisposed, isTrue);
          });
        });
      });

      group('should upate the old scope', () {
        group('when a path is given', () {
          test('and the path ends with a same key', () {
            final scope = Scope.example();
            scope.mockContent({
              'a': {
                'b': {
                  'c': 0,
                  'p': 10,
                },
                'x': {
                  'y': {
                    'z': 0,
                  },
                },
              },
            });

            final a = scope.findChildScope('a')!;
            final b = scope.findChildScope('a.b')!;
            final c = scope.findNode<int>('a.b.c')!;
            final x = scope.findChildScope('a.x')!;
            final y = scope.findChildScope('a.x.y')!;
            final z = scope.findNode<int>('a.x.y.z')!;

            // Replace the scope
            final newScope = ScopeBluePrint.fromJson({
              'a': {
                'b': {
                  'c': 5,
                  'd': 6,
                },
                'k': {
                  'l': 7,
                },
              },
            });

            scope.replaceChild(newScope, path: 'a');

            final aOut = scope.findChildScope('a')!;
            final bout = scope.findChildScope('a.b')!;
            final cOut = scope.findNode<int>('a.b.c')!;
            final kOut = scope.findChildScope('a.k');
            final pOut = scope.findNode<int>('a.b.p');

            // The original scopes should be kept
            expect(aOut, a);
            expect(bout, b);
            expect(cOut, c);
            expect(kOut, isNotNull);
            expect(pOut, isNull);

            // An additional node should be added
            expect(scope.findNode<int>('a.b.d')?.product, 6);

            // The blue print of the node should be updated
            expect(cOut.bluePrint.initialProduct, 5);

            // The scopes x, y, z should be removed and disposed
            expect(scope.findChildScope('a.x'), isNull);
            expect(x.isDisposed, isTrue);

            expect(scope.findChildScope('a.x.y'), isNull);
            expect(y.isDisposed, isTrue);

            expect(scope.findNode<int>('a.x.z'), isNull);
            expect(z.isDisposed, isTrue);
          });
        });
      });
    });

    group('findOrCreateNode()', () {
      test('should return an existing node when possible', () {
        expect(
          scope.findOrCreateNode(
            NodeBluePrint(
              initialProduct: 0,
              produce: produce,
              key: 'node',
            ),
          ),
          node,
        );
      });

      group('should throw', () {
        group('when existing node exists', () {
          test('but have a different produce method', () {
            expect(
              () => scope.findOrCreateNode<int>(
                NodeBluePrint(
                  initialProduct: 0,
                  produce: (components, previousProduct) => 0,
                  key: 'node',
                ),
              ),
              throwsA(
                predicate<AssertionError>(
                  (e) => e.toString().contains(
                        'Node with key "example" already exists '
                        'with different configuration',
                      ),
                ),
              ),
            );
          });

          test('but has a different type', () {
            expect(
              () => scope.findOrCreateNode<String>(
                NodeBluePrint(
                  initialProduct: 'hello',
                  produce: (components, previousProduct) => 'world',
                  key: 'node',
                ),
              ),
              throwsA(
                predicate<AssertionError>(
                  (e) => e.toString().contains(
                        'Node with key "example" already exists '
                        'with different configuration',
                      ),
                ),
              ),
            );
          });
        });
      });
    });

    group('findOrCreateNodes', () {
      test('should return a list of nodes', () {
        final bluePrint = ScopeBluePrint.example().children.last;
        final nodes = scope.findOrCreateNodes(bluePrint.nodes);
        expect(nodes, hasLength(2));
        expect(nodes[0].key, 'node');
        expect(nodes[1].key, 'customer');
      });
    });
    group('addNode()', () {
      test('should create a node and set the scope and SCM correctly', () {
        expect(node.scope, scope);
        expect(node.scm, scope.scm);
      });

      test('should throw if a node with the same key already exists', () {
        expect(
          () => scope.addNode(
            Node<int>(
              bluePrint: NodeBluePrint<int>(
                initialProduct: 0,
                produce: (components, previousProduct) => previousProduct,
                key: 'node',
              ),
              scope: scope,
            ),
          ),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains('already exists'),
            ),
          ),
        );
      });

      test('should add the node to the chain\'s nodes', () {
        expect(scope.nodes, [node]);
      });

      test('should replace an existing disposed node', () {
        final scope = Scope.example();
        scope.mockContent({
          'a': 0,
          'b': NodeBluePrint.map(supplier: 'a', toKey: 'b', initialProduct: 1),
        });
        scope.scm.testFlushTasks();

        final a = scope.findNode<int>('a')!;
        a.dispose();
        expect(a.isDisposed, isTrue);
        expect(a.isErased, isFalse);

        // Replace the node
        final aNew = a.bluePrint.instantiate(scope: a.scope);
        final aNewCheck = scope.findNode<int>('a')!;
        expect(aNew, aNewCheck);
      });
    });

    group('replaceNode()', () {
      test('should replace the node with the given key', () {
        final newNode = NodeBluePrint<int>(
          initialProduct: 0,
          produce: (components, previousProduct) => previousProduct,
          key: 'node',
        );

        scope.replaceNode(newNode);
        expect(scope.node<int>('node')?.bluePrint, newNode);
      });

      test('should throw if the node does not exist', () {
        final newNode = NodeBluePrint<int>(
          initialProduct: 0,
          produce: (components, previousProduct) => previousProduct,
          key: 'unknown',
        );

        expect(
          () => scope.replaceNode(newNode),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.toString().contains(
                    'Node with key "unknown" does not exist in scope "example"',
                  ),
            ),
          ),
        );
      });
    });
    group('removeNode(), removeNodes()', () {
      test('should remove the node with the given key', () {
        expect(
          scope.findOrCreateNode(
            NodeBluePrint.example(
              key: 'node1',
            ),
          ),
          isNotNull,
        );

        final bp0 = scope.node<int>('node')!.bluePrint;
        final bp1 = scope.node<int>('node1')!.bluePrint;
        scope.removeNodes([bp0, bp1]);
        expect(scope.node<int>('node'), isNull);
        expect(scope.node<int>('node1'), isNull);
      });

      test('should also remove the inserts of the node', () {
        final scope = Scope.example();
        final host = scope.findOrCreateNode<int>(
          NodeBluePrint(
            initialProduct: 0,
            produce: (components, previousProduct) => previousProduct,
            key: 'node',
          ),
        );

        final insert = Insert.example(host: host);
        expect(insert.isDisposed, isFalse);

        scope.removeNode('node');
        expect(insert.isDisposed, isTrue);
      });

      test('should do nothing if node does not exist', () {
        expect(
          () => scope.removeNode('Unknown'),
          returnsNormally,
        );
      });
    });

    group('isAncestorOf(scope)', () {
      test('should return true if the scope is an ancestor of the given scope',
          () {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        final childScopeA = root.child('childScopeA')!;
        final grandChildScope = childScopeA.child('grandChildScope')!;
        expect(root.isAncestorOf(childScopeA), isTrue);
        expect(root.isAncestorOf(grandChildScope), isTrue);
        expect(childScopeA.isAncestorOf(grandChildScope), isTrue);
      });
    });

    group('isDescendantOf(scope)', () {
      test('should return true if the scope is a descendant of the given scope',
          () {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        final childScopeA = root.child('childScopeA')!;
        final grandChildScope = childScopeA.child('grandChildScope')!;
        expect(childScopeA.isDescendantOf(root), isTrue);
        expect(grandChildScope.isDescendantOf(root), isTrue);
        expect(grandChildScope.isDescendantOf(childScopeA), isTrue);
      });
    });

    group('node.dispose(), removeNode()', () {
      test('should remove the node from the chain', () {
        expect(scope.nodes, isNotEmpty);
        node.dispose();
        expect(scope.nodes, isEmpty);
      });
    });

    group('initSuppliers()', () {
      test('should allow to create a hierarchy of scopes', () {
        final scm = Scm.testInstance;
        final root = ExampleScopeRoot(scm: scm);
        expect(root.nodes.map((n) => n.key), ['rootA', 'rootB']);
        for (var element in root.nodes) {
          scm.nominate(element);
        }
        expect(root.children.map((e) => e.key), ['childScopeA', 'childScopeB']);
        expect(root.path, 'exampleRoot');

        final childA = root.child('childScopeA')!;
        final childB = root.child('childScopeB')!;
        expect(childA.nodes.map((n) => n.key), ['childNodeA', 'childNodeB']);
        expect(childB.nodes.map((n) => n.key), ['childNodeA', 'childNodeB']);

        expect(childA.path, 'exampleRoot.childScopeA');
        expect(childB.path, 'exampleRoot.childScopeB');

        for (var element in childA.nodes) {
          scm.nominate(element);
        }

        for (var element in childB.nodes) {
          scm.nominate(element);
        }

        final grandChild = childA.child('grandChildScope')!;
        for (final element in grandChild.nodes) {
          scm.nominate(element);
        }
        expect(grandChild.path, 'exampleRoot.childScopeA.grandChildScope');
        expect(
          grandChild.nodes.first.path,
          'exampleRoot.childScopeA.grandChildScope.grandChildNodeA',
        );

        scm.testFlushTasks();
      });
    });

    group('graph, saveGraphToFile', () {
      // .......................................................................
      Future<void> updateGraphFile(Scope chain, String fileName) async {
        final cwd = Directory.current.path;
        final graphFile = '$cwd/test/graphs/$fileName';

        // Save dot file
        await chain.writeImageFile(graphFile);

        // Save svg file
        final svgFile = graphFile.replaceAll('.dot', '.svg');
        await chain.writeImageFile(svgFile);

        // Create graph directly
        final graph = chain.dot();
        expect(graph, isNotNull);
      }

      // .......................................................................
      test('should print a simple graph correctly', () async {
        initSupplierProducerCustomer();
        createSimpleChain();
        await updateGraphFile(scope, 'simple_graph.dot');
      });

      test('should print a more advanced graph correctly', () async {
        initMusicExampleNodes();

        // .................................
        // Create the following supply chain
        //  key
        //   |-synth
        //   |  |-audio (realtime)
        //   |
        //   |-screen
        //   |  |-grid
        key.addCustomer(synth);
        key.addCustomer(screen);
        synth.addCustomer(audio);
        screen.addCustomer(grid);
        await updateGraphFile(scope, 'advanced_graph.dot');
      });

      test('should print scopes correctly', () async {
        final root = ExampleScopeRoot(scm: Scm.testInstance);
        await updateGraphFile(root, 'graphs_with_scopes.dot');
      });

      group('with write2x == true', () {
        test('should wrid also a 2x version of the file', () async {
          final tmpDir = Directory.systemTemp.createTempSync();
          final imagePath = '${tmpDir.path}/test.png';
          final image2xPath = '${tmpDir.path}/test@2x.png';
          final root = ExampleScopeRoot(scm: Scm.testInstance);
          await root.writeImageFile(imagePath, write2x: true);
          expect(await File(imagePath).exists(), isTrue);
          expect(await File(image2xPath).exists(), isTrue);
          await tmpDir.delete(recursive: true);
        });
      });
    });

    group('findNode(key)', () {
      group('without scope in key', () {
        group('returns', () {
          group('the right node', () {
            late final ExampleScopeRoot rootScope;

            setUpAll(() {
              rootScope = ExampleScopeRoot(scm: Scm.testInstance);
            });

            test('when the node is contained in own scope', () {
              // Find a node directly contained in chain
              final rootA = rootScope.findNode<int>('rootA');
              expect(rootA?.key, 'rootA');

              final rootB = rootScope.findNode<int>('rootB');
              expect(rootB?.key, 'rootB');

              // Child nodes should find their own nodes
              final childScopeA = rootScope.child('childScopeA')!;
              final childNodeAFromChild =
                  childScopeA.findNode<int>('childNodeA');
              expect(childNodeAFromChild?.key, 'childNodeA');
            });

            test('when the path contains an alias', () {
              final scope = Scope.example();
              scope.mockContent({
                'a': {
                  'b': {
                    'c0|c1|c2': {
                      'd': 0,
                    },
                  },
                },
              });

              // Find the node c
              expect(scope.findNode<int>('a.b.c0.d')?.key, 'd');
              expect(scope.findNode<int>('a.b.c1.d')?.key, 'd');
              expect(scope.findNode<int>('a.b.c2.d')?.key, 'd');
              expect(scope.findNode<int>('a.b.c3.d')?.key, isNull);
            });

            group('when the node is contained in parent chain', () {
              test('part 1', () {
                // Should return nodes from parent chain
                final childScopeA = rootScope.child('childScopeA')!;
                final rootAFromChild = childScopeA.findNode<int>('rootA');
                expect(rootAFromChild?.key, 'rootA');
              });

              test('part 2', () {
                final corpus = Scope.example(key: 'corpus');
                corpus.mockContent({
                  'width': 600.0,
                  'depth': 615.0,
                  'panels': {
                    'rightPanel': {
                      'thickness': 19.0,
                    },
                    'leftPanel': {
                      'thickness': 19.0,
                    },
                    'bottomPanel': ScopeBluePrint(
                      key: 'bottomPanel',
                      nodes: [
                        NodeBluePrint<double>(
                          key: 'thickness',
                          initialProduct: 19.0,
                          produce: (components, previousProduct) => 19.0,
                        ),
                      ],
                    ),
                  },
                });

                final panel = corpus.findChildScope('bottomPanel')!;
                final corpusWidth = panel.findNode<double>('corpus.width');
                expect(corpusWidth, isNotNull);
              });
            });

            group('when the node is contained in sibling chain', () {
              test('and only there', () {
                // Create a new chain
                final root = Scope.example();

                // Create two child scopes
                Scope(
                  bluePrint: const ScopeBluePrint(key: 'childScopeA'),
                  parent: root,
                );

                final b = Scope(
                  bluePrint: const ScopeBluePrint(key: 'childScopeA'),
                  parent: root,
                );

                // Add a NodeA to ChildScopeA
                final nodeA = root.child('childScopeA')!.findOrCreateNode<int>(
                      NodeBluePrint(
                        key: 'nodeA',
                        initialProduct: 0,
                        produce: (components, previous) => previous,
                      ),
                    );

                // ChildScopeB should find the node in ChildScopeA
                final Node<int>? foundNodeA = b.findNode<int>('nodeA');
                expect(foundNodeA, nodeA);
              });

              test('and also in a parent sibling chain', () {
                final scope = Scope.example();
                scope.mockContent({
                  'corpus': {
                    'panels': {
                      'left': {
                        'corners': {
                          'backTopRight': {
                            'leftPanelMiterCut': {
                              'yInserts': {
                                'somethingElse': 0,
                              },
                            },
                          },
                          'frontTopRight': {
                            'leftPanelMiterCut': {
                              'yInserts': {
                                'frontTopRightMiterCut': 0,
                              },
                            },
                          },
                        },
                      },
                      'bottom': {
                        'corners': {
                          'frontTopRight': {
                            'bottomPanelMiterCut': {
                              'xInserts': {
                                'frontTopRightMiterCut': 0,
                              },
                            },
                          },
                        },
                      },
                    },
                  },
                });

                final startScope = scope.findChildScope('backTopRight')!;
                expect(
                  startScope.findNode<int>('frontTopRightMiterCut')!.path,
                  endsWith('yInserts.frontTopRightMiterCut'),
                );

                final startScope1 = scope
                    .findChildScope('backTopRight.leftPanelMiterCut.yInserts')!;

                expect(
                  startScope1.findNode<int>('frontTopRightMiterCut')!.path,
                  endsWith('yInserts.frontTopRightMiterCut'),
                );
              });
            });

            test('when the node is contained within a child of the parent', () {
              final scope = Scope.example();
              scope.mockContent({
                'root': {
                  'corpus': {
                    'bounds': {
                      'xLeft': 0,
                    },
                    'corners': {
                      'frontBottomLeft': {
                        'x': 0,
                      },
                    },
                    'panels': {
                      'left': {
                        'bounds': {
                          'xLeft': 0,
                        },
                      },
                    },
                  },
                },
              });

              final frontBottomLeft =
                  scope.findChildScope('corners.frontBottomLeft')!;
              final xLeft = frontBottomLeft.findNode<dynamic>('bounds.xLeft')!;
              expect(xLeft.path, endsWith('corpus.bounds.xLeft'));
            });

            test('when the node is contained somewhere else', () {
              final root = ExampleScopeRoot(scm: Scm.testInstance);

              // Create a node somewhere deep in the hierarchy
              final grandChildScope =
                  root.child('childScopeA')!.child('grandChildScope')!;

              final grandChildNodeX = Node<int>(
                bluePrint: NodeBluePrint<int>(
                  key: 'grandChildNodeX',
                  initialProduct: 0,
                  produce: (components, previousProduct) => 0,
                ),
                scope: grandChildScope,
              );

              // Search the node from the root
              final foundGRandChildNodeX =
                  root.findNode<int>('grandChildNodeX');
              expect(foundGRandChildNodeX, grandChildNodeX);
            });
          });

          group('null', () {
            group('when node cannot be found', () {
              test('and throwIfNotFound is false or not defined', () {
                final unknownNode = scope.findNode<int>(
                  'Unknown',
                  throwIfNotFound: false,
                );
                expect(unknownNode, isNull);

                final unknownNode1 = scope.findNode<int>('Unknown');
                expect(unknownNode1, isNull);
              });
            });
          });
        });
      });

      group('with scope in key', () {
        group('return', () {
          group('the right node', () {
            test('when the node is contained in own scope', () {
              final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
              final childScopeA = rootScope.child('childScopeA')!;
              final grandChildScope = childScopeA.child('grandChildScope')!;
              final grandChildNodeAExpected = grandChildScope.findNode<int>(
                'grandChildNodeA',
              );

              final grandChildNodeReal = grandChildScope.findNode<int>(
                'childScopeA.grandChildScope.grandChildNodeA',
              );
              expect(grandChildNodeReal, grandChildNodeAExpected);
            });

            group('when the node is contained in parent scope', () {
              test('and no aliases are used', () {
                final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
                final childScopeA = rootScope.child('childScopeA')!;
                final grandChildScope = childScopeA.child('grandChildScope')!;
                final childNodeAExpected = childScopeA.findNode<int>(
                  'childNodeA',
                );

                final childNodeAReal = grandChildScope.findNode<int>(
                  'childScopeA.childNodeA',
                );
                expect(childNodeAReal, childNodeAExpected);
              });
              test('and the scope key is an alias', () {
                final scope = Scope.example();
                scope.mockContent(
                  {
                    'a': {
                      // .........................................
                      // Create a first scope scA with the alias X
                      'scA': const ScopeBluePrint(
                        key: 'scA',
                        aliases: ['x'],

                        // The scope has a child scope
                        children: [
                          ScopeBluePrint(key: 'scAChild0'),
                        ],

                        // And a node
                        nodes: [
                          NodeBluePrint<int>(
                            key: 'scANode',
                            initialProduct: 0,
                          ),
                        ],
                      ),

                      // .........................................
                      // Create a second scope scB, also with the alias X
                      'scB': const ScopeBluePrint(
                        key: 'scB',
                        aliases: ['x'],

                        // The scope has also a child scope
                        children: [
                          ScopeBluePrint(key: 'scAChild1'),
                        ],

                        // And it as also a node
                        nodes: [
                          NodeBluePrint<int>(
                            key: 'scANode',
                            initialProduct: 0,
                          ),
                        ],
                      ),
                    },
                  },
                );

                // Get one of the child scopes
                final scAChild0 = scope.findChildScope('scAChild0')!;

                // Search for a node in the parent scope using the alias
                final scANode = scAChild0.findNode<int>('x.scANode');

                expect(scANode, isNotNull);
              });
            });

            test('when the node is contained in sibling scope', () {
              final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
              final childScopeA = rootScope.child('childScopeA')!;
              final grandChildScope = childScopeA.child('grandChildScope')!;
              final grandChildNodeBExpected = grandChildScope.findNode<int>(
                'grandChildNodeB',
              );

              final grandChildNodeReal = grandChildScope.findNode<int>(
                'childScopeA/grandChildScope/grandChildNodeB',
              );
              expect(grandChildNodeReal, grandChildNodeBExpected);
            });
          });
        });
      });

      group('with skipInserts', () {
        test('should return inserts when skipInserts is false ', () {
          final builder = ScBuilder.example();
          final scope = builder.scope;
          final hostB = scope.findNode<int>('hostB')!;

          expect(
            hostB.inserts.map(
              (e) => e.key,
            ),
            [
              // Currently we instantiate the root builders first
              'p0Add111',
              'p1MultiplyByTen',

              // Followed by child builders
              'c0MultiplyByTwo',
            ],
          );

          // skipInserts is false. The insert node will be found.
          expect(
            scope.findNode<int>('hostBInserts.p0Add111', skipInserts: false),
            isNotNull,
          );

          // skipInserts is true. The insert node will not be found.
          expect(
            scope.findNode<int>('hostBInserts.p0Add111', skipInserts: true),
            isNull,
          );
        });
      });

      group('throws', () {
        test('if the type does not match', () {
          final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
          expect(
            () => rootScope.findNode<String>('rootA'),
            throwsA(
              predicate<ArgumentError>(
                (e) => e
                    .toString()
                    .contains('Node with key "rootA" is not of type String'),
              ),
            ),
          );
        });

        test('if throwIfNotFound is true and node is not found', () {
          final supplyScope = Scope.example();
          expect(
            () => supplyScope.findNode<int>('unknown', throwIfNotFound: true),
            throwsA(
              predicate<ArgumentError>(
                (e) =>
                    e.toString().contains('Node with path "unknown" not found'),
              ),
            ),
          );
        });

        test('if multiple nodes of the same key and type are found', () {
          final supplyScope = ExampleScopeRoot(scm: Scm.testInstance);
          expect(
            () => supplyScope.findNode<int>('grandChildNodeA'),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.toString().contains(
                      'Scope "exampleRoot": More than one node '
                      'with key "grandChildNodeA" and '
                      'Type<int> found:',
                    ),
              ),
            ),
          );
        });
      });
    });

    group('findScope(path)', () {
      final scope = Scope.example();
      scope.mockContent({
        'a': {
          'b': {
            'c': {
              'd': 0,
            },
          },
          'e': {
            'f': {
              'g': 2,
            },
          },
        },
      });

      group('should return', () {
        test('null', () {
          expect(scope.findScope('a.b.c.d'), isNull);
        });

        group('the scope,', () {
          test('if the address matches the full path', () {
            final c = scope.findScope('a.b.c')!;
            expect(c.key, 'c');
          });

          test('if the address matches a scope with a sub part of the path',
              () {
            final b = scope.findScope('a.b')!;
            expect(b.key, 'b');
          });

          test('if the address matches a scope in the parent', () {
            final c = scope.findScope('a')!;
            final a = c.findScope('a')!;
            expect(a.key, 'a');
          });
        });
      });

      group('should throw', () {
        test('when throwIfNotFound is true and the scope is not found', () {
          expect(
            () => scope.findScope('a.b.c.d', throwIfNotFound: true),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.toString().contains(
                      'Scope with path "a.b.c.d" not found.',
                    ),
              ),
            ),
          );
        });
      });
    });

    group('hasNode(key)', () {
      test('should return true if the scope has a node with the given key', () {
        final rootScope = ExampleScopeRoot(scm: Scm.testInstance);
        expect(rootScope.hasNode('rootA'), isTrue);
        expect(rootScope.hasNode('rootB'), isTrue);
        expect(rootScope.hasNode('Unknown'), isFalse);

        final childScope = rootScope.child('childScopeA')!;
        expect(childScope.hasNode('childNodeA'), isTrue);
        expect(childScope.hasNode('childNodeB'), isTrue);
        expect(childScope.hasNode('Unknown'), isFalse);
        expect(childScope.hasNode('rootA'), isTrue);
      });
    });

    group('mockContent', () {
      test('should create a mock content', () {
        final scope = Scope.example();
        scope.mockContent({
          'a': {
            'int': 5,
            'b': {
              'int': 10,
              'double': 3.14,
              'string': 'hello',
              'bool': true,
              'enum': const NodeBluePrint<TestEnum>(
                key: 'enum',
                initialProduct: TestEnum.a,
              ),
              'c': [
                const ScopeBluePrint(key: 'd'),
                const ScopeBluePrint(key: 'e'),
                const ScopeBluePrint(key: 'f'),
              ],
              'g': const ScopeBluePrint(key: 'g'),
            },
          },
        });

        expect(scope.findNode<int>('a.int')?.product, 5);
        expect(scope.findNode<int>('a.b.int')?.product, 10);
        expect(scope.findNode<double>('a.b.double')?.product, 3.14);
        expect(scope.findNode<bool>('a.b.bool')?.product, true);
        expect(scope.findNode<TestEnum>('a.b.enum')?.product, TestEnum.a);

        expect(scope.findChildScope('a.b.c.d')!.key, 'd');
        expect(scope.findChildScope('a.b.c.e')!.key, 'e');
        expect(scope.findChildScope('a.b.c.f')!.key, 'f');
        expect(scope.findChildScope('a.b.g')!.key, 'g');
      });

      group('should throw', () {
        test('if an unsupported type is mocked', () {
          final scope = Scope.example();
          expect(
            () => scope.mockContent({
              'a': {
                'unsupported': TestEnum.a,
              },
            }),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.toString().contains(
                      'Type TestEnum not supported. '
                      'Use NodeBluePrint<TestEnum> instead.',
                    ),
              ),
            ),
          );
        });

        test('if a list does not contain ScopeBluePrint', () {
          final scope = Scope.example();
          expect(
            () => scope.mockContent({
              'a': {
                'b': [5],
              },
            }),
            throwsA(
              predicate<ArgumentError>(
                (e) => e.toString().contains(
                      'Lists must only contain ScopeBluePrints.',
                    ),
              ),
            ),
          );
        });
      });
    });

    group('addScBuilder, removeScBuilder, builder', () {
      test('should add and remove a builder', () {
        final scope = Scope.example();
        scope.mockContent({
          'a': {
            'b': {
              'node0': 0,
            },
          },
        });
        final bluePrint = ScBuilderBluePrint.example.bluePrint;
        expect(scope.builders, isEmpty);

        // Instantiating the builder should call addScBuilder
        final builder = bluePrint.instantiate(scope: scope);
        expect(scope.builders, contains(builder));

        // Now we can get the builder by key
        expect(scope.builder(bluePrint.key), builder);

        // Disposing the builder should call removeScBuilder
        builder.dispose();
        expect(scope.builders, isNot(contains(bluePrint)));
      });
    });

    group('metaScopes', () {
      final scope = Scope.example();
      scope.mockContent({
        'a': {
          'b': {
            'c': 0,
          },
        },
      });

      group('general', () {
        test('should return the scope providing event suppliers', () {
          final onScopeA = scope.metaScope('on')!;
          expect(onScopeA.key, 'on');
          final onScopeB = scope.findChildScope('a.b')!.metaScope('on')!;
          expect(onScopeB.key, 'on');
        });
        test('should not be part of the on scope itself', () {
          final onScopeA = scope.metaScope('on')!;
          expect(onScopeA.metaScopes, isEmpty);
        });
        group('should be findable', () {
          test('via findNode()', () {
            // Try to find the node
            final onScopeA = scope.metaScope('on')!;
            final onChange = onScopeA.findNode<void>('on.change');
            expect(onChange, isNotNull);
            expect(onChange?.key, 'change');
          });
          test('via findScope()', () {
            expect(scope.findScope('on'), isNotNull);
            expect(scope.findScope('a.on'), isNotNull);
            expect(scope.findScope('a.b.on'), isNotNull);
          });
          test('via findChildScope()', () {
            expect(scope.findChildScope('on'), isNotNull);
            expect(scope.findChildScope('a.on'), isNotNull);
            expect(scope.findChildScope('a.b.on'), isNotNull);
          });
        });

        group('isMetaScope', () {
          test(
              'should return true if a scope is a meta scope '
              'and false otherwise', () {
            expect(scope.findChildScope('on')!.isMetaScope, isTrue);
            expect(scope.findChildScope('a.on')!.isMetaScope, isTrue);
            expect(scope.findChildScope('a.b.on')!.isMetaScope, isTrue);

            expect(scope.findChildScope('a')!.isMetaScope, isFalse);
            expect(scope.findChildScope('a.b')!.isMetaScope, isFalse);
          });
        });

        test('should find other suppliers in the hierarchy', () {
          final onScopeB = scope.findScope('a.b.on')!;
          final nodeC = onScopeB.findNode<int>('b.c');
          expect(nodeC, isNotNull);
          expect(nodeC?.key, 'c');
        });
      });
    });

    group('on', () {
      final scope = Scope.example();
      scope.mockContent({
        'a': {
          'a0': 0,
          'b': {
            'b0': 1,
            'b1': 2,
            'c': {
              'c0': 0,
              'c1': 1,
            },
          },
        },
      });
      final scm = scope.scm;

      final a = scope.findScope('a')!;
      final a0 = scope.findNode<int>('a.a0')!;
      final b = scope.findScope('b')!;
      final b0 = scope.findNode<int>('b0')!;
      final b1 = scope.findNode<int>('b1')!;
      final c = scope.findScope('c')!;
      final c0 = scope.findNode<int>('c0')!;
      final c1 = scope.findNode<int>('c1')!;

      setUp(() {
        scope.reset();
      });

      group('change', () {
        test('should exist', () {
          final onChange = scope.findNode<void>('on.change')!;
          expect(onChange.key, 'change');
        });

        test('should allow to observe all changes of in a scope', () {
          // ........................................
          // Create nodes observing scopes a,b and e

          // Observere changes on a
          final aChanges = <Scope>[];
          NodeBluePrint<void>(
            key: 'aObserver',
            initialProduct: null,
            suppliers: ['a.on.change'],
            produce: (components, _) => aChanges.add(components.first as Scope),
          ).instantiate(scope: scope);

          // Observere changes on b
          final bChanges = <Scope>[];
          NodeBluePrint<void>(
            key: 'bObserver',
            initialProduct: null,
            suppliers: ['a.b.on.change'],
            produce: (components, _) => bChanges.add(components.first as Scope),
          ).instantiate(scope: scope);

          // Observere changes on c
          final cChanges = <Scope>[];
          NodeBluePrint<void>(
            key: 'cObserver',
            initialProduct: null,
            suppliers: ['a.b.c.on.change'],
            produce: (components, _) => cChanges.add(components.first as Scope),
          ).instantiate(scope: scope);

          scm.testFlushTasks();
          aChanges.clear();
          bChanges.clear();
          cChanges.clear();

          // .....................
          // Change something in a
          // and check if the changes were observed only by a
          a0.product = 1;
          scm.testFlushTasks();

          expect(aChanges, [a]);
          expect(bChanges, isEmpty);
          expect(cChanges, isEmpty);
          aChanges.clear();

          // .....................
          // Change something in b
          // and check if the changes were observed only by b
          b0.product = 2;
          scm.testFlushTasks();

          expect(aChanges, isEmpty);
          expect(bChanges, [b]);
          expect(cChanges, isEmpty);

          b1.product = 3;
          scm.testFlushTasks();

          expect(aChanges, isEmpty);
          expect(bChanges, [b, b]);
          expect(cChanges, isEmpty);
          bChanges.clear();

          // .....................
          // Change something in c
          // and check if the changes were observed only by c
          c0.product = 2;
          scm.testFlushTasks();

          expect(aChanges, isEmpty);
          expect(bChanges, isEmpty);
          expect(cChanges, [c]);

          c1.product = 3;
          scm.testFlushTasks();

          expect(aChanges, isEmpty);
          expect(bChanges, isEmpty);
          expect(cChanges, [c, c]);
        });
      });

      group('changeRecursive', () {
        test('should exist', () {
          final onChange = scope.findNode<void>('on.changeRecursive')!;
          expect(onChange.key, 'changeRecursive');
        });

        test(
            'should allow to observe all changes of in a scope '
            'and its child scopes.', () {
          // ........................................
          // Create nodes observing scopes a,b and e

          // Observere changes on a
          final aChanges = <Scope>[];
          NodeBluePrint<void>(
            key: 'aObserverRecursive',
            initialProduct: null,
            suppliers: ['a.on.changeRecursive'],
            produce: (components, _) => aChanges.add(components.first as Scope),
          ).instantiate(scope: scope);

          // Observere changes on b
          final bChanges = <Scope>[];
          NodeBluePrint<void>(
            key: 'bObserverRecursive',
            initialProduct: null,
            suppliers: ['a.b.on.changeRecursive'],
            produce: (components, _) => bChanges.add(components.first as Scope),
          ).instantiate(scope: scope);

          // Observere changes on c
          final cChanges = <Scope>[];
          NodeBluePrint<void>(
            key: 'cObserverRecursive',
            initialProduct: null,
            suppliers: ['a.b.c.on.changeRecursive'],
            produce: (components, _) => cChanges.add(components.first as Scope),
          ).instantiate(scope: scope);

          scm.testFlushTasks();
          aChanges.clear();
          bChanges.clear();
          cChanges.clear();

          // .....................
          // Change something in a
          // and check if the changes were observed only by a
          a0.product = 1;
          scm.testFlushTasks();

          expect(aChanges, [a]);
          expect(bChanges, isEmpty);
          expect(cChanges, isEmpty);
          aChanges.clear();

          // .....................
          // Change something in b
          // and check if the changes were observed by b and its parent a
          b0.product = 2;
          scm.testFlushTasks();

          expect(aChanges, [a]);
          expect(bChanges, [b]);
          expect(cChanges, isEmpty);

          b1.product = 3;
          scm.testFlushTasks();

          expect(aChanges, [a, a]);
          expect(bChanges, [b, b]);
          expect(cChanges, isEmpty);
          aChanges.clear();
          bChanges.clear();

          // .....................
          // Change something in c
          // and check if the changes were observed by c
          // and its ancestors b and a
          c0.product = 2;
          scm.testFlushTasks();

          expect(aChanges, [a]);
          expect(bChanges, [b]);
          expect(cChanges, [c]);

          c1.product = 3;
          scm.testFlushTasks();

          expect(aChanges, [a, a]);
          expect(bChanges, [b, b]);
          expect(cChanges, [c, c]);
        });
      });
    });
  });
}
