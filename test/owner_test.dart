// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('Owner', () {
    group('example', () {
      test('should have only null callbacks', () {
        expect(Owner.example.willDispose, isNull);
        expect(Owner.example.didDispose, isNull);
        expect(Owner.example.willErase, isNull);
        expect(Owner.example.didErase, isNull);
        expect(Owner.example.willUndispose, isNull);
        expect(Owner.example.didUndispose, isNull);
      });
    });
  });
}
