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
