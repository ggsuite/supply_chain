import 'package:fake_async/fake_async.dart';
import 'package:supply_chain/src/schedule_task.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';
import './sample_nodes.dart';

void main() {
  // ...........................................................................
  void produceInitially() {
    scm.tick();

    // Flush all micro tasks
    scm.testFlushTasks();

    // All products should be ready and have produced
    expect(supplier.isReady, isTrue);
    expect(producer.isReady, isTrue);
    expect(customer.isReady, isTrue);

    expect(supplier.product, 1);
    expect(producer.product, 10);
    expect(customer.product, 11);
  }

  // ...........................................................................
  setUp(
    () {
      scm = Scm(
        isTest: true,
      );

      scope = Scope.example(scm: scm);

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
    // #########################################################################
    test('should initialize correctly', () {
      // ..............
      // Initialization

      // Add one supplier, producer and customer
      initSupplierProducerCustomer();
      createSimpleChain();

      // ....................
      // Check pre-conditions

      // Did connect scm with nodes?
      expect(scm, supplier.scm);
      expect(scm, producer.scm);
      expect(scm, customer.scm);

      // ..................
      // Initial nomination

      // Freshly added nodes are immediately nominated
      expect(scm.nominatedNodes, [supplier, producer, customer]);

      // No node is staged for production
      expect(supplier.isStaged, isFalse);
      expect(producer.isStaged, isFalse);
      expect(customer.isStaged, isFalse);

      // Products should be inital products
      expect(supplier.product, 0);
      expect(producer.product, 0);
      expect(customer.product, 0);

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
      expect(scm.preparedNodes, [supplier, producer, customer]);

      // .................
      // Initial execution

      // Initally no node has yet produced
      expect(supplier.product, 0);
      expect(producer.product, 0);
      expect(customer.product, 0);

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
      expect(scm.testFastTasks, isEmpty);

      // Product should still be initial
      final productBefore = supplier.product;
      expect(productBefore, 0);

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
    });

    // #########################################################################
    test('should animate correctly', () {
      // Create a chain, containing a supplier, a producer and a customer
      initSupplierProducerCustomer();
      createSimpleChain();
      produceInitially();

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
      expect(producer.product, 20);
      expect(customer.product, 21);

      // Each time tick() is called, the production starts again
      scm.tick();
      scm.testFlushTasks();
      expect(supplier.product, 3);
      expect(producer.product, 30);
      expect(customer.product, 31);

      // Don't animate supplier anymore
      // Tick will not have an effect anymore.
      supplier.isAnimated = false;
      scm.tick();
      scm.testFlushTasks();
      expect(supplier.product, 3);
      expect(producer.product, 30);
      expect(customer.product, 31);
    });

    // #########################################################################
    test('should prefer realtime nodes', () {
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

      // .........................
      // Initially all nodes have initial values
      scm.testFlushTasks();
      expect(key.product, 0);
      expect(synth.product, 0);
      expect(audio.product, 0);
      expect(screen.product, 0);
      expect(grid.product, 0);

      // Trigger the first frame to let all nodes produce
      scm.tick();
      scm.testFlushTasks();
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
      expect(scm.preparedNodes, [screen]);

      // Lets flush all tasks
      scm.testFlushTasks();

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
    });

    // #########################################################################
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

    // #########################################################################
    group('should handle timeouts', () {
      test('with shouldTimeOut false', () {
        initTimeoutExampleNodes();

        // Create a chain containing
        // - a supplierA, timing out
        // - a supplierB, not timing out
        // - and a producer
        producer.addSupplier(supplierA);
        producer.addSupplier(supplierB);

        // Disable timeouts
        scm.shouldTimeOut = true;

        // Make producer a realtime node for fast processing
        producer.ownPriority = Priority.realtime;

        // Flush all micro tasks -> Nodes should produce
        scm.testFlushTasks();

        // SupplierA is ready
        expect(supplierA.isReady, isTrue);

        // SupplierB is not announced update. It is not ready.
        expect(supplierB.isReady, isFalse);

        // Producer is not ready, because one of its suppliers is not ready.
        expect(producer.isReady, isFalse);

        // Producer could not produce because supplerB is timing out
        expect(producer.product, 0);

        // Now assume producer b is ready
        scm.hasNewProduct(supplierB);
        scm.testFlushTasks();

        // Now everybody is ready
        expect(supplierA.isReady, isTrue);
        expect(supplierB.isReady, isTrue);
        expect(supplierB.isReady, isTrue);
      });

      test('with shouldTimeOut true', () {
        initTimeoutExampleNodes();

        // Create a chain containing
        // - a supplierA, timing out
        // - a supplierB, not timing out
        // - and a producer
        producer.addSupplier(supplierA);
        producer.addSupplier(supplierB);

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
      });
    });

    group('nodesWithKey<T>(key)', () {
      test('should return all nodes with a given key and type', () {
        final root = Scope.root(key: 'Example', scm: Scm.testInstance);
        final scm = root.scm;
        final chain0 = Scope(key: '0', parent: root);
        final chain1 = Scope(key: '1', parent: root);
        final chain2 = Scope(key: '2', parent: root);

        // Create some nodes
        final intNodeA0 = Node<int>(
          bluePrint: NodeBluePrint(
            key: 'A',
            produce: (c, p) => 1,
            initialProduct: 1,
          ),
          scope: chain0,
        );

        final intNodeA1 = Node<int>(
          bluePrint: NodeBluePrint(
            key: 'A',
            produce: (c, p) => 1,
            initialProduct: 1,
          ),
          scope: chain1,
        );

        final stringNodeA = Node<String>(
          bluePrint: NodeBluePrint(
            key: 'A',
            produce: (c, p) => 'A',
            initialProduct: 'A',
          ),
          scope: chain2,
        );

        final stringNodeB = Node<String>(
          bluePrint: NodeBluePrint(
            key: 'B',
            produce: (c, p) => 'B',
            initialProduct: 'B',
          ),
          scope: chain2,
        );

        expect(scm.nodesWithKey<int>('A'), [intNodeA0, intNodeA1]);
        expect(scm.nodesWithKey<String>('A'), [stringNodeA]);
        expect(scm.nodesWithKey<String>('B'), [stringNodeB]);
        expect(
          scm.nodesWithKey<dynamic>('A').toSet(),
          {intNodeA0, intNodeA1, stringNodeA},
        );
      });
    });
  });

  // ###########################################################################
  group('test helpers', () {
    // #########################################################################
    test('should be provided during testing', () {
      // Create some variables
      final scm = Scm.example();
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

    // #########################################################################
    group('testInstance', () {
      test('should return a new instance with isTest == true', () {
        final scm = Scm.testInstance;
        expect(scm.isTest, isTrue);
      });
    });

    // #########################################################################
    group('removeNode', () {
      test('should remove the node', () {
        final scm = Scm.testInstance;
        final node = Node.example(scope: scope);
        scm.addNode(node);
        expect(scm.nodes, contains(node));

        scm.removeNode(node);
        expect(scm.nodes, isNot(contains(node)));
      });
    });

    // #########################################################################
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

  // ###########################################################################
  test('Test with non test environment should work fine', () {
    fakeAsync((fake) {
      final scm = Scm.example(isTest: false);
      final chain = Scope.root(key: 'Example', scm: scm);
      final node = Node.example(scope: chain);
      expect(node.product, 0);
      scm.nominate(node);
      fake.flushMicrotasks();
      expect(node.product, 1);
    });
  });
}
