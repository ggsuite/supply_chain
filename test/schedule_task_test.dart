// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:supply_chain/src/schedule_task.dart';

import 'package:test/test.dart';

void main() {
  group('ScheduleTask', () {
    test('should work fine', () {
      final messages = <String>[];

      capturePrint(
        ggLog: messages.add,
        code: () {
          final task = exampleTask;
          task();
          expect(messages[0], 'exampleTask');

          exampleScheduleTask(task);
          expect(messages[1], 'runTask:');
          expect(messages[2], 'exampleTask');
        },
      );
    });
  });
}
