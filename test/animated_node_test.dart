// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  late Scope scope;
  late Scm scm;
  late Node<double> target;
  late AnimatedNode<double> smooth;

  // ...........................................................................
  void build({int totalFrames = 4, double Function(double t)? curve}) {
    scope = Scope.example();
    scm = scope.scm;
    scope.mockContent({
      'target': 0.0,
      'smooth': AnimatedNodeBluePrint.forDouble(
        key: 'smooth',
        initialProduct: 0.0,
        suppliers: ['target'],
        totalFrames: totalFrames,
        curve: curve ?? linearCurve,
      ),
    });
    target = scope.findNode<double>('target')!;
    smooth = scope.findNode<double>('smooth')! as AnimatedNode<double>;
    scm.flush();
  }

  group('AnimatedNode', () {
    group('example', () {
      test('creates a settled animated node', () {
        final node = AnimatedNode.example();
        expect(node, isA<AnimatedNode<double>>());
        expect(node.isAnimating, isFalse);
      });
    });

    group('startup', () {
      test('snaps the first input without animating', () {
        build();
        expect(smooth.product, 0.0);
        expect(smooth.isAnimating, isFalse);
        expect(scm.animatedNodes, isNot(contains(smooth)));
      });
    });

    group('basic animation', () {
      test('ramps from the current output to the new input over the '
          'frames, one step per tick', () {
        build(totalFrames: 4);

        target.product = 1.0;

        // The tick that delivers the new target already advances the first
        // frame - the animation starts moving immediately.
        scm.flush();
        expect(smooth.product, closeTo(0.25, 1e-9));
        expect(smooth.isAnimating, isTrue);
        expect(smooth.frame, 1);

        // Each tick advances exactly one frame.
        scm.flush();
        expect(smooth.product, closeTo(0.5, 1e-9));
        scm.flush();
        expect(smooth.product, closeTo(0.75, 1e-9));

        // Final frame settles on the exact endpoint and stops animating.
        scm.flush();
        expect(smooth.product, closeTo(1.0, 1e-9));
        expect(smooth.isAnimating, isFalse);

        // Once settled, further ticks are no-ops.
        scm.flush();
        expect(smooth.product, closeTo(1.0, 1e-9));
        expect(scm.animatedNodes, isNot(contains(smooth)));
      });
    });

    group('retargeting', () {
      test('mid-animation retarget rebases from the current visible value', () {
        build(totalFrames: 4);

        target.product = 1.0;
        scm.flush(); // 0.25
        scm.flush(); // 0.5
        expect(smooth.product, closeTo(0.5, 1e-9));

        target.product = 3.0;
        scm.flush(); // rebase from 0.5 towards 3.0, first frame consumed
        expect(smooth.from, closeTo(0.5, 1e-9));
        expect(smooth.to, closeTo(3.0, 1e-9));
        expect(smooth.frame, 1);
        expect(smooth.product, closeTo(1.125, 1e-9)); // 0.5 + 2.5 * 0.25

        scm.flush(); // 0.5 + 2.5 * 0.5 = 1.75
        expect(smooth.product, closeTo(1.75, 1e-9));
      });

      test('a target changing on every tick keeps easing toward the '
          'latest value', () {
        build(totalFrames: 4);

        // Before the fix the restart branch never consumed a frame, so a
        // continuously moving target froze the output at 0.0 forever.
        for (var i = 1; i <= 8; i++) {
          target.product = i.toDouble();
          scm.flush();
        }
        expect(smooth.product, greaterThan(0.0));
        expect(smooth.isAnimating, isTrue);

        // Once the target stops moving, the animation settles on it.
        for (var i = 0; i < 4; i++) {
          scm.flush();
        }
        expect(smooth.product, closeTo(8.0, 1e-9));
        expect(smooth.isAnimating, isFalse);
      });

      test('rewriting the same target does not restart the animation', () {
        build(totalFrames: 4);

        target.product = 1.0;
        scm.flush(); // frame 1
        expect(smooth.frame, 1);

        target.product = 1.0; // same value -> no retarget
        scm.flush();
        expect(smooth.isAnimating, isTrue);
        expect(smooth.frame, 2);
      });

      test('a supplier re-emission between ticks does not consume a '
          'frame', () {
        build(totalFrames: 4);
        smooth.ownPriority = Priority.realtime;

        target.product = 1.0;
        scm.flush();
        final frameAfterTick = smooth.frame;

        // Re-emit the same value without a tick: realtime nodes produce
        // between ticks, but no frame may be consumed.
        target.product = 1.0;
        scm.flush(tick: false);
        expect(smooth.frame, frameAfterTick);
        expect(smooth.isAnimating, isTrue);
      });

      test('retargeting to the current output value snaps and stops', () {
        build(totalFrames: 4);

        var completeCount = 0;
        smooth.onComplete = () => completeCount++;

        target.product = 1.0;
        scm.flush(); // 0.25
        scm.flush(); // 0.5
        expect(smooth.product, closeTo(0.5, 1e-9));

        // Retarget to the value currently on the output: from == to -> snap.
        target.product = 0.5;
        scm.flush();
        expect(smooth.isAnimating, isFalse);
        expect(smooth.product, closeTo(0.5, 1e-9));

        // The snap settles the frame counter: later same-value rewrites must
        // not advance a phantom animation or fire onComplete spuriously.
        for (var i = 0; i < 6; i++) {
          target.product = 0.5;
          scm.flush();
        }
        expect(completeCount, 0);
        expect(smooth.isAnimating, isFalse);
        expect(smooth.product, closeTo(0.5, 1e-9));
      });
    });

    group('settled', () {
      test('an unchanged input on a settled node keeps the settled value', () {
        build(totalFrames: 4);

        target.product = 1.0;
        for (var i = 0; i < 6; i++) {
          scm.flush();
        }
        expect(smooth.isAnimating, isFalse);
        expect(smooth.product, closeTo(1.0, 1e-9));

        // Rewriting the same target re-produces the node while it is settled.
        target.product = 1.0;
        scm.flush();
        expect(smooth.product, closeTo(1.0, 1e-9));
        expect(smooth.isAnimating, isFalse);
      });
    });

    group('curve', () {
      test('applies the animation curve', () {
        build(totalFrames: 4, curve: (t) => t * t);

        target.product = 1.0;
        scm.flush(); // frame 1: t = 0.25, curve = 0.0625
        expect(smooth.product, closeTo(0.0625, 1e-9));
      });
    });

    group('NaN safety', () {
      test('two identical NaN inputs do not restart on every tick', () {
        build(totalFrames: 4);

        target.product = double.nan;
        scm.flush();
        expect(smooth.frame, 1);

        // NaN == NaN is false; the NaN-aware comparator must treat it as
        // unchanged so the animation advances instead of restarting.
        scm.flush();
        expect(smooth.frame, 2);
      });
    });

    group('completion', () {
      test('onComplete fires exactly once when the animation settles', () {
        build(totalFrames: 4);

        var completeCount = 0;
        smooth.onComplete = () => completeCount++;

        target.product = 1.0;
        for (var i = 0; i < 10; i++) {
          scm.flush();
        }

        expect(smooth.product, closeTo(1.0, 1e-9));
        expect(completeCount, 1);
      });

      test('onComplete observes the settled product and may dispose the '
          'node', () {
        build(totalFrames: 4);

        double? productSeenInCallback;
        smooth.onComplete = () {
          productSeenInCallback = smooth.product;
          smooth.dispose();
        };

        target.product = 1.0;
        for (var i = 0; i < 10; i++) {
          scm.flush();
        }

        // The callback ran after the final product was applied and the
        // production was finalized - disposing did not crash the pipeline.
        expect(productSeenInCallback, closeTo(1.0, 1e-9));
        expect(smooth.isDisposed, isTrue);
      });
    });

    group('disposal', () {
      test('a disposed animating node is removed from the animated set', () {
        build(totalFrames: 4);

        // Give smooth a customer so dispose parks it (does not erase it).
        scope.mockContent({
          'downstream': nbp(
            from: ['smooth'],
            to: 'downstream',
            init: 0.0,
            produce: (c, p, n) => c.first as double,
          ),
        });
        scm.flush();

        target.product = 1.0;
        scm.flush();
        expect(smooth.isAnimating, isTrue);
        expect(scm.animatedNodes, contains(smooth));

        smooth.dispose();
        expect(scm.animatedNodes, isNot(contains(smooth)));

        // Ticking must not resurrect it or stall the pipeline.
        for (var i = 0; i < 20; i++) {
          scm.flush();
        }
        expect(scm.animatedNodes, isNot(contains(smooth)));
      });
    });

    group('independent instances', () {
      test('the same blue print animates independently in two scopes', () {
        final bluePrint = AnimatedNodeBluePrint.forDouble(
          key: 'smooth',
          initialProduct: 0.0,
          suppliers: ['target'],
          totalFrames: 4,
          curve: linearCurve,
        );

        final scopeA = Scope.example();
        scopeA.mockContent({'target': 0.0, 'smooth': bluePrint});
        final scopeB = Scope.example();
        scopeB.mockContent({'target': 0.0, 'smooth': bluePrint});

        final targetA = scopeA.findNode<double>('target')!;
        final targetB = scopeB.findNode<double>('target')!;
        final smoothA = scopeA.findNode<double>('smooth')! as AnimatedNode;
        final smoothB = scopeB.findNode<double>('smooth')! as AnimatedNode;
        scopeA.scm.flush();
        scopeB.scm.flush();

        targetA.product = 1.0;
        targetB.product = 10.0;
        scopeA.scm.flush(); // frame 1
        scopeB.scm.flush();

        expect(smoothA.product, closeTo(0.25, 1e-9));
        expect(smoothB.product, closeTo(2.5, 1e-9));
      });
    });

    group('live blue print replacement', () {
      test('a replacement animated blue print applies its config', () {
        build(totalFrames: 4);

        // Overlay the same node with a longer animation.
        smooth.addBluePrint(
          AnimatedNodeBluePrint.forDouble(
            key: 'smooth',
            initialProduct: 0.0,
            suppliers: ['target'],
            totalFrames: 12,
            curve: linearCurve,
          ),
        );
        scm.flush();

        target.product = 1.0;
        scm.flush();
        expect(smooth.product, closeTo(1.0 / 12.0, 1e-9));
      });

      test('mockedProduct stops the animation', () {
        build(totalFrames: 4);

        target.product = 1.0;
        scm.flush();
        expect(smooth.isAnimating, isTrue);

        smooth.mockedProduct = 9.0;
        scm.flush();
        expect(smooth.isAnimating, isFalse);
        expect(scm.animatedNodes, isNot(contains(smooth)));
        expect(smooth.product, 9.0);
      });

      test('overlaying a non-animated blue print stops the animation', () {
        build(totalFrames: 4);

        target.product = 1.0;
        scm.flush();
        expect(smooth.isAnimating, isTrue);

        final overlay = nbp(
          from: ['target'],
          to: 'smooth',
          init: 0.0,
          produce: (c, p, n) => c.first as double,
        );
        smooth.addBluePrint(overlay);
        scm.flush();
        expect(smooth.isAnimating, isFalse);
        expect(scm.animatedNodes, isNot(contains(smooth)));

        // Removing the overlay restores the animated blue print; the next
        // target change animates again.
        smooth.removeBluePrint(overlay);
        scm.flush();
        target.product = 2.0;
        scm.flush();
        expect(smooth.isAnimating, isTrue);
      });
    });

    group('generic types', () {
      test('animates an int with rounded interpolation', () {
        final scope = Scope.example();
        final scm = scope.scm;
        scope.mockContent({
          'target': 0,
          'smooth': AnimatedNodeBluePrint.forInt(
            key: 'smooth',
            initialProduct: 0,
            suppliers: ['target'],
            totalFrames: 4,
            curve: linearCurve,
          ),
        });
        final target = scope.findNode<int>('target')!;
        final smooth = scope.findNode<int>('smooth')! as AnimatedNode<int>;
        scm.flush();

        target.product = 8;
        scm.flush(); // round(8 * 0.25) = 2
        expect(smooth.product, 2);
        scm.flush(); // round(8 * 0.5) = 4
        expect(smooth.product, 4);
        scm.flush(); // round(8 * 0.75) = 6
        scm.flush(); // settle
        expect(smooth.product, 8);
      });
    });

    group('downstream propagation', () {
      test('customers observe every intermediate frame, but the redundant '
          'restart frame is gated', () {
        final scope = Scope.example();
        final scm = scope.scm;
        final recorded = <double>[];
        scope.mockContent({
          'target': 0.0,
          'smooth': AnimatedNodeBluePrint.forDouble(
            key: 'smooth',
            initialProduct: 0.0,
            suppliers: ['target'],
            totalFrames: 4,
            curve: linearCurve,
          ),
          'recorder': nbp(
            from: ['smooth'],
            to: 'recorder',
            init: 0.0,
            produce: (c, p, n) {
              recorded.add(c.first as double);
              return c.first as double;
            },
          ),
        });
        final target = scope.findNode<double>('target')!;
        scm.flush();

        recorded.clear();
        target.product = 1.0;
        for (var i = 0; i < 6; i++) {
          scm.flush();
        }

        // The recorder sees exactly the four value-changing frames - no
        // redundant restart emission.
        expect(recorded, [
          closeTo(0.25, 1e-9),
          closeTo(0.5, 1e-9),
          closeTo(0.75, 1e-9),
          closeTo(1.0, 1e-9),
        ]);
      });
    });
  });

  group('NodeBluePrint.propagateOnChangeOnly', () {
    test('an unchanged product does not schedule the node customers', () {
      final scope = Scope.example();
      final scm = scope.scm;
      scope.mockContent({
        'a': 5,
        'gated': NodeBluePrint<int>(
          key: 'gated',
          initialProduct: 0,
          suppliers: ['a'],
          produce: (c, p, n) => (c.first as int) < 10 ? 7 : 99,
          propagateOnChangeOnly: true,
        ),
        'counter': nbp(
          from: ['gated'],
          to: 'counter',
          init: 0,
          produce: (c, p, n) => p + 1,
        ),
      });
      final a = scope.findNode<int>('a')!;
      final counter = scope.findNode<int>('counter')!;
      scm.flush();
      final produced = counter.product;

      // 'gated' stays 7 -> customer must not be scheduled again.
      a.product = 6;
      scm.flush();
      expect(counter.product, produced);

      // 'gated' changes to 99 -> customer is scheduled.
      a.product = 15;
      scm.flush();
      expect(counter.product, produced + 1);
    });

    test('the first production always propagates, even if it equals the '
        'initial product', () {
      final scope = Scope.example();
      final scm = scope.scm;
      scope.mockContent({
        'a': 0,
        'gated': NodeBluePrint<int>(
          key: 'gated',
          initialProduct: 7,
          suppliers: ['a'],
          produce: (c, p, n) => 7,
          propagateOnChangeOnly: true,
        ),
        'sink': nbp(
          from: ['gated'],
          to: 'sink',
          init: -1,
          produce: (c, p, n) => c.first as int,
        ),
      });
      final sink = scope.findNode<int>('sink')!;
      scm.flush();
      expect(sink.product, 7);
    });
  });
}
