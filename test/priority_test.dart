// @license
// Copyright (c) 2019 - 2023 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/src/priority.dart';
import 'package:test/test.dart';

void main() {
  group('Priority', () {
    test('should work fine', () {
      expect(Priority.lowest, Priority.frame);
      expect(Priority.highest, Priority.realtime);
    });
  });
}
