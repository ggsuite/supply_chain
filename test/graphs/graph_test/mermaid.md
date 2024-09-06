<!--
@license
Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

## A Mermaid Sample Diagram

```mermaid
graph TD
    subgraph butterFly
        subgraph level3
            s111_8["s111"]
            c111_28["c111"]
            subgraph level2
                s11_11["s11"]
                s10_12["s10"]
                s01_13["s01"]
                s00_14["s00"]
                c00_24["c00"]
                c01_25["c01"]
                c10_26["c10"]
                c11_27["c11"]
                subgraph level1
                    s1_17["s1"]
                    s0_18["s0"]
                    c0_22["c0"]
                    c1_23["c1"]
                    subgraph level0
                        x_21["x"]
                    end
                end
            end
        end
    end

    s111_8 --> s11_11
    s11_11 --> s1_17
    s10_12 --> s1_17
    s01_13 --> s0_18
    s00_14 --> s0_18
    c11_27 --> c111_28
    s1_17 --> x_21
    s0_18 --> x_21
    c0_22 --> c00_24
    c0_22 --> c01_25
    c1_23 --> c10_26
    c1_23 --> c11_27
    x_21 --> c0_22
    x_21 --> c1_23
```
