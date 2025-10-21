// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final builder = ScBuilderBluePrint.example;
  final builderBluePrint = builder.bluePrint as ExampleScBuilderBluePrint;
  final hostScope = builder.scope;

  group('ScBuilderBluePrint', () {
    group('example', () {
      test('should trigger "needsUpdate" when a.other changes', () {
        // Check state before
        final scope = builder.scope;
        expect(builderBluePrint.needsUpdateCalls, hasLength(1));

        // Change a.other which is set as "needsUpdateSuppliers"
        final a = scope.findNode<num>('a/other')!;
        a.product = 2;
        scope.scm.testFlushTasks();

        // Check state after
        expect(builderBluePrint.needsUpdateCalls, hasLength(2));
        final (Scope s, value) = builderBluePrint.needsUpdateCalls.last;
        expect(value.first, 2);
        expect(s, scope);
      });
    });

    group('instantiate', () {
      test('should create  a builder and add it to scope', () {
        final scope = Scope.example();
        final builder = ScBuilderBluePrint.example.bluePrint.instantiate(
          scope: scope,
        );
        expect(scope.builders, contains(builder));
      });

      test('should apply all methods handed via constructor correctly ', () {
        bool didCallNeedsUpdate = false;
        final resultScope = ScopeBluePrint.example();
        final resultNode = NodeBluePrint.example();

        final builder = ScBuilderBluePrint(
          key: 'test',
          addScopes: ({required Scope hostScope}) => [resultScope],
          replaceScope: ({required hostScope, required scopeToBeReplaced}) {
            return resultScope;
          },
          addNodes: ({required Scope hostScope}) => [resultNode],
          replaceNode: ({required hostScope, required nodeToBeReplaced}) =>
              resultNode,
          inserts: ({required Node<dynamic> hostNode}) => [resultNode],
          needsUpdate:
              ({required Scope hostScope, required List<dynamic> components}) {
                didCallNeedsUpdate = true;
              },
        );

        expect(builder.addScopes(hostScope: Scope.example()), [resultScope]);

        expect(
          builder.replaceScope(
            hostScope: hostScope,
            scopeToBeReplaced: resultScope,
          ),
          resultScope,
        );

        expect(builder.addNodes(hostScope: hostScope), [resultNode]);

        expect(
          builder.replaceNode(
            hostScope: hostScope,
            nodeToBeReplaced: Node.example(scope: hostScope),
          ),
          resultNode,
        );

        expect(builder.inserts(hostNode: Node.example(scope: hostScope)), [
          resultNode,
        ]);

        builder.needsUpdate(hostScope: hostScope, components: [1, 2, 3]);
        expect(didCallNeedsUpdate, isTrue);
      });
    });

    group('base class methods', () {
      test('addScopes', () {
        expect(
          builderBluePrint.addScopes(hostScope: Scope.example()),
          <ScopeBluePrint>[],
        );
      });

      test('replaceScope', () {
        final scopeToBeReplaced = ScopeBluePrint.example();

        final replacedScope = builderBluePrint.replaceScope(
          hostScope: hostScope,
          scopeToBeReplaced: scopeToBeReplaced,
        );

        expect(replacedScope, scopeToBeReplaced);

        expect(
          builderBluePrint.addNodes(hostScope: hostScope),
          <NodeBluePrint<dynamic>>[],
        );
      });

      test('replaceNode', () {
        final node = Node.example();

        final replacedNode = builderBluePrint.replaceNode(
          hostScope: hostScope,
          nodeToBeReplaced: node,
        );

        expect(replacedNode, node.bluePrint);
      });

      test('inserts(hostNode)', () {
        final hostNode = Node.example();
        expect(builderBluePrint.inserts(hostNode: hostNode), isEmpty);
      });
    });

    group('scopes', () {
      group('addScopes', () {
        group('when instantiating the builder', () {
          group('should apply the builder', () {
            test('to the scope and all existing child scopes', () {});
          });
        });
        group('when instantiating new scopes', () {
          group('should apply the builder', () {
            test('to the new scope and all new child scopes', () {});
          });
        });
      });
      group('replaceScope', () {
        group('when instantiating the builder', () {
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
        group('should bypass all inserts added by the builder', () {});
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

        group('should throw', () {
          test('if there are customers relying on the scope', () {});
        });
      });
    });

    group('nodes', () {
      group('addNodes', () {
        group('when instantiating the builder', () {
          test('add the nodes to the host scope and its children', () {});
        });
        group('when instantiating a new scope', () {
          test('should add nodes to the new scope and its children', () {});
        });
      });
      group('replaceNode', () {
        group('when instantiating the builder', () {
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
        test('should remove all added nodes', () {});

        test(
          'should re-replace all replaced nodes by its original nodes',
          () {},
        );

        group('should throw', () {
          test(
            'if there are customers relying on the nodes to be removed',
            () {},
          );
        });
      });
    });
    group('inserts', () {
      group('addInserts', () {
        group('when instantiating the builder', () {
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

    group('shouldProcessChildren(scope)', () {
      group('should throw', () {
        test(
          'when not derived or specified by constructor / derived class',
          () {
            const builder = ScBuilderBluePrint(key: 'test');
            expect(
              () => builder.shouldProcessChildren(hostScope),
              throwsA(
                isA<UnimplementedError>().having(
                  (e) => e.message,
                  'message',
                  contains(
                    'Please either specify shouldProcessChildren '
                    'constructor parameter or override '
                    'shouldProcessChildren method in your '
                    'class derived from ScBuilderBluePrint.',
                  ),
                ),
              ),
            );
          },
        );
      });
    });

    group('shouldProcessScope(scope), shouldProcessChildren(scope)', () {
      group('should throw', () {
        test('when shouldProcessScope is not derived or specified '
            'by constructor / derived class', () {
          const builder = ScBuilderBluePrint(key: 'test');
          expect(
            () => builder.shouldProcessScope(hostScope),
            throwsA(
              isA<UnimplementedError>().having(
                (e) => e.message,
                'message',
                contains(
                  'Please either specify shouldProcessScope '
                  'constructor parameter or override '
                  'shouldProcessScope method in your '
                  'class derived from ScBuilderBluePrint.',
                ),
              ),
            ),
          );
        });

        test('when shouldProcessChildren is not derived or specified '
            'by constructor / derived class', () {
          const builder = ScBuilderBluePrint(key: 'test');
          expect(
            () => builder.shouldProcessChildren(hostScope),
            throwsA(
              isA<UnimplementedError>().having(
                (e) => e.message,
                'message',
                contains(
                  'Please either specify shouldProcessChildren '
                  'constructor parameter or override '
                  'shouldProcessChildren method in your '
                  'class derived from ScBuilderBluePrint.',
                ),
              ),
            ),
          );
        });
      });

      group('should only process nodes matching the specified fillter', () {
        final t = ScBuilder.testScope.key;
        late ScBuilder builder;
        late Scope scope;
        final List<String> shouldProcessScopeCalls = [];
        final List<String> shouldProcessChildrenCalls = [];
        final List<String> addNodesCalls = [];
        final List<String> addScopesCalls = [];
        final List<String> replaceNodeCalls = [];
        final List<String> replaceScopeCalls = [];
        final allCalls = [
          shouldProcessScopeCalls,
          addNodesCalls,
          addScopesCalls,
          replaceNodeCalls,
          replaceScopeCalls,
        ];

        void init({
          required bool Function(Scope scope) shouldProcessScope,
          required bool Function(Scope scope) shouldProcessChildren,
        }) {
          for (var calls in allCalls) {
            calls.clear();
          }

          scope = Scope.example();
          scope.mockContent({
            'n0': 0,
            'c0': {
              'c1': {'n2': 2},
            },
          });

          builder = ScBuilderBluePrint(
            key: 'test',
            shouldProcessScope: (Scope scope) {
              shouldProcessScopeCalls.add(scope.key);
              return shouldProcessScope(scope);
            },
            shouldProcessChildren: (Scope scope) {
              shouldProcessChildrenCalls.add(scope.key);
              return shouldProcessChildren(scope);
            },
            addNodes: ({required hostScope}) {
              addNodesCalls.add(hostScope.key);
              return [];
            },
            addScopes: ({required hostScope}) {
              addScopesCalls.add(hostScope.key);
              return [];
            },
            replaceNode: ({required hostScope, required nodeToBeReplaced}) {
              replaceNodeCalls.add(nodeToBeReplaced.key);
              return nodeToBeReplaced.bluePrint;
            },
            replaceScope: ({required hostScope, required scopeToBeReplaced}) {
              replaceScopeCalls.add(hostScope.key);
              return scopeToBeReplaced;
            },
          ).instantiate(scope: scope);

          builder.scope.scm.testFlushTasks();
        }

        group(
          'with shouldProcessScope and shouldProcessChildren configured',
          () {
            test('to process all scopes and nodes', () {
              init(
                shouldProcessScope: (scope) => true,
                shouldProcessChildren: (scope) => true,
              );

              expect(shouldProcessScopeCalls, ['example', 'c0', 'c1']);
              expect(addNodesCalls, [t, 'example', 'c0', 'c1']);
              expect(addScopesCalls, [t, 'example', 'c0', 'c1']);
              expect(replaceNodeCalls, ['n0', 'n2']);
              expect(replaceScopeCalls, <String>[]); // Not yet implemented
            });

            test('to process only c1', () {
              init(
                shouldProcessScope: (scope) => scope.key == 'c1',
                shouldProcessChildren: (scope) =>
                    const ['example', 'c0'].contains(scope.key),
              );

              expect(shouldProcessScopeCalls, ['example', 'c0', 'c1']);
              expect(addNodesCalls, [t, 'c1']);
              expect(addScopesCalls, [t, 'c1']);
              expect(replaceNodeCalls, ['n2']);
              expect(replaceScopeCalls, <String>[]); // Not yet implemented
            });

            test('to process only n0', () {
              init(
                shouldProcessChildren: (scope) => false,
                shouldProcessScope: (scope) => scope.key == 'example',
              );

              expect(shouldProcessScopeCalls, ['example']);
              expect(addNodesCalls, [t, 'example']);
              expect(addScopesCalls, [t, 'example']);
              expect(replaceNodeCalls, ['n0']);
              expect(replaceScopeCalls, <String>[]); // Not yet implemented
            });
          },
        );
      });
    });
  });
}
