:::mermaid
flowchart TD
  subgraph exampleRoot_5["exampleRoot"]
    rootA_4["rootA"]
    rootB_5["rootB"]
    subgraph childScopeA_6["childScopeA"]
      childNodeA_6["childNodeA"]
      childNodeB_7["childNodeB"]
      subgraph grandChildScope_7["grandChildScope"]
        grandChildNodeA_8["grandChildNodeA"]
      end
    end
    subgraph childScopeB_8["childScopeB"]
      childNodeA_9["childNodeA"]
      childNodeB_10["childNodeB"]
      subgraph grandChildScope_9["grandChildScope"]
        grandChildNodeA_11["grandChildNodeA"]
      end
    end
  end


  classDef highlight fill:#FFFFAA,stroke:#333;
:::