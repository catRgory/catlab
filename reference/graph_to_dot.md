# Convert a graph ACSet to DOT format

Convert a graph ACSet to DOT format

## Usage

``` r
graph_to_dot(
  g,
  node_label = NULL,
  edge_label = NULL,
  directed = TRUE,
  graph_attrs = NULL
)
```

## Arguments

- g:

  A graph ACSet with V, E, src, tgt

- node_label:

  Optional attribute name to use as node labels

- edge_label:

  Optional attribute name to use as edge labels

- directed:

  Logical; if TRUE (default), produce a directed graph

- graph_attrs:

  Optional character vector of graph-level DOT attributes

## Value

A DOT format string

## Examples

``` r
g <- path_graph(3)
cat(graph_to_dot(g))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   1 -> 2;
#>   2 -> 3;
#> }
```
