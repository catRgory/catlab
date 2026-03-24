# Coequalizer of two parallel ACSet transformations

Given f, g: A → B, identify f(a) with g(a) for all a.

## Usage

``` r
coequalizer(f, g)
```

## Arguments

- f:

  ACSetTransformation A → B

- g:

  ACSetTransformation A → B

## Value

List with `coequalizer` (ACSet) and `proj` (projection morphism)

## Examples

``` r
A <- Graph(V = 1)
B <- Graph(V = 3)
f <- ACSetTransformation(list(V = 1L, E = integer(0)), A, B)
g <- ACSetTransformation(list(V = 2L, E = integer(0)), A, B)
ceq <- coequalizer(f, g)
nv(ceq$coequalizer) # 2 (vertices 1 and 2 identified)
#> [1] 2
```
