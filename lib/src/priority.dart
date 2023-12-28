// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Nodes can have different update priorities
enum Priority {
  frame(1),
  realtime(2);

  static Priority get lowest => Priority.frame;
  static Priority get highest => Priority.realtime;

  final int value;
  const Priority(this.value);
}
