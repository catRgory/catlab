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
