// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Nodes can have different update priorities.
///
/// [value] encodes processing urgency, not a user-facing rank: a higher value
/// is processed earlier. [structure] has the highest value because structural
/// updates must run before all others. [realtime] is the highest priority
/// assigned for regular value updates - hence [highest] returns [realtime].
enum Priority {
  /// Nodes with frame priority are updated once in a frame
  frame(1),

  /// Nodes with realtime priority are updated immediately
  realtime(2),

  /// Nodes with structure priority are updated before all others.
  /// Use this priority for dynamic chain structure updates.
  structure(3);

  /// Returns the lowest priority
  static Priority get lowest => Priority.frame;

  /// Returns the highest priority assigned for regular updates ([realtime]).
  ///
  /// Note: [structure] has a higher [value] (it is processed first), but it is
  /// a special priority for structural updates, not a regular "higher" rank.
  static Priority get highest => Priority.realtime;

  /// The numeric processing urgency. Higher values are processed earlier.
  final int value;

  /// Constructor
  const Priority(this.value);
}
