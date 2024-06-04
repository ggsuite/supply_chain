// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('Doc', () {
    group('example', () {
      test('should work', () async {
        // Create a tmp directory
        final targetDirRoot = Directory('/tmp/').existsSync()
            ? '/tmp/'
            : Directory.systemTemp.path;

        final targetDir = '$targetDirRoot/supply_chain_doc';

        final scope = Scope.example();
        scope.mockContent({
          'a': {
            'b': {
              'c': const NodeBluePrint<int>(
                key: 'c',
                suppliers: ['d'],
                initialProduct: 0,
                documentation: 'Documentation of node c.',
              ),
              'd': const NodeBluePrint<int>(
                key: 'd',
                initialProduct: 1,
                documentation: 'Documentation of node d.',
              ),
            },
          },
        });

        final doc = Doc(
          targetDirectory: targetDir,
          scope: scope,
        );

        // Create the documentation
        await doc.create();

        final html = await File('$targetDir/index.html').readAsString();

        // Add a h1 headline for each scope
        expect(html, contains('<h1>a</h1>'));
        expect(html, contains('<h1>b</h1>'));

        // Add a h2 headline for each node
        expect(html, contains('<h2>c</h2>'));
        expect(html, contains('<h2>d</h2>'));

        // Document suppliers
        expect(html, contains('<li><code>d</code></li>'));

        // Document blue print documentation
        expect(html, contains('Documentation of node c.'));
        expect(html, contains('Documentation of node d.'));
      });
    });
  });
}
