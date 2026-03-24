# Identity transformation

Identity transformation

## Usage

``` r
id_transformation(acs)
```

## Arguments

- acs:

  An ACSet

## Examples

``` r
g <- path_graph(3)
id <- id_transformation(g)
is_natural(id) # TRUE
#> [1] TRUE
id@components$V  # c(1, 2, 3)
#> [1] 1 2 3
```
