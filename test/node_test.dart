// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  late Scm scm;
  late Scope chain;
  late Node<int> node;

  setUp(
    () {
      testSetNextKeyCounter(0);
      Node.testResetIdCounter();
      scm = Scm(isTest: true);
      chain = Scope.example(scm: scm);
      node = Node.example(scope: chain);
    },
  );

  // #########################################################################
  group('node', () {
    // .........................................................................

    test('exampleNode', () {
      expect(node.product, 0);

      // Nominate the node for production
      scm.nominate(node);

      // Flushing tasks will produce
      scm.testFlushTasks();

      // Production should be done
      expect(node.product, 1);
      expect(node.key, 'aaliyah');
      expect(node.toString(), 'aaliyah');

      // If now scm is given, then the testInstance will be used
      final node2 = Node.example();
      expect(node2.scm, Scm.testInstance);
    });

    group('path', () {
      test('should return the path of the node', () {
        expect(node.path, 'example.aaliyah');
      });
    });

    group('matchesPath', () {
      test('should return true if the path matches', () {
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

        final d = scope.findNode<int>('a.b.c1.d')!;
        expect(d.matchesPath('a.b.c0.d'), isTrue);
        expect(d.matchesPath('a.b.c1.d'), isTrue);
        expect(d.matchesPath('a.b.c2.d'), isTrue);
        expect(d.matchesPath('a.b.c3.d'), isFalse);
      });
    });

    group('commonParent', () {
      test('should return the common parent of two nodes', () {
        final parent = Scope.example(key: 'root');
        parent.mockContent({
          'k': {
            'a': {
              'b': 0,
            },
            'c': {
              'd': 0,
            },
          },
        });

        final k = parent.findScope('k')!;
        final b = parent.findNode<int>('b')!;
        final c = parent.findNode<int>('d')!;

        expect(b.commonParent(c), k);
      });
    });

    test('product, produce(), reportUpdate()', () {
      // Check initial values
      expect(node.product, 0);
      expect(scm.nominatedNodes, [node]);
      expect(node.suppliers, isEmpty);
      expect(node.customers, isEmpty);
      expect(scm.nodes, [node]);

      // Call produce method
      final productBefore = node.product;
      scm.testFlushTasks();
      expect(node.product, productBefore + 1);
    });

    test('suppliers, addSupplier(), removeSupplier()', () {
      final supplier0 = Node.example(scope: chain);
      final supplier1 = Node.example(scope: chain);

      // Add supplier the first time
      expect(scm.nominatedNodes, [node, supplier0, supplier1]);
      node.addSupplier(supplier0);

      // Was supplier added?
      expect(node.suppliers, [supplier0]);

      // Do all initial processing
      scm.testFlushTasks();

      // Is node customer of supplier?
      expect(supplier0.customers, [node]);

      // Add same supplier a second time.
      node.addSupplier(supplier0);

      // Nothing should change
      expect(node.suppliers, [supplier0]);
      expect(supplier0.customers, [node]);

      // Does it add a second supplier?
      node.addSupplier(supplier1);
      expect(node.suppliers, [supplier0, supplier1]);

      // Is node now also customer of supplier1?
      expect(supplier1.customers, [node]);

      // Remove first supplier
      scm.clear();
      expect(scm.nominatedNodes, isEmpty);
      node.removeSupplier(supplier0);
      expect(node.suppliers, [supplier1]);
      expect(supplier0.customers, <Node<dynamic>>[]);

      // Was node nominated?
      expect(scm.nominatedNodes, [node]);

      // Remove second supplier
      scm.clear();
      node.removeSupplier(supplier1);
      expect(node.suppliers, <Node<dynamic>>[]);
      expect(supplier1.customers, <Node<dynamic>>[]);

      // Was node be nominated?
      expect(scm.nominatedNodes, [node]);
    });

    test('customers, addSupplier(), removeSupplier()', () {
      final customer0 = Node.example(scope: chain);
      final customer1 = Node.example(scope: chain);

      // Add customer the first time
      node.addCustomer(customer0);

      // Was customer added?
      expect(node.customers, [customer0]);

      // Is node supplier of customer?
      expect(customer0.suppliers, [node]);

      // Add same customer a second time.
      node.addCustomer(customer0);

      // Nothing should change
      expect(node.customers, [customer0]);
      expect(customer0.suppliers, [node]);

      // Add a second customer
      node.addCustomer(customer1);
      expect(node.customers, [customer0, customer1]);

      // Is node now also supplier of customer1?
      expect(customer1.suppliers, [node]);

      // Remove first customer
      node.removeCustomer(customer0);
      expect(node.customers, [customer1]);
      expect(customer0.suppliers, <Node<dynamic>>[]);

      // Remove second customer
      node.removeCustomer(customer1);
      expect(node.customers, <Node<dynamic>>[]);
      expect(customer1.suppliers, <Node<dynamic>>[]);
    });

    group('deepSuppliers, deepCustomers', () {
      for (final withScopes in [true, false]) {
        final ButterFlyExample(
          :s111,
          :s11,
          :s10,
          :s01,
          :s00,
          :s1,
          :s0,
          :x,
          :c0,
          :c1,
          :c00,
          :c01,
          :c10,
          :c11,
          :c111,
        ) = ButterFlyExample(withScopes: withScopes);

        group('should empty arrays', () {
          test('when depth == 0', () {
            expect(x.deepSuppliers(depth: 0), <Node<dynamic>>[]);
            expect(x.deepCustomers(depth: 0), <Node<dynamic>>[]);
          });
        });

        group('should only return own suppliers and customers', () {
          test('when depth == 1', () {
            expect(x.deepSuppliers(depth: 1), [s1, s0]);
            expect(x.deepCustomers(depth: 1), [c0, c1]);
          });
        });

        group('should return suppliers of supplier and customers of customers',
            () {
          test('when depth == 2', () {
            expect(x.deepSuppliers(depth: 2), [s1, s0, s11, s10, s01, s00]);
            expect(x.deepCustomers(depth: 2), [c0, c1, c00, c01, c10, c11]);
          });
        });

        group('should return all suppliers and customers', () {
          test('when depth == 1000', () {
            final expectedSuppliers = [s1, s0, s11, s10, s111, s01, s00];
            final expectedCustomers = [c0, c1, c00, c01, c10, c11, c111];

            expect(x.deepSuppliers(depth: 1000), expectedSuppliers);
            expect(x.deepSuppliers(depth: -1), expectedSuppliers);
            expect(x.deepCustomers(depth: 1000), expectedCustomers);
            expect(x.deepCustomers(depth: -1), expectedCustomers);
          });
        });
      }
    });

    group('plugins', () {
      test('should work as expected', () {
        // Create pluginNode2
        final host = Node.example(key: 'host');
        final scm = host.scope.scm;

        // Check the initial product
        scm.testFlushTasks();
        expect(host.product, 1);

        // Insert a first plugin 2, adding 2 to the original product
        final plugin2 = PluginNode.example(
          key: 'plugin2',
          produce: (components, previousProduct) => previousProduct + 2,
          host: host,
        );

        scm.testFlushTasks();
        expect(host.plugins, [plugin2]);
        expect(plugin2.input, host);
        expect(plugin2.output, host);
        expect(plugin2, isNotNull);
        expect(host.originalProduct, 1);
        expect(host.product, 1 + 2);

        // Insert pluginNode0 before pluginNode2, multiplying by 3
        final plugin0 = PluginNode.example(
          key: 'plugin0',
          produce: (components, previousProduct) => previousProduct * 3,
          host: host,
          index: 0,
        );
        scm.testFlushTasks();

        expect(host.plugins, [plugin0, plugin2]);
        expect(plugin0.input, host);
        expect(plugin0.output, plugin2);
        expect(host.originalProduct, 1);
        expect(host.product, 1 * 3 + 2);

        // Insert pluginNode1 between pluginNode0 and pluginNode2
        // The plugin multiplies the previous result by 4
        final plugin1 = PluginNode.example(
          key: 'plugin1',
          produce: (components, previousProduct) => previousProduct * 4,
          host: host,
          index: 1,
        );
        scm.testFlushTasks();
        expect(host.plugins, [plugin0, plugin1, plugin2]);
        expect(plugin0.input, host);
        expect(plugin0.output, plugin1);
        expect(plugin1.input, plugin0);
        expect(plugin1.output, plugin2);
        expect(plugin2.input, plugin1);
        expect(plugin2.output, host);
        expect(host.originalProduct, 1);
        expect(host.product, (1 * 3 * 4) + 2);

        // Insert pluginNode3 after pluginNode2 adding ten
        final plugin3 = PluginNode.example(
          key: 'plugin3',
          produce: (components, previousProduct) => previousProduct + 10,
          host: host,
          index: 3,
        );
        scm.testFlushTasks();
        expect(host.plugins, [plugin0, plugin1, plugin2, plugin3]);
        expect(plugin0.input, host);
        expect(plugin0.output, plugin1);
        expect(plugin1.input, plugin0);
        expect(plugin1.output, plugin2);
        expect(plugin2.input, plugin1);
        expect(plugin2.output, plugin3);
        expect(plugin3.input, plugin2);
        expect(plugin3.output, host);
        expect(host.originalProduct, 1);
        expect(host.product, (1 * 3 * 4) + 2 + 10);

        // Remove plugin node in the middle
        plugin1.dispose();
        scm.testFlushTasks();
        expect(host.plugins, [plugin0, plugin2, plugin3]);
        expect(plugin0.input, host);
        expect(plugin0.output, plugin2);
        expect(plugin2.input, plugin0);
        expect(plugin2.output, plugin3);
        expect(plugin3.input, plugin2);
        expect(plugin3.output, host);
        expect(host.originalProduct, 1);
        expect(host.product, (1 * 3) + 2 + 10);

        // Remove first plugin node
        plugin0.dispose();
        scm.testFlushTasks();
        expect(host.plugins, [plugin2, plugin3]);
        expect(plugin2.input, host);
        expect(plugin2.output, plugin3);
        expect(plugin3.input, plugin2);
        expect(plugin3.output, host);
        expect(host.originalProduct, 1);
        expect(host.product, 1 + 2 + 10);

        // Remove last plugin node
        plugin3.dispose();
        scm.testFlushTasks();
        expect(host.plugins, [plugin2]);
        expect(plugin2.input, host);
        expect(plugin2.output, host);
        expect(host.originalProduct, 1);
        expect(host.product, 1 + 2);

        // Remove last remaining plugin node
        plugin2.dispose();
        scm.testFlushTasks();
        expect(host.plugins, <PluginNode<dynamic>>[]);
        expect(host.originalProduct, 1);
        expect(host.product, 1);
      });

      group('clearPlugins()', () {
        test('should remove all plugins from node', () {
          final host = Node.example(key: 'host');
          final scm = host.scope.scm;

          // Insert pluginNode0 before pluginNode2, multiplying by 3
          final plugin0 = PluginNode.example(
            key: 'plugin0',
            produce: (components, previousProduct) => previousProduct * 3,
            host: host,
          );

          // Insert a first plugin 2, adding 2 to the original product
          final plugin1 = PluginNode.example(
            key: 'plugin1',
            produce: (components, previousProduct) => previousProduct + 2,
            host: host,
          );

          scm.testFlushTasks();
          expect(host.plugins, [plugin0, plugin1]);

          host.clearPlugins();
          scm.testFlushTasks();
          expect(host.plugins, <PluginNode<dynamic>>[]);

          expect(plugin0.isDisposed, true);
          expect(plugin1.isDisposed, true);
        });
      });

      group('plugin(String key)', () {
        test('should return null if plugin with key does not exist', () {
          final host = Node.example(key: 'host');
          expect(host.plugin('plugin'), isNull);
        });

        test('should return the plugin with the key', () {
          final host = Node.example(key: 'host');
          final plugin = PluginNode.example(
            key: 'plugin',
            produce: (components, previousProduct) => previousProduct + 2,
            host: host,
          );

          expect(host.plugin('plugin'), plugin);
        });
      });
    });

    test('dispose() should work fine', () {
      // Create a supplier -> producer -> customer chain
      final supplier = Node.example(
        scope: chain,
        bluePrint: NodeBluePrint.example(key: 'supplier'),
      );
      final producer = Node.example(
        scope: chain,
        bluePrint: NodeBluePrint.example(key: 'producer'),
      );
      final customer = Node.example(
        scope: chain,
        bluePrint: NodeBluePrint.example(key: 'customer'),
      );
      producer.addCustomer(customer);
      producer.addSupplier(supplier);

      // Before node is managed by SCM and part of it's scope
      expect(scm.nodes, contains(producer));
      expect(chain.findNode<int>('producer'), producer);

      // Dispose supplier
      // It should be removed from suppliers's customer list
      // It should be removed from customers's supplier list
      producer.dispose();
      expect(producer.suppliers, isEmpty);
      expect(producer.customers, isEmpty);
      expect(supplier.customers, isEmpty);
      expect(customer.suppliers, isEmpty);

      // Should remove the node from the scm
      expect(scm.nodes, isNot(contains(producer)));

      // Should remove the node from the scope
      expect(chain.findNode<int>('producer'), isNull);
    });

    test('reset', () {
      final scope = Scope.example();
      const bp = NodeBluePrint(key: 'test', initialProduct: 5);
      final node = bp.instantiate(scope: scope);
      final node2 = NodeBluePrint<int>.map(
        supplier: 'test',
        toKey: 'test2',
        initialProduct: 6,
      ).instantiate(scope: scope);

      scope.scm.testFlushTasks();
      expect(node2.product, 5);

      node.product = 11;
      scope.scm.testFlushTasks();
      expect(node2.product, 11);
      node.reset();
      scope.scm.testFlushTasks();
      expect(node2.product, 5);
    });

    group('isAnimated', () {
      test('should return true if node is animated', () {
        expect(node.isAnimated, false);
        node.isAnimated = true;
        expect(node.isAnimated, true);
        node.isAnimated = false;
        expect(node.isAnimated, false);
      });
    });

    group('ownPriority, priority', () {
      test('should work as expected', () {
        // Initially node has lowest priority
        node.ownPriority = Priority.lowest;
        expect(node.ownPriority, Priority.lowest);

        // Priority will be the node's own priority
        // because SCM did not overwrite it
        expect(node.priority, Priority.lowest);

        // Assumce SCM will add a higher priority
        node.customerPriority = Priority.highest;

        // Priority will be the customer's priority,
        // because it is higher then the node's own priority
        expect(node.priority, Priority.highest);

        // Assume the node itself has a high priority
        // and SCM assignes a lower priority
        node.ownPriority = Priority.highest;
        node.customerPriority = Priority.lowest;

        // Now priority will be the node's own priority
        // because it is higher then the customer's priority
        expect(node.priority, Priority.highest);
      });
    });

    group('set and get product', () {
      test('should possible if no suppliers and produce function is given', () {
        // Create a node -> customer chain
        final chain = Scope.example(scm: scm);

        final node = Node<int>(
          scope: chain,
          bluePrint: const NodeBluePrint<int>(
            key: 'node',
            initialProduct: 0,
          ),
        );

        final customer = Node<int>(
          scope: chain,
          bluePrint: NodeBluePrint<int>(
            key: 'customer',
            initialProduct: 0,
            suppliers: ['node'],
            produce: (components, previousProduct) =>
                (components[0] as int) * 10,
          ),
        );

        // Check initial values
        expect(node.product, 0);

        // Set a product from the outside
        node.product = 1;
        expect(node.product, 1);

        // Let the chain run
        chain.scm.testFlushTasks();

        // Check if customer got the new component
        expect(customer.product, 10);
      });
    });

    group('update(bluePrint)', () {
      test('should do nothing, when bluePrint is the same as before', () {
        node.update(node.bluePrint);
      });

      group('should throw an assertion error', () {
        test('when key is different', () {
          const otherBluePrint = NodeBluePrint<int>(
            key: 'otherKey',
            initialProduct: 6,
          );

          expect(
            () => node.update(otherBluePrint),
            throwsA(isA<AssertionError>()),
          );
        });
      });

      test('should replace the previous blue print and nominate the node', () {
        final otherBluePrint = node.bluePrint.copyWith(
          initialProduct: 6,
          produce: (components, previousProduct) => 7,
        );

        node.update(otherBluePrint);

        expect(
          node.bluePrint,
          otherBluePrint,
        );

        expect(scm.nominatedNodes, [node]);
      });
    });

    group('saveGraphToFile', () {
      test('should save the graph to a file', () async {
        final node = ButterFlyExample(withScopes: true).x;
        const path = 'test/graphs/graph_test/node_test_saveGraphToFile.dot';
        await node.writeImageFile(path);
      });
    });

    group('graph', () {
      test(
        'should return a dot representation of node and its suppliers '
        'and customers',
        () {
          final node = ButterFlyExample(withScopes: true).x;
          final graph = node.dot();
          expect(graph, isNotNull);
        },
      );
    });

    group('special cases', () {
      group('should throw', () {
        group('when the new product is not in the list of allowed values', () {
          test('with a fixed value assigned', () {
            final node = Node<int>(
              scope: Scope.example(),
              bluePrint: const NodeBluePrint<int>(
                key: 'node',
                initialProduct: 0,
                allowedProducts: [0, 1, 2],
              ),
            );

            expect(
              () => node.product = 3,
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains(
                    'The product 3 is not in the list of allowed '
                    'products [0, 1, 2].',
                  ),
                ),
              ),
            );
          });

          test('with value produced', () {
            final node = Node<int>(
              scope: Scope.example(),
              bluePrint: NodeBluePrint<int>(
                key: 'node',
                initialProduct: 0,
                allowedProducts: [0, 1, 2],
                produce: (List<dynamic> components, previousProduct) => 3,
              ),
            );

            expect(
              () => node.produce(),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.message,
                  'message',
                  contains(
                    'The product 3 is not in the list of allowed '
                    'products [0, 1, 2].',
                  ),
                ),
              ),
            );
          });
        });
      });
    });
  });

  group('Examples', () {
    test('ButterFlyExample', () {
      expect(ButterFlyExample(), isNotNull);
    });
    test('TriangleExample', () {
      expect(TriangleExample(), isNotNull);
    });
  });
}
