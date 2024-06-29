// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final pluginBluePrint = PluginBluePrint.example.bluePrint;
  final hostScope = Scope.example();
  final scopeToBeReplaced = ScopeBluePrint.example();

  group('PluginBluePrint', () {
    group('instantiate', () {
      test('should create  a plugin and add it to scope', () {
        final scope = Scope.example();
        final plugin = PluginBluePrint.example.bluePrint.instantiate(
          scope: scope,
        );
        expect(scope.plugins, contains(plugin));
      });
    });

    group('base class methods', () {
      test('addScopes', () {
        expect(
          pluginBluePrint.addScopes(hostScope: Scope.example()),
          <ScopeBluePrint>[],
        );
      });

      test('replaceScope', () {
        final replacedScope = pluginBluePrint.replaceScope(
          hostScope: hostScope,
          scopeToBeReplaced: scopeToBeReplaced,
        );

        expect(replacedScope, scopeToBeReplaced);

        expect(
          pluginBluePrint.addNodes(hostScope: hostScope),
          <NodeBluePrint<dynamic>>[],
        );
      });

      test('replaceNode', () {
        final node = Node.example();

        final replacedNode = pluginBluePrint.replaceNode(
          hostScope: hostScope,
          nodeToBeReplaced: node,
        );

        expect(replacedNode, node.bluePrint);
      });

      test('inserts(hostNode)', () {
        final hostNode = Node.example();
        expect(pluginBluePrint.inserts(hostNode: hostNode), isEmpty);
      });
    });

    group('scopes', () {
      group('addScopes', () {
        group('when instantiating the plugin', () {
          group('should apply the plugin', () {
            test('to the scope and all existing child scopes', () {});
          });
        });
        group('when instantiating new scopes', () {
          group('should apply the plugin', () {
            test('to the new scope and all new child scopes', () {});
          });
        });
      });
      group('replaceScope', () {
        group('when instantiating the plugin', () {
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
        group('should bypass all inserts added by the plugin', () {});
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
        group('when instantiating the plugin', () {
          test('add the nodes to the host scope and its children', () {});
        });
        group('when instantiating a new scope', () {
          test('should add nodes to the new scope and its children', () {});
        });
      });
      group('replaceNode', () {
        group('when instantiating the plugin', () {
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
        group('when instantiating the plugin', () {
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
