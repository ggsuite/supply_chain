// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('Performance optimizations', () {
    group('ready queues', () {
      // Note: the fallback scan for nodes entering preparedNodes directly
      // is tested in scm_test.dart ('produce fallback' group).

      test('should re-bucket nodes whose priority changed while ready', () {
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);

        scope.mockContent({
          'supplier': 0,
          'customer': nbp(
            from: ['supplier'],
            to: 'customer',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
        });
        scm.flush();

        final supplier = scope.findNode<int>('supplier')!;

        // Nominate the supplier and prepare it.
        // It enters the frame priority ready queue.
        scm.nominate(supplier);
        scm.testRunFastTasks();
        expect(scm.preparedNodes, contains(supplier));

        // Raise the priority to realtime and process the priority update
        supplier.ownPriority = Priority.realtime;
        scm.testRunFastTasks();

        // Production must pick the supplier from the realtime bucket -
        // without a tick() lowering the minimum production priority.
        scm.testRunNormalTasks();
        expect(scm.preparedNodes, isNot(contains(supplier)));

        scm.flush(tick: false);
        expect(supplier.isReady, isTrue);
      });

      test('should remove disposed nodes from preparedNodes immediately', () {
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);

        scope.mockContent({
          'supplier': 0,
          'middle': nbp(
            from: ['supplier'],
            to: 'middle',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          'customer': nbp(
            from: ['middle'],
            to: 'customer',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
        });
        scm.flush();

        final middle = scope.findNode<int>('middle')!;

        // Prepare the middle node (it has a customer, so it will not be
        // erased on dispose)
        scm.nominate(middle);
        scm.testRunFastTasks();
        expect(scm.preparedNodes, contains(middle));

        // Disposing must remove it from preparedNodes right away
        middle.dispose();
        expect(scm.preparedNodes, isNot(contains(middle)));

        scm.flush();
      });
    });

    group('timeout check timer', () {
      test('should reuse one timer across production cycles', () {
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);

        scope.mockContent({
          'supplier': 0,
          'middle': nbp(
            from: ['supplier'],
            to: 'middle',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          'customer': nbp(
            from: ['middle'],
            to: 'customer',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
        });
        scm.flush();

        final supplier = scope.findNode<int>('supplier')!;
        supplier.product = 1;

        // Step through the production waves manually and make sure the
        // timeout check timer stays the same instance. Previously every
        // production cycle created (and leaked) a new periodic timer.
        Object? firstTimer;
        var guard = 0;
        scm.tick();
        while (scm.testFastTasks.isNotEmpty || scm.testNormalTasks.isNotEmpty) {
          scm.testRunFastTasks();
          scm.testRunNormalTasks();

          final timer = scm.testTimer;
          if (timer != null) {
            firstTimer ??= timer;
            expect(identical(timer, firstTimer), isTrue);
          }

          expect(++guard < 100, isTrue);
        }

        // A timer was created and cleaned up after the pipeline drained
        expect(firstTimer, isNotNull);
        expect(scm.testTimer, isNull);
      });
    });

    group('topological ranks', () {
      test('should support suppliers created after their customers', () {
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);

        // The customer is created first, the supplier afterwards. The edge
        // therefore violates the creation order and triggers a local
        // topological reordering.
        final customer = Node<int>(
          bluePrint: NodeBluePrint<int>(
            key: 'customer',
            initialProduct: 0,
            suppliers: ['supplier'],
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          scope: scope,
        );

        final supplier = Node<int>(
          bluePrint: const NodeBluePrint<int>(
            key: 'supplier',
            initialProduct: 5,
          ),
          scope: scope,
        );

        scm.flush();
        expect(customer.product, 6);

        supplier.product = 10;
        scm.flush();
        expect(customer.product, 11);
      });

      test('should detect circular dependencies via backward edges', () {
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);

        Node<int>(
          bluePrint: NodeBluePrint<int>(
            key: 'a',
            initialProduct: 0,
            suppliers: ['b'],
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          scope: scope,
        );

        Node<int>(
          bluePrint: NodeBluePrint<int>(
            key: 'b',
            initialProduct: 0,
            suppliers: ['a'],
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          scope: scope,
        );

        expect(
          scm.flush,
          throwsA(
            predicate<Exception>(
              (e) => e.toString().contains('Circular dependency detected:'),
            ),
          ),
        );
      });

      test('should detect circular dependencies in diamond graphs', () {
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);

        // Diamond: top -> left/right -> bottom.
        // Then try to make bottom a supplier of top.
        scope.mockContent({
          'top': nbp(
            from: ['bottom'],
            to: 'top',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          'left': nbp(
            from: ['top'],
            to: 'left',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          'right': nbp(
            from: ['top'],
            to: 'right',
            init: 0,
            produce: (c, p, n) => (c.first as int) + 1,
          ),
          'bottom': nbp(
            from: ['left', 'right'],
            to: 'bottom',
            init: 0,
            produce: (c, p, n) => (c.first as int) + (c.last as int),
          ),
        });

        expect(
          scm.flush,
          throwsA(
            predicate<Exception>(
              (e) => e.toString().contains('Circular dependency detected:'),
            ),
          ),
        );
      });

      test('should handle chains of many thousand nodes', () {
        // The previous implementation overflowed the stack when preparing
        // chains of ~8000 nodes and needed quadratic time to build them.
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);
        const n = 10000;

        Node<int>(
          bluePrint: const NodeBluePrint<int>(key: 'n0', initialProduct: 0),
          scope: scope,
        );

        for (var i = 1; i < n; i++) {
          Node<int>(
            bluePrint: NodeBluePrint<int>(
              key: 'n$i',
              initialProduct: 0,
              suppliers: ['n${i - 1}'],
              produce: (c, p, n) => (c.first as int) + 1,
            ),
            scope: scope,
          );
        }

        scm.flush();

        final first = scope.findNode<int>('n0')!;
        final last = scope.findNode<int>('n${n - 1}')!;
        expect(last.product, n - 1);

        first.product = 1;
        scm.flush();
        expect(last.product, n);
      });
    });

    group('Scope.nodeByKey', () {
      test('should return the node with the exact key or null', () {
        final scm = Scm(isTest: true);
        final scope = Scope.root(key: 'root', scm: scm);

        scope.mockContent({'supplier': 0});
        scm.flush();

        final supplier = scope.findNode<int>('supplier')!;
        expect(scope.nodeByKey('supplier'), same(supplier));
        expect(scope.nodeByKey('unknown'), isNull);
      });
    });
  });
}
