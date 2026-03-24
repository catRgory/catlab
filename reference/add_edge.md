# Add an edge from s to t

Add an edge from s to t

## Usage

``` r
add_edge(g, s, t, ...)
```

## Arguments

- g:

  A graph ACSet

- s:

  Source vertex index

- t:

  Target vertex index

- ...:

  Additional attributes

## Examples

``` r
g <- Graph()
add_vertices(g, 2)
#> [1] 1 2
add_edge(g, 1, 2)
#> [1] 1
edge_src(g, 1) # 1
#> [1] 1
edge_tgt(g, 1) # 2
#> [1] 2
```
