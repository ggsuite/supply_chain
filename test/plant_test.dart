// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/src/plant.dart';
import 'package:test/test.dart';

void main() {
  group('Plant', () {
    test('should work fine', () {
      // const Plant();
      expect(examplePlant(), isNotNull);
    });
  });
}
