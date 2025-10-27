// @license
// Copyright (c) 2019 - 2024 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// A class that holds two functions that will be called when
/// a scope or a node is disposed
class Owner<T> {
  /// Creates a new owner.
  const Owner({
    this.willDispose,
    this.didDispose,
    this.willErase,
    this.didErase,
    this.willUndispose,
    this.didUndispose,
  });

  /// This function will be called when the item will be disposed.
  final void Function(T)? willDispose;

  /// This function will be called when the item is disposed.
  final void Function(T)? didDispose;

  /// This function will be called when the item will be undisposed.
  final void Function(T)? willUndispose;

  /// This function will be called when the item is undisposed.
  final void Function(T)? didUndispose;

  /// This function will be called when the item will be erased.
  final void Function(T)? willErase;

  /// This function will be called when the item is disposed.
  final void Function(T)? didErase;

  /// Returns a default instance that will do nothing
  static const example = Owner<String>();
}
