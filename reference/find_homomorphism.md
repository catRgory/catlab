# Find a homomorphism between two ACSets

Uses backtracking search to find an ACSetTransformation from `pattern`
to `target`. Returns `NULL` if no homomorphism exists.

## Usage

``` r
find_homomorphism(pattern, target, monic = FALSE, initial = NULL)
```

## Arguments

- pattern:

  Source ACSet (typically small)

- target:

  Target ACSet (typically larger)

- monic:

  Logical; if TRUE, require injective components (monomorphism)

- initial:

  Optional named list of partial assignments to seed the search

## Value

An ACSetTransformation, or NULL if none exists

## Examples

``` r
e <- path_graph(2)           # single edge: 1 -> 2
tri <- cycle_graph(3)        # triangle: 1 -> 2 -> 3 -> 1
h <- find_homomorphism(e, tri)
is_natural(h)                # TRUE
#> [1] TRUE
```
