# Coproduct (disjoint union) with injection morphisms

Coproduct (disjoint union) with injection morphisms

## Usage

``` r
coproduct(acs1, acs2)
```

## Arguments

- acs1:

  First ACSet

- acs2:

  Second ACSet

## Examples

``` r
g1 <- path_graph(2) # 1 -> 2
g2 <- path_graph(2) # 1 -> 2
cp <- coproduct(g1, g2)
nv(cp$coproduct) # 4
#> [1] 4
ne(cp$coproduct) # 2
#> [1] 2
```
