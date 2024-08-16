// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

final _camelCase = RegExp(r'^[_§]?[a-z][a-z0-9]*([A-Z0-9][a-z0-9]*)*$');

/// Extension for lower camel case
extension IsCamelCaseExtension on String {
  /// Returns true if the string is lower camel case
  bool get isCamelCase => _camelCase.hasMatch(this);
}
