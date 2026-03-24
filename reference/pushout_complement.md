# Compute pushout complement (DPO step 1)

Given l: I → L and m: L → G, find K and morphisms ik: I → K, kg: K → G
such that the square (l, m, ik, kg) is a pushout.

## Usage

``` r
pushout_complement(l, m)
```

## Arguments

- l:

  ACSetTransformation I → L

- m:

  ACSetTransformation L → G (match morphism)

## Value

List with `K` (ACSet), `ik` (I → K), `kg` (K → G), or signals an error
if gluing conditions fail.

## Details

Requires the gluing conditions:

1.  No dangling edges: deletion of a vertex doesn't orphan edges

2.  Identification: distinct deleted items aren't identified by match
