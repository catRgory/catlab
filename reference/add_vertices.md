# Add multiple vertices

Add multiple vertices

## Usage

``` r
add_vertices(g, n, ...)
```

## Arguments

- g:

  A graph ACSet

- n:

  Number of vertices to add

- ...:

  Additional attributes

## Examples

``` r
g <- Graph()
add_vertices(g, 4)
#> [1] 1 2 3 4
nv(g) # 4
#> [1] 4
```
