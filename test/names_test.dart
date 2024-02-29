// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_supply_chain/src/names.dart';
import 'package:test/test.dart';

void main() {
  group('Names', () {
    group('nextName', () {
      test('should return the next name', () {
        testSetNextCounter(0);
        expect(nextName, names[0]);
        expect(nextName, names[1]);
        expect(nextName, names[2]);

        testSetNextCounter(0);
        expect(nextName, names[0]);
        expect(nextName, names[1]);
        expect(nextName, names[2]);

        testSetNextCounter(names.length - 1);
        expect(nextName, names.last);
        expect(nextName, names.first);
      });
    });
  });
}
