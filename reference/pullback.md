# Pullback of ACSets along a cospan

Given f: B → D and g: C → D, compute the pullback B ×\_D C, consisting
of pairs (b, c) where f(b) = g(c) for every object type.

## Usage

``` r
pullback(f, g)
```

## Arguments

- f:

  ACSetTransformation B → D

- g:

  ACSetTransformation C → D

## Value

List with `pullback`, `proj1`, `proj2`

## Examples

``` r
# Pullback of two maps into a common target
D <- path_graph(2) # 1 -> 2
B <- path_graph(2) # 1 -> 2
C <- path_graph(2) # 1 -> 2
f <- ACSetTransformation(list(V = c(1L, 2L), E = 1L), B, D)
g <- ACSetTransformation(list(V = c(1L, 2L), E = 1L), C, D)
pb <- pullback(f, g)
nv(pb$pullback) # 2
#> [1] 2
```
