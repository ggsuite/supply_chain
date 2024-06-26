// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('InsertBluePrint', () {
    group('example', () {
      test('should work', () {
        final insertBluePrint = InsertBluePrint.example();
        expect(insertBluePrint.produce([], 0), 1);
        expect(insertBluePrint, isNotNull);
        expect(insertBluePrint.isInsert, isTrue);
      });
    });

    group('instantiate', () {
      test('should return an instantiated insert', () {
        final insertBluePrint = InsertBluePrint.example();
        final insert = insertBluePrint.instantiateAsInsert(
          host: Node.example(),
        );

        expect(insert, isNotNull);
        expect(insert.host, isNotNull);
        expect(insert.bluePrint, insertBluePrint);
      });
    });
  });
}
