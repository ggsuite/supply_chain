// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:supply_chain/src/names.dart';
import 'package:supply_chain/src/node.dart';
import 'package:supply_chain/src/scm_node_interface.dart';
import 'package:test/test.dart';

void main() {
  group('ScmNodeInterface', () {
    test('should work fine', () {
      final ni = ExampleScmNodeInterface();
      final messages = <String>[];
      final node = exampleNode();
      testSetNextCounter(0);

      capturePrint(
        ggLog: messages.add,
        code: () {
          ni.addNode(node);
          expect(messages.last, 'addNode: Aaliyah');
          ni.removeNode(node);
          expect(messages.last, 'removeNode: Aaliyah');
          ni.animateNode(node);
          expect(messages.last, 'animateNode: Aaliyah');
          ni.deanimateNode(node);
          expect(messages.last, 'deanimateNode: Aaliyah');
          ni.priorityHasChanged(node);
          expect(messages.last, 'priorityHasChanged: Aaliyah');
          ni.nominate(node);
          expect(messages.last, 'nominate: Aaliyah');
          ni.hasNewProduct(node);
          expect(messages.last, 'hasNewProduct: Aaliyah');
        },
      );
    });
  });
}
