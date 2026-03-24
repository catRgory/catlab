# Find all homomorphisms between two ACSets

Find all homomorphisms between two ACSets

## Usage

``` r
find_all_homomorphisms(
  pattern,
  target,
  monic = FALSE,
  initial = NULL,
  limit = Inf
)
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

- limit:

  Maximum number of homomorphisms to find (default: Inf)

## Value

List of ACSetTransformations

## Examples

``` r
e <- path_graph(2)
tri <- cycle_graph(3)
hs <- find_all_homomorphisms(e, tri)
length(hs) # number of edge-embeddings into triangle
#> [1] 3
```
