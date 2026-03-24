# Product (categorical product) of two ACSets

Computes the categorical product A × B with projection morphisms. For
each object type, parts are all pairs (a, b). Homs and attrs are paired
componentwise.

## Usage

``` r
product(acs1, acs2)
```

## Arguments

- acs1:

  First ACSet

- acs2:

  Second ACSet

## Value

List with `product`, `proj1`, `proj2`

## Examples

``` r
g1 <- path_graph(2) # 1 -> 2
g2 <- path_graph(3) # 1 -> 2 -> 3
p <- product(g1, g2)
nv(p$product) # 6 (2 * 3)
#> [1] 6
```
