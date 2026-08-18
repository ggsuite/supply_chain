# Changelog

## Unreleased

### Changed

- Use ggwsm in pipelines

## 5.5.0 - 2026-08-15

### Added

- `Scm.tickCount`: monotonic counter of the ticks that nominated the
animated nodes.
- `Scope.testRestIdCounter` is back as a deprecated forwarding alias of
`testResetIdCounter` - the rename had shipped in a non-major release.

### Changed

- Rework copyright headers
- `Scope.mermaid`'s parameter is named `markdownFormat` (was
`markDownFormat`), matching `Scope.writeImageFile`.
- `AnimatedNodeBluePrint.forInt` accepts a custom `equals`.
- `AnimatedNodeBluePrint` accepts `canBeSmart`, `smartMaster` and
`productionTimeout` and forwards them to `NodeBluePrint`.

### Fixed

- Cleanup copy right headers. Update to dart 3.13. Auto fixes.

- Cleanup copy right headers. Update to dart 3.13. Auto fixes. Setup quick-check pipeline.

- Change-gating (`propagateOnChangeOnly`) no longer strands the staged
customer cone when a production is gated. Previously a customer with a
second supplier could never become ready again, deadlocking the whole
pipeline (`Scm.flush()` spun forever and all animations froze).

- The change gate compares against the product the customers last received
instead of the freshly overwritten one. Previously every external
`product =` write on a writable gated node and every un-mocking transition
was silently swallowed, and a tolerance-based `changeComparator` re-based
its baseline on every gated production so unbounded drift never propagated.

- `AnimatedNode` frames are tick-aware (via the new `Scm.tickCount`): a
supplier re-emitting the same value between ticks no longer fast-forwards
the animation, and a target changing on every tick no longer freezes the
output - the node keeps easing toward the latest target, consuming at most
one frame per tick.

- A retarget to the current output value (snap) settles the frame counter;
previously later same-value writes advanced a phantom animation and fired
`onComplete` spuriously.

- `onComplete` fires after the final product is applied and the production
is finalized. Previously it fired mid-production, observed the previous
frame's value, and a callback disposing the node crashed the pipeline.

- The generic `AnimatedNodeBluePrint` default `equals` treats NaN as equal
to NaN; a NaN target no longer restarts the animation on every tick forever
(previously only `forDouble` was NaN-aware).

- Output gating of animated nodes always uses exact equality. Previously the
user-supplied tolerance `equals` also gated propagation, so animations whose
per-frame steps stayed within the tolerance never reached their customers.

- `AnimatedNodeBluePrint.copyWith` and `connectSupplier` preserve the
animated subtype. Previously deriving or rewiring an animated blue print
(e.g. via `ScopeBluePrint` connections or smart masters) silently produced a
plain forwarding node, and instantiating a derived copy crashed with a
type-cast error at its first production. Pairing the blue print with a
non-animated node (e.g. as an insert) now throws a descriptive `StateError`.

- `AnimatedNode` reads its animation config live from the blue print, so
replacing the blue print on a live node takes effect instead of being
silently ignored. Overlaying a non-animated blue print or setting
`mockedProduct` stops the animation instead of leaving the node in the SCM's
animated set producing on every tick forever.

- Disposing any node clears `isAnimated`, so a plain node disposed while
animated no longer stalls its remaining customers (the 5.4.0 fix only
covered `AnimatedNode`).

- `AnimatedNode.example()` flushes with a tick and returns a produced,
settled node instead of an unproduced, still staged one.

- `Scope.findOrCreateNode` validates the blue print (`check()`) before
creating the node, so misconfigured blue prints fail with a clear
`ArgumentError` instead of a raw `StateError` during production.

- The mermaid markdown goldens are written to unique files per graph;
previously three tests overwrote the same two golden files.

- `.gitignore` uses `.gg/*` so the `!.gg/.gg.json` re-include actually
works; the inert `pubspec.lock merge=ours` attribute was removed.


## 5.4.2 - 2026-07-11

### Fixed

- Fix issues in animation nodes and other issues

## 5.4.1 - 2026-07-11

## 5.4.0 - 2026-07-11

### Added

- `AnimatedNode` / `AnimatedNodeBluePrint`: a node that eases its output from
its current value toward a new input value over a fixed number of frames,
producing one intermediate value per `Scm.tick()`. Supply an animation curve
(`double Function(double t)` mapping normalized time to eased progress) and a
`lerp`; the convenience factories `AnimatedNodeBluePrint.forDouble` and
`.forInt` cover the common cases. The node manages `isAnimated` itself, snaps
the first input, retargets smoothly mid-animation, and exposes an `onComplete`
callback and an `isAnimating` getter.
- `NodeBluePrint.propagateOnChangeOnly` (with an optional `changeComparator`):
when enabled, a node only schedules its customers when its freshly produced
product differs from the previous one, so a high-frequency or jittery input
does not cascade redundant recomputations through the graph. `AnimatedNode`
enables this by default.
- `NodeBluePrint.createNode`: the single overridable node-construction hook,
routed through by both `instantiate` and `Scope.findOrCreateNode`, so
`NodeBluePrint` subtypes are honored on every creation path.

### Fixed

- A node disposed while still animating (kept alive by remaining customers) is
now removed from the SCM's animated set instead of being ticked forever.

## 5.3.2 - 2026-07-10

### Changed

- Rename testRestIdCounter into testResetIdCounter

## 5.3.1 - 2026-07-09

## 5.3.0 - 2026-07-08

### Added

- `Scope.nodeByKey`: O(1) lookup of an own node (including inserts) by its
exact key.
- `benchmark/supply_chain_benchmark.dart`: reproducible performance
benchmark covering chains, fan-out, fan-in, layered DAGs, bulk updates and
the non-test (microtask driven) production mode.

### Changed

- Allow mermaid to be printed as markdown
- `NodeBluePrint.clearParsers` now also clears registered json serializers.
- Documentation: corrected the `Node` constructor parameter docs, documented
how asynchronous producers interact with `Scm.shouldTimeOut`, and clarified
that `Priority.value` encodes processing urgency (so `structure` has the
highest value while `realtime` is the highest regular priority).

### Fixed

- `Scm` no longer leaks one periodic timeout-check timer per production
cycle. Previously every cycle created a new `Timer.periodic` without
cancelling the old one; in non-test mode a single long chain propagation
could leak thousands of permanently firing timers.
- Preparing very deep customer chains no longer overflows the stack
(`Scm._prepareNode` is iterative now; chains of 8000+ nodes previously
crashed with a `StackOverflowError`).
- Disposed nodes are removed from the prepared sets immediately on dispose
instead of lingering until the next production cycle.
- `NodeBluePrint.castMap` now casts `Map<String, String>` correctly (it
previously routed through the `bool` caster).
- `NodeBluePrint.removeJsonParser` now actually removes the parser; it used a
wrong map key (`T.runtimeType` instead of `T`) and silently did nothing.
- `NodeBluePrint.addJsonSerializer` now keys serializers by type, so serializers
for different types no longer collide. Previously the shared `T.runtimeType`
key allowed only a single serializer to be registered globally.

### Performance

- `Scm._produce` no longer rescans all prepared nodes on every production
cycle. Ready nodes are kept in per-priority ready queues; each production
cycle now costs O(batch) instead of O(all prepared nodes). Bulk updates and
initial production of a graph with N nodes dropped from O(N²) to O(N).
- Circular dependency detection no longer enumerates every path through the
supplier graph (exponential on diamond-shaped graphs). Nodes maintain an
incrementally updated topological rank (Pearce-Kelly); connecting a supplier
created before its customer is now O(1) to check.
- `Node.initSuppliers` no longer performs Θ(S²) pairwise path matching when
connecting S suppliers.
- `Node._customers` is now a Set and suppliers are shadowed by a Set:
building and tearing down wide fan-outs is linear instead of quadratic.
- `Scope.child` uses the existing children map instead of a linear scan.
- `Scope.smartMaster` no longer recurses into the parent twice
(was O(2^depth), now O(depth)).
- `NodeBluePrint.instantiate` looks the node up in the scope's node map
instead of scanning all nodes.
- `Disposed` stores nodes and scopes in Sets; erasing many disposed items is
linear instead of quadratic.
- `Scm._addPreparedNodes` iterates its input once instead of twice.
- `Scm.nominate` evaluates the cheap fast-path conditions before scanning
suppliers.

## 5.2.0 - 2026-07-05

## 5.1.0 - 2026-07-05

### Changed

- Improve performance using claude code

## 5.0.2 - 2026-06-04

### Added

- Add clarification comments for priority

## 5.0.1 - 2026-06-04

### Changed

- Fix CHANGELOG.md

## 5.0.0 - 2026-06-04

### Added

- Asynchronous producers: a produce function may now return a `Future`. The
node stays in production until the future resolves and its customers wait for
the result.
- `Scm.settle()` (alias `Scm.flushAsync()`) awaits in-flight asynchronous
productions until the supply chain is quiescent.
- `NodeBluePrint.productionTimeout` and `Node.productionTimeout` to override the
SCM's default production timeout per node.
- `Scm.onProductionError` hook invoked when an asynchronous production fails.

### Changed

- BREAKING CHANGE: `Produce<T>` now returns `FutureOr<T>` instead of `T`.
Providing synchronous producers is unchanged, but code that calls a produce
function directly (e.g. `NodeBluePrint.produce` or
`ScopeBluePrintFactory.produce`) now receives a `FutureOr<T>` and must cast
when the result is known to be synchronous.
- By default an asynchronous production that exceeds the frame budget
(`Scm.timeout`, 5ms) is finalized with the previous product so the frame is
never blocked; the real result is applied as a follow-up update once the
future resolves. Set a longer `productionTimeout` for a single-update result.

## 4.0.3 - 2025-10-27

### Fixed

- Trial to fix non displayed image 2

## 4.0.2 - 2025-10-27

### Fixed

- Trial to fix non displayed image

## 4.0.1 - 2025-10-27

### Added

- Add debugging tutorial

### Fixed

- Fix issue with diagram on main README.md

## 4.0.0 - 2025-10-27

### Changed

- BREAKING CHANGE: produce function will require a node param
- BREAKING CHANGE: testFlushTasks is renamed into flush
- Rework README

### Removed

- Remove doc.dart

## 3.0.2 - 2025-10-21

### Fixed

- Fix an error with .. pathes

## 3.0.1 - 2025-10-21

### Changed

- Update dart SDK to 3.9.2

## 3.0.0 - 2025-10-21

### Changed

- BREAKING CHANGE: Use / instead of . for describing node and scope pathes

## 2.0.0 - 2025-09-09

### Changed

- BREAKING CHANGE: ScopeBluePrint.fromJson will treat numbers as num and not as int or double anymore

## 1.3.3 - 2025-09-09

### Added

- Add .gitattributes file

### Changed

- BREAKING CHANGE: Switch from double to num

## 1.3.2 - 2025-07-15

### Fixed

- Fix an error while adding JSON parsers

## 1.3.1 - 2025-06-25

### Fixed

- Fix an issue with registering JSON parsers

## 1.3.0 - 2025-06-24

### Added

- Add tests for handling JSON

### Changed

- Allow to parse enums
- Improve handling Json values
- Improve json handling in nodes
- Prepare new version

## 1.2.0 - 2025-06-19

### Changed

- Improve catching JSON serialization errors

## 1.1.3 - 2025-06-19

### Changed

- `Scope.preset` and `Scope.setPreset` will output and input custom types as JSON
- `Scope.dumpSupplyChain` and `Scope.dumpSupplyChain` will output and input custom types as JSON

## 1.1.2 - 2025-06-12

### Fixed

- Fix an error confusing double and int while setting presets

## 1.1.1 - 2025-06-07

### Changed

- BREAKING CHANGE: Update API to generate graph images
- Allow to specify the markdown format (azure or github) when exporting mermaid diagrams

## 1.1.0 - 2025-06-07

### Added

- Add mermaid support

### Changed

- Tests do not create png and svg files anymore
- Upgrade to dart 2.8

## 1.0.15 - 2025-05-21

### Changed

- Update repo URL from inlavigo to ggsuite

### Fixed

- Fix unit test errors

## 1.0.14 - 2025-05-21

### Added

- Add SubChainManagerBluePrint
- Add ScopeBluePrintFactory
- Add boilerplate for ScopeBluePrintFactory
- Add Scope.dispose
- Add path to node and scope. Allow to specify a scope in supplier keys
- Add built method to ScopeBluePrint
- Add Scope.mockContent
- Add Scope.findScope
- Add Scope.root
- Add Scope replaceChild(), addChild(), remove()
- Add Scope deepParents, deepChildren
- Add Node.graph and Node.saveGraphToFile
- Add options to control if a node is highlighted or not
- Add option show dependent nodes only
- Add additional cases for printing graphs
- Add NodeBluePrint.map
- Add Doc class to create html documentations
- Add Scope.reset and Node.reset
- Add Node.addInsert and removeInsert
- Added Scope.addInsert and removeInsert
- Add modifyChildScope, modifyChildNode
- Add switchSupplier
- Add overridable modifyChildScope and modifyChildNode
- Add willInstantiate
- Add possibility to set a mocked product
- Add set get mockedProduct
- Add NodeBluePrint
- Add base of ScBuilder
- Add the concept of child builders
- Add builder node adder
- Add ScBuilderScopeAdder
- Add a needsUpdate method and needsUpdate supplier to allow triggering a builder on the basis of previous events
- Add findItem method which returns either a Scope or Node
- Add findScope2 using the same algorithm as findNode
- Add an on.change meta node
- Add a write2x option to save files also in double resolution
- Add some tests
- Add class Disposed to manage disposed nodes and test disposal and recreation of nodes cleanly
- Add additional unit tests for removal and recreation of nodes and scopes
- Add additional tests. Fix an issue with smart nodes.
- Add additional checks for supplier consistency
- Add tests for applying builders to nodes created by builders
- Add shouldProcessChildren to optimize application of builders
- Add Scope.ls to print all children and nodes of a scope
- Add onInstantiate bluePrint
- Add ScopeBluePrint.onInstantiate, onDispose
- Add Scope.smartMaster and Scope.isSmartScope
- Add smart scopes
- Add shouldProcessScope
- Add tests for shouldProcessScope and make sure it is called or the root
- Add Scope.jsonDump
- Add sourceNodesOnly option for jsonDump
- Add Scope.preset
- Add Scope.preset() and Scope.setPreset()

### Changed

- Turn NodeBluePrint into const constructor
- Make sure disposing a node removes it from the SCM and it's scope
- ScopeBluePrintFactory can dynamically create new sub scopes
- Node and scope names must be camel case now
- Scope:instantiate: Rename parentScope param into scope
- ScopeBluePrints will alwas create a scope
- Rename subScope to childScope
- Breaking change: Use . instead / for scope notation
- Ignoflushecuted on GitHub
- Allow to embedd real ScopeBluePrints into mockContent
- Rework example
- Allow to embed ScopeBluePrints directly in mocked content
- Move initialization of suppliers to SCM
- Improve error message
- Let testFlushTasks also trigger a tick
- deepSuppliers and deepCustomers
- Use a new flexible graph implementation
- Good progress in visualizing supply chains
- Rename identifiers
- Give each dot file a unique name
- Highlight selected node in Node.writeImageFile, childScopeDepth is -1 by default
- Instantiation of a scope requires a blue print
- Scopes can now have key aliases
- Rename writeDotFile into writeImageFile
- Detect duplicate keys
- Renamed map to forward
- Rename forward to forwardTo
- Print only suppliers of nodes in doc graphs
- Inserts can be added and removed now
- Handle the case that a insert has inserts
- Removing a insert from a node will dispose the insert
- Implement better way to handle inserts
- Split build into buildNodes and buildScopes
- Allow to override nodes and scopes while instantiating a scope blue print
- Define overrides in constructor
- Refactor ScopeInsert
- instantiate scope inserts within their own scope
- Hand over scope in method modifyChildNode
- Improved error message
- Allow a to specify a list of allowed products for a node
- Rename additionalNodes into additionalScopes
- Rename forwardFrom -
- Rename forwardFrom -> switchSupplier
- Rename modifyNode into modifyChildNode
- Improve assertion
- Rework modifyChildScopes
- Rename ScopeScBuilder into ScopeInserts
- Work on builder and inserts
- ScBuilders can define builders for certain child scopes
- findNode will skip inserts by default
- Rename Inserts into ScBuilderInserts
- ScBuilders can replace nodes now
- Split node and rank separation
- Rename nodeOverrides and scopeOverrides
- Improve merging of built and constructor nodes and scopes
- Rename ScopeBluePrintFactory into ScopeFactory
- Rename SubScopeManager into ScopeFactory, rename ScopeBluePrint.findNode()
into findNode, offer methods to connect a blue print's node to other external
nodes
- Allow to connect nodes and scopes to nodes and scopes in the outside
- Rename Plugin into ScBuilder
- Change Scope.example - Use instantiate
- ScBuilder: Allow to init additional scopes later
- ScBuilders can be applied to nodes and scopes after instantiation
- BREAKING CHANGE: Remove modifyChildScope and modifyChildNode.
Modifications can only be done via builders.
- Rework scope nodes and scope children
- Some renamings
- Refactor aliases. Add buildAliases
- Rebuild connections
- Simplify overrides
- Allow to submit connections when creating a scope from JSON
- Rename customizer into builder
- Rename findScope into findChildScope
- Rename findScope2 into findScope
- Introduce metaScopes to provide suppliers informing about scope changes
- Improve instantiation of MetaScopes
- Rename _findNode into _findItem
- Using supplier pathes like a.on.change or a.on.changeRecursive it is now possible to observe changes on complete scopes or children
- Write svg instead of dot files. Fix an error causing cropped SVG window for dot graphs.
- Set graph quality to 300 dpi
- Set output quality to 150dpi
- Set Gsize=0.5 when exporting graphs
- Show empty scopes beside nodes in the last shown graph level
- Increase default graph dpi to 300dpi
- Set default quality to 100 dpi
- Change default resolution to 72dpi
- Distinguish between disposal of and removal nodes. Nodes can only be erased when they have no customers. Nodes that have customers can be disposed. But they will remain in the node hierarchy until the last customers has been removed.
- Make removeSupplier private. Only dispose and erase can be used.
- Make removeCustomer private. Only dispose and erase can be used.
- Make erase private. Publicly nodes can only be disposed. Erasal happens when the last customer is removed from a node.
- Mute suppliers in the blue print when a node is disposed
- Move all scope disposal steps to _dispose
- Don't erase scopes until the last node and child scope has been erased
- Allow to add an owner to nodes who is informed about disposal or erasal
- Allow to add an owner to scopes who is informat about disposal, undisposal and erasal
- ScBuilderNodeAdder is informed when one of the created nodes is erased
- Prevent that a builder is applied to scopes created by this builder before
- Make sure produce does not change the order
- ScBuilderBluePrint can be instantiated without constructor
- Use _2x instead of @2x for highres files
- Scope.children must not return disposed nodes
- Generate graph new with GraphViz 12.0.0. Set font to Arial.
- Experiment using Image Magick to convert svgs to pngs
- Don't let disposed nodes produce
- More detailed error message when supplier is not found
- Throw an error when suppliers with the same key are provided
- Prepare not throwing if a supplier is not available for a short time
- Try again later to add suppliers not available immediately
- Suppliers must not be available from the beginning
- Rework initialization of suppliers
- Rename replaceNode into addBluePrintOverlay. Add Scope.addOrReplaceNode.
- Throw if a node is replaced with one with invalid suppliers
- Rename SmartNodeNode into SmartNode
- Use master as term for the node delivering data to a smart node.
- Make smart node more stable
- Don't throw if builder is applied two times to the same scope
- Optimize NodeBluePrint operator==
- Optimize handling of realtime nodes
- Optimize Scope.matchesKey
- Optimize master path of smart nodes
- Optimize smart node handling
- Work on shouldProcessChildren
- Rename shouldDigInto into shouldProcessChildren
- Provide a method to stop processing at a certain point
- Implementers of ScBuilderBluePrint must implement shouldProcessChildren
- Optimize comparison of ScopeBluePrints
- Optimizations
- Optimize produce performance
- Allow to disable extra checks
- Optimize nomination - Certain nodes should produce directly and should not run through the nomination and production process
- Allow to disable on.change and on.changeRecursive
- Refactor SmartNodes
- Throw if a smart scope is instantiated within a smart scope
- Finalize smart scope concept
- Rename hostScope back into scope
- Smart nodes must not be in the same scope as its master nodes
- Breaking change: Turn shouldStopProcessingAfter -
- Improve tests for shouldProcessScope
- Optimize application of sub builders
- Allow to search nodes only in parents by adding ..
- Point to parent suppliers by adding ..
- Improve searching things in parent scopes
- Update gg_cache
- Allow to return an eflushhout throwing when setting presets
- Setting an empty preset will reset the supply chain
- Presets do not export empty scopes

### Fixed

- Fix need of calling testFlushTasks two times
- Fix issues in relation with aliases
- Fix various search issues
- Fix an search error with scope aliases
- Fix an error
- Fix an error with forwarding dpi
- Fix an issue with hidden scopes in graph print outs
- Fix aliases did not work accross multiple search scenarios
- Fix no error was thrown when nodes were added to every scope without checking
- Fix no error was thrown when scopes were added to every scope without checking
- Fix an issue with aliases
- Fix potential bug in relation with connections
- Fix a small issue with connections
- Fix an issue while disposing scopes
- Fix an github issue
- Fix issues with healing disposed scopes
- Fix an issue when smart nodes were disposed
- Fix an issue when erasing suppliers
- Fix an small issue with not detecting missing suppliers
- Fix a bug where builders were instantiated twice
- Fix issues with smart nodes
- Fixing memory leaks
- Fix an issue with onInstantiate
- Fix circular dependency issue in relation with smart nodes
- Fix an issue with mocked nodes

### Removed

- Removed plant
- Remove dependencies from ScopeBluePrint
- Remove key named parameter from node
- Remove ScopeInsert
- Remove concept of InsertBluePrint. NodeBluePrint is enough.
- Remove mustCallSuper
- Remove scaling of images again
- Remove remove method
- Remove replaceScopes - Is done by builders now
- Removed an exception when the same blueprint was added multiple times to a node

## 1.0.13 - 2024-05-17

### Added

- Add possibility to instantiate a scope blue print right within parent scope
- Add class NodeConfig
- Add NodeConfig to Node
- Add SupplyChain:findOrCreateNodes
- Add ScopeBluePrint

### Changed

- Switch to absolute imports
- A node's product can now be set from the outside
- SupplyChain finds or creates nodes based on config
- Update graph files on disk, separate nodes and edges in dot file
- Write graphs to webp
- Rename SupplyChain into Scope
- Rename NodeConfig into NodeBluePrint

### Removed

- Remove findOrCreateNodes because type cannot be inferred

## 1.0.12 - 2024-05-10

### Changed

- Rename createNode into findOrCreateNode

## 1.0.11 - 2024-05-10

- Add `equalsGraph`
- Make `findNode` finding arbitrary nodes

### Changed

- Updated version in pubspec.yaml

### Removed

- Remove ScmNodeInterface, find arbitrary nodes by SupplyChain:findNode

## 1.0.10 - 2024-05-10

## 1.0.9 - 2024-05-10

### Changed

- Nodes can be found in direct children
- Supply chains need a parent chain from beginning

## 1.0.8 - 2024-05-10

### Added

- Add option to findNode

## 1.0.7 - 2024-05-08

### Added

- Add SupplyChain.hasNode

## 1.0.6 - 2024-05-08

### Removed

- Remove print statement

## 1.0.5 - 2024-05-08

### Fixed

- Fix issues in supply chain

## 1.0.4 - 2024-05-08

### Changed

- Rename scope into chain

## 1.0.3 - 2024-05-08

### Changed

- Renamed name into key

## 1.0.2 - 2024-05-08

### Changed

- Rename name into key
- Rename Scope into SupplyChain

## 1.0.1 - 2024-05-08

### Added

- Add Scope
- Add Scope class + print scopes using dot
- Add isDescendantOf, isAncestorOf, initSuppliers
- Add ValueNode

### Changed

- Scopes can build an hierrarchy
- Hand over components and previous value to produce method

### Removed

- Removed needsUpdate because it is not used

## 1.0.0 - 2024-05-04

### Changed

- Rename gg_supply_chain into supply_chain
- Updated version
- Upgraded gg_fake_timer
- 'Pipline: Disable cache'
- 'publish_to: none for private repositories'
- Rework changelog
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into
.github/workflows to make github installing flutter and not dart SDK'
