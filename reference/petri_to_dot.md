# Render a Petri net as a bipartite DOT graph

Species are circles, transitions are boxes. Input/output arcs connect
them. Uses DiagrammeR for rendering.

## Usage

``` r
petri_to_dot(pn)
```

## Arguments

- pn:

  A Petri net ACSet

## Examples

``` r
pn <- acsets::ACSet(acsets::BasicSchema(
  obs = c("S", "T", "I", "O"),
  homs = list(acsets::hom("is", "I", "S"), acsets::hom("it", "I", "T"),
             acsets::hom("os", "O", "S"), acsets::hom("ot", "O", "T"))))
acsets::add_parts(pn, "S", 2)
#> [1] 1 2
acsets::add_parts(pn, "T", 1)
#> [1] 1
acsets::add_part(pn, "I", is = 1L, it = 1L)
#> [1] 1
acsets::add_part(pn, "I", is = 2L, it = 1L)
#> [1] 2
acsets::add_part(pn, "O", os = 1L, ot = 1L)
#> [1] 1
cat(petri_to_dot(pn))
#> digraph PetriNet {
#>   rankdir=LR;
#>   S_1 [label="S1" shape=circle style=filled fillcolor=lightskyblue];
#>   S_2 [label="S2" shape=circle style=filled fillcolor=lightskyblue];
#>   T_1 [label="T1" shape=box style=filled fillcolor=lightsalmon];
#>   S_1 -> T_1;
#>   S_2 -> T_1;
#>   T_1 -> S_1;
#> }
```
