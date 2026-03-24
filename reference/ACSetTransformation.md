# ACSet transformation (natural transformation between ACSets)

ACSet transformation (natural transformation between ACSets)

## Usage

``` r
ACSetTransformation(
  components = list(),
  dom_acset = acsets::ACSet(),
  codom_acset = acsets::ACSet()
)
```

## Arguments

- components:

  Named list of integer vectors mapping parts

- dom_acset:

  Domain ACSet

- codom_acset:

  Codomain ACSet

## Examples

``` r
g <- path_graph(2)          # 1 -> 2
h <- path_graph(3)          # 1 -> 2 -> 3
alpha <- ACSetTransformation(
  components = list(V = c(1L, 2L), E = 1L),
  dom_acset = g, codom_acset = h
)
alpha@components$V # c(1, 2)
#> [1] 1 2
```
