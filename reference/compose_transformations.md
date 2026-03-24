# Compose two ACSet transformations

Compose two ACSet transformations

## Usage

``` r
compose_transformations(alpha, beta)
```

## Arguments

- alpha:

  An
  [ACSetTransformation](https://catrgory.github.io/catlab/reference/ACSetTransformation.md)

- beta:

  An
  [ACSetTransformation](https://catrgory.github.io/catlab/reference/ACSetTransformation.md)

## Examples

``` r
g1 <- path_graph(2)
g2 <- path_graph(3)
g3 <- path_graph(4)
alpha <- ACSetTransformation(
  components = list(V = c(1L, 2L), E = 1L),
  dom_acset = g1, codom_acset = g2
)
beta <- ACSetTransformation(
  components = list(V = c(1L, 2L, 3L), E = c(1L, 2L)),
  dom_acset = g2, codom_acset = g3
)
gamma <- compose_transformations(alpha, beta)
is_natural(gamma) # TRUE
#> [1] TRUE
```
