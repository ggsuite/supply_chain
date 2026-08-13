// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// A simple task delegate
typedef Task = void Function();

/// A delegate for scheduling a task
typedef ScheduleTask = void Function(Task);

/// An example task
Task get exampleTask =>
    () => {};

/// An example schedule task
ScheduleTask get exampleScheduleTask => (Task task) {
  task();
};
