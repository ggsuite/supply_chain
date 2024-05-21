// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('SubChainManagerBluePrint', () {
    group('example', () {
      test('should work', () {
        const subChainManagerBluePrint = SubChainManagerBluePrint.example;
        subChainManagerBluePrint.produce([], []);
        expect(subChainManagerBluePrint, isNotNull);
      });
    });
  });
}
