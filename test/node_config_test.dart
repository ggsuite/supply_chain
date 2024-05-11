// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('NodeConfig', () {
    group('example', () {
      test('with key', () {
        final nodeConfig = NodeConfig.example(key: 'Node');
        expect(nodeConfig.key, 'Node');
        expect(nodeConfig.initialProduct, 0);
        expect(nodeConfig.suppliers, ['Supplier']);
        expect(nodeConfig.produce([], 0), 1);
      });

      test('without key', () {
        final nodeConfig = NodeConfig.example();
        expect(nodeConfig.key, 'Aaliyah');
        expect(nodeConfig.initialProduct, 0);
        expect(nodeConfig.suppliers, ['Supplier']);
        expect(nodeConfig.produce([], 0), 1);
      });
    });
  });
}
