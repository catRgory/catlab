# Cascading deletion: compute subobject of G after removing matched elements

Given l: I → L and m: L → G, remove m(L) \\ m(l(I)) from G, cascading to
remove any elements that reference deleted elements.

## Usage

``` r
cascading_complement(l, m)
```

## Arguments

- l:

  ACSetTransformation I → L

- m:

  ACSetTransformation L → G

## Value

List with K (ACSet), ik (I → K), kg (K → G)
