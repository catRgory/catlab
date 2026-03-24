# Render an ACSet as an interactive diagram via DiagrammeR

Render an ACSet as an interactive diagram via DiagrammeR

## Usage

``` r
to_graphviz(x, ...)
```

## Arguments

- x:

  An ACSet (graph, Petri net, UWD, etc.)

- ...:

  Passed to
  [`to_dot()`](https://catrgory.github.io/catlab/reference/to_dot.md)

## Value

A DiagrammeR `htmlwidget` (displays in RStudio Viewer or notebook)

## Examples

``` r
g <- path_graph(3)
# \donttest{
to_graphviz(g)

{"x":{"diagram":"digraph G {\n  1;\n  2;\n  3;\n  1 -> 2;\n  2 -> 3;\n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}# }
```
