# Check naturality of an ACSet transformation

Check naturality of an ACSet transformation

## Usage

``` r
is_natural(alpha)
```

## Arguments

- alpha:

  An
  [ACSetTransformation](https://catrgory.github.io/catlab/reference/ACSetTransformation.md)

## Examples

``` r
g <- path_graph(2)
h <- path_graph(3)
alpha <- ACSetTransformation(
  components = list(V = c(1L, 2L), E = 1L),
  dom_acset = g, codom_acset = h
)
is_natural(alpha) # TRUE
#> [1] TRUE
```
