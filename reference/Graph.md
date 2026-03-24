# Create a directed graph

Create a directed graph

## Usage

``` r
Graph(...)
```

## Arguments

- ...:

  Arguments passed to the ACSet constructor

## Examples

``` r
g <- Graph()
add_vertices(g, 3)
#> [1] 1 2 3
add_edge(g, 1, 2)
#> [1] 1
add_edge(g, 2, 3)
#> [1] 2
nv(g) # 3
#> [1] 3
ne(g) # 2
#> [1] 2
```
