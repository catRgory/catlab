# Typed product of typed ACSets

Given typed ACSets phi_1: X_1 -\> T and phi_2: X_2 -\> T (over the same
type system), compute their typed product via pullback over T.

## Usage

``` r
typed_product(tacs1, tacs2)
```

## Arguments

- tacs1:

  TypedACSet

- tacs2:

  TypedACSet

## Value

TypedACSet (the product in ACSet/T)

## Details

For each object ob, the product contains pairs (x1, x2) where phi_1(x1)
== phi_2(x2). This is the categorical pullback in the slice category
ACSet/T.

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
tp <- typed_product(t1, t2)
nv(flatten_typed(tp))
#> [1] 2
```
