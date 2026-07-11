// @license
// Copyright (c) 2019 - 2026 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('linearCurve', () {
    test('returns its input unchanged', () {
      expect(linearCurve(0.0), 0.0);
      expect(linearCurve(0.5), 0.5);
      expect(linearCurve(1.0), 1.0);
    });
  });

  group('AnimatedNodeBluePrint', () {
    AnimatedNodeBluePrint<double> doubleBluePrint({
      List<String> suppliers = const ['target'],
      int totalFrames = 4,
    }) => AnimatedNodeBluePrint<double>(
      key: 'smooth',
      initialProduct: 0.0,
      suppliers: suppliers,
      totalFrames: totalFrames,
      curve: linearCurve,
      lerp: (a, b, t) => a + (b - a) * t,
    );

    test('is a NodeBluePrint that enables change gating by default', () {
      final bluePrint = doubleBluePrint(totalFrames: 3);
      expect(bluePrint, isA<NodeBluePrint<double>>());
      expect(bluePrint.totalFrames, 3);
      expect(bluePrint.propagateOnChangeOnly, isTrue);
      expect(bluePrint.changeComparator, isNotNull);
    });

    test('uses == for change detection by default', () {
      final bluePrint = doubleBluePrint();
      expect(bluePrint.isEqual(1.0, 1.0), isTrue);
      expect(bluePrint.isEqual(1.0, 2.0), isFalse);
    });

    test('accepts a custom equals', () {
      final bluePrint = AnimatedNodeBluePrint<double>(
        key: 'smooth',
        initialProduct: 0.0,
        suppliers: ['target'],
        totalFrames: 4,
        curve: linearCurve,
        lerp: (a, b, t) => a + (b - a) * t,
        equals: (a, b) => (a - b).abs() < 0.5,
      );
      expect(bluePrint.isEqual(1.0, 1.2), isTrue);
      expect(bluePrint.isEqual(1.0, 2.0), isFalse);
    });

    group('check', () {
      test('throws unless there is exactly one supplier', () {
        expect(
          () => doubleBluePrint(suppliers: const []).check(),
          throwsArgumentError,
        );
        expect(
          () => doubleBluePrint(suppliers: const ['a', 'b']).check(),
          throwsArgumentError,
        );
      });

      test('throws if totalFrames < 1', () {
        expect(
          () => doubleBluePrint(totalFrames: 0).check(),
          throwsArgumentError,
        );
      });

      test('accepts a valid configuration', () {
        expect(() => doubleBluePrint(totalFrames: 1).check(), returnsNormally);
      });
    });

    group('createNode', () {
      test('creates an AnimatedNode', () {
        final scope = Scope.example();
        scope.mockContent({'target': 0.0});
        expect(
          doubleBluePrint().createNode(scope: scope),
          isA<AnimatedNode<double>>(),
        );
      });
    });

    group('produce', () {
      test('the installed produce function drives the animation', () {
        final scope = Scope.example();
        final scm = scope.scm;
        scope.mockContent({
          'target': 0.0,
          'smooth': doubleBluePrint(totalFrames: 2),
        });
        final target = scope.findNode<double>('target')!;
        final smooth = scope.findNode<double>('smooth')!;
        scm.flush();

        target.product = 1.0;
        scm.flush(); // restart
        scm.flush(); // frame 1 -> 0.5
        expect(smooth.product, closeTo(0.5, 1e-9));
      });
    });

    group('instantiate', () {
      test('returns the same AnimatedNode for the same key', () {
        final scope = Scope.example();
        final bluePrint = doubleBluePrint();
        scope.mockContent({'target': 0.0, 'smooth': bluePrint});
        final n1 = scope.findNode<double>('smooth');
        final n2 = bluePrint.instantiate(scope: scope);
        expect(identical(n1, n2), isTrue);
        expect(n2, isA<AnimatedNode<double>>());
      });

      test('is honored by Scope.findOrCreateNode', () {
        final scope = Scope.example();
        scope.mockContent({'target': 0.0});
        expect(
          scope.findOrCreateNode(doubleBluePrint()),
          isA<AnimatedNode<double>>(),
        );
      });
    });

    group('forDouble', () {
      test('interpolates linearly and enables gating', () {
        final bluePrint = AnimatedNodeBluePrint.forDouble(
          key: 'smooth',
          initialProduct: 0.0,
          suppliers: ['target'],
          totalFrames: 4,
          curve: linearCurve,
        );
        expect(bluePrint.lerp(0.0, 10.0, 0.25), closeTo(2.5, 1e-9));
        expect(bluePrint.lerp(0.0, 10.0, 1.0), closeTo(10.0, 1e-9));
        expect(bluePrint.propagateOnChangeOnly, isTrue);
      });

      test('treats NaN as equal to NaN', () {
        final bluePrint = AnimatedNodeBluePrint.forDouble(
          key: 'smooth',
          initialProduct: 0.0,
          suppliers: ['target'],
          totalFrames: 4,
          curve: linearCurve,
        );
        expect(bluePrint.isEqual(double.nan, double.nan), isTrue);
        expect(bluePrint.isEqual(1.0, 1.0), isTrue);
        expect(bluePrint.isEqual(1.0, 2.0), isFalse);
      });
    });

    group('forInt', () {
      test('interpolates with rounding', () {
        final bluePrint = AnimatedNodeBluePrint.forInt(
          key: 'smooth',
          initialProduct: 0,
          suppliers: ['target'],
          totalFrames: 4,
          curve: linearCurve,
        );
        expect(bluePrint.lerp(0, 10, 0.0), 0);
        expect(bluePrint.lerp(0, 10, 0.5), 5);
        expect(bluePrint.lerp(0, 10, 1.0), 10);
        expect(bluePrint.propagateOnChangeOnly, isTrue);
      });
    });
  });
}
