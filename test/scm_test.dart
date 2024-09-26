import 'package:fake_async/fake_async.dart';
import 'package:supply_chain/src/schedule_task.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'shared_tests.dart';

void main() {
  late Scm scm;
  late Scope scope;

  // ...........................................................................
  setUp(
    () {
      testSetNextKeyCounter(0);
      Node.testResetIdCounter();
      scm = Scm(
        isTest: true,
      );

      scope = Scope.example(scm: scm);
      scm.initSuppliers();
      scm.testRunFastTasks();
    },
  );

  // ...........................................................................
  void expectPriority(Iterable<Node<dynamic>> nodes, Priority priority) {
    for (final node in nodes) {
      expect(node.priority, priority);
    }
  }

  // ...........................................................................
  void expectIsStaged(Iterable<Node<dynamic>> nodes, bool isStaged) {
    for (final node in nodes) {
      expect(node.isStaged, isStaged);
    }
  }

  // ...........................................................................
  void expectIsReady(
    Iterable<Node<dynamic>> nodes,
    bool isReady, {
    Iterable<Node<dynamic>>? except,
  }) {
    except ??= [];

    for (final node in nodes) {
      if (except.contains(node)) {
        expect(node.isReady, !isReady);
      } else {
        expect(node.isReady, isReady);
      }
    }
  }

  group('Scm', () {
    test(
      'should initialize correctly',
      () {
        // ..............
        // Initialization
        final scope = Scope.example();
        final scm = scope.scm;

        // Add one supplier, producer and customer
        scope.mockContent({
          'supplier': nbp(
            from: [],
            to: 'supplier',
            init: 1,
            produce: (components, previousProduct) => ++previousProduct,
          ),
          'producer': nbp(
            from: ['supplier'],
            to: 'producer',
            init: 2,
            produce: (components, previousProduct) =>
                (components.first as int) * 5,
          ),
          'customer': nbp(
            from: ['producer'],
            to: 'customer',
            init: 3,
            produce: (components, previousProduct) =>
                (components.first as int) + 1,
          ),
        });

        final supplier = scope.findNode<int>('supplier')!;
        final producer = scope.findNode<int>('producer')!;
        final customer = scope.findNode<int>('customer')!;

        // ....................
        // Check pre-conditions

        // Did connect scm with nodes?
        expect(scm, supplier.scm);
        expect(scm, producer.scm);
        expect(scm, customer.scm);

        // ..................
        // Initial nomination

        // Freshly added nodes are immediately nominated
        expect(scm.nominatedNodes, contains(supplier));
        expect(scm.nominatedNodes, contains(producer));
        expect(scm.nominatedNodes, contains(customer));

        // No node is staged for production
        expect(supplier.isStaged, isFalse);
        expect(producer.isStaged, isFalse);
        expect(customer.isStaged, isFalse);

        // Products should be inital products
        expect(supplier.product, 1);
        expect(producer.product, 2);
        expect(customer.product, 3);

        // ...................
        // Initial preparation

        // Realtime tasks are scheduled that will start the preparation
        expect(scm.testFastTasks, isNotEmpty);
        expect(scm.testNormalTasks, isEmpty);

        // Run realtime tasks to execute prepration
        scm.testRunFastTasks();

        // Now all nodes should be prepared,
        // i.e. all nodes are staged
        expect(supplier.isStaged, isTrue);
        expect(producer.isStaged, isTrue);
        expect(customer.isStaged, isTrue);

        // Nodes should not be nominated anymore
        expect(scm.nominatedNodes, isEmpty);

        // Nodes should appear within prepared nodes
        expect(scm.preparedNodes, contains(supplier));
        expect(scm.preparedNodes, contains(producer));
        expect(scm.preparedNodes, contains(customer));

        // .................
        // Initial execution

        // Initally no node has yet produced
        expect(supplier.product, 1);
        expect(producer.product, 2);
        expect(customer.product, 3);

        // None of the nodes should be ready
        expect(supplier.isReady, isFalse);
        expect(producer.isReady, isFalse);
        expect(customer.isReady, isFalse);

        // Only the supplier should be ready to produce,
        // because it has no suppliers.
        expect(supplier.isReadyToProduce, isTrue);
        expect(producer.isReadyToProduce, isFalse);
        expect(customer.isReadyToProduce, isFalse);

        // A production task should be added
        expect(scm.testNormalTasks, isNotEmpty);
        expect(scm.testFastTasks, isNotEmpty);

        // Product should still be initial
        final productBefore = supplier.product;
        expect(productBefore, 1);

        // ...........

        // Execute tasks
        scm.testRunNormalTasks();

        // Production should not start because our nodes have frame priority.
        // Outside tick() only realtime nodes are processed.
        expect(scm.minProductionPriority, Priority.realtime);
        expect(supplier.isReady, isFalse);
        expect(producer.isReady, isFalse);
        expect(customer.isReady, isFalse);

        // Let's trigger a frame.
        // minProductionPriority goes down to frame
        scm.tick();
        expect(scm.minProductionPriority, Priority.frame);

        // Let's execute tasks again
        scm.testRunNormalTasks();

        // Now supplier has been produced
        expect(supplier.isReady, isTrue);
        expect(supplier.product, productBefore + 1);

        // Producer and customer have not yet produced
        expect(producer.isReady, isFalse);
        expect(customer.isReady, isFalse);

        // Producer is now ready to produce
        // because it's supplier isReady
        expect(producer.isReadyToProduce, isTrue);

        // Customer is not ready to produce
        // because it's supplier is not ready.
        expect(customer.isReadyToProduce, isFalse);

        // ...........

        // Execute tasks -> Production should start again
        scm.testRunNormalTasks();

        // Now also producer should be ready
        expect(producer.isReady, isTrue);
        expect(producer.product, 10);

        // Customer is not yet ready.
        // But it is ready to produce,
        // because it's supplier (producer) has been updated.
        expect(customer.isReady, isFalse);
        expect(customer.isReadyToProduce, isTrue);

        // ...........

        // Execute tasks -> Production should start again
        scm.testRunNormalTasks();

        // Finally also last item in the chain (customer) should be ready
        expect(customer.isReady, isTrue);
        expect(customer.product, 11);

        // The production mode should be set back
        expect(scm.minProductionPriority, Priority.realtime);
      },
    );

    group('should throw', () {
      test('if nodes with non existing suppliers exist', () {
        final scope = Scope.example();
        scope.mockContent({
          'a': NodeBluePrint<int>(
            key: 'a',
            initialProduct: 0,
            suppliers: ['b', 'unknown'],
            produce: (c, p) => 1,
          ),
          'b': NodeBluePrint<int>(
            key: 'b',
            initialProduct: 0,
            suppliers: [],
            produce: (c, p) => 1,
          ),
        });

        scope.scm.tick();

        expect(
          () => scope.scm.testFlushTasks(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Node "root.example.a": Supplier with key "unknown" not found.',
            ),
          ),
        );
      });
    });

    test(
      'should animate correctly',
      () {
        // Create a chain, containing a supplier, a producer and a customer
        final scope = Scope.example();
        final scm = scope.scm;
        scope.mockContent({
          'supplier': nbp(
            from: [],
            to: 'supplier',
            init: 0,
            produce: (c, p) {
              return (p) + 1;
            },
          ),
          'producer': nbp(
            from: ['supplier'],
            to: 'producer',
            init: 0,
            produce: (c, p) {
              return (c.first as int) + 10;
            },
          ),
        });

        final supplier = scope.findNode<int>('supplier')!;
        final producer = scope.findNode<int>('producer')!;
        scm.testFlushTasks();
        expect(supplier.product, 1);
        expect(producer.product, 11);

        // Initially supplier is not animated
        expect(supplier.isAnimated, isFalse);
        expect(scm.animatedNodes, isNot(contains(supplier)));

        // Animate supplier
        // Supplier should be part of animated nodes
        supplier.isAnimated = true;
        expect(scm.animatedNodes, contains(supplier));

        // Deanimate supplier
        // Supplier is not part of animated nodes anymore
        supplier.isAnimated = false;
        expect(scm.animatedNodes, isNot(contains(supplier)));

        // Animate supplier again
        // Supplier should be part of animated nodes
        supplier.isAnimated = true;
        expect(scm.animatedNodes, contains(supplier));

        // ..........
        // Emit a tick
        scm.tick();

        // Supplier should be nominated because it is animated.
        // The other two are not nominated, because they are not animated.
        expect(scm.nominatedNodes, [supplier]);

        // Finish production by flushing all tasks
        scm.testFlushTasks();
        expect(supplier.product, 2);
        expect(producer.product, 12);

        // Each time tick() is called, the production starts again
        scm.testFlushTasks();
        expect(supplier.product, 3);
        expect(producer.product, 13);

        // Don't animate supplier anymore
        // Tick will not have an effect anymore.
        supplier.isAnimated = false;
        scm.testFlushTasks();
        expect(supplier.product, 3);
        expect(producer.product, 13);
      },
    );

    test(
      'should prefer realtime nodes',
      () {
        // .................................
        // Create the following supply chain
        //  key
        //   |-synth
        //   |  |-audio (realtime)
        //   |
        //   |-screen
        //   |  |-grid

        final scope = Scope.example();
        final scm = scope.scm;
        scope.mockContent(
          {
            'key': nbp(
              from: [],
              to: 'key',
              init: 0,
              produce: (c, p) {
                return (p) + 1;
              },
            ),
            'synth': nbp(
              from: ['key'],
              to: 'synth',
              init: 0,
              produce: (c, p) {
                return (c.first as int) * 10;
              },
            ),
            'audio': nbp(
              from: ['synth'],
              to: 'audio',
              init: 0,
              produce: (c, p) {
                return (c.first as int) + 1;
              },
            ),
            'screen': nbp(
              from: ['key'],
              to: 'screen',
              init: 0,
              produce: (c, p) {
                return (c.first as int) * 100;
              },
            ),
            'grid': nbp(
              from: ['screen'],
              to: 'grid',
              init: 0,
              produce: (c, p) {
                return (c.first as int) + 2;
              },
            ),
          },
        );

        // .............................
        scm.testFlushTasks(tick: false);

        final key = scope.findNode<int>('key')!;
        final synth = scope.findNode<int>('synth')!;
        final audio = scope.findNode<int>('audio')!;
        final screen = scope.findNode<int>('screen')!;
        final grid = scope.findNode<int>('grid')!;

        // .........................
        // Initially all nodes have initial values
        expect(key.product, 0);
        expect(synth.product, 0);
        expect(audio.product, 0);
        expect(screen.product, 0);
        expect(grid.product, 0);

        // Trigger the first frame to let all nodes produce
        scm.tick();
        scm.testFlushTasks(tick: false);
        expect(key.product, 1);
        expect(synth.product, 10);
        expect(audio.product, 11);
        expect(screen.product, 100);
        expect(grid.product, 102);

        final allNodes = [key, synth, audio, screen, grid];
        final realtimeNodes = [key, synth, audio];
        final normalNodes = [screen, grid];

        expectPriority(allNodes, Priority.frame);
        expect(scm.minProductionPriority, Priority.realtime);

        // .....................
        // Test priority changes

        // Let audio be a realtime node
        audio.ownPriority = Priority.realtime;

        // After flusing micro tasks ...
        scm.testRunFastTasks();
        expectPriority(realtimeNodes, Priority.realtime);
        expectPriority(normalNodes, Priority.frame);

        // Set back audio node to normal priority.
        // All nodes should have normal priority again.
        audio.ownPriority = Priority.frame;
        scm.testRunFastTasks();
        expectPriority(allNodes, Priority.frame);

        // ..........................
        // Test prioritzed processing

        // Set audio node to realtime priority again
        audio.ownPriority = Priority.realtime;
        scm.testRunFastTasks();
        expectPriority(realtimeNodes, Priority.realtime);
        expectPriority(normalNodes, Priority.frame);

        // Before nothing is stage
        expectIsStaged(allNodes, false);

        // Let's change the key
        scm.nominate(key);

        // All nodes should be staged. But no node is ready.
        scm.testRunFastTasks();
        expectIsStaged(allNodes, true);
        expectIsReady(allNodes, false);

        // First the realtime nodes key, synth, audio should be processed
        scm.testRunFastTasks(); // Realtime nodes are processed using fast tasks
        expectIsReady(allNodes, false, except: [key]);

        scm.testRunFastTasks();
        expectIsReady(allNodes, false, except: [key, synth]);

        scm.testRunFastTasks();
        expectIsReady(allNodes, false, except: [key, synth, audio]);

        // .....................................
        // After having processed all realtime nodes, visual nodes follow.
        expectIsReady(allNodes, true, except: [screen, grid]);
        expect(
          scm.preparedNodes.where(
            (element) => !element.isMetaNode,
          ),
          [screen],
        );

        // Lets flush all tasks
        scm.testFlushTasks(tick: false);

        // screen and grid are not still ready
        // because minimum production priority is set to realtime
        expectIsReady([screen, grid], false);

        // Let's trigger a frame. Minimum production priority will be lowered.
        expect(scm.minProductionPriority, Priority.realtime);
        scm.tick();
        expect(scm.minProductionPriority, Priority.frame);

        // Screen should be processed. But not grid.
        scm.testRunNormalTasks();
        expect(screen.isReady, isTrue);
        expect(grid.isReady, isFalse);

        // In the last event loop cycle, also grid should be processed
        scm.testRunNormalTasks();
        expectIsReady([screen, grid], true);
      },
    );

    test('should throw if hasNewProduct(node) is called without nomination',
        () {
      // Create a node
      final node = Node.example(scope: scope);

      // Call hasNewProduct() without nomination.
      // Throws.
      expect(
        () => node.scm.hasNewProduct(node),
        throwsA(
          predicate(
            (StateError p0) {
              expect(
                  p0.message,
                  'Node "$node" did call "hasNewProduct()" '
                  'without being nominated before.');
              return true;
            },
          ),
        ),
      );
    });

    group('should handle timeouts', () {
      late Scope scope;
      late Scm scm;
      late Node<int> supplierA;
      late Node<int> supplierB;
      late Node<int> producer;

      setUp(
        () {
          scope = Scope.example();
          scm = scope.scm;

          // Create a chain containing
          // - a supplierA, not timing out
          // - a supplierB, timing out
          // - and a producer

          supplierB = _NodeThatTimesOut(
            scope: scope,
            bluePrint: nbp(
              from: [],
              to: 'b',
              init: 0,
              produce: (c, p) => p++,
            ),
          );

          supplierA = nbp(
            from: [],
            to: 'a',
            init: 0,
            produce: (c, p) => p++,
          ).instantiate(scope: scope);

          producer = nbp(
            from: ['a', 'b'],
            to: 'produce',
            init: 0,
            produce: (c, p) => (c.first as int) + (c.last as int),
          ).instantiate(scope: scope);
        },
      );

      test(
        'with shouldTimeOut false',
        () {
          // Disable timeouts
          scm.shouldTimeOut = true;

          // Make producer a realtime node for fast processing
          producer.ownPriority = Priority.realtime;

          // Flush all micro tasks -> Nodes should produce
          scm.testFlushTasks(tick: false);

          // SupplierA is not ready
          expect(supplierA.isReady, isTrue);

          // SupplierB is not announced update. It is not ready.
          expect(supplierB.isReady, isFalse);

          // Producer is not ready, because one of its suppliers is not ready.
          expect(producer.isReady, isFalse);

          // Producer could not produce because supplerB is timing out
          expect(producer.product, 0);

          // Now assume producer b is ready
          scm.hasNewProduct(supplierB);
          scm.testFlushTasks(tick: false);

          // Now everybody is ready
          expect(supplierA.isReady, isTrue);
          expect(supplierB.isReady, isTrue);
          expect(supplierB.isReady, isTrue);
        },
      );

      test(
        'with shouldTimeOut true',
        () {
          // Disable timeouts
          scm.shouldTimeOut = true;

          // Make producer a realtime node for fast processing
          producer.ownPriority = Priority.realtime;

          // Set clock
          const elapsedTime = Duration(milliseconds: 123);
          scm.testStopwatch.elapse(elapsedTime);

          // Flush all micro tasks -> Nodes should produce
          scm.testFlushTasks();

          // SupplierA is ready
          expect(supplierA.isReady, isTrue);
          expect(supplierA.productionStartTime, elapsedTime);

          // SupplierB is not announced update. It is not ready.
          expect(supplierB.isReady, isFalse);
          expect(supplierB.productionStartTime, elapsedTime);

          // Producer is not ready, because one of its suppliers is not ready.
          expect(producer.isReady, isFalse);
          expect(producer.productionStartTime, Duration.zero);

          // Producer could not produce because supplerB is timing out
          expect(producer.product, 0);

          // Exceed time over timeout duration
          scm.testStopwatch.elapse(scm.timeout);

          // Let check timer fire
          expect(scm.testTimer, isNotNull);
          expect(scm.testTimer?.isCancelled, isFalse);
          scm.testTimer?.fire();

          // Run fast tasks
          scm.testRunFastTasks();

          // SupplerB should be marked as isTimedOut
          expect(supplierB.isTimedOut, isTrue);

          // Timing out means that supplierB is marked as ready.
          expect(supplierB.isReady, isTrue);

          // Timer should be cancelled
          expect(scm.testTimer, isNull);

          // Producer will now produce with the existing product
          // of supplierB.
          expect(producer.isReady, isTrue);
          expect(producer.product, supplierA.product + supplierB.product);
        },
      );
    });

    group('nodesWithKey<T>(key)', () {
      test('should return all nodes with a given key and type', () {
        final root = Scope.root(key: 'example', scm: Scm.testInstance);
        final scm = root.scm;
        final chain0 =
            Scope(bluePrint: const ScopeBluePrint(key: 's0'), parent: root);
        final chain1 =
            Scope(bluePrint: const ScopeBluePrint(key: 's1'), parent: root);
        final chain2 =
            Scope(bluePrint: const ScopeBluePrint(key: 's2'), parent: root);

        // Create some nodes
        final intNodeA0 = Node<int>(
          bluePrint: NodeBluePrint(
            key: 'a',
            produce: (c, p) => 1,
            initialProduct: 1,
          ),
          scope: chain0,
        );

        final intNodeA1 = Node<int>(
          bluePrint: NodeBluePrint(
            key: 'a',
            produce: (c, p) => 1,
            initialProduct: 1,
          ),
          scope: chain1,
        );

        final stringNodeA = Node<String>(
          bluePrint: NodeBluePrint(
            key: 'a',
            produce: (c, p) => 'a',
            initialProduct: 'a',
          ),
          scope: chain2,
        );

        final stringNodeB = Node<String>(
          bluePrint: NodeBluePrint(
            key: 'b',
            produce: (c, p) => 'b',
            initialProduct: 'b',
          ),
          scope: chain2,
        );

        expect(scm.nodesWithKey<int>('a'), [intNodeA0, intNodeA1]);
        expect(scm.nodesWithKey<String>('a'), [stringNodeA]);
        expect(scm.nodesWithKey<String>('b'), [stringNodeB]);
        expect(
          scm.nodesWithKey<dynamic>('a').toSet(),
          {intNodeA0, intNodeA1, stringNodeA},
        );
      });
    });

    group('should handle inserts correctly', () {
      test('general workflow', () {
        // Create insert2
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

        // Insert a first insert 2, adding 2 to the original product
        final insert2 = Insert.example(
          key: 'insert2',
          produce: (components, previousProduct) => previousProduct + 2,
          host: host,
        );

        scm.testFlushTasks();
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
          produce: (components, previousProduct) => previousProduct * 3,
          host: host,
          index: 0,
        );
        scm.testFlushTasks();

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
          produce: (components, previousProduct) => previousProduct * 4,
          host: host,
          index: 1,
        );
        scm.testFlushTasks();
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
          produce: (components, previousProduct) => previousProduct + 10,
          host: host,
          index: 3,
        );
        scm.testFlushTasks();
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
        scm.testFlushTasks();
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
        scm.testFlushTasks();
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
        scm.testFlushTasks();
        expect(host.inserts, [insert2]);
        expect(insert2.input, host);
        expect(insert2.output, host);
        expect(host.originalProduct, 1);
        expect(host.product, 1 + 2);
        expect(customer0.product, 1 + 2);
        expect(customer1.product, 1 + 2);

        // Remove last remaining insert node
        insert2.dispose();
        scm.testFlushTasks();
        expect(host.inserts, <Insert<dynamic>>[]);
        expect(host.originalProduct, 1);
        expect(host.product, 1);
        expect(customer0.product, 1);
        expect(customer1.product, 1);
      });

      test('when a node is scheduled also the inserts should work', () {
        int hostCalls = 0;
        final host = Node.example(
          bluePrint: NodeBluePrint<int>(
            key: 'host',
            initialProduct: 0,
            produce: (components, previousProduct) => ++hostCalls,
          ),
        );

        final scope = host.scope;
        final scm = host.scope.scm;

        final customer0 =
            host.bluePrint.forwardTo('customer0').instantiate(scope: scope);

        var p0Calls = 0;
        final insert0 = NodeBluePrint.example(
          key: 'insert0',
          produce: (components, previousProduct) => ++p0Calls,
        ).instantiateAsInsert(host: host);

        var p1Calls = 0;
        final insert1 = NodeBluePrint.example(
          key: 'insert1',
          produce: (components, previousProduct) => ++p1Calls,
        ).instantiateAsInsert(host: host);

        // Check state before
        scm.testFlushTasks();
        expect(hostCalls, 1);
        expect(p0Calls, 1);
        expect(p1Calls, 1);

        // Nominate the host node for production
        scm.nominate(host);

        // Product
        scm.testFlushTasks();

        // The host as well the inserts should have been produced
        expect(host.product, 2);
        expect(p0Calls, 2);
        expect(p1Calls, 2);

        // Dispose
        customer0.dispose();
        insert0.dispose();
        insert1.dispose();
      });
    });

    group('special cases', () {
      test('should be able to survive a shortly missed supplier', () {
        // ......................................................
        // Create a customer with a supplier not already existing
        final scope = Scope.example();
        final scm = scope.scm;

        final customer = NodeBluePrint<int>(
          key: 'customer',
          initialProduct: 0,
          suppliers: ['supplier'],
          produce: (components, previousProduct) {
            return (components[0] as int) + 1;
          },
        ).instantiate(scope: scope);

        // .....................................
        // Create a node that installs a builder
        // that adds the missed supplier
        NodeBluePrint(
          key: 'builderInstaller',
          initialProduct: 0,
          produce: (components, previousProduct) {
            ScBuilderBluePrint(
              key: 'builder',
              shouldDigInto: (scope) => const [
                'example',
              ].contains(scope.key),
              addNodes: ({required hostScope}) {
                if (hostScope == scope) {
                  return [
                    const NodeBluePrint<int>(
                      key: 'supplier',
                      initialProduct: 5,
                    ),
                  ];
                }
                return [];
              },
            ).instantiate(scope: scope);

            return 1;
          },
        ).instantiate(scope: scope);

        // The missed supplier should be found
        // also if it is created later
        scm.testFlushTasks();
        expect(customer.product, 6);
      });

      test('should throw when an replaced node has invalid suppliers', () {
        // Create a node with valid suppliers
        final scope = Scope.example();
        final scm = scope.scm;
        nbp(from: [], to: 'a', init: 0).instantiate(scope: scope);
        scm.testFlushTasks();

        // Replace the node with a node that has invalid suppliers
        final invalidNode = nbp(from: ['unknown'], to: 'a', init: 0);
        scope.addOrReplaceNode(invalidNode);

        expect(
          () => scm.testFlushTasks(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Node "root.example.a": Supplier with key "unknown" not found.',
            ),
          ),
        );
      });
    });

    group('smartNodes', () {
      smartNodeTest();
    });
  });

  group('test helpers', () {
    test('should be provided during testing', () {
      // Create some variables
      final scm = Scm.example();
      scm.testFlushTasks();
      expect(scm.isTest, isTrue);
      var fastTaskCounter = 0;
      var normalTaskCounter = 0;

      // Create a helper
      void createAndAddTasks() {
        (scm.testFastTasks as List<Task>).add(
          () => fastTaskCounter++,
        );
        expect(scm.testFastTasks.length, 1);

        // Add a task to normal tasks
        (scm.testNormalTasks as List<Task>).add(
          () => normalTaskCounter++,
        );
        expect(scm.testNormalTasks.length, 1);
      }

      // Add a task to fast tasks
      createAndAddTasks();

      // ..............
      // Run fast tasks
      scm.testRunFastTasks();
      expect(fastTaskCounter, 1);
      expect(scm.testFastTasks, isEmpty);

      // Run normal tasks
      scm.testRunNormalTasks();
      expect(normalTaskCounter, 1);
      expect(scm.testNormalTasks, isEmpty);

      // ..................
      // Create tasks again
      createAndAddTasks();

      // Clear tasks
      scm.testClearScheduledTasks();
      expect(scm.testFastTasks, isEmpty);
      expect(scm.testNormalTasks, isEmpty);
    });

    group('testInstance', () {
      test('should return a new instance with isTest == true', () {
        final scm = Scm.testInstance;
        expect(scm.isTest, isTrue);
      });
    });

    group('addNode, removeNode', () {
      test('should remove the node', () {
        final scm = Scm.testInstance;
        final node = Node.example(scope: scope);
        scm.addNode(node);
        expect(scm.nodes, contains(node));

        scm.removeNode(node);
        expect(scm.nodes, isNot(contains(node)));
      });

      test('should assert that the node is not disposed', () {
        final scm = Scm.testInstance;

        final node = Node.example(scope: scope);
        final id = node.id;
        node.dispose();

        expect(
          () => scm.addNode(node),
          throwsA(
            predicate(
              (AssertionError p0) {
                expect(
                  p0.message,
                  contains('example/aaliyah with id $id is disposed.'),
                );
                return true;
              },
            ),
          ),
        );
      });
    });

    group('clear()', () {
      test('should clear nominated, prepared and producing nodes', () {
        fakeAsync((fake) {
          final scm = Scm.testInstance;
          final node = Node.example(scope: scope);
          scm.addNode(node);

          (scm.nominatedNodes as Set<Node>).add(node);
          (scm.preparedNodes as Set<Node>).add(node);
          (scm.producingNodes as Set<Node>).add(node);

          // Before
          expect(scm.nominatedNodes, contains(node));
          expect(scm.preparedNodes, contains(node));
          expect(scm.producingNodes, contains(node));

          // Apply
          scm.clear();

          // After
          expect(scm.nominatedNodes, isNot(contains(node)));
          expect(scm.preparedNodes, isNot(contains(node)));
          expect(scm.producingNodes, isNot(contains(node)));
        });
      });
    });
  });

  test('Test with non test environment should work fine', () {
    fakeAsync((fake) {
      final scm = Scm.example(isTest: false);
      final chain = Scope.root(key: 'example', scm: scm);
      final node = Node.example(scope: chain);
      expect(node.product, 0);
      scm.nominate(node);
      fake.flushMicrotasks();
      expect(node.product, 1);
    });
  });
}

class _NodeThatTimesOut<T> extends Node<T> {
  _NodeThatTimesOut({
    required super.bluePrint,
    required super.scope,
  });

  @override
  void produce({bool announce = true}) {
    // Do nothing. This node will time out.
  }
}
