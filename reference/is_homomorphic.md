# Check if a homomorphism exists

Check if a homomorphism exists

## Usage

``` r
is_homomorphic(pattern, target, monic = FALSE)
```

## Arguments

- pattern:

  Source ACSet (typically small)

- target:

  Target ACSet (typically larger)

- monic:

  Logical; if TRUE, require injective components (monomorphism)

## Value

Logical

## Examples

``` r
e <- path_graph(2)
tri <- cycle_graph(3)
is_homomorphic(e, tri) # TRUE
#> [1] TRUE
```
