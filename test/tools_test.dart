// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('Tools', () {
    group('IsPascalCaseExtension', () {
      test('should return true if a string has pascal case format', () {
        expect('HelloWorld'.isPascalCase, isTrue);
        expect('Hello85'.isPascalCase, isTrue);
        expect('Hello'.isPascalCase, isTrue);
        expect('hello'.isPascalCase, isFalse);
        expect('helloWorld'.isPascalCase, isFalse);
        expect('Hello World'.isPascalCase, isFalse);
        expect('Hello-World'.isPascalCase, isFalse);
      });
    });
  });
}
