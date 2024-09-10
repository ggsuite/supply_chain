# Changelog

## [Unreleased]

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

### Changed

- Turn NodeBluePrint into const constructor
- Make sure disposing a node removes it from the SCM and it's scope
- ScopeBluePrintFactory can dynamically create new sub scopes
- Node and scope names must be camel case now
- Scope:instantiate: Rename parentScope param into scope
- ScopeBluePrints will alwas create a scope
- Rename subScope to childScope
- Breaking change: Use . instead / for scope notation
- Ignore code not executed on GitHub
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
- Rename \_findNode into \_findItem
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
- Move all scope disposal steps to \_dispose
- Don't erase scopes until the last node and child scope has been erased
- Allow to add an owner to nodes who is informed about disposal or erasal
- Allow to add an owner to scopes who is informat about disposal, undisposal and erasal
- ScBuilderNodeAdder is informed when one of the created nodes is erased
- Prevent that a builder is applied to scopes created by this builder before
- Make sure produce does not change the order
- ScBuilderBluePrint can be instantiated without constructor
- Use \_2x instead of @2x for highres files
- Scope.children must not return disposed nodes
- Generate graph new with GraphViz 12.0.0. Set font to Arial.
- Experiment using Image Magick to convert svgs to pngs
- Don't let disposed nodes produce
- More detailed error message when supplier is not found
- Throw an error when suppliers with the same key are provided
- Prepare not throwing if a supplier is not available for a short time
- Try again later to add suppliers not available immediately

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

## [1.0.13] - 2024-05-17

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

## [1.0.12] - 2024-05-10

### Changed

- Rename createNode into findOrCreateNode

## [1.0.11] - 2024-05-10

- Add `equalsGraph`
- Make `findNode` finding arbitrary nodes

### Changed

- Updated version in pubspec.yaml

### Removed

- Remove ScmNodeInterface, find arbitrary nodes by SupplyChain:findNode

## [1.0.10] - 2024-05-10

## [1.0.9] - 2024-05-10

### Changed

- Nodes can be found in direct children
- Supply chains need a parent chain from beginning

## [1.0.8] - 2024-05-10

### Added

- Add option to findNode

## [1.0.7] - 2024-05-08

### Added

- Add SupplyChain.hasNode

## [1.0.6] - 2024-05-08

### Removed

- Remove print statement

## [1.0.5] - 2024-05-08

### Fixed

- Fix issues in supply chain

## [1.0.4] - 2024-05-08

### Changed

- Rename scope into chain

## [1.0.3] - 2024-05-08

### Changed

- Renamed name into key

## [1.0.2] - 2024-05-08

### Changed

- Rename name into key
- Rename Scope into SupplyChain

## [1.0.1] - 2024-05-08

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

## [1.0.0] - 2024-05-04

### Changed

- Rename gg\_supply\_chain into supply\_chain
- Updated version
- Upgraded gg\_fake\_timer
- 'Pipline: Disable cache'
- 'publish\_to: none for private repositories'
- Rework changelog
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into
.github/workflows to make github installing flutter and not dart SDK'

[Unreleased]: https://github.com/inlavigo/supply_chain/compare/1.0.13...HEAD
[1.0.13]: https://github.com/inlavigo/supply_chain/compare/1.0.12...1.0.13
[1.0.12]: https://github.com/inlavigo/supply_chain/compare/1.0.11...1.0.12
[1.0.11]: https://github.com/inlavigo/supply_chain/compare/1.0.10...1.0.11
[1.0.10]: https://github.com/inlavigo/supply_chain/compare/1.0.9...1.0.10
[1.0.9]: https://github.com/inlavigo/supply_chain/compare/1.0.8...1.0.9
[1.0.8]: https://github.com/inlavigo/supply_chain/compare/1.0.7...1.0.8
[1.0.7]: https://github.com/inlavigo/supply_chain/compare/1.0.6...1.0.7
[1.0.6]: https://github.com/inlavigo/supply_chain/compare/1.0.5...1.0.6
[1.0.5]: https://github.com/inlavigo/supply_chain/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/inlavigo/supply_chain/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/inlavigo/supply_chain/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/inlavigo/supply_chain/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/inlavigo/supply_chain/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/inlavigo/supply_chain/tag/%tag
