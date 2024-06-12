// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('PluginNode', () {
    group('example', () {
      test('should work', () {
        final pluginNode = PluginNode.example(key: 'plugin');

        final host = pluginNode.host;

        expect(host.plugins, [pluginNode]);
        expect(pluginNode.input, host);
        expect(pluginNode.output, host);
        expect(pluginNode, isNotNull);
      });
    });

    test('should insert and remove plugins correctly', () {
      // Create pluginNode2
      final host = Node.example(key: 'host');
      final scope = host.scope;
      final scm = host.scope.scm;

      final customer0 =
          host.bluePrint.forwardTo('customer0').instantiate(scope: scope);

      final customer1 =
          host.bluePrint.forwardTo('customer1').instantiate(scope: scope);

      // Check the initial product
      scm.testFlushTasks();
      expect(host.product, 1);
      expect(customer0.product, 1);
      expect(customer1.product, 1);

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
      expect(customer0.product, 1 + 2);
      expect(customer1.product, 1 + 2);

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
      expect(customer0.product, 1 * 3 + 2);
      expect(customer1.product, 1 * 3 + 2);

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
      expect(customer0.product, (1 * 3 * 4) + 2);
      expect(customer1.product, (1 * 3 * 4) + 2);

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
      expect(customer0.product, (1 * 3 * 4) + 2 + 10);
      expect(customer1.product, (1 * 3 * 4) + 2 + 10);

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
      expect(customer0.product, (1 * 3) + 2 + 10);
      expect(customer1.product, (1 * 3) + 2 + 10);

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
      expect(customer0.product, 1 + 2 + 10);
      expect(customer1.product, 1 + 2 + 10);

      // Remove last plugin node
      plugin3.dispose();
      scm.testFlushTasks();
      expect(host.plugins, [plugin2]);
      expect(plugin2.input, host);
      expect(plugin2.output, host);
      expect(host.originalProduct, 1);
      expect(host.product, 1 + 2);
      expect(customer0.product, 1 + 2);
      expect(customer1.product, 1 + 2);

      // Remove last remaining plugin node
      plugin2.dispose();
      scm.testFlushTasks();
      expect(host.plugins, <PluginNode<dynamic>>[]);
      expect(host.originalProduct, 1);
      expect(host.product, 1);
      expect(customer0.product, 1);
      expect(customer1.product, 1);
    });

    group('should apply plugins correctly', () {
      test('with one plugin', () {
        final scope = Scope.example();
        final scm = scope.scm;

        final host = const NodeBluePrint(key: 'host', initialProduct: 1)
            .instantiate(scope: scope);

        final plugin = NodeBluePrint(
          key: 'plugin0',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct * 10;
          },
        ).instantiateAsPlugin(host: host);

        // The product of the host should be multiplied by 10
        scm.testFlushTasks();
        expect(plugin.product, 10);
        expect(host.originalProduct, 1);
        expect(host.product, 10);

        // Change the host product
        host.product = 2;
        scm.testFlushTasks();
        expect(plugin.product, 20);
        expect(host.originalProduct, 2);
        expect(host.product, 20);
      });

      test('with two plugins', () {
        final scope = Scope.example();
        final scm = scope.scm;
        final host = const NodeBluePrint(key: 'host', initialProduct: 1)
            .instantiate(scope: scope);

        final plugin0 = NodeBluePrint(
          key: 'plugin0',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct * 10;
          },
        ).instantiateAsPlugin(host: host);

        final plugin1 = NodeBluePrint(
          key: 'plugin1',
          initialProduct: 0,
          produce: (components, previousProduct) {
            return previousProduct * 10;
          },
        ).instantiateAsPlugin(host: host);

        // The product of the host should be multiplied by 10
        scm.testFlushTasks();
        expect(plugin0.product, 10);
        expect(plugin1.product, 100);
        expect(host.originalProduct, 1);
        expect(host.product, 100);

        // Change the host product
        host.product = 2;
        scm.testFlushTasks();
        expect(plugin0.product, 20);
        expect(plugin1.product, 200);
        expect(host.originalProduct, 2);
        expect(host.product, 200);
      });

      test('with a plugin that has suppliers', () {
        final scope = Scope.example();
        final scm = scope.scm;

        // Create a host node
        final host = const NodeBluePrint(key: 'host', initialProduct: 1)
            .instantiate(scope: scope);

        // Add a customer to the host node
        final customer =
            host.bluePrint.forwardTo('customer').instantiate(scope: scope);

        // Create a supplier that delivers a factor
        final factor = const NodeBluePrint(key: 'factor', initialProduct: 10)
            .instantiate(scope: scope);

        // Create a plugin that multiplies the product with the factor
        final plugin0 = NodeBluePrint(
          key: 'plugin0',
          initialProduct: 0,
          suppliers: ['factor'],
          produce: (components, previousProduct) {
            final factor = components.first as int;
            return previousProduct * factor;
          },
        ).instantiateAsPlugin(host: host);

        // Initially the product of the host should be multiplied by 10
        // because the factor is 10
        scm.testFlushTasks();
        expect(host.customers, [customer]);
        expect(plugin0.product, 10);
        expect(host.originalProduct, 1);
        expect(host.product, 10);
        expect(customer.product, 10);

        // Change the host's original product
        host.product = 2;
        scm.testFlushTasks();
        expect(plugin0.product, 20);
        expect(host.originalProduct, 2);
        expect(host.product, 20);
        expect(customer.product, 20);

        // Change the factor which will modify the way, the plugin calculates
        factor.product = 100;
        scm.testFlushTasks();
        expect(plugin0.product, 200);
        expect(host.originalProduct, 2);
        expect(host.product, 200);
        expect(customer.product, 200);
      });
    });

    group('should throw', () {
      test('when index is too big', () {
        final host = Node.example();
        NodeBluePrint.example(key: 'plugin0').instantiateAsPlugin(
          host: host,
        );

        expect(
          () => NodeBluePrint.example(key: 'plugin1').instantiateAsPlugin(
            host: host,
            index: 2,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (p0) {
                return p0.message;
              },
              'message',
              'Plugin index 2 is out of range.',
            ),
          ),
        );
      });
      test('when index is too small', () {
        final host = Node.example();

        expect(
          () => NodeBluePrint.example(key: 'plugin0').instantiateAsPlugin(
            host: host,
            index: -1,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (p0) {
                return p0.message;
              },
              'message',
              'Plugin index -1 is out of range.',
            ),
          ),
        );
      });
    });
  });
}
