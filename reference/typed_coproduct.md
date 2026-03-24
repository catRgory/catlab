# Typed coproduct of typed ACSets

Given typed ACSets phi_1: X_1 -\> T and phi_2: X_2 -\> T, compute their
coproduct via pushout of the initial object. In practice this is the
disjoint union with combined typing.

## Usage

``` r
typed_coproduct(tacs1, tacs2)
```

## Arguments

- tacs1:

  TypedACSet

- tacs2:

  TypedACSet

## Value

TypedACSet

## Examples

``` r
T <- Graph()
add_vertices(T, 2)
#> [1] 1 2
add_edge(T, 1, 2)
#> [1] 1
g1 <- Graph()
add_vertices(g1, 2)
#> [1] 1 2
add_edge(g1, 1, 2)
#> [1] 1
t1 <- typed_acset(g1, T, V = c(1L, 2L), E = 1L)
g2 <- Graph()
add_vertices(g2, 2)
#> [1] 1 2
add_edge(g2, 1, 2)
#> [1] 1
t2 <- typed_acset(g2, T, V = c(1L, 2L), E = 1L)
tc <- typed_coproduct(t1, t2)
nv(flatten_typed(tc)) # 4
#> [1] 4
```
