// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('Tools', () {
    group('IsCamelCaseExtension', () {
      test('should return true if a string has camel case format', () {
        expect('_helloWorld'.isCamelCase, isTrue);
        expect('helloWorld'.isCamelCase, isTrue);
        expect('hello85'.isCamelCase, isTrue);
        expect('hello'.isCamelCase, isTrue);
        expect('Hello'.isCamelCase, isFalse);
        expect('HelloWorld'.isCamelCase, isFalse);
        expect('hello World'.isCamelCase, isFalse);
        expect('hello-World'.isCamelCase, isFalse);
      });
    });
  });
}
