# Convert an arbitrary ACSet to DOT format

Convert an arbitrary ACSet to DOT format

## Usage

``` r
generic_to_dot(acs, ...)
```

## Arguments

- acs:

  An ACSet

- ...:

  Additional arguments (currently unused)

## Value

A DOT format string

## Examples

``` r
g <- path_graph(3)
cat(generic_to_dot(g))
#> digraph G {
#>   rankdir=LR;
#>   V_1 [label="V:1" shape=box];
#>   V_2 [label="V:2" shape=box];
#>   V_3 [label="V:3" shape=box];
#>   E_1 [label="E:1" shape=box];
#>   E_2 [label="E:2" shape=box];
#>   E_1 -> V_1 [label="src"];
#>   E_2 -> V_2 [label="src"];
#>   E_1 -> V_2 [label="tgt"];
#>   E_2 -> V_3 [label="tgt"];
#> }
```
