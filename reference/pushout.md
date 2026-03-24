# Pushout of ACSets along two morphisms from a common apex

Given f: A → B and g: A → C, compute the pushout B +\_A C.

## Usage

``` r
pushout(f, g)
```

## Arguments

- f:

  ACSetTransformation A → B

- g:

  ACSetTransformation A → C

## Examples

``` r
# Glue two edges at a shared vertex
A <- Graph(V = 1)
B <- path_graph(2) # 1 -> 2
C <- path_graph(2) # 1 -> 2
f <- ACSetTransformation(list(V = 1L, E = integer(0)), A, B)
g <- ACSetTransformation(list(V = 1L, E = integer(0)), A, C)
po <- pushout(f, g)
nv(po$pushout) # 3 (vertex 1 shared)
#> [1] 3
ne(po$pushout) # 2
#> [1] 2
```
