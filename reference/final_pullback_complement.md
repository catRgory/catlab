# Compute the final pullback complement (FPC) for SqPO rewriting

Given f: A → B and m: B → C, compute D and morphisms n: A → D, g: D → C
such that the square is a final pullback.

## Usage

``` r
final_pullback_complement(f, m)
```

## Arguments

- f:

  ACSetTransformation A → B

- m:

  ACSetTransformation B → C

## Value

List with D (ACSet), n (A → D), g (D → C)

## Details

For finite C-sets:

- Elements c in C not in m(B): kept (multiplied if hom targets are
  cloned)

- Elements c = m(b) where b in f(A): cloned (one copy per A-preimage)

- Elements c = m(b) where b not in f(A): deleted

- "Kept" elements whose hom targets were cloned are expanded (product
  rule)
