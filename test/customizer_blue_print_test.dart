// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final customizerBluePrint = CustomizerBluePrint.example.bluePrint;
  final hostScope = Scope.example();
  final scopeToBeReplaced = ScopeBluePrint.example();

  group('CustomizerBluePrint', () {
    group('instantiate', () {
      test('should create  a customizer and add it to scope', () {
        final scope = Scope.example();
        final customizer = CustomizerBluePrint.example.bluePrint.instantiate(
          scope: scope,
        );
        expect(scope.customizers, contains(customizer));
      });
    });

    group('base class methods', () {
      test('addScopes', () {
        expect(
          customizerBluePrint.addScopes(hostScope: Scope.example()),
          <ScopeBluePrint>[],
        );
      });

      test('replaceScope', () {
        final replacedScope = customizerBluePrint.replaceScope(
          hostScope: hostScope,
          scopeToBeReplaced: scopeToBeReplaced,
        );

        expect(replacedScope, scopeToBeReplaced);

        expect(
          customizerBluePrint.addNodes(hostScope: hostScope),
          <NodeBluePrint<dynamic>>[],
        );
      });

      test('replaceNode', () {
        final node = Node.example();

        final replacedNode = customizerBluePrint.replaceNode(
          hostScope: hostScope,
          nodeToBeReplaced: node,
        );

        expect(replacedNode, node.bluePrint);
      });

      test('inserts(hostNode)', () {
        final hostNode = Node.example();
        expect(customizerBluePrint.inserts(hostNode: hostNode), isEmpty);
      });
    });

    group('scopes', () {
      group('addScopes', () {
        group('when instantiating the customizer', () {
          group('should apply the customizer', () {
            test('to the scope and all existing child scopes', () {});
          });
        });
        group('when instantiating new scopes', () {
          group('should apply the customizer', () {
            test('to the new scope and all new child scopes', () {});
          });
        });
      });
      group('replaceScope', () {
        group('when instantiating the customizer', () {
          group('should replace the scope', () {
            test('in all existing child scopes', () {});
          });
        });
        group('when instantiating new scopes', () {
          group('should replace the scope', () {
            test('in all new child scopes', () {});
          });
        });
      });
      group('bypass', () {
        group('should bypass all inserts added by the customizer', () {});
      });
      group('dispose', () {
        test('should remove all added scopes and their children', () {});
        test(
          'should remove all added scopes and their children and customers',
          () {},
        );

        test(
          'should re-replace all replaced nodes by its original nodes',
          () {},
        );

        group(
          'should throw',
          () {
            test(
              'if there are customers relying on the scope',
              () {},
            );
          },
        );
      });
    });

    group('nodes', () {
      group('addNodes', () {
        group('when instantiating the customizer', () {
          test('add the nodes to the host scope and its children', () {});
        });
        group('when instantiating a new scope', () {
          test('should add nodes to the new scope and its children', () {});
        });
      });
      group('replaceNode', () {
        group('when instantiating the customizer', () {
          group('should replace the node', () {
            test('in all existing matching child scopes', () {});
          });
        });
        group('when instantiating a new scope', () {
          group('should replace the node', () {
            test('in the new node and its children', () {});
          });
        });
      });

      group('bypass', () {
        test(
          'should re-replace all replaced nodes by the original nodes',
          () {},
        );
      });

      group('dispose', () {
        test('should remove all added nodes', () {});
        test(
          'should remove all added nodes',
          () {},
        );

        test(
          'should re-replace all replaced nodes by its original nodes',
          () {},
        );

        group(
          'should throw',
          () {
            test(
              'if there are customers relying on the nodes to be removed',
              () {},
            );
          },
        );
      });
    });
    group('inserts', () {
      group('addInserts', () {
        group('when instantiating the customizer', () {
          test('should add the inserts to all matching existing nodes', () {});
        });
        group('when instantiating new scopes', () {
          test('should add the inserts to all matching new nodes', () {});
        });
      });
      group('bypass', () {
        test('should bypass the production in all insert nodes', () {});
      });
      group('disable', () {
        test('should remove all inserts from the chain', () {});
      });

      group('enable', () {
        test('should add all inserts to the chain again', () {});
      });

      group('dispose', () {
        test('should remove all added inserts', () {});

        test(
          'should throw if there are customers relying on the inserts',
          () {},
        );
      });
    });
  });
}
