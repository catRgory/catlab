# Add a vertex, returning its ID

Add a vertex, returning its ID

## Usage

``` r
add_vertex(g, ...)
```

## Arguments

- g:

  A graph ACSet

- ...:

  Additional attributes

## Examples

``` r
g <- Graph()
v1 <- add_vertex(g)
v2 <- add_vertex(g)
nv(g) # 2
#> [1] 2
```
