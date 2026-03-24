# Convert an ACSet to DOT format string

Convert an ACSet to DOT format string

## Usage

``` r
to_dot(x, ...)
```

## Arguments

- x:

  An ACSet

- ...:

  Additional arguments passed to format-specific methods

## Examples

``` r
g <- path_graph(3)
cat(to_dot(g))
#> digraph G {
#>   1;
#>   2;
#>   3;
#>   1 -> 2;
#>   2 -> 3;
#> }
```
