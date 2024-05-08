// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/src/keys.dart';
import 'package:test/test.dart';

void main() {
  group('Names', () {
    group('nextName', () {
      test('should return the next key', () {
        testSetNextCounter(0);
        expect(nextKey, keys[0]);
        expect(nextKey, keys[1]);
        expect(nextKey, keys[2]);

        testSetNextCounter(0);
        expect(nextKey, keys[0]);
        expect(nextKey, keys[1]);
        expect(nextKey, keys[2]);

        testSetNextCounter(keys.length - 1);
        expect(nextKey, keys.last);
        expect(nextKey, keys.first);
      });
    });
  });
}
