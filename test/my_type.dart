// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// .............................................................................
class MyTypNoJson {
  const MyTypNoJson(this.x);
  final int x;
}

// .............................................................................
class MyType {
  const MyType(this.x);
  final int x;

  Map<String, dynamic> toJson() {
    return {'x': x};
  }

  factory MyType.fromJson(Map<String, dynamic> json) {
    return MyType(json['x'] as int);
  }
}
