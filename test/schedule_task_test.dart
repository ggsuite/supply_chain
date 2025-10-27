// @license
// Copyright (c) 2019 - 2024 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/src/schedule_task.dart';
import 'package:test/test.dart';

void main() {
  group('ScheduleTask', () {
    test('should work fine', () {
      final messages = <String>[];

      exampleTask();

      exampleScheduleTask(() => messages.add('exampleTask'));
      expect(messages[0], 'exampleTask');
    });
  });
}
