// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Nodes can have different update priorities
enum Priority {
  /// Nodes with frame priority are updated once in a frame
  frame(1),

  /// Nodes with realtime priority are updated immediately
  realtime(2);

  /// Returns the lowest priority
  static Priority get lowest => Priority.frame;

  /// Returns the highest priority
  static Priority get highest => Priority.realtime;

  /// Returns the numeric value of the priority
  final int value;

  /// Constructor
  const Priority(this.value);
}
