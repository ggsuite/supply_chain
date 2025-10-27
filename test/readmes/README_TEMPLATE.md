# Supply Chain - Data Flow & State Management

Supply Chain (SC) is a data flow and state management framework.

## Features

- ✅ Efficiently manage application state
- ✅ Visualize application data flow & dependencies
- ✅ Smoothly animate state transitions
- ✅ Efficient processing using caching and priorization
- ✅ Prevent unneccessary updates
- ✅ Query nodes and scopes
- ✅ Modify supply chains using plugins
- ✅ Create auto connecting smart nodes

## Concept

A customer `nodes` receive components from one or more supplier nodes. Each node
creates a `product`, that is delivered to customer nodes. The application state
is modelled as an supply chain. Nodes again are put into nested `scopes`. A
`supply chain manager` (SCM) coordinates the process.

```mermaid
INSERT test/goldens/tutorials/basics_tutorial/basic_01.mmd
```

## Getting started

The following test demonstrates important supply chain features.

```dart
INSERT test/tutorials/basics_tutorial_test.dart
```

## Features and bugs

Please file feature requests and bugs at [GitHub](https://github.com/ggsuite/supply_chain).
