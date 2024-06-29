// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('PluginNodeReplacer', () {
    group('example', () {
      test('should work', () {
        final pluginNodeReplacer = PluginNodeReplacer.example;
        final plugin = pluginNodeReplacer.plugin;
        final scope = plugin.scope;
        scope.scm.testFlushTasks();

        // Get the nodes a,b and d,e out of the hierarchy
        final a = scope.findNode<int>('a')!;
        final b = scope.findNode<int>('b')!;
        final d = scope.findNode<int>('d')!;
        final e = scope.findNode<int>('e')!;
        final f = scope.findNode<String>('f')!;

        // Because of the ReplaceIntNodesBy42 plugin,
        // the nodes a, b, d, and e should be deliver 42
        expect(a.product, 42);
        expect(b.product, 42);
        expect(d.product, 42);
        expect(e.product, 42);
        expect(f.product, 'f');

        // Lets dispose the plugin.
        // The nodes a, b, d, and e should be deliver 1, 2, 4, and 5 again
        plugin.dispose();
        scope.scm.testFlushTasks();

        expect(a.product, 1);
        expect(b.product, 2);
        expect(d.product, 4);
        expect(e.product, 5);
        expect(f.product, 'f');

        expect(pluginNodeReplacer, isNotNull);
      });
    });
  });
}
