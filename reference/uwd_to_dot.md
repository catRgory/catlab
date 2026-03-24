# Render a UWD as a DOT diagram

Boxes are rectangles, junctions are small circles, outer ports are shown
at the boundary.

## Usage

``` r
uwd_to_dot(w)
```

## Arguments

- w:

  A UWD ACSet

## Examples

``` r
w <- uwd(c("s", "r"), c("s", "i"), c("i", "r"))
cat(uwd_to_dot(w))
#> graph UWD {
#>   rankdir=LR;
#>   J_1 [label="s" shape=circle width=0.3 style=filled fillcolor=gray90];
#>   J_2 [label="r" shape=circle width=0.3 style=filled fillcolor=gray90];
#>   J_3 [label="i" shape=circle width=0.3 style=filled fillcolor=gray90];
#>   B_1 [label="Box 1" shape=box style=filled fillcolor=lightyellow];
#>   B_2 [label="Box 2" shape=box style=filled fillcolor=lightyellow];
#>   OP_1 [label="" shape=diamond width=0.2 style=filled fillcolor=black];
#>   OP_1 -- J_1;
#>   OP_2 [label="" shape=diamond width=0.2 style=filled fillcolor=black];
#>   OP_2 -- J_2;
#>   B_1 -- J_1;
#>   B_1 -- J_3;
#>   B_2 -- J_3;
#>   B_2 -- J_2;
#> }
```
