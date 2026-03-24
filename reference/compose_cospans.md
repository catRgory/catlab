# Compose two structured cospans along a shared foot

Given M: A -\> X \<- B and N: B -\> Y \<- C (where B is the shared
foot), compute the composite M;N: A -\> Z \<- C via pushout of X and Y
over B.

## Usage

``` r
compose_cospans(M, N)
```

## Arguments

- M:

  StructuredCospan with at least 2 legs (left=first, right=last)

- N:

  StructuredCospan with at least 2 legs (left=first, right=last)

## Value

StructuredCospan with 2 legs: left from M, right from N

## Examples

``` r
# Compose two path-graph cospans end-to-end
g1 <- path_graph(3)
sc1 <- open_acset(g1, "V", 1L, 3L)
g2 <- path_graph(2)
sc2 <- open_acset(g2, "V", 1L, 2L)
composed <- compose_cospans(sc1, sc2)
nv(cospan_apex(composed)) # 4 (shared vertex merged)
#> [1] 4
```
